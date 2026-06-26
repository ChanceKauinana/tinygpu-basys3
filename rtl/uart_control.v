`timescale 1ns / 1ps
`default_nettype none

module uart_control (
    clk,
    rst,

    rx_data,
    rx_valid,

    uart_btnU,
    uart_btnD,
    uart_btnL,
    uart_btnR,
    uart_btnC
);

    input  wire       clk;
    input  wire       rst;

    input  wire [7:0] rx_data;
    input  wire       rx_valid;

    output reg        uart_btnU;
    output reg        uart_btnD;
    output reg        uart_btnL;
    output reg        uart_btnR;
    output reg        uart_btnC;

    always @(posedge clk) begin
        if (rst) begin
            uart_btnU <= 1'b0;
            uart_btnD <= 1'b0;
            uart_btnL <= 1'b0;
            uart_btnR <= 1'b0;
            uart_btnC <= 1'b0;
        end else begin
            // Default: no command pulse.
            uart_btnU <= 1'b0;
            uart_btnD <= 1'b0;
            uart_btnL <= 1'b0;
            uart_btnR <= 1'b0;
            uart_btnC <= 1'b0;

            if (rx_valid) begin
                case (rx_data)
                    8'h77: uart_btnU <= 1'b1; // 'w'
                    8'h73: uart_btnD <= 1'b1; // 's'
                    8'h61: uart_btnL <= 1'b1; // 'a'
                    8'h64: uart_btnR <= 1'b1; // 'd'
                    8'h63: uart_btnC <= 1'b1; // 'c'

                    8'h57: uart_btnU <= 1'b1; // 'W'
                    8'h53: uart_btnD <= 1'b1; // 'S'
                    8'h41: uart_btnL <= 1'b1; // 'A'
                    8'h44: uart_btnR <= 1'b1; // 'D'
                    8'h43: uart_btnC <= 1'b1; // 'C'

                    default: begin
                        uart_btnU <= 1'b0;
                        uart_btnD <= 1'b0;
                        uart_btnL <= 1'b0;
                        uart_btnR <= 1'b0;
                        uart_btnC <= 1'b0;
                    end
                endcase
            end
        end
    end

endmodule

`default_nettype wire