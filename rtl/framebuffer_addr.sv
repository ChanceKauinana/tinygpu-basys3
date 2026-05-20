`timescale 1ns / 1ps
`default_nettype none

module framebuffer_addr (
    x,
    y,
    addr,
    valid
);

    input  wire [8:0]  x;
    input  wire [7:0]  y;
    output wire [16:0] addr;
    output wire        valid;

    localparam FB_WIDTH  = 320;
    localparam FB_HEIGHT = 240;

    wire [16:0] x_ext;
    wire [16:0] y_ext;

    assign x_ext = {8'b0, x};
    assign y_ext = {9'b0, y};

    assign valid = (x < FB_WIDTH) && (y < FB_HEIGHT);

    // addr = y * 320 + x
    // 320 = 256 + 64
    assign addr = (y_ext << 8) + (y_ext << 6) + x_ext;

endmodule

`default_nettype wire