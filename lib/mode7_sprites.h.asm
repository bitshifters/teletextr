\\ MODE 7 Sprite routines
\\ 6502 include file
\\ Relies on defines in mode7_plot_pixel.h.asm

.mode7_sprites_data_ptr	SKIP 2

mode7_sprites_base_addr_HI = draw_buffer_addr

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

\ ******************************************************************
\ * Sprite sizes as defined:
\ * .mode7_sprites_set_size_8 - actually 7x7 pixels (4x3 chars)
\ * .mode7_sprites_set_size_12 - actually 11x12 pixels (6x5 chars)
\ * .mode7_sprites_set_size_16 - actually 15x16 pixels (8x6 chars)
\ ******************************************************************


MACRO SPRITE_PLOT_INDEX_TABLE char_width, char_height
{
	FOR y, 0, char_height - 1, 1
	FOR x, 0, char_width - 1, 1
	EQUB (y * MODE7_char_width) + x
	NEXT
	NEXT
	EQUB 255
}
ENDMACRO

MACRO SPRITE_PLOT_MULT_TABLE char_width, char_height
{
	size = char_width * char_height
	FOR n, 0, 5, 1
	EQUB n * size
	NEXT
}
ENDMACRO

MACRO SPRITE_PLOT_SET_SIZE char_width, char_height, mult_table, lookup_table
{
	pixel_width = char_width * 2
	pixel_height = (char_height * 3) - 2
	data_size = char_width * char_height

	\\ Set centre
	LDA #(pixel_width / 2)
	STA mode7_sprites_centre_x + 1
	LDA #(pixel_height / 2)
	STA mode7_sprites_centre_y + 1
		
	\\ Set clip
	LDA #(PLOT_PIXEL_RANGE_X - pixel_width)
	STA mode7_sprites_right_clip + 1
	LDA #(PLOT_PIXEL_RANGE_Y - pixel_height)
	STA mode7_sprites_bottom_clip + 1

	\\ Set data offset lookup
	LDA #LO(mult_table)
	STA mode7_sprites_data_size + 1
	LDA #HI(mult_table)
	STA mode7_sprites_data_size + 2

	\\ Set offset to mask
	LDA #LO(data_size * 6)
	STA mode7_sprites_total_size_LO + 1
	LDA #HI(data_size * 6)
	STA mode7_sprites_total_size_HI + 1

	\\ Set screen index table
	LDA #LO(lookup_table)
	STA mode7_sprites_screen_lookup + 1
	LDA #HI(lookup_table)
	STA mode7_sprites_screen_lookup + 2
}
ENDMACRO
