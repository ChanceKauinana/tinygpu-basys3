`timescale 1ns / 1ps

module fb_pixel_writer (
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

    // Chosen test pixel
    localparam [8:0] PIXEL_X = 9'd160;
    localparam [7:0] PIXEL_Y = 8'd120;

    // RGB332 color
    localparam [7:0] PIXEL_COLOR = 8'b111_111_11; // white

    reg done;

    always @(posedge clk) begin
        if (rst) begin
            write_addr <= 17'd0;
            write_data <= 8'd0;
            write_en   <= 1'b0;
            done       <= 1'b0;
        end else begin
            if (!done) begin
                // addr = y * 320 + x
                // 320 = 256 + 64
                write_addr <= (PIXEL_Y << 8) + (PIXEL_Y << 6) + PIXEL_X;
                write_data <= PIXEL_COLOR;
                write_en   <= 1'b1;
                done       <= 1'b1;
            end else begin
                write_en <= 1'b0;
            end
        end
    end

endmodule