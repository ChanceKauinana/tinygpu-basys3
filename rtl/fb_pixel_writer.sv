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

    // Draw a visible 32x32 square near the center.
    localparam [8:0] START_X = 9'd144;
    localparam [7:0] START_Y = 8'd104;
    localparam [8:0] SIZE    = 9'd32;

    // White in RGB332.
    localparam [7:0] PIXEL_COLOR = 8'b111_111_11;

    reg [8:0] dx;
    reg [7:0] dy;

    wire [8:0] current_x;
    wire [7:0] current_y;

    assign current_x = START_X + dx;
    assign current_y = START_Y + dy;

    always @(posedge clk) begin
        if (rst) begin
            dx         <= 9'd0;
            dy         <= 8'd0;
            write_addr <= 17'd0;
            write_data <= 8'd0;
            write_en   <= 1'b0;
        end else begin
            write_en   <= 1'b1;
            write_addr <= (current_y << 8) + (current_y << 6) + current_x;
            write_data <= PIXEL_COLOR;

            if (dx == SIZE - 1) begin
                dx <= 9'd0;

                if (dy == SIZE - 1) begin
                    dy <= 8'd0;   // restart square forever
                end else begin
                    dy <= dy + 8'd1;
                end
            end else begin
                dx <= dx + 9'd1;
            end
        end
    end

endmodule