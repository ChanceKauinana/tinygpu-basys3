`timescale 1ns / 1ps

module button_inputs (
    clk,
    rst,

    btnU,
    btnD,
    btnL,
    btnR,
    btnC,

    btnU_clean,
    btnD_clean,
    btnL_clean,
    btnR_clean,
    btnC_clean,

    btnU_pulse,
    btnD_pulse,
    btnL_pulse,
    btnR_pulse,
    btnC_pulse
);

    input  wire clk;
    input  wire rst;

    input  wire btnU;
    input  wire btnD;
    input  wire btnL;
    input  wire btnR;
    input  wire btnC;

    output wire btnU_clean;
    output wire btnD_clean;
    output wire btnL_clean;
    output wire btnR_clean;
    output wire btnC_clean;

    output wire btnU_pulse;
    output wire btnD_pulse;
    output wire btnL_pulse;
    output wire btnR_pulse;
    output wire btnC_pulse;

    button_pulse u_btnU (
        .clk          (clk),
        .rst          (rst),
        .button_in    (btnU),
        .button_clean (btnU_clean),
        .pulse_out    (btnU_pulse)
    );

    button_pulse u_btnD (
        .clk          (clk),
        .rst          (rst),
        .button_in    (btnD),
        .button_clean (btnD_clean),
        .pulse_out    (btnD_pulse)
    );

    button_pulse u_btnL (
        .clk          (clk),
        .rst          (rst),
        .button_in    (btnL),
        .button_clean (btnL_clean),
        .pulse_out    (btnL_pulse)
    );

    button_pulse u_btnR (
        .clk          (clk),
        .rst          (rst),
        .button_in    (btnR),
        .button_clean (btnR_clean),
        .pulse_out    (btnR_pulse)
    );

    button_pulse u_btnC (
        .clk          (clk),
        .rst          (rst),
        .button_in    (btnC),
        .button_clean (btnC_clean),
        .pulse_out    (btnC_pulse)
    );

endmodule