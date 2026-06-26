`timescale 1ns / 1ps
`default_nettype none

module uart_command_sync (
    clk_uart,
    rst_uart,

    clk_pixel,
    rst_pixel,

    uart_btnU,
    uart_btnD,
    uart_btnL,
    uart_btnR,
    uart_btnC,

    uart_btnU_pix,
    uart_btnD_pix,
    uart_btnL_pix,
    uart_btnR_pix,
    uart_btnC_pix
);

    input  wire clk_uart;
    input  wire rst_uart;

    input  wire clk_pixel;
    input  wire rst_pixel;

    input  wire uart_btnU;
    input  wire uart_btnD;
    input  wire uart_btnL;
    input  wire uart_btnR;
    input  wire uart_btnC;

    output wire uart_btnU_pix;
    output wire uart_btnD_pix;
    output wire uart_btnL_pix;
    output wire uart_btnR_pix;
    output wire uart_btnC_pix;

    uart_cmd_bridge bridge_U (
        .clk_uart  (clk_uart),
        .rst_uart  (rst_uart),
        .cmd_uart  (uart_btnU),
        .clk_pixel (clk_pixel),
        .rst_pixel (rst_pixel),
        .cmd_pixel (uart_btnU_pix)
    );

    uart_cmd_bridge bridge_D (
        .clk_uart  (clk_uart),
        .rst_uart  (rst_uart),
        .cmd_uart  (uart_btnD),
        .clk_pixel (clk_pixel),
        .rst_pixel (rst_pixel),
        .cmd_pixel (uart_btnD_pix)
    );

    uart_cmd_bridge bridge_L (
        .clk_uart  (clk_uart),
        .rst_uart  (rst_uart),
        .cmd_uart  (uart_btnL),
        .clk_pixel (clk_pixel),
        .rst_pixel (rst_pixel),
        .cmd_pixel (uart_btnL_pix)
    );

    uart_cmd_bridge bridge_R (
        .clk_uart  (clk_uart),
        .rst_uart  (rst_uart),
        .cmd_uart  (uart_btnR),
        .clk_pixel (clk_pixel),
        .rst_pixel (rst_pixel),
        .cmd_pixel (uart_btnR_pix)
    );

    uart_cmd_bridge bridge_C (
        .clk_uart  (clk_uart),
        .rst_uart  (rst_uart),
        .cmd_uart  (uart_btnC),
        .clk_pixel (clk_pixel),
        .rst_pixel (rst_pixel),
        .cmd_pixel (uart_btnC_pix)
    );

endmodule

`default_nettype wire