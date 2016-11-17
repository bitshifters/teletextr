\\ MODE 7 Sprite routines
\\ 6502 source file
\\ Relies on tables in mode7_plot_pixel.asm

\ ******************************************************************
\ *	Fast small sprite plot - fixed 4x3 chars = 7x7 pixels
\ * Coordinates plot_x, plot_y assume 4 char boundary
\ * Call with X = plot_x, Y = plot_y
\ * No clipping but safe to call outside of visible area
\ * Probably fairly simple to adapt this to 8x6 chars = 15x16 pixels
\ ******************************************************************

IF 0
.mode7_sprites_plot_masked_8e
{
    TXA:SEC:SBC #4:TAX
    TYA:SEC:SBC #4:TAY

	cpx #PLOT_PIXEL_RANGE_X
	bcs sprite_not_visible
	\\ If X char outside edge of screen then return
	cpx #PLOT_PIXEL_RANGE_X - 8
	bcs sprite_not_visible
    
	cpy #PLOT_PIXEL_RANGE_Y
	bcs sprite_not_visible
	cpy #PLOT_PIXEL_RANGE_Y - 9
	bcc sprite_is_visible

	.sprite_not_visible
	RTS

	\\ X coordinate to char
    .sprite_is_visible
	TXA									; 2c
	LSR A								; 2c

	STA plot_char_x + 1					; 2c

	\\ Where are we reading data from?

	TXA									; 2c
	AND #&1								; 2c x_offset
	ORA mod3_table, Y					; 4c y_offset
	LSR A								; 2c shift down
	BCC no_x_offset						; 3c if x_offset falls into carry
	ORA #&10							; 2c add it back (shifted down)
	CLC									; 2c
	.no_x_offset

	\\ Could simplify this if assuming sprite data is page aligned

	ADC mode7_sprites_data_ptr					; 3c
	STA sprite_data_addr + 1			; 4c
	LDA mode7_sprites_data_ptr+1					; 3c
	ADC #0								; 2c
	STA sprite_data_addr + 2			; 4c

	\\ Can now claim X register as finished with plot_x

	\\ Y coordinate to char
	LDX div3_table, Y					; 4c

	\\ Where are we writing to?
	\\ Carry clear after addition above
	LDA mode7_row_addr_LO, X			; 4c
    .plot_char_x
	ADC #0						        ; 2c
	STA screen_load_addr + 1			; 4c
	STA screen_write_addr + 1			; 4c
	LDA mode7_row_addr_HI, X			; 4c
	ADC #0								; 2c
	STA screen_load_addr + 2			; 4c
	STA screen_write_addr + 2			; 4c
	
	\\ Could simplify this if assuming sprite data is page aligned

	\\ Mask data lies after sprite data
	\\ Carry clear after addition above
	LDA sprite_data_addr + 1			; 4c
	ADC #96								; 2c
	STA sprite_mask_addr + 1			; 4c
	LDA sprite_data_addr + 2			; 4c
	ADC #0								; 2c
	STA sprite_mask_addr + 2			; 4c

	LDY #0								; 2c
	LDX #0								; 2c

	\\ Setup overhead = 114c

	\\ Write 12 bytes...
	\\ 4 bytes per row x 3 rows

	.loop
	.screen_load_addr
	LDA &7C00, X						; 4c
	.sprite_mask_addr
	AND &1000, Y				    	; 4c
	.sprite_data_addr
	ORA &2000, Y					    ; 4c
	.screen_write_addr
	STA &7C00, X						; 5c

	INY									; 2c
	LDX fast_plot_index_8e, Y			; 4c
	BPL loop							; 3c

	\\ Total for write = 12 x 26c = 312c
	\\ Overall = 114c + 312c = 426c

	.return
	RTS
}


.mode7_sprites_plot_masked_16e
{
    TXA:SEC:SBC #8:TAX
    TYA:SEC:SBC #8:TAY

	cpx #PLOT_PIXEL_RANGE_X
	bcs sprite_not_visible
	\\ If X char outside edge of screen then return
	cpx #PLOT_PIXEL_RANGE_X - 16
	bcs sprite_not_visible
    
	cpy #PLOT_PIXEL_RANGE_Y
	bcs sprite_not_visible
	cpy #PLOT_PIXEL_RANGE_Y - 18
	bcc sprite_is_visible

	.sprite_not_visible
	RTS

	\\ X coordinate to char
    .sprite_is_visible
	TXA									; 2c
	LSR A								; 2c
	STA plot_char_x + 1					; 4c

	\\ Where are we reading data from?

	TXA									; 2c
	AND #&1								; 2c x_offset
	ORA mod3_table, Y					; 4c y_offset
	LSR A								; 2c shift down
	BCC no_x_offset						; 3c if x_offset falls into carry
	ORA #&10							; 2c add it back (shifted down)
	CLC									; 2c
	.no_x_offset
	LSR A: LSR A: LSR A:LSR A			; 8c shift down so is lookup - could simplify this

	TAX									; 2c
	LDA fast_plot_mult_48, X			; 4c lookup * 48

	\\ Could simplify this if assuming sprite data is page aligned

	ADC mode7_sprites_data_ptr					; 3c
	STA sprite_data_addr + 1			; 4c
	LDA mode7_sprites_data_ptr+1					; 3c
	ADC #0								; 2c
	STA sprite_data_addr + 2			; 4c

	\\ Can now claim X register as finished with plot_x

	\\ Y coordinate to char
	LDX div3_table, Y					; 4c

	\\ Where are we writing to?
	\\ Carry clear after addition above
	LDA mode7_row_addr_LO, X			; 4c
    .plot_char_x
	ADC #0      						; 2c
	STA screen_load_addr + 1			; 4c
	STA screen_write_addr + 1			; 4c
	LDA mode7_row_addr_HI, X			; 4c
	ADC #0								; 2c
	STA screen_load_addr + 2			; 4c
	STA screen_write_addr + 2			; 4c
	
	\\ Could simplify this if assuming sprite data is page aligned

	\\ Mask data lies after sprite data
	\\ Carry clear after addition above
	LDA sprite_data_addr + 1			; 4c
	ADC #LO(8 * 6 * 6)					; 2c
	STA sprite_mask_addr + 1			; 4c
	LDA sprite_data_addr + 2			; 4c
	ADC #HI(8 * 6 * 6)					; 2c
	STA sprite_mask_addr + 2			; 4c

	LDY #0								; 2c
	LDX #0								; 2c

	\\ Setup overhead = 128c

	\\ Write 48 bytes...
	\\ 8 bytes per row x 6 rows

	.loop
	.screen_load_addr
	LDA &7C00, X						; 4c
	.sprite_mask_addr
	AND &2000, Y					; 4c
	.sprite_data_addr
	ORA &3000, Y					; 4c
	.screen_write_addr
	STA &7C00, X						; 5c

	INY									; 2c
	LDX fast_plot_index_16e, Y			; 4c
	CPX #&FF							; 2c
	BNE loop							; 3c

	\\ Total for write = 48 x 28c = 1344c
	\\ Overall = 128c + 1344c = 1472c

	.return
	RTS
}
ENDIF


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
	cpx #PLOT_PIXEL_RANGE_X - 1
	bcs sprite_not_visible
    
	.mode7_sprites_bottom_clip
	cpy #PLOT_PIXEL_RANGE_Y - 1
	bcc sprite_is_visible

	.sprite_not_visible
	RTS

	\\ X coordinate to char
    .sprite_is_visible
	TXA									; 2c
	LSR A								; 2c

	STA sprite_plot_char_x + 1			; 4c

	\\ Where are we reading data from?

	TXA									; 2c
	AND #&1								; 2c x_offset
	ORA mode7_sprite_mod3_table, Y		; 4c y_offset

	\\ Multiply by our offset to locate sprite data
	TAX									; 2c
	.mode7_sprites_data_size
	LDA &1000, X			; 4c lookup * 48

	\\ Could simplify this if assuming sprite data is page aligned

	CLC
	ADC mode7_sprites_data_ptr			; 3c
	STA sprite_data_addr + 1			; 4c
	LDA mode7_sprites_data_ptr+1		; 3c
	ADC #0								; 2c
	STA sprite_data_addr + 2			; 4c

	\\ Can now claim X register as finished with plot_x

	\\ Y coordinate to char
	LDX div3_table, Y					; 4c

	\\ Where are we writing to?
	\\ Carry clear after addition above
	LDA mode7_row_addr_LO, X			; 4c
    .sprite_plot_char_x
	ADC #0						        ; 2c
	STA screen_load_addr + 1			; 4c
	STA screen_write_addr + 1			; 4c
	LDA mode7_row_addr_HI, X			; 4c
	ADC #0								; 2c
	STA screen_load_addr + 2			; 4c
	STA screen_write_addr + 2			; 4c
	
	\\ Could simplify this if assuming sprite data is page aligned

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

	\\ Setup overhead = XXXX

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
	CPX #&FF							; this can be omitted for sprites < 3 rows in size
	BNE mode7_sprites_plot_masked_loop	; 3c

	\\ Total for write = XXXX
	\\ Overall = XXXX

	.mode7_sprites_plot_masked_return
	RTS
\\}

\\ Generate functions to set sprite size in general routine

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

.mode7_sprite_mod3_table
FOR n, 0, PLOT_PIXEL_RANGE_Y-1, 1
	EQUB (n MOD 3) << 1						; shift this up as bottom bit is our x offset
NEXT

\\ Sure we can share these with the pixel plot routine

.mode7_row_addr_LO
FOR n, 0, MODE7_char_height-1, 1
EQUB LO(&7800 + n * MODE7_char_width)
NEXT

.mode7_row_addr_HI
FOR n, 0, MODE7_char_height-1, 1
EQUB HI(&7800 + n * MODE7_char_width)
NEXT

.div3_table
FOR n, 0, PLOT_PIXEL_RANGE_Y-1, 1
	EQUB (n DIV 3)
NEXT
