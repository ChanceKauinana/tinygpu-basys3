`timescale 1ns / 1ps

module tb_etch_sketch_engine;
    reg clk;
    reg rst;

    reg btnU;
    reg btnD;
    reg btnL;
    reg btnR;
    reg btnC;

    // color value used for user drawing operations
    reg [7:0] draw_color;

    // framebuffer write interface from the DUT
    wire [16:0] write_addr;
    wire [7:0] write_data;
    wire write_en;
    
    integer i;
    reg saw_draw_write;
    reg saw_clear_write;
    

    etch_sketch_engine #(.MOVE_DELAY(20'd5)) dut (
        .clk (clk),
        .rst (rst),
        .btnU (btnU),
        .btnD (btnD),
        .btnL (btnL),
        .btnR (btnR),
        .btnC (btnC),
        .draw_color (draw_color),
        .write_addr (write_addr),
        .write_data (write_data),
        .write_en (write_en)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    initial begin
        rst = 1'b1;
        btnU = 1'b0;
        btnD = 1'b0;
        btnL = 1'b0;
        btnR = 1'b0;
        btnC = 1'b0;
        draw_color = 8'hFF; // White color

        repeat(2) @(posedge clk);
        rst = 1'b0;

        // after reset expect the engine to issue an initial clear to the framebuffer
        @(posedge clk);
        if (write_en == 1'b1 && write_data == 8'h00)
            $display("Pass: Initial clear write detected");
        else
            $display("Fail: Expected a clear write, write_en = %0b write_data = %0d", write_en, write_data);
        

        repeat(76810) @(posedge clk); // Wait for the clear to finish

        saw_draw_write = 1'b0;

        // drive right button to move the cursor and trigger a draw operation
        btnR = 1'b1;
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk);
            if (write_en && write_data == draw_color)
                saw_draw_write = 1'b1;
        end
        btnR = 1'b0;

        if (saw_draw_write)
            $display("PASS: saw draw write after btnR press");
        else
            $display("FAIL: did not see draw write after btnR press");
        

        // press the clear button and verify the engine clears the framebuffer again
        btnC = 1'b1;
        @(posedge clk);

        saw_clear_write = 1'b0;

        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk);
            if (write_en && write_data == 8'h00)
                saw_clear_write = 1'b1;
        end

     if (saw_clear_write)
         $display("PASS: saw clear write after btnC press");
     else
         $display("FAIL: did not see clear write after btnC press");
    $finish;
    end
    
    initial begin
        #2_000_000;
        $display ("TIMEOUT: simulation took too long");
    end
    endmodule