# Development Log

## Day 1
- Began Python setup and created the project folder.
- Set up git and GitHub for version control.
- Wrote `tinygpu_top` and VGA timing modules to drive color bars on the VGA screen. (Still needs testing with real VGA hardware.)
- Configured Vivado so it can generate bitstreams properly.

## Day 2
- Built a framebuffer display pipeline instead of using the normal direct VGA output.
- Converted the display from 640x480 to 320x240 to save memory.
- Successfully displayed color bars on the Basys3 VGA output.
- Confirmed that the display reads from an 8-bit RGB332 framebuffer and scales that output to the screen.

## Day 3
- Reviewed the code and began understanding how all the modules work together.
- `fb_pixel_writer` draws a solid-color square into the framebuffer on top of the startup color bars.
- `framebuffer_addr` converts 2D framebuffer coordinates into linear memory addresses, using a formula that keeps pixel placement consistent.
- `vga_timing` scans pixels across each row, then moves to the next row until it reaches the bottom of the screen.
- `tinygpu_top` connects these modules, taking 640x480 VGA timing and mapping visible pixels into a 320x240 framebuffer.
- The output effectively scales framebuffer pixels by 2x so the image fills the VGA screen.
- Added a button controller that cycles through different background colors.
- Added a scene writer that can draw different scenes on the VGA display. Currently it draws a red rectangle.
