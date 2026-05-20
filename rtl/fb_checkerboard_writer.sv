`timescale 1ns / 1ps

// Simple writer that fills the entire framebuffer with a checkerboard
// pattern. Useful for testing the VGA pipeline and verifying that the
// framebuffer memory and address mapping are correct.
module fb_checkerboard_writer (
    clk,
    rst,

    // Write port outputs (connect these to your framebuffer's write port)
    write_addr,
    write_data,
    write_en
);

    input  wire        clk;   // clock used to step through pixels
    input  wire        rst;   // synchronous reset (active high)

    // Write port signals produced by this module. `write_addr` is the
    // linear address into the framebuffer, `write_data` is the 8-bit
    // pixel color (RGB332), and `write_en` strobes the write.
    output reg  [16:0] write_addr;
    output reg  [7:0]  write_data;
    output reg         write_en;

    // Framebuffer geometry constants. Kept local so they are easy to
    // change in one place. `FB_SIZE` isn't used directly here but shows
    // the total pixel count conceptually.
    localparam FB_WIDTH  = 320;
    localparam FB_HEIGHT = 240;
    localparam FB_SIZE   = FB_WIDTH * FB_HEIGHT;

    // `x` and `y` iterate over every pixel in the framebuffer. They are
    // sized to accommodate the full range of coordinates used by 320x240.
    reg [8:0] x;
    reg [7:0] y;

    // Walk through every pixel on each clock. We compute the linear
    // address for the current (x,y) using the same shift-and-add trick
    // used elsewhere: addr = y*320 + x = (y<<8) + (y<<6) + x.
    always @(posedge clk) begin
        if (rst) begin
            // Reset counters and outputs to a known idle state.
            x          <= 9'd0;
            y          <= 8'd0;
            write_addr <= 17'd0;
            write_data <= 8'd0;
            write_en   <= 1'b0;
        end else begin
            // Enable writing. In a real system you might gate this to avoid
            // repeatedly overwriting memory, but for a test pattern we
            // continuously stream writes so the pattern remains present.
            write_en   <= 1'b1;

            // Convert (x,y) -> linear address (row-major order).
            write_addr <= (y << 8) + (y << 6) + x;

            // Checkerboard pattern generation:
            // We want 16x16 squares. Using bits of `x` and `y` is a very
            // cheap way to divide coordinates into blocks. Specifically,
            // `x[4]` and `y[4]` are the 5th bits (counting from 0), so they
            // change every 16 pixels: bits 0..3 cover 16 positions, bit 4
            // flips for each 16-pixel group. XORing these two bits gives a
            // classic checkerboard pattern: alternating squares across
            // rows and columns.
            //
            // Color format: RGB332 (3 red, 3 green, 2 blue). We use plain
            // white and black here for high contrast.
            if (x[4] ^ y[4]) begin
                write_data <= 8'b111_111_11; // white (max for R,G,B)
            end else begin
                write_data <= 8'b000_000_00; // black (all zeros)
            end

            // Advance to the next pixel. When we reach the end of a row
            // (`x == FB_WIDTH-1`) we wrap `x` to 0 and increment `y`. When
            // we finish the last row we wrap `y` to 0 and start again.
            if (x == FB_WIDTH - 1) begin
                x <= 9'd0;

                if (y == FB_HEIGHT - 1) begin
                    y <= 8'd0; // finished full frame, restart
                end else begin
                    y <= y + 8'd1; // next row
                end
            end else begin
                x <= x + 9'd1; // next column
            end
        end
    end

endmodule