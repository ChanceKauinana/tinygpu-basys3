module tinygpu_top (
    input  logic       clk,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    output logic       Hsync,
    output logic       Vsync
);

    // Basys 3 clock is 100 MHz.
    // For beginner VGA testing, divide by 4 to get 25 MHz.
    // Standard 640x480 VGA uses ~25.175 MHz, but 25 MHz usually works.
    logic [1:0] clk_div = 2'b00;
    logic       pixel_clk;

    always_ff @(posedge clk) begin
        clk_div <= clk_div + 2'b01;
    end

    assign pixel_clk = clk_div[1];

    logic [9:0] x;
    logic [9:0] y;
    logic       visible;

    vga_timing timing_inst (
        .pixel_clk(pixel_clk),
        .rst      (1'b0),
        .x        (x),
        .y        (y),
        .visible  (visible),
        .hsync    (Hsync),
        .vsync    (Vsync)
    );

    always_comb begin
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (visible) begin
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