`default_nettype none

// Module: vga_timing
// Purpose: Generate standard 640x480 VGA timing signals and pixel coordinates.
// Inputs: pixel clock, synchronous reset
// Outputs: x/y coordinates, visible window indicator, hsync/vsync pulses
module vga_timing (
    input  logic       pixel_clk,
    input  logic       rst,

    output logic [9:0] x,
    output logic [9:0] y,
    output logic       visible,
    output logic       hsync,
    output logic       vsync
);

    // Horizontal timing constants for 640x480 VGA.
    localparam int H_VISIBLE = 640;
    localparam int H_FRONT   = 16;
    localparam int H_SYNC    = 96;
    localparam int H_BACK    = 48;
    localparam int H_TOTAL   = 800;

    // Vertical timing constants for 640x480 VGA.
    localparam int V_VISIBLE = 480;
    localparam int V_FRONT   = 10;
    localparam int V_SYNC    = 2;
    localparam int V_BACK    = 33;
    localparam int V_TOTAL   = 525;

    // Counters that sweep through horizontal and vertical timing.
    logic [9:0] h_count;
    logic [9:0] v_count;

    // Advance the horizontal counter on each pixel clock. When the end of
    // the line is reached, reset horizontal count and increment the vertical
    // counter to the next scanline.
    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                // End of a full horizontal line.
                h_count <= 10'd0;

                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0; // wrap to first line of next frame
                else
                    v_count <= v_count + 10'd1;
            end else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    assign x = h_count;
    assign y = v_count;

    assign visible = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    assign hsync = ~((h_count >= H_VISIBLE + H_FRONT) &&
                     (h_count <  H_VISIBLE + H_FRONT + H_SYNC));

    assign vsync = ~((v_count >= V_VISIBLE + V_FRONT) &&
                     (v_count <  V_VISIBLE + V_FRONT + V_SYNC));

endmodule