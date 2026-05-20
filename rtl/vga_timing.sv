// VGA timing generator for 640x480 @ 60 Hz output.
// Produces pixel coordinates, visible-region enable,
// and active-low sync pulses based on the pixel clock.
module vga_timing (
    input  logic       pixel_clk, // pixel clock input (approx. 25 MHz for VGA)
    input  logic       rst,       // synchronous reset for the counters

    output logic [9:0] x,         // current pixel X coordinate inside full scanline
    output logic [9:0] y,         // current pixel Y coordinate inside full frame
    output logic       visible,   // true when pixel is inside visible display area
    output logic       hsync,     // horizontal sync output (active low)
    output logic       vsync      // vertical sync output (active low)
);

    // Horizontal timing constants for 640x480 VGA.
    // The total line time is visible area + front porch + sync pulse + back porch.
    localparam int H_VISIBLE = 640; // visible horizontal pixels
    localparam int H_FRONT   = 16;  // front porch interval
    localparam int H_SYNC    = 96;  // horizontal sync pulse width
    localparam int H_BACK    = 48;  // back porch interval
    localparam int H_TOTAL   = 800; // full horizontal period

    // Vertical timing constants for 640x480 VGA.
    // The total frame time is visible area + front porch + sync pulse + back porch.
    localparam int V_VISIBLE = 480; // visible vertical lines
    localparam int V_FRONT   = 10;  // vertical front porch lines
    localparam int V_SYNC    = 2;   // vertical sync pulse lines
    localparam int V_BACK    = 33;  // vertical back porch lines
    localparam int V_TOTAL   = 525; // full vertical period

    // Counters that sweep through horizontal and vertical timing.
    logic [9:0] h_count; // current position in the scanline
    logic [9:0] v_count; // current line number in the frame

    // Advance the horizontal counter on each pixel clock.
    // When the end of the line is reached, reset horizontal count and
    // advance the vertical counter to the next scanline.
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

    // Expose the current scan position to the top-level module.
    assign x = h_count;
    assign y = v_count;

    // The visible region is the intersection of horizontal and vertical
    // visible areas. Outside this area, the display should remain black.
    assign visible = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    // Generate active-low sync pulses.
    // The sync pulse is asserted during the sync window immediately
    // following the visible area and front porch.
    assign hsync = ~((h_count >= H_VISIBLE + H_FRONT) &&
                     (h_count <  H_VISIBLE + H_FRONT + H_SYNC));

    assign vsync = ~((v_count >= V_VISIBLE + V_FRONT) &&
                     (v_count <  V_VISIBLE + V_FRONT + V_SYNC));

endmodule