`timescale 1ns / 1ps

module fb_scene_writer (
    clk,
    rst,
    bg_color,

    write_addr,
    write_data,
    write_en,

    busy,
    done
);

    input  wire        clk;
    input  wire        rst;
    input  wire [7:0]  bg_color;

    output reg  [16:0] write_addr;
    output reg  [7:0]  write_data;
    output reg         write_en;

    output reg         busy;
    output reg         done;

    // ------------------------------------------------------------
    // Framebuffer constants
    // ------------------------------------------------------------

    localparam FB_WIDTH  = 320;
    localparam FB_HEIGHT = 240;

    // ------------------------------------------------------------
    // RGB332 colors
    // Format: RRR_GGG_BB
    // ------------------------------------------------------------

    localparam [7:0] COLOR_RED     = 8'b111_000_00;
    localparam [7:0] COLOR_GREEN   = 8'b000_111_00;
    localparam [7:0] COLOR_BLUE    = 8'b000_000_11;
    localparam [7:0] COLOR_WHITE   = 8'b111_111_11;
    localparam [7:0] COLOR_YELLOW  = 8'b111_111_00;
    localparam [7:0] COLOR_MAGENTA = 8'b111_000_11;
    localparam [7:0] COLOR_CYAN    = 8'b000_111_11;

    // Rectangle color for now
    localparam [7:0] RECT_COLOR = COLOR_RED;

    // ------------------------------------------------------------
    // Rectangle settings
    // ------------------------------------------------------------

    localparam [8:0] RECT_X = 9'd112;
    localparam [7:0] RECT_Y = 8'd88;
    localparam [8:0] RECT_W = 9'd96;
    localparam [7:0] RECT_H = 8'd64;

    // ------------------------------------------------------------
    // Drawing phases
    // ------------------------------------------------------------

    localparam [1:0] PHASE_CLEAR = 2'd0;
    localparam [1:0] PHASE_RECT  = 2'd1;
    localparam [1:0] PHASE_DONE  = 2'd2;

    reg [1:0] phase;

    // Counters for clearing background
    reg [8:0] clear_x;
    reg [7:0] clear_y;

    // Counters for rectangle drawing
    reg [8:0] rect_dx;
    reg [7:0] rect_dy;

    wire [8:0] rect_current_x;
    wire [7:0] rect_current_y;

    assign rect_current_x = RECT_X + rect_dx;
    assign rect_current_y = RECT_Y + rect_dy;

    // ------------------------------------------------------------
    // Main controlled scene writer
    // ------------------------------------------------------------

    always @(posedge clk) begin
        if (rst) begin
            phase      <= PHASE_CLEAR;

            clear_x    <= 9'd0;
            clear_y    <= 8'd0;

            rect_dx    <= 9'd0;
            rect_dy    <= 8'd0;

            write_addr <= 17'd0;
            write_data <= 8'd0;
            write_en   <= 1'b0;

            busy       <= 1'b1;
            done       <= 1'b0;
        end else begin
            if (phase == PHASE_CLEAR) begin
                // ------------------------------------------------
                // Phase 1:
                // Fill entire framebuffer with chosen background color
                // ------------------------------------------------

                busy       <= 1'b1;
                done       <= 1'b0;
                write_en   <= 1'b1;

                write_addr <= (clear_y << 8) + (clear_y << 6) + clear_x;
                write_data <= bg_color;

                if (clear_x == FB_WIDTH - 1) begin
                    clear_x <= 9'd0;

                    if (clear_y == FB_HEIGHT - 1) begin
                        clear_y <= 8'd0;
                        phase   <= PHASE_RECT;
                    end else begin
                        clear_y <= clear_y + 8'd1;
                    end
                end else begin
                    clear_x <= clear_x + 9'd1;
                end

            end else if (phase == PHASE_RECT) begin
                // ------------------------------------------------
                // Phase 2:
                // Draw rectangle on top of background
                // ------------------------------------------------

                busy       <= 1'b1;
                done       <= 1'b0;
                write_en   <= 1'b1;

                write_addr <= (rect_current_y << 8) + (rect_current_y << 6) + rect_current_x;
                write_data <= RECT_COLOR;

                if (rect_dx == RECT_W - 1) begin
                    rect_dx <= 9'd0;

                    if (rect_dy == RECT_H - 1) begin
                        rect_dy <= 8'd0;
                        phase   <= PHASE_DONE;
                    end else begin
                        rect_dy <= rect_dy + 8'd1;
                    end
                end else begin
                    rect_dx <= rect_dx + 9'd1;
                end

            end else begin
                // ------------------------------------------------
                // Phase 3:
                // Stop writing. The final image stays in framebuffer.
                // ------------------------------------------------

                write_en <= 1'b0;
                busy     <= 1'b0;
                done     <= 1'b1;
            end
        end
    end

endmodule