`timescale 1ns / 1ps

module fb_checkerboard_writer (
    clk,
    rst,

    write_addr,
    write_data,
    write_en
);

    input  wire        clk;
    input  wire        rst;

    output reg  [16:0] write_addr;
    output reg  [7:0]  write_data;
    output reg         write_en;

    localparam FB_WIDTH  = 320;
    localparam FB_HEIGHT = 240;
    localparam FB_SIZE   = FB_WIDTH * FB_HEIGHT;

    reg [8:0] x;
    reg [7:0] y;

    always @(posedge clk) begin
        if (rst) begin
            x          <= 9'd0;
            y          <= 8'd0;
            write_addr <= 17'd0;
            write_data <= 8'd0;
            write_en   <= 1'b0;
        end else begin
            write_en   <= 1'b1;
            write_addr <= (y << 8) + (y << 6) + x;

            // 16x16 checkerboard pattern.
            // RGB332 color format:
            // 8'b111_111_11 = white
            // 8'b000_000_00 = black
            if (x[4] ^ y[4]) begin
                write_data <= 8'b111_111_11; // white
            end else begin
                write_data <= 8'b000_000_00; // black
            end

            if (x == FB_WIDTH - 1) begin
                x <= 9'd0;

                if (y == FB_HEIGHT - 1) begin
                    y <= 8'd0;
                end else begin
                    y <= y + 8'd1;
                end
            end else begin
                x <= x + 9'd1;
            end
        end
    end

endmodule