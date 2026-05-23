# TinyGPU-Basys3

TinyGPU-Basys3 is a small FPGA-based graphics pipeline built for the Digilent Basys 3 board.

The goal of this project is to learn how graphics hardware works at a low level by designing a simple GPU-style pipeline from scratch using Verilog/SystemVerilog. Instead of only writing software that draws graphics, this project focuses on building the actual hardware logic that receives drawing commands, turns them into pixels, stores them in a framebuffer, and outputs the image to a VGA monitor.

This project is meant to help me build skills related to FPGA design, digital logic, computer architecture, graphics pipelines, and eventually ASIC/GPU engineering.

---

## Project Overview

Modern GPUs are extremely complex, but at a basic level they follow a similar idea:

1. Receive drawing commands
2. Decode those commands
3. Convert shapes into pixels
4. Store pixel data in memory
5. Output pixels to a display

TinyGPU-Basys3 is a simplified version of that idea.

The planned system will receive drawing commands from a computer over USB-UART. The FPGA will decode those commands and use hardware modules to draw pixels, rectangles, and eventually lines or triangles into a framebuffer. A VGA controller will continuously read from the framebuffer and display the result on a monitor.

```text
Computer / Python Script
        |
        | USB-UART
        v
Basys 3 FPGA
        |
        v
Command Receiver
        |
        v
Command Decoder
        |
        v
Rasterizer / Drawing Engine
        |
        v
Framebuffer
        |
        v
VGA Controller
        |
        v
Monitor

Curent features:
- 640x480 VGA output
- 320x240 RGB332 framebuffer
- 2x framebuffer scaling
- Button-controlled drawing cursor
- Switch-controlled drawing/background colors
- Clear/reset drawing
- LED switch indicators

Next features:
- Simulation testbenches
- Rectangle drawing primitive
- Line drawing primitive
- UART command interface
- Python command sender