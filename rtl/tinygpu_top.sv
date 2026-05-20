`timescale 1ns / 1ps
`default_nettype none

module tinygpu_top (
    // Top-level module for a tiny GPU that drives a VGA output.
    // - `clk` is the incoming system clock (fast). We divide this
    //   down to create a `pixel_clk` used by VGA timing and the
    //   framebuffer. All visible/video operations run on `pixel_clk`.
    // - `vgaRed`, `vgaGreen`, `vgaBlue` are the 4-bit color outputs
    //   sent to the VGA DAC for each pixel (R,G,B each 4 bits -> 12-bit color).
    // - `Hsync` and `Vsync` are the horizontal and vertical sync
    //   signals required by the VGA monitor to know frame/line timing.
    clk,
    vgaRed,
    vgaGreen,
    vgaBlue,
    Hsync,
    Vsync
);

    input  wire       clk;           // incoming system clock (e.g., 100 MHz)
    output reg  [3:0] vgaRed;        // 4-bit red output for VGA
    output reg  [3:0] vgaGreen;      // 4-bit green output for VGA
    output reg  [3:0] vgaBlue;       // 4-bit blue output for VGA
    output reg        Hsync;         // horizontal sync pulse for VGA
    output reg        Vsync;         // vertical sync pulse for VGA

    // ------------------------------------------------------------
    // Clock divider
    // We take the incoming `clk` and divide it down by 4 to
    // generate a `pixel_clk`. The VGA timing module expects a
    // pixel clock that steps once per visible pixel; dividing the
    // system clock lets us match that rate.
    // ------------------------------------------------------------

    reg [1:0] clk_div = 2'b00; // small counter to divide clock by 4
    wire      pixel_clk;       // lower-speed clock used for pixels

    // Simple binary counter clock divider. Every rising edge increments
    // `clk_div`. The MSB (`clk_div[1]`) toggles once for every four
    // input clock cycles, producing our pixel clock.
    always @(posedge clk) begin
        clk_div <= clk_div + 2'b01;
    end

    assign pixel_clk = clk_div[1];


    // ------------------------------------------------------------
    // VGA timing signals
    // The `vga_timing` module generates the current pixel coordinates
    // (`vga_x`, `vga_y`) and the raw `visible`, `hsync`, `vsync` signals
    // according to the VGA 640x480 timing standard. These tell us when
    // to output pixels and when the monitor is in blanking intervals.
    // ------------------------------------------------------------

    wire [9:0] vga_x;
    wire [9:0] vga_y;
    wire       visible_raw;
    wire       hsync_raw;
    wire       vsync_raw;

    vga_timing timing_inst (
        .pixel_clk(pixel_clk),
        .rst      (1'b0),
        .x        (vga_x),
        .y        (vga_y),
        .visible  (visible_raw),
        .hsync    (hsync_raw),
        .vsync    (vsync_raw)
    );


    // ------------------------------------------------------------
    // Convert 640x480 VGA coordinates to 320x240 framebuffer coords
    // The physical VGA signal is 640x480. Our framebuffer stores a smaller
    // image at 320x240 to save memory. We convert coordinates by dropping
    // the least significant bit (i.e., dividing by 2) when the pixel is
    // within the visible area. Outside the visible area we set coords to 0.
    // ------------------------------------------------------------

    wire [8:0] fb_x;
    wire [7:0] fb_y;

    // Use the raw visible signal to gate coordinate conversion so that
    // we only request framebuffer pixels when the monitor is actually
    // displaying them. `vga_x[9:1]` and `vga_y[8:1]` perform the divide
    // by two needed to convert from 640x480 -> 320x240.
    assign fb_x = visible_raw ? vga_x[9:1] : 9'd0;
    assign fb_y = visible_raw ? vga_y[8:1] : 8'd0;


    // ------------------------------------------------------------
    // Framebuffer address calculation
    // Given an (x,y) coordinate in the framebuffer space, compute the
    // linear memory address used to read the pixel color from RAM.
    // The `framebuffer_addr` module encapsulates how 2D coordinates map
    // to a 1D address (for example row-major ordering).
    // ------------------------------------------------------------

    wire [16:0] fb_read_addr;
    wire        fb_coord_valid;

    framebuffer_addr fb_addr_inst (
        .x    (fb_x),
        .y    (fb_y),
        .addr (fb_read_addr),
        .valid(fb_coord_valid)
    );


    // ------------------------------------------------------------
    // Framebuffer memory
    // The framebuffer stores pixel colors. In this design the color is
    // 8 bits wide and encoded as RGB332 (3 bits red, 3 bits green, 2 bits blue).
    // A separate writer module (`fb_pixel_writer`) can write test patterns
    // into the framebuffer for demonstrations or debugging.
    // ------------------------------------------------------------

    wire [7:0]  fb_color;

    wire [16:0] test_write_addr;
    wire [7:0]  test_write_data;
    wire        test_write_en;

    // This instance can be replaced with real camera/frame generator logic.
    fb_pixel_writer test_writer_inst (
        .clk        (pixel_clk),
        .rst        (1'b0),
        .write_addr (test_write_addr),
        .write_data (test_write_data),
        .write_en   (test_write_en)
    );

    // `framebuffer` is a dual-port memory: one port is read by the VGA
    // pipeline (using `read_addr`/`read_clk`), the other can be written by
    // a writer (here `test_writer_inst`). The read data `fb_color` is the
    // 8-bit RGB332 pixel value we will convert to VGA levels.
    framebuffer fb_inst (
        .read_addr  (fb_read_addr),
        .read_clk   (pixel_clk),
        .read_data  (fb_color),

        .write_addr(test_write_addr),
        .write_data(test_write_data),
        .write_en  (test_write_en),
        .write_clk (pixel_clk)
    );

    // ------------------------------------------------------------
    // Delay visible/sync signals by one pixel clock
    // Many video pipelines need signals aligned to the pixel data. The
    // timing module produced `visible_raw`, `hsync_raw`, `vsync_raw` at
    // the current pixel time. We register (`<=`) them on the rising edge
    // of `pixel_clk` so that the sync outputs and our visible flag are
    // stable when we use `fb_color` to drive the DAC outputs.
    // ------------------------------------------------------------

    reg visible_d;

    always @(posedge pixel_clk) begin
        visible_d <= visible_raw; // registered (one-cycle delayed) visible
        Hsync     <= hsync_raw;   // output sync signals registered to pixel clock
        Vsync     <= vsync_raw;
    end


    // ------------------------------------------------------------
    // Convert 8-bit RGB332 framebuffer color to 12-bit VGA RGB444
    // Our framebuffer stores color in RGB332 format: bits [7:5]=R, [4:2]=G, [1:0]=B.
    // The VGA output expects 4 bits per channel (RGB444). To expand the
    // smaller number of bits to 4 bits we replicate the most significant
    // bit(s) into the lower bits. This is a simple way to scale color
    // without doing any arithmetic. When `visible_d` is false (blanking),
    // we drive black (all zeros) to the DAC.
    // ------------------------------------------------------------

    always @(*) begin
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (visible_d) begin
            // For red: take 3 bits and repeat the top bit to make 4 bits.
            // Example: R=101 -> {101,1} = 1011
            vgaRed   = {fb_color[7:5], fb_color[7]};

            // For green: same idea with bits [4:2]
            vgaGreen = {fb_color[4:2], fb_color[4]};

            // For blue: we only have 2 bits; repeat them to fill 4 bits.
            // {b1,b0,b1,b0} gives a reasonable expansion for 2->4 bits.
            vgaBlue  = {fb_color[1:0], fb_color[1:0]};
        end
    end

endmodule

`default_nettype wire