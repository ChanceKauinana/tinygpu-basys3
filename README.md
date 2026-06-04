# TinyGPU-Basys3: FPGA VGA Drawing Engine (V1.0)

TinyGPU-Basys3 is an FPGA graphics project built for the Digilent Basys 3 Artix-7 board. The design generates 640x480 VGA output from a 320x240 RGB332 framebuffer and supports an interactive Etch-a-Sketch drawing mode using the board's push buttons and switches.

The goal of this project is to practice FPGA RTL design, VGA timing, framebuffer memory, hardware debugging, and simulation-based verification.

## Demo

Demo video/GIF: Coming SOON

## Features

- 640x480 VGA output
- 320x240 framebuffer scaled 2x to VGA resolution
- 8-bit RGB332 framebuffer color format
- RGB332-to-RGB444 VGA output conversion
- Button-controlled Etch-a-Sketch drawing
- Switch-controlled drawing color
- Switch-controlled background color
- Center button clear/reset behavior
- LEDs mirror switch states for debugging
- Simulation testbenches for core modules

## Hardware / Tools

- Digilent Basys 3 FPGA board
- Xilinx/AMD Artix-7 FPGA: xc7a35tcpg236-1
- Vivado 2025.1
- Verilog/SystemVerilog
- VGA monitor
- Git/GitHub

## System Architecture

The design uses a VGA timing generator to scan through 640x480 display coordinates. Visible VGA coordinates are scaled down to 320x240 framebuffer coordinates by dropping the least significant bit of each coordinate.

The framebuffer stores 8-bit RGB332 pixel data. During display output, the framebuffer pixel is expanded to 12-bit RGB444 for the Basys 3 VGA connector.

Empty framebuffer pixels use value `8'd0`. The top-level display logic treats this as transparent/background and displays the selected background color from `sw[15:8]`. Nonzero framebuffer pixels are displayed as drawn pixels.

```text
Buttons / Switches
        |
        v
Etch-a-Sketch Engine
        |
        v
Framebuffer Write Port
        |
        v
320x240 RGB332 Framebuffer
        |
        v
Framebuffer Read Port
        |
        v
RGB332 to RGB444 Conversion
        |
        v
640x480 VGA Output
```

## Controls

| Input | Function |
|---|---|
| `btnU` | Move/draw cursor up |
| `btnD` | Move/draw cursor down |
| `btnL` | Move/draw cursor left |
| `btnR` | Move/draw cursor right |
| `btnC` | Clear drawing |
| `sw[7:0]` | Drawing color in RGB332 |
| `sw[15:8]` | Background color in RGB332 |
| `led[15:0]` | Mirrors switch states |

## Verification

| Testbench | Module Tested | Checks |
|---|---|---|
| `tb_framebuffer_addr.sv` | `framebuffer_addr` | Address calculation, valid coordinate detection, edge cases |
| `tb_vga_timing.sv` | `vga_timing` | Counter reset, horizontal wrap, visible-region behavior, hsync timing |
| `tb_etch_sketch_engine.sv` | `etch_sketch_engine` | Startup clear behavior, draw write behavior, clear button behavior |

All testbenches are located in the `tests/` directory.

## Build / Run Instructions

1. Open the Vivado project.
2. Make sure the target part is set to `xc7a35tcpg236-1`.
3. Run synthesis.
4. Run implementation.
5. Generate the bitstream.
6. Open Hardware Manager.
7. Program the Basys 3 board.
8. Connect the VGA monitor and use the board buttons/switches to draw.

## Current Limitations

- The design uses a single framebuffer, so reads and writes may occur during the same display frame.
- The framebuffer uses `8'd0` as the transparent/background value, so true black drawing is not supported in the current version.
- Button inputs are not fully debounced.
- The pixel clock is generated using a simple clock divider instead of a dedicated clocking wizard/MMCM.

## Future Work

- Add button debouncing
- Add a proper 25 MHz clocking wizard/MMCM pixel clock
- Add an on-screen cursor indicator
- Add line or rectangle drawing primitives
- Add UART command input
- Add more complete verification and assertions
- Add optional flash programming so the design loads on power-up

## What I Learned

- How VGA timing works at the RTL level
- How to build a framebuffer-backed display system
- How to map 2D coordinates into linear memory
- How to use RGB332 color and expand it to VGA RGB444
- How to write simulation testbenches for combinational and sequential RTL
- How to debug synthesis, implementation, and hardware issues in Vivado