`timescale 1ns / 1ps
`default_nettype none

module uart_rx (
    clk,
    rst,
    rx,
    rx_data,
    rx_valid
);

    input  wire       clk;
    input  wire       rst;
    input  wire       rx;

    output reg  [7:0] rx_data;
    output reg        rx_valid;

    // For 100 MHz clock and 9600 baud:
    // 100,000,000 / 9600 = 10416.67
    parameter CLKS_PER_BIT = 10417;

    localparam STATE_IDLE  = 2'd0;
    localparam STATE_START = 2'd1;
    localparam STATE_DATA  = 2'd2;
    localparam STATE_STOP  = 2'd3;

    reg [1:0]  state     = STATE_IDLE;
    reg [13:0] clk_count = 14'd0;
    reg [2:0]  bit_index = 3'd0;
    reg [7:0]  rx_shift  = 8'd0;

    // Synchronize async UART input into clk domain
    reg rx_sync_0 = 1'b1;
    reg rx_sync_1 = 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            state     <= STATE_IDLE;
            clk_count <= 14'd0;
            bit_index <= 3'd0;
            rx_shift  <= 8'd0;
            rx_data   <= 8'd0;
            rx_valid  <= 1'b0;
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;
        end else begin
            rx_valid <= 1'b0;

            rx_sync_0 <= rx;
            rx_sync_1 <= rx_sync_0;

            case (state)
                STATE_IDLE: begin
                    clk_count <= 14'd0;
                    bit_index <= 3'd0;

                    // UART line is normally high. A low means start bit.
                    if (rx_sync_1 == 1'b0) begin
                        state <= STATE_START;
                    end
                end

                STATE_START: begin
                    // Wait half a bit time, then confirm start bit is still low.
                    if (clk_count == (CLKS_PER_BIT / 2)) begin
                        if (rx_sync_1 == 1'b0) begin
                            clk_count <= 14'd0;
                            state     <= STATE_DATA;
                        end else begin
                            state <= STATE_IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 14'd1;
                    end
                end

                STATE_DATA: begin
                    // Sample each data bit in the middle of its bit period.
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 14'd0;

                        // UART sends least-significant bit first.
                        rx_shift[bit_index] <= rx_sync_1;

                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state     <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 3'd1;
                        end
                    end else begin
                        clk_count <= clk_count + 14'd1;
                    end
                end

                STATE_STOP: begin
                    // Wait one stop-bit period, then output the received byte.
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 14'd0;
                        rx_data   <= rx_shift;
                        rx_valid  <= 1'b1;
                        state     <= STATE_IDLE;
                    end else begin
                        clk_count <= clk_count + 14'd1;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule

`default_nettype wire