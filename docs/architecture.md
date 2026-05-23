vga_timing
  → VGA x/y coordinates

x/y scaling
  → 640x480 VGA coordinates become 320x240 framebuffer coordinates

framebuffer_addr
  → converts x/y into memory address

framebuffer
  → stores RGB332 pixels

fb_scene_writer
  → writes background and rectangle into framebuffer

RGB332 to RGB444 converter
  → sends color to VGA output