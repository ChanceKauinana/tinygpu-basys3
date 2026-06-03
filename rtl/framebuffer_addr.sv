`timescale 1ns / 1ps
`default_nettype none

// Module: framebuffer_addr
// Purpose: Convert 2D framebuffer coordinates into a linear address
//          and indicate whether the coordinates are valid.
// Inputs: framebuffer x/y coordinates
// Outputs: linear memory address, valid flag
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

    // Framebuffer dimensions used by this mapping. Using `localparam`
    // makes the numbers easy to change in one place if we port the
    // design to a different resolution later.
    localparam FB_WIDTH  = 320;
    localparam FB_HEIGHT = 240;

    // Compute row-major framebuffer addresses without a multiplier.
    wire [16:0] x_ext;
    wire [16:0] y_ext;

    assign x_ext = {8'b0, x};
    assign y_ext = {9'b0, y};

    // `valid` tells the caller whether the supplied coordinates are within
    // the framebuffer area. This prevents accidental reads outside memory
    // bounds when upstream logic might present out-of-range coordinates.
    assign valid = (x < FB_WIDTH) && (y < FB_HEIGHT);

    // Compute the linear address for row-major order:
    //   addr = y * FB_WIDTH + x
    // Instead of using a hardware multiplier, we exploit that
    // FB_WIDTH = 320 = 256 + 64 = (1<<8) + (1<<6).
    // Therefore: y*320 = (y << 8) + (y << 6)
    // This uses only shifts and adds which are cheap in hardware.
    // Finally we add `x` to get the final address within the row.
    //
    // Example: for x=10, y=2 -> addr = 2*320 + 10 = 640 + 10 = 650
    assign addr = (y_ext << 8) + (y_ext << 6) + x_ext;

endmodule

`default_nettype wire