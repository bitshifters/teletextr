\\ Plot Pixel functions
\\ 6502 include file
\\ DISPLAY_MODE variable must be set prior to inclusion

; [ 1][ 2] + 160
; [ 4][ 8]
; [16][64]


PLOT_PIXEL_RANGE_X = 2*40 - 2   ; -2 to compensate for 1st char being graphics control code
PLOT_PIXEL_RANGE_Y = 3*25
	
.plot_lo 	SKIP 1
.plot_hi	SKIP 1
.plot_tmp   SKIP 1
.plot_cnt   SKIP 2

plot_base_addr = draw_buffer_addr


DEBUG_PIXEL_COUNT = FALSE


MACRO DRAW_NUMBER var, addr
	lda var
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda hexascii,x
	sta addr+0
	lda var
	and #15
	tax
	lda hexascii,x		
	sta addr+1
ENDMACRO

MACRO DRAW_PIXEL_COUNT  addr
	DRAW_NUMBER plot_cnt+1, addr
	DRAW_NUMBER plot_cnt+0, addr+2
ENDMACRO

MACRO RESET_PIXEL_COUNT
	lda #0
	sta plot_cnt+0
	sta plot_cnt+1
ENDMACRO