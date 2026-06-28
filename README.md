# TinyGPU-Basys3: FPGA VGA Drawing Engine

TinyGPU-Basys3 is an FPGA graphics project built for the Digilent Basys 3 Artix-7 board. The design generates 640x480 VGA output from a 320x240 RGB332 framebuffer and supports an interactive Etch-a-Sketch style drawing mode using push buttons, switches, and UART keyboard commands.

The project was built to practice FPGA RTL design, VGA timing, framebuffer memory, hardware debugging, clock-domain crossing, UART input, timing constraints, and simulation-based verification.

## Demo

[Watch v1.0 Demo Video Here](https://youtu.be/XUvRm200iu8)

The v1.0 demo shows the Basys 3 generating VGA output, switch-controlled draw/background colors, button-controlled drawing, LED switch indicators, and clear-screen behavior.

> A v2.0 demo will show the updated debounced controls, on-screen cursor overlay, Clocking Wizard pixel clock, and UART keyboard control.

## Versions

* **v1.0** — Initial VGA framebuffer drawing engine with Etch-a-Sketch controls, switch-controlled draw/background colors, LED switch indicators, clear-screen behavior, and simulation testbenches.
* **v2.0** — Added debounced button inputs, a color-matched on-screen cursor overlay, a Clocking Wizard/MMCM-generated VGA pixel clock, UART keyboard control, and a clock-domain crossing bridge for UART commands.

## Features

* 640x480 VGA output
* 320x240 framebuffer scaled 2x to VGA resolution
* 8-bit RGB332 framebuffer color format
* RGB332-to-RGB444 VGA output conversion
* Framebuffer-backed Etch-a-Sketch drawing engine
* Button-controlled cursor movement and drawing
* UART keyboard control using `W/A/S/D` movement and `C` clear command
* Switch-controlled drawing color
* Switch-controlled background color
* Color-matched on-screen cursor overlay
* Center button clear/reset behavior
* Debounced physical button inputs
* Clocking Wizard/MMCM-generated VGA pixel clock
* UART RX module for PC-to-FPGA serial input
* Clock-domain crossing bridge from 100 MHz UART/system clock to pixel clock domain
* Timing exception for intentional UART-to-pixel-clock CDC path
* LEDs mirror switch states for debugging
* Simulation testbenches for core modules

## Hardware / Tools

* Digilent Basys 3 FPGA board
* Xilinx/AMD Artix-7 FPGA: `xc7a35tcpg236-1`
* Vivado 2025.1
* Verilog/SystemVerilog
* VGA monitor
* USB-UART serial terminal
* Git/GitHub

## System Architecture

The design uses a VGA timing generator to scan through 640x480 display coordinates. Visible VGA coordinates are scaled down to 320x240 framebuffer coordinates by dropping the least significant bit of each coordinate.

The framebuffer stores 8-bit RGB332 pixel data. During display output, the framebuffer pixel is expanded to 12-bit RGB444 for the Basys 3 VGA connector.

Empty framebuffer pixels use value `8'd0`. The top-level display logic treats this value as transparent/background and displays the selected background color from `sw[15:8]`. Nonzero framebuffer pixels are displayed as drawn pixels.

UART commands are received in the 100 MHz system clock domain, decoded into command pulses, and then safely transferred into the pixel clock domain using toggle-based clock-domain crossing synchronizers. The drawing engine latches short UART movement pulses until the next movement tick so keyboard commands are not missed.

```text
Physical Buttons
        |
        v
Debounced Button Inputs
        |
        +------------------+
                           |
USB-UART RX                |
        |                  |
        v                  |
UART Command Decode        |
        |                  |
        v                  |
CDC Command Bridge --------+
        |
        v
Combined Draw Commands
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
Cursor Overlay + Background Selection
        |
        v
RGB332 to RGB444 Conversion
        |
        v
640x480 VGA Output
```

## Controls

### Board Controls

| Input       | Function                   |
| ----------- | -------------------------- |
| `btnU`      | Move/draw cursor up        |
| `btnD`      | Move/draw cursor down      |
| `btnL`      | Move/draw cursor left      |
| `btnR`      | Move/draw cursor right     |
| `btnC`      | Clear drawing              |
| `sw[7:0]`   | Drawing color in RGB332    |
| `sw[15:8]`  | Background color in RGB332 |
| `led[15:0]` | Mirrors switch states      |

### UART Controls

UART is configured for 9600 baud, 8 data bits, no parity, and 1 stop bit.

| UART Key  | Function               |
| --------- | ---------------------- |
| `W` / `w` | Move/draw cursor up    |
| `A` / `a` | Move/draw cursor left  |
| `S` / `s` | Move/draw cursor down  |
| `D` / `d` | Move/draw cursor right |
| `C` / `c` | Clear drawing          |

## Major Modules

| Module               | Description                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------------ |
| `tinygpu_top`        | Top-level module connecting VGA timing, framebuffer, drawing engine, buttons, switches, UART, and VGA output |
| `vga_timing`         | Generates 640x480 VGA coordinates, visible-region flag, `hsync`, and `vsync`                                 |
| `framebuffer`        | Block-RAM inferred framebuffer storing 320x240 8-bit RGB332 pixels                                           |
| `framebuffer_addr`   | Converts 2D framebuffer coordinates into a linear memory address                                             |
| `etch_sketch_engine` | Handles cursor movement, drawing writes, clear-screen behavior, and UART movement pulse latching             |
| `button_inputs`      | Wraps debouncing and pulse generation for the five Basys 3 push buttons                                      |
| `button_pulse`       | Debounces a button input and generates clean button level/pulse outputs                                      |
| `uart_rx`            | Receives serial UART bytes using 9600 baud, 8N1 format                                                       |
| `uart_control`       | Decodes UART bytes into movement and clear command pulses                                                    |
| `uart_cmd_bridge`    | Transfers one UART command pulse across clock domains using a toggle synchronizer                            |
| `uart_command_sync`  | Wraps multiple UART command CDC bridges for movement and clear commands                                      |
| `clk_wiz_0`          | Clocking Wizard IP used to generate the VGA pixel clock                                                      |

## Clocking and Timing

The Basys 3 provides a 100 MHz system clock. The VGA pixel clock is generated using a Vivado Clocking Wizard/MMCM instead of a fabric clock divider.

The UART receiver and command decoder run in the 100 MHz system clock domain. The VGA pipeline and drawing engine run in the pixel clock domain. UART commands cross into the pixel clock domain through a toggle-based synchronizer.

The first synchronizer register is marked as asynchronous using `ASYNC_REG`, and the XDC file includes a timing exception for the intentional UART command CDC path.

## Verification

| Testbench                  | Module Tested        | Checks                                                                |
| -------------------------- | -------------------- | --------------------------------------------------------------------- |
| `tb_framebuffer_addr.sv`   | `framebuffer_addr`   | Address calculation, valid coordinate detection, edge cases           |
| `tb_vga_timing.sv`         | `vga_timing`         | Counter reset, horizontal wrap, visible-region behavior, hsync timing |
| `tb_etch_sketch_engine.sv` | `etch_sketch_engine` | Startup clear behavior, draw write behavior, clear button behavior    |

All testbenches are located in the `tests/` directory.

## Build / Run Instructions

1. Open the Vivado project.
2. Make sure the target part is set to `xc7a35tcpg236-1`.
3. Confirm the Basys 3 constraints file is enabled.
4. Run synthesis.
5. Run implementation.
6. Generate the bitstream.
7. Open Hardware Manager.
8. Program the Basys 3 board.
9. Connect the VGA monitor.
10. Use the board buttons/switches or UART keyboard commands to draw.

## UART Setup

1. Connect the Basys 3 to the PC using the USB cable.
2. Open a serial terminal such as Tera Term.
3. Select the Basys 3 USB serial port.
4. Configure the serial terminal for:

   * Baud rate: `9600`
   * Data bits: `8`
   * Parity: `None`
   * Stop bits: `1`
   * Flow control: `None`
5. Type `W`, `A`, `S`, `D`, or `C` to control the drawing engine.

## Current Limitations

* The design uses a single framebuffer, so reads and writes may occur during the same display frame.
* The framebuffer uses `8'd0` as the transparent/background value, so true black drawing is not supported in the current version.
* UART keyboard repeat behavior depends on the host computer and terminal settings.

## Project Status

* TinyGPU-Basys3 is complete. The final version includes VGA framebuffer drawing, debounced physical controls, an on-screen cursor overlay, Clocking Wizard pixel clock generation, UART keyboard control, and timing-clean clock-domain crossing for UART commands.

## What I Learned

* How VGA timing works at the RTL level
* How to build a framebuffer-backed display system
* How to map 2D coordinates into linear memory
* How to use RGB332 color and expand it to VGA RGB444
* How to debounce mechanical button inputs
* How to generate a pixel clock using Vivado Clocking Wizard/MMCM IP
* How to implement UART RX in RTL
* How to decode serial commands into hardware control pulses
* How to safely cross command pulses between clock domains
* How to write and apply a timing exception for an intentional CDC path
* How to write simulation testbenches for combinational and sequential RTL
* How to debug synthesis, implementation, timing, and hardware issues in Vivado
