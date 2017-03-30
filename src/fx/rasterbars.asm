
; extremely dodgy raster bars
; copied from Kieran's mode7-sprites cracktro wip
; uses way too much memory for the quality of the effect!

.start_fx_rasterbars

MODE7_shadow_addr = MODE7_VRAM_SHADOW

FX_RASTERBAR_TABLE_SIZE = 64
FX_RASTER_BAR_GAP = 9

.raster_idx
EQUB 0

.fx_rasterbars_colour
EQUB 0

.fx_rasterbars_write_shadow
{
	CLC

	\\ Do fg colour
	FOR y,0,MODE7_char_height-1,1
	LDA teletext_fg_col + y
	ADC #MODE7_graphic_black
	STA MODE7_shadow_addr + (y * MODE7_char_width) + 3
	NEXT

	\\ Do fx char
	FOR y,0,MODE7_char_height-1,1
	LDA teletext_fx + y
	STA MODE7_shadow_addr + (y * MODE7_char_width) + 2
	NEXT

	\\ Do bg col
	LDX #MODE7_black_bg
	LDY #MODE7_new_bg

	FOR y,0,MODE7_char_height-1,1
	{
		LDA teletext_bg_col + y
		BEQ black

		\\ Colour
		ADC #MODE7_graphic_black
		STA MODE7_shadow_addr + (y * MODE7_char_width) + 0
		STY MODE7_shadow_addr + (y * MODE7_char_width) + 1
		BNE done

		.black
		STX MODE7_shadow_addr + (y * MODE7_char_width) + 1

		.done
	}
	NEXT

	.return
	RTS
}

.fx_rasterbars_reset_bg
{
	LDA #0
	LDY #MODE7_char_height - 1
	.loop1
	STA teletext_bg_col, Y
	DEY
	BNE loop1

	LDA #MODE7_contiguous
	LDY #MODE7_char_height - 1
	.loop2
	STA teletext_fx, Y
	DEY
	BNE loop2

	.return
	RTS
}

.fx_rasterbars_update
{
	\\ Clear our old bars - simpler to just blat the whole lot
	\\ Unless we want this effect to work with other bg effects
	JSR fx_rasterbars_reset_bg

    \\ Update raster index into table
	CLC
	LDA raster_idx
	ADC delta_time					; move delta_time entries forward each update
	AND #(FX_RASTERBAR_TABLE_SIZE - 1)
	STA raster_idx
	TAX
	
	\\ Start with colour bit 1

	LDA #1
	STA fx_rasterbars_colour

    \\ Do this as a loop as not so time critical
	.loop

	\\ Load charater row Y from table
	LDY raster_y_table, X

	\\ Update colour for this row + 2 more
	LDA fx_rasterbars_colour
	ORA teletext_bg_col, Y
	STA teletext_bg_col, Y
	LDA fx_rasterbars_colour
	ORA teletext_bg_col+1, Y
	STA teletext_bg_col+1, Y
	LDA fx_rasterbars_colour
	ORA teletext_bg_col+2, Y
	STA teletext_bg_col+2, Y

	\\ Set these rows to separated gfx
    LDA #MODE7_separated
	STA teletext_fx, Y
	STA teletext_fx+1, Y
	STA teletext_fx+2, Y

	\\ Next colour bit
	LDA fx_rasterbars_colour
	ASL A

	\\ Until done all 3 bits
	CMP #8
	BCS return
	STA fx_rasterbars_colour

	\\ Next bar is offset in our table
	TXA
	CLC
	ADC #FX_RASTER_BAR_GAP					; move 16 entries forward for each bar
	AND #(FX_RASTERBAR_TABLE_SIZE - 1)
	TAX

	JMP loop

	.return
	RTS
}


.raster_y_table				; don't need 256 entries but easier for now
FOR n, 0, FX_RASTERBAR_TABLE_SIZE - 1, 1
	EQUB 12 + 6.9 * SIN(PI * n / (FX_RASTERBAR_TABLE_SIZE / 2))
NEXT
  
\\ Teletext screen = bg col + black/new bg + fx + fg col
.teletext_bg_col
FOR n, 0, MODE7_char_height-1, 1
EQUB 0
NEXT

.teletext_fg_col
FOR n, 0, MODE7_char_height-1, 1
EQUB 7
NEXT

.teletext_fx
FOR n, 0, MODE7_char_height-1, 1
EQUB MODE7_contiguous
NEXT


.end_fx_rasterbars