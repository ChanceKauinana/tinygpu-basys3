# Development Log

## Overview
- TinyGPU (Basys3) is a small FPGA-based GPU pipeline that renders a 320x240 RGB332 framebuffer and scales it to a 640x480 VGA output. The top-level design (`tinygpu_top.sv`) ties together VGA timing, a dual-port `framebuffer.sv`, address translation (`framebuffer_addr.sv`), an interactive drawing engine (`etch_sketch_engine.sv`), button handling, and UART input.

## Day 1 — Project setup and first VGA pipeline
- Initialized repository, Vivado project, and basic toolchain.
- Implemented `vga_timing.sv` (generates 640x480 timing: `x`, `y`, `visible`, `hsync`, `vsync`) and a minimal `tinygpu_top.sv` to drive color bars on the Basys3 VGA port.
- Verified bitstream generation in Vivado.

## Day 2 — Framebuffer and resolution change
- Replaced direct pixel generation with a framebuffer-based pipeline to allow random-access drawing.
- Implemented `framebuffer.sv` as a synchronous dual-port BRAM (320x240, 8-bit RGB332).
- Implemented coordinate scaling in `tinygpu_top.sv` to map 640x480 VGA coordinates to 320x240 framebuffer coordinates (2x pixel scaling).

## Day 3 — Read/write path and helpers
- Wrote `framebuffer_addr.sv` to convert 2D framebuffer coordinates into linear memory addresses (row-major addressing with range checks).
- Added test/helper writers: `fb_pixel_writer.sv` and `fb_checkerboard_writer.sv` to exercise read/write paths and display patterns.

## Days 4–7 — Interactive drawing engine (etch-a-sketch)
- Implemented `etch_sketch_engine.sv` that maintains a cursor and issues writes (`write_addr`, `write_data`, `write_en`) into the framebuffer.
- Integrated `button_inputs.v` / `button_pulse.sv` to debounce and pulse physical push-buttons for up/down/left/right/clear controls.
- Added switch-based color selection (background in `sw[15:8]`, draw color in `sw[7:0]`) and LED passthrough for quick status.

## Days 8–11 — Verification and unit tests
- Added testbenches: `tb_framebuffer_addr.sv`, `tb_vga_timing.sv`, and `tb_etch_sketch_engine.sv` to validate addressing math, VGA timing, and drawing behavior (clear, movement, pixel writes).

## Days 12–13 — Cleanup and refactor
- Improved comments and module headers, standardized signal names.
- Fixed small bugs discovered in simulation and cleaned up redundant logic.

## Days 14–16 — Release and demo
- Tagged a TinyGPU V1.0 milestone.
- Produced demo video and updated `README.md` with clearer usage and demo instructions.

## Days 17–25 — Enhancements
- Added button debouncing and pulse generation in `button_pulse.sv` and consolidated button handling in `button_inputs.v`.
- Added cursor-on display (cursor detection logic in `tinygpu_top.sv`) so the user can see the current draw position.
- Implemented UART reception and command parsing (`uart_rx.v`, `uart_control.v`, `uart_command_sync.v`) to allow keyboard control (W/A/S/D + C) over a serial terminal.




