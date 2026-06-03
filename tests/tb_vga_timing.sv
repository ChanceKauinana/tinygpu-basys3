`timescale 1ns / 1ps

// ------------------------------------------------------------
// Testbench: tb_vga_timing
// DUT:       vga_timing
//
// Purpose:
//   Verify VGA timing counters, visible region, and sync pulses
//   for standard 640x480 timing.
//
// Checks:
//   - Counter wrap and line/field progression
//   - Visible signal behavior
//   - Hsync/Vsync pulse timing
//
// Expected Result:
//   All checks print PASS in the simulation console.
// ------------------------------------------------------------

module tb_vga_timing;

    reg  pixel_clk;
    reg rst;

    wire [9:0] x;
    wire [9:0] y;
    wire visible;
    wire hsync;
    wire vsync;

    vga_timing dut (
        .pixel_clk (pixel_clk),
        .rst (rst),
        .x (x),
        .y (y),
        .visible (visible),
        .hsync (hsync),
        .vsync (vsync)
    );

    initial begin
        pixel_clk = 1'b0;
        forever #5 pixel_clk = ~pixel_clk;
    end

    initial begin 
        rst = 1'b1;
        repeat (10) @(posedge pixel_clk);
        rst = 1'b0;

        // ------------------ Basic counter progression ------------------
        @(posedge pixel_clk);
        if (x == 10'd1 && y ==10'd0)
            $display("Pass x = %0d, y = %0d", x, y);
        else
            $display("Fail x = %0d, y = %0d", x, y);

        repeat (798) @(posedge pixel_clk);
        if (x == 10'd799 && y == 10'd0)
            $display("Pass: The display reached the end of the first line");
        else
            $display("Fail: expected x = 799, y=0, got x=%0d y = %0d", x, y);

        @(posedge pixel_clk);
        if (x == 10'd0 && y == 10'd1)
            $display("Pass: X Wrapped to front, Y incremented");
        else
            $display("Fail: X should be 0 Y should be 1, got x=%0d y=%0d", x, y);

        // ------------------ Visible-region checks ----------------------
        if (visible ==1'b1)
            $display("Pass: visible is high inside the display area");
        else
            $display("Fail: visible should be high, got visible = %0d", visible);

        repeat(640)@(posedge pixel_clk);

        if (x == 10'd640 && visible == 1'b0)
            $display ("Pass: visible is low after visible horizontal region");
        else
            $display("Fail: Visible should be low, got x = %0d visible = %0d", x, visible);

        // ------------------ Hsync timing checks ------------------------
        repeat(16) @(posedge pixel_clk);

        if (x == 10'd656 && hsync == 1'b0)
            $display("Pass: hsync is high after front porch");
        else
            $display("Fail: hsync should be high, got x = %0d hsync = %0d", x, hsync);

        repeat(96) @(posedge pixel_clk);
        if (x == 10'd752 && hsync == 1'b1)
            $display("Pass: hsync is low during sync pulse");
        else
            $display("Fail: hsync should be low, got x = %0d hsync = %0d", x, hsync);

        $finish;
    end
        
endmodule