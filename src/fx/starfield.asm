
; quick & dirty starfield
; copied from Kieran's mode7-sprites cracktro wip

.start_fx_starfield

STARFIELD_shadow_addr = &7800

STARFIELD_ERASE_STARS = TRUE				; FALSE if erasing screen anyway

STARFIELD_top_row = 1						; omit Ceefax header
STARFIELD_left_column = 4					; needs to be 4 if req background colour
STARFIELD_num_stars = 24					; also number of rows

STARFIELD_right_edge = (MODE7_char_width - STARFIELD_left_column) * 2
STARFIELD_start_addr = STARFIELD_shadow_addr + (STARFIELD_top_row * MODE7_char_width) + STARFIELD_left_column

\ ******************************************************************
\ *	Starfield FX
\ ******************************************************************

.fx_starfield_update
{
	\\ Set graphics white
	lda #144+7
	jsr mode7_set_graphics_shadow_fast	

	\\ Set start address
	LDA #LO(STARFIELD_start_addr)
	STA writeptr
	LDA #HI(STARFIELD_start_addr)
	STA writeptr+1

	LDX #0
	.loop

	\\ Erase old star
	IF STARFIELD_ERASE_STARS
	LDA stars_table_byte,X
	CMP #32
	BNE no_erase
	
	LDA stars_table_x,X
	LSR A:LSR A:TAY
	
	LDA #32
	STA (writeptr),Y
	ENDIF

	.no_erase
	\\ Update star x position based on speed & wrap
	CLC
	LDA stars_table_x,X
	ADC stars_table_speed,X
	CMP #STARFIELD_right_edge*2
	BCC no_wrap
	SBC #STARFIELD_right_edge*2
	.no_wrap
	STA stars_table_x,X

	\\ Calculate x char
	LSR A:LSR A:TAY

	\\ Is there something there already?
	LDA (writeptr), Y
	IF STARFIELD_ERASE_STARS
	STA stars_table_byte,X
	ENDIF
	CMP #32
	BNE skip_write

	\\ Plot our star
	LDA stars_table_x,X
	LSR A
	AND #&1						; odd or even
	CLC
	ADC #33						; 1 or 2 OR 32
	STA (writeptr), Y			; reuses Y as x char from above

	.skip_write

	\\ Next star
	INX
	CPX #STARFIELD_num_stars
	BCS return

	\\ Next row
	CLC
	LDA writeptr
	ADC #MODE7_char_width
	STA writeptr
	BCC no_carry
	INC writeptr+1
	.no_carry
	JMP loop

	.return
	RTS
}

\ ******************************************************************
\ *	Look up tables
\ ******************************************************************

.stars_table_x
FOR n, 0, STARFIELD_num_stars, 1
	EQUB RND(STARFIELD_right_edge * 2)
NEXT

.stars_table_speed
FOR n, 0, STARFIELD_num_stars, 1
	EQUB 1+RND(3)					; only 3 speeds
NEXT

IF STARFIELD_ERASE_STARS
.stars_table_byte
SKIP STARFIELD_num_stars
ENDIF

.end_fx_starfield