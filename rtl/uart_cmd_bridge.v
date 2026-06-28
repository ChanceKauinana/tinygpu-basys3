`timescale 1ns / 1ps
`default_nettype none

module uart_cmd_bridge (
    clk_uart,
    rst_uart,
    cmd_uart,

    clk_pixel,
    rst_pixel,
    cmd_pixel
);

    input  wire clk_uart;
    input  wire rst_uart;
    input  wire cmd_uart;

    input  wire clk_pixel;
    input  wire rst_pixel;
    output reg  cmd_pixel;

    reg toggle_uart;

    (* ASYNC_REG = "TRUE" *) reg toggle_sync_0;
    (* ASYNC_REG = "TRUE" *) reg toggle_sync_1;
    (* ASYNC_REG = "TRUE" *) reg toggle_sync_2;

    always @(posedge clk_uart) begin
        if (rst_uart) begin
            toggle_uart <= 1'b0;
        end else begin
            if (cmd_uart) begin
                toggle_uart <= ~toggle_uart;
            end
        end
    end

    always @(posedge clk_pixel) begin
        if (rst_pixel) begin
            toggle_sync_0 <= 1'b0;
            toggle_sync_1 <= 1'b0;
            toggle_sync_2 <= 1'b0;
            cmd_pixel    <= 1'b0;
        end else begin
            toggle_sync_0 <= toggle_uart;
            toggle_sync_1 <= toggle_sync_0;
            toggle_sync_2 <= toggle_sync_1;

            cmd_pixel <= toggle_sync_1 ^ toggle_sync_2;
        end
    end

endmodule

`default_nettype wire