`timescale 1ns / 1ps
`default_nettype none

// Framebuffer module with separate read and write ports.
// The framebuffer stores pixel color values in block RAM
// and supports a synchronous read path for VGA display logic
// plus a synchronous write path for drawing/graphics updates.
module framebuffer #(
    parameter int FB_WIDTH   = 320, // frame buffer width in pixels
    parameter int FB_HEIGHT  = 240, // frame buffer height in pixels
    parameter int COLOR_BITS = 8,   // bits per pixel
    parameter int ADDR_BITS  = 17   // address width for the pixel memory
)(
    // Read port: used by VGA display logic on the pixel clock.
    input  logic [ADDR_BITS-1:0]  read_addr,  // address of pixel to read
    input  logic                  read_clk,   // clock used for read access
    output logic [COLOR_BITS-1:0] read_data,  // color data returned after one cycle

    // Write port: used by drawing or rasterizer logic.
    input  logic [ADDR_BITS-1:0]  write_addr, // address of pixel to write
    input  logic [COLOR_BITS-1:0] write_data, // color value to write
    input  logic                  write_en,   // write enable signal
    input  logic                  write_clk   // clock used for write access
);

    // Total number of pixels in the framebuffer.
    localparam int FB_SIZE = FB_WIDTH * FB_HEIGHT;

    // Force Vivado to infer a block RAM memory for the frame buffer.
    // A dual-port block RAM is useful when reads and writes occur on
    // separate clocks or in different parts of the design.
    (* ram_style = "block" *)
    logic [COLOR_BITS-1:0] mem [0:FB_SIZE-1];

    // Initial test pattern helper variables.
    integer init_x;
    integer init_y;
    integer init_addr;

    // Preload the framebuffer with a simple RGB test pattern at simulation
    // start-up. The left third of the frame is red, the middle third is green,
    // and the right third is blue. This makes it easy to verify the output
    // before any drawing hardware is connected.
    initial begin
        for (init_y = 0; init_y < FB_HEIGHT; init_y = init_y + 1) begin
            for (init_x = 0; init_x < FB_WIDTH; init_x = init_x + 1) begin
                init_addr = init_y * FB_WIDTH + init_x;

                if (init_x < FB_WIDTH / 3) begin
                    // Red pixels in the left region.
                    mem[init_addr] = 8'b111_000_00;
                end else if (init_x < (2 * FB_WIDTH) / 3) begin
                    // Green pixels in the center region.
                    mem[init_addr] = 8'b000_111_00;
                end else begin
                    // Blue pixels in the right region.
                    mem[init_addr] = 8'b000_000_11;
                end
            end
        end
    end

    // Synchronous read logic for block RAM.
    // The address is registered by the block RAM and the output data
    // becomes available one clock cycle later on read_clk.
    always_ff @(posedge read_clk) begin
        if (read_addr < FB_SIZE) begin
            read_data <= mem[read_addr];
        end else begin
            // Return zero for invalid addresses to avoid X-states.
            read_data <= '0;
        end
    end

    // Synchronous write logic for the framebuffer.
    // When write_en is asserted, the provided write_data is stored at
    // write_addr on the rising edge of write_clk.
    always_ff @(posedge write_clk) begin
        if (write_en && (write_addr < FB_SIZE)) begin
            mem[write_addr] <= write_data;
        end
    end

endmodule

`default_nettype wire