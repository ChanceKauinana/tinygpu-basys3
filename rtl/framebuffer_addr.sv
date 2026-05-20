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

    // Zero-extend the input coordinates to the full address-width so
    // we can perform wider arithmetic without overflow.
    // `x` is 9 bits (0..511), `y` is 8 bits (0..255) in this design.
    assign x_ext = {8'b0, x}; // extend `x` to 17 bits
    assign y_ext = {9'b0, y}; // extend `y` to 17 bits

    // Valid indicates whether the (x,y) coordinate lies inside the
    // framebuffer rectangle. This allows the caller to skip reads or
    // handle out-of-bounds coordinates gracefully.
    assign valid = (x < FB_WIDTH) && (y < FB_HEIGHT);

    // Compute linear framebuffer address for row-major storage:
    //   addr = y * FB_WIDTH + x
    // For efficiency, use shifts and adds rather than a multiplier:
    //   FB_WIDTH = 320 = 256 + 64 = (1<<8) + (1<<6)
    // so y*320 = (y << 8) + (y << 6)
    // Final address is the sum of that product plus x.
    assign addr = (y_ext << 8) + (y_ext << 6) + x_ext;

endmodule

`default_nettype wire