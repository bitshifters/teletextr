\\ MODE 7 Sprite routines
\\ 6502 source file
\\ Relies on tables in mode7_plot_pixel.asm

\ ******************************************************************
\ *	Fast small masked sprite plot routine
\ *
\ * .mode7_sprites_plot_centred
\ * .mode7_sprites_plot_masked
\ *
\ * Call with X = pixel x-coordinate, Y = pixel y-coordinate and
\ * mode7_sprites_data_ptr = address of sprite + mask data (preserved)
\ * No clipping but safe to call outside of visible area
\ *
\ * Dimensions of sprite are determined in code so must be set by
\ * changing code at run-time but macros exist to automate this.
\ ******************************************************************

.mode7_sprites_plot_centred
\\{
	TXA
	SEC
	.mode7_sprites_centre_x
	SBC #0
	TAX
    TYA
	SEC
	.mode7_sprites_centre_y
	SBC #0
	TAY
\\}
\\ Fall through to plot routine

.mode7_sprites_plot_masked
\\{
	\\ If right edge of sprite beyond right edge of screen don't plot

	.mode7_sprites_right_clip
	cpx #PLOT_PIXEL_RANGE_X - 1			; 2c
	bcs mode7_sprites_not_visible		; 2c

	\\ If bottom edge of sprite beyond bottom edge of screen don't plot
    
	.mode7_sprites_bottom_clip
	cpy #PLOT_PIXEL_RANGE_Y - 1			; 2c
	bcs mode7_sprites_not_visible		; 3c

	\\ Where are we writing to?

	\\ X coordinate to char
	STX mode7_sprites_plot_x + 1		; 4c
	TXA									; 2c
	LSR A								; 2c

	\\ Can use X now as have saved it

	\\ Y coordinate to char
	LDX mode7_sprites_div3_table, Y		; 4c

	\\ Calculate screen address
	CLC									; 2c
	ADC mode7_sprites_row_addr_LO, X	; 4c
	STA screen_load_addr + 1			; 4c
	STA screen_write_addr + 1			; 4c
	LDA mode7_sprites_row_addr_HI, X	; 4c
	ADC mode7_sprites_base_addr_HI		; 3c
	STA screen_load_addr + 2			; 4c
	STA screen_write_addr + 2			; 4c

	\\ Where are we reading data from?

	\\ Calculate offset 0 - 5
	.mode7_sprites_plot_x
	LDA #0								; 2c
	AND #&1								; 2c x_offset
	ORA mode7_sprites_mod3_table, Y		; 4c y_offset

	\\ Multiply by our offset to locate sprite data
	TAX									; 2c
	.mode7_sprites_data_size
	LDA &1000, X						; 4c

	\\ Could simplify this if assuming sprite data is page aligned?

	CLC
	ADC mode7_sprites_data_ptr			; 3c
	STA sprite_data_addr + 1			; 4c
	LDA mode7_sprites_data_ptr+1		; 3c
	ADC #0								; 2c
	STA sprite_data_addr + 2			; 4c

	
	\\ Could simplify this if assuming sprite data is page aligned?

	\\ Mask data lies after sprite data
	\\ Carry clear after addition above
	LDA sprite_data_addr + 1			; 4c
	.mode7_sprites_total_size_LO
	ADC #0								; 2c
	STA sprite_mask_addr + 1			; 4c
	LDA sprite_data_addr + 2			; 4c
	.mode7_sprites_total_size_HI
	ADC #0								; 2c
	STA sprite_mask_addr + 2			; 4c

	LDY #0								; 2c
	LDX #0								; 2c

	\\ Setup overhead = 106c

	\\ Write sprite bytes...

	.mode7_sprites_plot_masked_loop
	.screen_load_addr
	LDA &7800, X						; 4c
	.sprite_mask_addr
	AND &2000, Y				    	; 4c
	.sprite_data_addr
	ORA &3000, Y					    ; 4c
	.screen_write_addr
	STA &7800, X						; 5c

	INY									; 2c
	.mode7_sprites_screen_lookup
	LDX &4000, Y						; 4c
	BNE mode7_sprites_plot_masked_loop	; 3c

	\\ Total for write = 26c per byte = 312c / 780c / 1248c (for size 8 / 12 / 16)
	\\ Overall = 418c / 886c / 1354c (~5c per sixel)

	.mode7_sprites_not_visible
	RTS
\\}


\ ******************************************************************
\ * Sprite sizes as defined:
\ * .mode7_sprites_set_size_8 - actually 7x7 pixels (4x3 chars)
\ * .mode7_sprites_set_size_12 - actually 11x12 pixels (6x5 chars)
\ * .mode7_sprites_set_size_16 - actually 15x16 pixels (8x6 chars)
\ ******************************************************************

.mode7_sprites_set_size_8
{
	SPRITE_PLOT_SET_SIZE 4, 3, mode7_sprites_mult_by_12, mode7_sprites_plot_index_4x3
	RTS
}

.mode7_sprites_set_size_12
{
	SPRITE_PLOT_SET_SIZE 6, 5, mode7_sprites_mult_by_30, mode7_sprites_plot_index_6x5
	RTS
}

.mode7_sprites_set_size_16
{
	SPRITE_PLOT_SET_SIZE 8, 6, mode7_sprites_mult_by_48, mode7_sprites_plot_index_8x6
	RTS
}

\\ Need lookup tables corresponding to our sprite sizes

.mode7_sprites_plot_index_4x3
SPRITE_PLOT_INDEX_TABLE 4, 3

.mode7_sprites_plot_index_6x5
SPRITE_PLOT_INDEX_TABLE 6, 5

.mode7_sprites_plot_index_8x6
SPRITE_PLOT_INDEX_TABLE 8, 6

.mode7_sprites_mult_by_12
SPRITE_PLOT_MULT_TABLE 4, 3

.mode7_sprites_mult_by_30
SPRITE_PLOT_MULT_TABLE 6, 5

.mode7_sprites_mult_by_48
SPRITE_PLOT_MULT_TABLE 8, 6

\\ General lookups needed for sprite routine

.mode7_sprites_mod3_table
FOR n, 0, PLOT_PIXEL_RANGE_Y-1, 1
	EQUB (n MOD 3) << 1						; shift this up as bottom bit is our x offset
NEXT

\\ Sure we can share these with the pixel plot routine somehow?  :)
\\ These tables take up less space (75 + 25 + 25) than just having LO & HI addresses for all pixels (75 + 75) 

.mode7_sprites_div3_table
FOR n, 0, PLOT_PIXEL_RANGE_Y-1, 1
	EQUB (n DIV 3)
NEXT

.mode7_sprites_row_addr_LO
FOR n, 0, MODE7_char_height-1, 1
EQUB LO(n * MODE7_char_width + 1)
NEXT

.mode7_sprites_row_addr_HI
FOR n, 0, MODE7_char_height-1, 1
EQUB HI(n * MODE7_char_width + 1)
NEXT
