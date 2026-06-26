`timescale 1ns / 1ps
`default_nettype none

// Module: tinygpu_top
// Purpose: Top-level GPU system that connects VGA timing, framebuffer memory,
//          and the etch-sketch drawing engine.
// Inputs: system clock, direction/clear buttons, switch-based background and draw color
// Outputs: VGA RGB signals, Hsync/Vsync, LED status
module tinygpu_top (
    clk,

    btnU,
    btnD,
    btnL,
    btnR,
    btnC,

    uart_rx_pin,

    sw,
    led,

    vgaRed,
    vgaGreen,
    vgaBlue,
    Hsync,
    Vsync
);
    input  wire       clk;

    input  wire       btnU;
    input  wire       btnD;
    input  wire       btnL;
    input  wire       btnR;
    input  wire       btnC;

    input wire       uart_rx_pin;

    input  wire [15:0] sw;
    output wire [15:0] led;


    output reg  [3:0] vgaRed;
    output reg  [3:0] vgaGreen;
    output reg  [3:0] vgaBlue;
    output reg        Hsync;
    output reg        Vsync;

    wire [8:0] cursor_x;
    wire [7:0] cursor_y;

//COME BACK AND FIX LATER::: TESTING UART RN
    //assign led = sw;

    wire pixel_clk;
    wire clk_locked;
    wire sys_rst;
    
    assign sys_rst = 1'b0;

    clk_wiz_0 clk_wiz_inst (
        .clk_out1 (pixel_clk),
        .reset    (sys_rst),
        .locked   (clk_locked),
        .clk_in1  (clk)
    );


    wire [7:0] uart_data;
    wire       uart_valid;

    reg [7:0] uart_led_data = 8'd0;

    uart_rx uart_rx_inst (
        .clk      (clk),
        .rst      (1'b0),
        .rx       (uart_rx_pin),
        .rx_data  (uart_data),
        .rx_valid (uart_valid)
    );

    always @(posedge clk) begin
        if (uart_valid) begin
            uart_led_data <= uart_data;
        end
    end

    assign led[7:0]  = uart_led_data;
    assign led[15:8] = sw[15:8];

    // ------------------------------------------------------------
    // VGA timing signals
    // The `vga_timing` module generates the current pixel coordinates
    // (`vga_x`, `vga_y`) and the raw `visible`, `hsync`, `vsync` signals
    // according to the VGA 640x480 timing standard. These tell us when
    // to output pixels and when the monitor is in blanking intervals.
    // ------------------------------------------------------------

    wire [9:0] vga_x;
    wire [9:0] vga_y;
    wire       visible_raw;
    wire       hsync_raw;
    wire       vsync_raw;

    vga_timing timing_inst (
        .pixel_clk(pixel_clk),
        .rst      (sys_rst),
        .x        (vga_x),
        .y        (vga_y),
        .visible  (visible_raw),
        .hsync    (hsync_raw),
        .vsync    (vsync_raw)
    );


    // Convert 640x480 VGA coordinates into 320x240 framebuffer coordinates.
    // The framebuffer is half resolution in each dimension, so the visible
    // VGA coordinates are scaled down by discarding the LSBs.
    wire [8:0] fb_x;
    wire [7:0] fb_y;

    assign fb_x = visible_raw ? vga_x[9:1] : 9'd0;
    assign fb_y = visible_raw ? vga_y[8:1] : 8'd0;


    // ------------------------------------------------------------
    // Framebuffer address calculation
    // Given an (x,y) coordinate in the framebuffer space, compute the
    // linear memory address used to read the pixel color from RAM.
    // The `framebuffer_addr` module encapsulates how 2D coordinates map
    // to a 1D address (for example row-major ordering).
    // ------------------------------------------------------------

    wire [16:0] fb_read_addr;
    wire        fb_coord_valid;

    framebuffer_addr fb_addr_inst (
        .x    (fb_x),
        .y    (fb_y),
        .addr (fb_read_addr),
        .valid(fb_coord_valid)
    );

    wire cursor_x_match;
    wire cursor_y_match;
    wire cursor_on;

    assign cursor_x_match = (fb_x >= cursor_x && fb_x <= cursor_x + 9'd1) ||
                            (fb_x <= cursor_x && fb_x + 9'd1 >= cursor_x);
    assign cursor_y_match = (fb_y >= cursor_y && fb_y <= cursor_y + 8'd1) ||
                            (fb_y <= cursor_y && fb_y + 8'd1 >= cursor_y);

    assign cursor_on = visible_raw && cursor_x_match && cursor_y_match;

    wire [7:0]  fb_color;

    wire [7:0] bg_color;
    wire [7:0] display_color;

    wire [7:0] base_color;

    assign bg_color = sw[15:8];

    assign base_color = (fb_color == 8'd0) ? bg_color : fb_color;

    wire [7:0] cursor_color;
    assign cursor_color = (sw[7:0] == 8'd0)? 8'b11111111 : sw[7:0];
    assign display_color = cursor_on ? cursor_color : base_color;

    wire [16:0] draw_write_addr;
    wire [7:0]  draw_write_data;
    wire        draw_write_en;

// ------------------------------------------------------------
// Button debouncing and pulse generation
// Mechanical buttons can produce noisy signals when pressed or released,
// causing multiple transitions instead of a clean single press. The
// `button_pulse` module takes a raw button input and produces a clean,
// debounced signal (`button_clean`) and a one-clock-cycle pulse (`pulse_out`)
// whenever a new button press is detected.
// ------------------------------------------------------------ 
    wire butnU_clean;
    wire butnD_clean;
    wire butnL_clean;
    wire butnR_clean;
    wire butnC_clean;

    wire butnU_pulse;
    wire butnD_pulse;
    wire butnL_pulse;
    wire butnR_pulse;
    wire butnC_pulse;

    button_inputs button_inputs_inst (
        .clk        (pixel_clk),
        .rst        (sys_rst),

        .btnU       (btnU),
        .btnD       (btnD),
        .btnL       (btnL),
        .btnR       (btnR),
        .btnC       (btnC),

        .btnU_clean (butnU_clean),
        .btnD_clean (butnD_clean),
        .btnL_clean (butnL_clean),
        .btnR_clean (butnR_clean),
        .btnC_clean (butnC_clean),

        .btnU_pulse (butnU_pulse),
        .btnD_pulse (butnD_pulse),
        .btnL_pulse (butnL_pulse),
        .btnR_pulse (butnR_pulse),
        .btnC_pulse (butnC_pulse)
    );

    etch_sketch_engine draw_engine_inst (
        .clk        (pixel_clk),
        .rst        (sys_rst),

        .btnU       (butnU_clean),
        .btnD       (butnD_clean),
        .btnL       (butnL_clean),
        .btnR       (butnR_clean),
        .btnC       (butnC_pulse),

        .draw_color (sw[7:0]),

        .write_addr (draw_write_addr),
        .write_data (draw_write_data),
        .write_en   (draw_write_en),

        .cursor_x_out(cursor_x),
        .cursor_y_out(cursor_y)
    );
    

    // `framebuffer` is a dual-port memory: one port is read by the VGA
    // pipeline, while the other accepts writes from the drawing engine.
    // The read path provides an 8-bit RGB332 pixel value for display.
    framebuffer fb_inst (
        .read_addr  (fb_read_addr),
        .read_clk   (pixel_clk),
        .read_data  (fb_color),

        .write_addr (draw_write_addr),
        .write_data (draw_write_data),
        .write_en   (draw_write_en),
        .write_clk  (pixel_clk)
    );

    // ------------------------------------------------------------
    // Delay visible/sync signals by one pixel clock
    // Many video pipelines need signals aligned to the pixel data. The
    // timing module produced `visible_raw`, `hsync_raw`, `vsync_raw` at
    // the current pixel time. We register (`<=`) them on the rising edge
    // of `pixel_clk` so that the sync outputs and our visible flag are
    // stable when we use `fb_color` to drive the DAC outputs.
    // ------------------------------------------------------------

    reg visible_d;

    always @(posedge pixel_clk) begin
        visible_d <= visible_raw; // registered (one-cycle delayed) visible
        Hsync     <= hsync_raw;   // output sync signals registered to pixel clock
        Vsync     <= vsync_raw;
    end


    // ------------------------------------------------------------
    // Convert 8-bit RGB332 framebuffer color to 12-bit VGA RGB444
    // Our framebuffer stores color in RGB332 format: bits [7:5]=R, [4:2]=G, [1:0]=B.
    // The VGA output expects 4 bits per channel (RGB444). To expand the
    // smaller number of bits to 4 bits we replicate the most significant
    // bit(s) into the lower bits. This is a simple way to scale color
    // without doing any arithmetic. When `visible_d` is false (blanking),
    // we drive black (all zeros) to the DAC.
    // ------------------------------------------------------------

    always @(*) begin
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (visible_d) begin
            // For red: take 3 bits and repeat the top bit to make 4 bits.
            // Example: R=101 -> {101,1} = 1011
            vgaRed   = {display_color[7:5], display_color[7]};

            // For green: same idea with bits [4:2]
            vgaGreen = {display_color[4:2], display_color[4]};

            // For blue: we only have 2 bits; repeat them to fill 4 bits.
            // {b1,b0,b1,b0} gives a reasonable expansion for 2->4 bits.
            vgaBlue  = {display_color[1:0], display_color[1:0]};
        end
    end

endmodule

`default_nettype wire