`timescale 1ns / 1ps
`default_nettype none

module tinygpu_top (
    clk,
    vgaRed,
    vgaGreen,
    vgaBlue,
    Hsync,
    Vsync
);

    input  wire       clk;
    output reg  [3:0] vgaRed;
    output reg  [3:0] vgaGreen;
    output reg  [3:0] vgaBlue;
    output reg        Hsync;
    output reg        Vsync;

    // Top-level tiny GPU module for the Basys 3 board.
    // This module demonstrates a minimal framebuffer pipeline:
    // - divide the 100 MHz system clock down to a pixel clock (~25 MHz)
    // - drive a VGA timing generator to produce `x`, `y`, and syncs
    // - map 640x480 VGA coordinates into a 320x240 framebuffer
    // - read a byte per pixel (RGB332) from the framebuffer
    // - convert RGB332 into RGB444 and drive the VGA outputs

    // ------------------------------------------------------------
    // Clock divider
    // ------------------------------------------------------------

    reg [1:0] clk_div = 2'b00;
    wire      pixel_clk;

    always @(posedge clk) begin
        clk_div <= clk_div + 2'b01;
    end

    assign pixel_clk = clk_div[1];


    // ------------------------------------------------------------
    // VGA timing signals
    // ------------------------------------------------------------

    // Signals produced by the VGA timing generator.
    // `vga_x`/`vga_y` count across the full scan including porches.
    wire [9:0] vga_x;
    wire [9:0] vga_y;
    wire       visible_raw; // high when inside the visible area
    wire       hsync_raw;   // raw hsync from timing module (active low)
    wire       vsync_raw;   // raw vsync from timing module (active low)

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
    // ------------------------------------------------------------

    // Convert 640x480 VGA coordinates to 320x240 framebuffer coordinates.
    // The framebuffer is half resolution in both dimensions, so we drop
    // the LSB of each coordinate (i.e. divide by two) by taking a slice.
    // When outside the visible region, drive coordinates to zero to
    // avoid reading out-of-bounds framebuffer addresses.
    wire [8:0] fb_x;
    wire [7:0] fb_y;

    // vga_x is 10 bits (0..799). Taking bits [9:1] divides by two -> 0..399.
    // The framebuffer width is 320, and `framebuffer_addr` will mark
    // coordinates out-of-range as invalid via its `valid` output.
    assign fb_x = visible_raw ? vga_x[9:1] : 9'd0;
    assign fb_y = visible_raw ? vga_y[8:1] : 8'd0;


    // ------------------------------------------------------------
    // Framebuffer address calculation
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
    // ------------------------------------------------------------

    wire [7:0] fb_color;

    framebuffer fb_inst (
        .read_addr (fb_read_addr),
        .read_clk  (pixel_clk),
        .read_data (fb_color),

        .write_addr(17'd0),
        .write_data(8'd0),
        .write_en  (1'b0),
        .write_clk (pixel_clk)
    );


    // ------------------------------------------------------------
    // Delay visible/sync signals by one pixel clock
    // ------------------------------------------------------------

    // Delay the visible flag by one pixel clock. The framebuffer read
    // is synchronous and returns data one clock after `read_addr` is
    // presented; by delaying `visible` we align the enable with the
    // valid `fb_color` output. Sync signals are passed through directly
    // (they are aligned with the pixel stream produced by the timing
    // generator) but we still register them to the pixel clock domain.
    reg visible_d;

    always @(posedge pixel_clk) begin
        visible_d <= visible_raw;
        Hsync     <= hsync_raw;
        Vsync     <= vsync_raw;
    end


    // ------------------------------------------------------------
    // Convert 8-bit RGB332 framebuffer color to 12-bit VGA RGB444
    // ------------------------------------------------------------

    // Convert 8-bit framebuffer color (RGB332) to 12-bit VGA color (RGB444).
    // RGB332 layout: [7:5] = R (3 bits), [4:2] = G (3 bits), [1:0] = B (2 bits).
    // We expand each field to 4 bits by repeating the MSB to LSB to approximate
    // brightness scaling: e.g., {r2,r1,r0,r2} maps 3->4 bits.
    always @(*) begin
        // default to black
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (visible_d) begin
            // Replicate the top bit to fill the 4th LSB for visual intensity.
            vgaRed   = {fb_color[7:5], fb_color[7]};        // RRR -> RRRR
            vgaGreen = {fb_color[4:2], fb_color[4]};        // GGG -> GGGG
            vgaBlue  = {fb_color[1:0], fb_color[1:0]};      // BB  -> BBBB by repeat
        end
    end

endmodule

`default_nettype wire