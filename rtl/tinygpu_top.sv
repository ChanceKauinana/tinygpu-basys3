// Top-level module for the Basys 3 tiny GPU demo.
// This module generates a simple VGA test pattern by
// instantiating a VGA timing generator and driving
// the 4-bit VGA RGB outputs and sync signals.
module tinygpu_top (
    input  logic       clk,       // 100 MHz board clock from the Basys 3
    output logic [3:0] vgaRed,    // 4-bit red VGA output
    output logic [3:0] vgaGreen,  // 4-bit green VGA output
    output logic [3:0] vgaBlue,   // 4-bit blue VGA output
    output logic       Hsync,     // Horizontal sync output
    output logic       Vsync      // Vertical sync output
);

    // Basys 3 onboard oscillator is 100 MHz.
    // 640x480 VGA requires about 25.175 MHz pixel clock.
    // We use a simple divide-by-4 clock divider to approximate
    // a 25 MHz pixel clock for this demonstration.
    logic [1:0] clk_div = 2'b00; // counter for pixel clock division
    logic       pixel_clk;       // generated pixel clock for VGA timing

    // Divide the 100 MHz system clock by four.
    // The MSB of clk_div toggles at 25 MHz when clk is 100 MHz.
    always_ff @(posedge clk) begin
        clk_div <= clk_div + 2'b01;
    end

    // Use the MSB of the divider as the pixel clock.
    assign pixel_clk = clk_div[1];

    // VGA timing outputs from the timing generator.
    logic [9:0] x;       // current pixel X coordinate (horizontal position)
    logic [9:0] y;       // current pixel Y coordinate (vertical position)
    logic       visible; // active video region indicator

    // Instantiate the VGA timing generator module.
    // It produces horizontal and vertical sync pulses,
    // the current pixel coordinates, and a visible-region flag.
    vga_timing timing_inst (
        .pixel_clk(pixel_clk), // pixel clock input for VGA timing
        .rst      (1'b0),      // no reset used in this simple demo
        .x        (x),         // output horizontal pixel position
        .y        (y),         // output vertical pixel position
        .visible  (visible),   // output active display region flag
        .hsync    (Hsync),     // horizontal sync output
        .vsync    (Vsync)      // vertical sync output
    );

    // Generate a simple color bar pattern based on the X coordinate.
    // The RGB outputs are driven only while the pixel is inside the
    // visible region; outside the visible area, the outputs remain black.
    always_comb begin
        // Default to black for all channels.
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (visible) begin
            // Divide the visible width into three equal sections:
            // - Left third: full red
            // - Middle third: full green
            // - Right third: full blue
            // This simple test pattern makes it easy to verify
            // that the VGA timing and color outputs are working.
            if (x < 10'd213) begin
                vgaRed = 4'hF;
            end else if (x < 10'd426) begin
                vgaGreen = 4'hF;
            end else begin
                vgaBlue = 4'hF;
            end
        end
    end

endmodule