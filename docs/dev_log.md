Day 1:
# began python setup, and setting up porject folder, git/github setup.
# Wrote the tinygpu top and timing in order to get color bars on the vga screen. (still needs to be tested with real vga).
# set up Vivado so it can generate bitstreams properly.

Day 2:
# Created a framebuffer display instead of the normal VGA display. Converts the display from 640x480 to 320x240. 
# successfuly displayed color bars on the Basyts 3 vga output. 
# the display reads from a 8 bit RGB 332 framebuffer and scales it the output. 

Day 3:
# Today so far, I examined my code a bit more and began to understand how all my modules come together. The FB_puxel writer writes a square of a solid pixel color over the RGB bars that were put on the board from startup from the Framebuffer module. The framebuffer addr module essentially converts the framebuffer into memory. There is a formula in framebuffer addr to place the pixels where they are that is concistent for all of the pixels on the screen. Next, in the vga timing it draws pixels across arow then moves onto the next row. Then it repeats it until it reaches the bottom of the screen. Finally, GPU top connects all these modules together. It recieves a 640x 280 VGA display to the framebuffer, then makes it to a 320x240 display. Then when it outputs, it will scale all the framebuffer pixels up by 2x so then it fits the entire screen.