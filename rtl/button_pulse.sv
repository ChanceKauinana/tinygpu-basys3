`timescale 1ns / 1ps

module button_pulse (
    clk,
    rst,
    button_in,
    button_clean,
    pulse_out
);

    input  wire clk;
    input  wire rst;
    input  wire button_in;

    output reg button_clean;
    output reg  pulse_out;

    // Synchronize button to clock
    reg button_sync_0;
    reg button_sync_1;

    // Debounce counter
    reg [19:0] debounce_count;
    reg        button_stable_prev;

    always @(posedge clk) begin
        if (rst) begin
            button_sync_0     <= 1'b0;
            button_sync_1     <= 1'b0;
            debounce_count    <= 20'd0;
            button_clean      <= 1'b0;
            button_stable_prev<= 1'b0;
            pulse_out         <= 1'b0;
        end else begin
            // Synchronizer
            button_sync_0 <= button_in;
            button_sync_1 <= button_sync_0;

            // Debounce:
            // If synchronized input equals current stable state, reset counter.
            // If different for long enough, accept new state.
            if (button_sync_1 == button_clean) begin
                debounce_count <= 20'd0;
            end else begin
                debounce_count <= debounce_count + 20'd1;

                if (debounce_count == 20'hFFFFF) begin
                    button_clean  <= button_sync_1;
                    debounce_count <= 20'd0;
                end
            end

            button_stable_prev <= button_clean;

            // Create one-clock pulse on rising edge of stable button press
            pulse_out <= button_clean && !button_stable_prev;
        end
    end

endmodule