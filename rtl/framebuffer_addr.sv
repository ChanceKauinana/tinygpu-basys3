`timescale 1ns / 1ps
`default_nettype none

// Simple helper module that converts 2D framebuffer coordinates
// (x,y) into a linear memory address used to index a frame buffer
// stored in row-major order. This module also reports whether the
// supplied coordinates lie inside the valid framebuffer rectangle.
//
// Why this exists: memories are one-dimensional, but screens are 2D.
// We need a deterministic mapping from (row, column) -> linear index.
module framebuffer_addr (
    x,
    y,
    addr,
    valid
);

    // Inputs:
    //  - `x`: horizontal coordinate in framebuffer space (0..FB_WIDTH-1).
    //         9 bits are used to give room when interfacing with larger
    //         upstream coordinates (e.g., converted from 640->320 scaling).
    //  - `y`: vertical coordinate in framebuffer space (0..FB_HEIGHT-1).
    //         8 bits are sufficient for 240 rows.
    input  wire [8:0]  x;
    input  wire [7:0]  y;

    // Outputs:
    //  - `addr`: linear address into the framebuffer memory. Width is 17
    //            bits to comfortably hold all pixel addresses for 320x240.
    //  - `valid`: high when (x,y) is inside the framebuffer bounds.
    output wire [16:0] addr;
    output wire        valid;

    // Framebuffer dimensions used by this mapping. Using `localparam`
    // makes the numbers easy to change in one place if we port the
    // design to a different resolution later.
    localparam FB_WIDTH  = 320;
    localparam FB_HEIGHT = 240;

    // We will do arithmetic in a wider bit-width to avoid overflow when
    // shifting/adding. `addr` is 17 bits so extend `x` and `y` to 17 bits
    // before performing multiplication (via shifts) and addition.
    wire [16:0] x_ext;
    wire [16:0] y_ext;

    // Zero-extend the smaller input vectors into the wider working width.
    // Example: if x=9'b000101101 then x_ext becomes 17'b00000000_000101101.
    assign x_ext = {8'b0, x}; // extend `x` (9 bits -> 17 bits)
    assign y_ext = {9'b0, y}; // extend `y` (8 bits -> 17 bits)

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