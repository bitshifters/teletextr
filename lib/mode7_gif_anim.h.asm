\\ MODE 7 Video routines
\\ 6502 include file
\\ Relies on defines in mode7_plot_pixel.h.asm

mode7_gif_anim_base_addr_HI = draw_buffer_addr

\ ******************************************************************
\ *	"Animated GIF" playback based on mode7-video codec
\ *
\ * Called this animated GIF as doesn't do all the fancy streaming
\ * of tracks from disc or decompression in irq/event callback.
\ *
\ * Instead just takes uncompressed (for now) mode7-video codec data
\ * and decode the next frame to anywhere on the screen on update,
\ * with support for looping.
\ * 
\ * Crappy toolchain exists to generate data from animated GIFs
\ * which are usually shorter than videos + loop.
\ ******************************************************************

\\ These can be simplified - don't need to be ZP
.mode7_gif_anim_num_deltas	        SKIP 2
.mode7_gif_anim_packed_delta	    SKIP 2
.mode7_gif_anim_shifted_bit		    SKIP 1
