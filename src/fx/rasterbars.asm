
; extremely dodgy raster bars
; copied from Kieran's mode7-sprites cracktro wip
; uses way too much memory for the quality of the effect!

MODE7_shadow_addr = &7800

RASTER_centre_row = 11
RASTER_wave_rows = 6
RASTER_table_inc = 64

.raster_idx
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

.fx_rasterbars_update
{
	\\ Clear our old bar
	LDX raster_idx
	LDY raster_y_table, X

	LDA #0
	STA teletext_bg_col, Y
	STA teletext_bg_col+1, Y
	STA teletext_bg_col+2, Y

    LDA #MODE7_contiguous
	STA teletext_fx, Y
	STA teletext_fx+1, Y
	STA teletext_fx+2, Y

	TXA
	CLC
	ADC #RASTER_table_inc
	TAX
	LDY raster_y_table, X

	LDA #0
	STA teletext_bg_col, Y
	STA teletext_bg_col+1, Y
	STA teletext_bg_col+2, Y

    LDA #MODE7_contiguous
	STA teletext_fx, Y
	STA teletext_fx+1, Y
	STA teletext_fx+2, Y
	
	TXA
	CLC
	ADC #RASTER_table_inc
	TAX
	LDY raster_y_table, X

	LDA #0
	STA teletext_bg_col, Y
	STA teletext_bg_col+1, Y
	STA teletext_bg_col+2, Y

    LDA #MODE7_contiguous
	STA teletext_fx, Y
	STA teletext_fx+1, Y
	STA teletext_fx+2, Y

    \\ Update raster index into table
	LDX raster_idx
	INX
	INX
	STX raster_idx
	
    \\ Write our new colour values
	LDY raster_y_table, X
	LDA #1
	ORA teletext_bg_col, Y
	STA teletext_bg_col, Y
	LDA #1
	ORA teletext_bg_col+1, Y
	STA teletext_bg_col+1, Y
	LDA #1
	ORA teletext_bg_col+2, Y
	STA teletext_bg_col+2, Y

    LDA #MODE7_separated
	STA teletext_fx, Y
	STA teletext_fx+1, Y
	STA teletext_fx+2, Y

	TXA
	CLC
	ADC #RASTER_table_inc
	TAX
	LDY raster_y_table, X

	LDA #2
	ORA teletext_bg_col, Y
	STA teletext_bg_col, Y
	LDA #2
	ORA teletext_bg_col+1, Y
	STA teletext_bg_col+1, Y
	LDA #2
	ORA teletext_bg_col+2, Y
	STA teletext_bg_col+2, Y

    LDA #MODE7_separated
	STA teletext_fx, Y
	STA teletext_fx+1, Y
	STA teletext_fx+2, Y
	
	TXA
	CLC
	ADC #RASTER_table_inc
	TAX
	LDY raster_y_table, X

	LDA #4
	ORA teletext_bg_col, Y
	STA teletext_bg_col, Y
	LDA #4
	ORA teletext_bg_col+1, Y
	STA teletext_bg_col+1, Y
	LDA #4
	ORA teletext_bg_col+2, Y
	STA teletext_bg_col+2, Y

    LDA #MODE7_separated
	STA teletext_fx, Y
	STA teletext_fx+1, Y
	STA teletext_fx+2, Y

	.return
	RTS
}


.raster_y_table				; don't need 256 entries but easier for now
FOR n, 0, 255, 1
	EQUB RASTER_centre_row + RASTER_wave_rows * SIN(PI * n / 128)
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
