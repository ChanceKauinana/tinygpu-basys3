`timescale 1ns / 1ps

// Test/helper module that writes a simple pixel pattern into the
// framebuffer memory. This is useful for verifying the framebuffer
// and VGA pipeline without needing an external image source.
module fb_pixel_writer (
    clk,
    rst,

    // Outputs connect to the framebuffer write port. They indicate the
    // address to write, the 8-bit pixel color to store, and when the
    // write is enabled.
    write_addr,
    write_data,
    write_en
);

    input  wire        clk;   // system or pixel clock (drives write sequencing)
    input  wire        rst;   // synchronous reset (active high)

    // Write port signals (driven by this writer)
    output reg  [16:0] write_addr; // linear framebuffer address (see framebuffer_addr)
    output reg  [7:0]  write_data; // 8-bit pixel value (RGB332 format)
    output reg         write_en;   // assert to perform write at `write_addr`

    // Configuration for the test pattern: a square SIZE x SIZE pixels
    // located at (START_X, START_Y) in framebuffer coordinates. These are
    // chosen so the square appears near the center of a 320x240 framebuffer.
    localparam [8:0] START_X = 9'd144; // left/top corner X coordinate
    localparam [7:0] START_Y = 8'd104; // left/top corner Y coordinate
    localparam [8:0] SIZE    = 9'd32;  // square width & height in pixels

    // Pixel color encoded in RGB332 (3 bits red, 3 bits green, 2 bits blue).
    // `111_11_11` means maximum intensity for red and green, minimum for blue -> white.
    localparam [7:0] PIXEL_COLOR = 8'b111_11_11;

    // `dx` and `dy` iterate over the square's local coordinates. We drive
    // the writes by walking `dx` from 0..SIZE-1 for each `dy` row, then
    // increment `dy` and repeat until the whole square is written. This
    // implementation continuously writes the same square forever.
    reg [8:0] dx; // horizontal offset inside the square
    reg [7:0] dy; // vertical offset inside the square

    // Compute the absolute framebuffer coordinates for the pixel we are
    // currently writing by adding the local offsets to the start position.
    wire [8:0] current_x;
    wire [7:0] current_y;

    assign current_x = START_X + dx;
    assign current_y = START_Y + dy;

    // Main sequential process: on each rising `clk` we either reset state
    // or produce a write to the framebuffer. This is synchronous logic.
    always @(posedge clk) begin
        if (rst) begin
            // On reset clear counters and disable writes. This ensures the
            // framebuffer isn't trampled while the system is starting up.
            dx         <= 9'd0;
            dy         <= 8'd0;
            write_addr <= 17'd0;
            write_data <= 8'd0;
            write_en   <= 1'b0;
        end else begin
            // Always enable writes here; in a more complex design you might
            // gate this with a bus-ready signal or a finite-state machine.
            write_en   <= 1'b1;

            // Compute the linear address for (current_x, current_y).
            // The formula used here matches `framebuffer_addr`'s mapping:
            //   addr = y*320 + x
            // and uses shifts because 320 = 256 + 64 = (1<<8) + (1<<6).
            write_addr <= (current_y << 8) + (current_y << 6) + current_x;

            // Provide the chosen pixel color for every write.
            write_data <= PIXEL_COLOR;

            // Advance to the next pixel within the square. When we reach the
            // end of a row (`dx == SIZE-1`) we reset `dx` and advance `dy`.
            // When `dy` also reaches the last row we wrap back to the first
            // row, so the square drawing repeats forever.
            if (dx == SIZE - 1) begin
                dx <= 9'd0;

                if (dy == SIZE - 1) begin
                    dy <= 8'd0;   // finished entire square, restart
                end else begin
                    dy <= dy + 8'd1; // next row
                end
            end else begin
                dx <= dx + 9'd1; // next column
            end
        end
    end

endmodule