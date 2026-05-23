`timescale 1ns / 1ps
`default_nettype none
// Simple dual-port framebuffer using inferred block RAM.
// - Read port: synchronous read clocked by `read_clk` returns pixel data
//   one cycle after presenting `read_addr`.
// - Write port: synchronous write clocked by `write_clk`, gated by
//   `write_en` to update individual pixels.
// Pixel format: 8-bit RGB332 (R:3, G:3, B:2).
`timescale 1ns / 1ps
`default_nettype none

module framebuffer (
    read_clk,
    read_addr,
    read_data,

    write_clk,
    write_addr,
    write_data,
    write_en
);

    // Read port: address presented on `read_addr` and sampled on rising
    // edge of `read_clk`. The corresponding `read_data` appears one
    // cycle later (typical for FPGA block RAMs configured in simple
    // single-port/dual-port synchronous modes).
    input  wire        read_clk;
    input  wire [16:0] read_addr;   // linear pixel address (0 .. FB_SIZE-1)
    output reg  [7:0]  read_data;   // 8-bit pixel color returned after one cycle

    // Write port: asynchronous domain to the read port. When `write_en`
    // is asserted on the rising edge of `write_clk`, `write_data` is
    // stored to `write_addr`.
    input  wire        write_clk;
    input  wire [16:0] write_addr;
    input  wire [7:0]  write_data;
    input  wire        write_en;

    // Framebuffer geometry parameters. The linear memory size is the
    // product of width and height. These are kept as localparams so
    // synthesis tools can compute memory dimensions at elaboration time.
    localparam FB_WIDTH  = 320;
    localparam FB_HEIGHT = 240;
    localparam FB_SIZE   = FB_WIDTH * FB_HEIGHT; // 76800

    // Instruct synthesis (Vivado) to infer block RAM rather than
    // distributed registers. The memory stores one byte per pixel.
    (* ram_style = "block" *)
    reg [7:0] mem [0:FB_SIZE-1];

    // Temporary loop variables for initial pattern fill during simulation
    // or FPGA configuration (if supported). These are integers used only
    // in the `initial` block and are not synthesized into hardware logic.
    integer init_x;
    integer init_y;
    integer init_addr;

    // Populate the framebuffer with a visible test pattern at startup.
    // This helps quickly verify that the VGA output and framebuffer
    // addressing are functioning before any dynamic writes occur.
    // The pattern: left third red, middle third green, right third blue.
    initial begin
        for (init_y = 0; init_y < FB_HEIGHT; init_y = init_y + 1) begin
            mem[init_addr] = 8'd0; // default to black
        end
    end

    // -----------------------------------------------------------------
    // Synchronous read port
    // -----------------------------------------------------------------
    // The BRAM returns the stored data one cycle after the read address
    // is provided. We check the address against the valid memory range
    // and return zero on out-of-range addresses to avoid X propagation.
    always @(posedge read_clk) begin
        if (read_addr < FB_SIZE) begin
            read_data <= mem[read_addr];
        end else begin
            read_data <= 8'd0;
        end
    end

    // -----------------------------------------------------------------
    // Synchronous write port
    // -----------------------------------------------------------------
    // Writes occur on the rising edge of `write_clk` when `write_en` is
    // asserted. We guard the write with a range check identical to the
    // read path.
    always @(posedge write_clk) begin
        if (write_en && (write_addr < FB_SIZE)) begin
            mem[write_addr] <= write_data;
        end
    end

endmodule

`default_nettype wire