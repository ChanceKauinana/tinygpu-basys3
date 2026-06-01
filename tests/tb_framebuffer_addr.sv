#Successfully compiled and ran the testbench for framebuffer_addr. All test cases passed as expected.

`timescale 1ns / 1ps

module tb_framebuffer_addr;

    reg  [8:0]  x;
    reg  [7:0]  y;
    wire [16:0] addr;
    wire        valid;

    framebuffer_addr dut (
        .x     (x),
        .y     (y),
        .addr  (addr),
        .valid (valid)
    );

    task check_addr;
        input [8:0]  test_x;
        input [7:0]  test_y;
        input [16:0] expected_addr;
        input        expected_valid;
        begin
            x = test_x;
            y = test_y;

            #1;

            if (addr !== expected_addr || valid !== expected_valid) begin
                $display("FAIL: x=%0d y=%0d addr=%0d valid=%0b | expected addr=%0d valid=%0b",
                         test_x, test_y, addr, valid, expected_addr, expected_valid);
            end else begin
                $display("PASS: x=%0d y=%0d addr=%0d valid=%0b",
                         test_x, test_y, addr, valid);
            end
        end
    endtask

    initial begin
        $display("Starting framebuffer_addr testbench...");

        check_addr(9'd0,   8'd0,   17'd0,     1'b1);
        check_addr(9'd1,   8'd0,   17'd1,     1'b1);
        check_addr(9'd0,   8'd1,   17'd320,   1'b1);
        check_addr(9'd160, 8'd120, 17'd38560, 1'b1);
        check_addr(9'd319, 8'd239, 17'd76799, 1'b1);

        // Out-of-range x
        check_addr(9'd320, 8'd0,   17'd320,   1'b0);

        // Out-of-range y
        check_addr(9'd0,   8'd240, 17'd76800, 1'b0);

        $display("framebuffer_addr testbench complete.");
        $finish;
    end

endmodule