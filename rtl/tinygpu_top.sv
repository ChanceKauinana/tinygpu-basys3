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
    // ------------------------------------------------------------

    wire [8:0] fb_x;
    wire [7:0] fb_y;

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

    reg visible_d;

    always @(posedge pixel_clk) begin
        visible_d <= visible_raw;
        Hsync     <= hsync_raw;
        Vsync     <= vsync_raw;
    end


    // ------------------------------------------------------------
    // Convert 8-bit RGB332 framebuffer color to 12-bit VGA RGB444
    // ------------------------------------------------------------

    always @(*) begin
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (visible_d) begin
            vgaRed   = {fb_color[7:5], fb_color[7]};
            vgaGreen = {fb_color[4:2], fb_color[4]};
            vgaBlue  = {fb_color[1:0], fb_color[1:0]};
        end
    end

endmodule

`default_nettype wire