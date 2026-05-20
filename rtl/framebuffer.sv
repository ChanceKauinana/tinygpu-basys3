`timescale 1ns / 1ps
`default_nettype none

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

    integer init_x;
    integer init_y;
    integer init_addr;

    initial begin
        for (init_y = 0; init_y < FB_HEIGHT; init_y = init_y + 1) begin
            for (init_x = 0; init_x < FB_WIDTH; init_x = init_x + 1) begin
                init_addr = init_y * FB_WIDTH + init_x;

                if (init_x < FB_WIDTH / 3) begin
                    mem[init_addr] = 8'b111_000_00; // red
                end else if (init_x < (2 * FB_WIDTH) / 3) begin
                    mem[init_addr] = 8'b000_111_00; // green
                end else begin
                    mem[init_addr] = 8'b000_000_11; // blue
                end
            end
        end
    end

    always @(posedge read_clk) begin
        if (read_addr < 17'd76800) begin
            read_data <= mem[read_addr];
        end else begin
            read_data <= 8'd0;
        end
    end

    always @(posedge write_clk) begin
        if (write_en && (write_addr < 17'd76800)) begin
            mem[write_addr] <= write_data;
        end
    end

endmodule

`default_nettype wire