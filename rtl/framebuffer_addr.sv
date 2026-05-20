`timescale 1ns / 1ps
`default_nettype none

module framebuffer_addr (
    input  logic [8:0]  x,       // 0 to 319 for 320-wide framebuffer
    input  logic [7:0]  y,       // 0 to 239 for 240-tall framebuffer

    output logic [16:0] addr,    // enough for addresses 0 to 76799
    output logic        valid    // high when x/y are inside the framebuffer
);

    localparam int FB_WIDTH  = 320;
    localparam int FB_HEIGHT = 240;

    // Extend x and y to 17 bits before doing math.
    // This avoids accidental truncation during shifts/addition.
    logic [16:0] x_ext;
    logic [16:0] y_ext;

    assign x_ext = {8'b0, x};  // 9-bit x becomes 17-bit
    assign y_ext = {9'b0, y};  // 8-bit y becomes 17-bit

    // valid tells the rest of the design whether this coordinate is on-screen.
    assign valid = (x < FB_WIDTH) && (y < FB_HEIGHT);

    // Address formula:
    //
    // addr = y * 320 + x
    //
    // Since 320 = 256 + 64:
    //
    // y * 320 = (y << 8) + (y << 6)
    //
    // This avoids a general multiplier.
    assign addr = (y_ext << 8) + (y_ext << 6) + x_ext;

endmodule

`default_nettype wire