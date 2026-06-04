`timescale 1ns / 1ps
`default_nettype none

// Module: framebuffer
// Purpose: Store and provide framebuffer pixels for VGA output.
// Inputs: synchronous read and write ports with addresses, data, and enables
// Outputs: pixel color data for the current read address
// Pixel format: 8-bit RGB332 (R:3, G:3, B:2).
module framebuffer (
    read_clk,
    read_addr,
    read_data,

    write_clk,
    write_addr,
    write_data,
    write_en
);

    input  wire        read_clk;
    input  wire [16:0] read_addr;
    output reg  [7:0]  read_data;


    input  wire        write_clk;
    input  wire [16:0] write_addr;
    input  wire [7:0]  write_data;
    input  wire        write_en;

    localparam FB_WIDTH  = 320;
    localparam FB_HEIGHT = 240;
    localparam FB_SIZE   = FB_WIDTH * FB_HEIGHT;

    (* ram_style = "block" *)
    reg [7:0] mem [0:FB_SIZE-1];

    // Synchronous read port with out-of-range protection.
    always @(posedge read_clk) begin
        if (read_addr < FB_SIZE) begin
            read_data <= mem[read_addr];
        end else begin
            read_data <= 8'd0;
        end
    end

    // Synchronous write port with address range checking.
    always @(posedge write_clk) begin
        if (write_en && (write_addr < FB_SIZE)) begin
            mem[write_addr] <= write_data;
        end
    end

endmodule

`default_nettype wire