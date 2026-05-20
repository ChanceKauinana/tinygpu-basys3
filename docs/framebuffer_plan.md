# Framebuffer Plan

## Resolution

Internal framebuffer resolution:

- Width: 320
- Height: 240
- Color: 8-bit RGB332

VGA output:

- 640x480
- Each framebuffer pixel is scaled to a 2x2 block

## Memory Size

320 x 240 = 76,800 pixels

At 8 bits per pixel:

76,800 bytes

## Addressing

Address formula:

addr = y * 320 + x

Optimized form:

addr = (y << 8) + (y << 6) + x

## Color Format

RGB332:

- color[7:5] = red
- color[4:2] = green
- color[1:0] = blue

Converted to VGA RGB444:

- vgaRed   = {color[7:5], color[7]}
- vgaGreen = {color[4:2], color[4]}
- vgaBlue  = {color[1:0], color[1:0]}

## First Goal

Display framebuffer-based color bars using 320x240 internal resolution scaled to 640x480 VGA.