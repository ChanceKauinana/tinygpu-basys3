`timescale 1ns / 1ps

module etch_sketch_engine (
    clk,
    rst,

    btnU,
    btnD,
    btnL,
    btnR,
    btnC,

    draw_color,

    write_addr,
    write_data,
    write_en
);

    input  wire        clk;
    input  wire        rst;

    input  wire        btnU;
    input  wire        btnD;
    input  wire        btnL;
    input  wire        btnR;
    input  wire        btnC;

    input  wire [7:0]  draw_color;

    output reg  [16:0] write_addr;
    output reg  [7:0]  write_data;
    output reg         write_en;

    localparam FB_WIDTH  = 320;
    localparam FB_HEIGHT = 240;

    localparam MODE_DRAW  = 1'b0;
    localparam MODE_CLEAR = 1'b1;

    reg mode;

    reg [8:0] cursor_x = 9'd160;
    reg [7:0] cursor_y = 8'd120;

    reg [8:0] clear_x;
    reg [7:0] clear_y;

    // About 25 moves/sec with 25 MHz pixel clock.
    localparam MOVE_DELAY = 20'd1_000_000;

    reg [19:0] move_counter = 20'd0;
    wire       move_tick;

    assign move_tick = (move_counter == MOVE_DELAY - 1);

    always @(posedge clk) begin
        if (rst) begin
            move_counter <= 20'd0;
        end else begin
            if (move_tick) begin
                move_counter <= 20'd0;
            end else begin
                move_counter <= move_counter + 20'd1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            mode       <= MODE_CLEAR;

            cursor_x   <= 9'd160;
            cursor_y   <= 8'd120;

            clear_x    <= 9'd0;
            clear_y    <= 8'd0;

            write_addr <= 17'd0;
            write_data <= 8'd0;
            write_en   <= 1'b0;
        end else begin
            write_en <= 1'b0;

            if (mode == MODE_CLEAR) begin
                // Clear one framebuffer pixel per clock.
                write_en   <= 1'b1;
                write_addr <= (clear_y << 8) + (clear_y << 6) + clear_x;
                write_data <= 8'b000_000_00; // empty/background

                if (clear_x == FB_WIDTH - 1) begin
                    clear_x <= 9'd0;

                    if (clear_y == FB_HEIGHT - 1) begin
                        clear_y  <= 8'd0;
                        mode     <= MODE_DRAW;
                        cursor_x <= 9'd160;
                        cursor_y <= 8'd120;
                    end else begin
                        clear_y <= clear_y + 8'd1;
                    end
                end else begin
                    clear_x <= clear_x + 9'd1;
                end

            end else begin
                // btnC clears the drawing.
                if (btnC) begin
                    mode    <= MODE_CLEAR;
                    clear_x <= 9'd0;
                    clear_y <= 8'd0;
                end else if (move_tick) begin
                    if (btnU && cursor_y > 0) begin
                        cursor_y <= cursor_y - 8'd1;
                    end else if (btnD && cursor_y < FB_HEIGHT - 1) begin
                        cursor_y <= cursor_y + 8'd1;
                    end else if (btnL && cursor_x > 0) begin
                        cursor_x <= cursor_x - 9'd1;
                    end else if (btnR && cursor_x < FB_WIDTH - 1) begin
                        cursor_x <= cursor_x + 9'd1;
                    end

                    write_addr <= (cursor_y << 8) + (cursor_y << 6) + cursor_x;

                    if (draw_color == 8'd0) begin
                        write_data <= 8'b111_111_11; // default white
                    end else begin
                        write_data <= draw_color;
                    end

                    write_en <= 1'b1;
                end
            end
        end
    end

endmodule