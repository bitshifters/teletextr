
; quick & dirty mirrored floor effect
; copied from Kieran's mode7-sprites cracktro wip
; hardcoded to only take top row of pixels from a row

DOTSCROLL_shadow_addr = &7800
DOTSCROLL_num_columns = 32
DOTSCROLL_num_rows = 8

_DOTSCROLL_SMOOTH = TRUE			; don't like this effect

\ ******************************************************************
\ *	Mirror FX
\ ******************************************************************


.fx_dotscroller_index
EQUB 0

.fx_dotscroller_byte
EQUB 0

\\ Bits in A, column# in X
.fx_dotscroller_plot_column
\\{
	STA fx_dotscroller_byte

	\\ X column to table index
	TXA
	ASL A: ASL A: ASL A
	TAX

	\\ How many times round the loop?
	.fx_dotscroller_plot_column_loop
	LDA fx_dotscroller_byte
	BEQ fx_dotscroller_plot_column_return

	ASL A						; I pllanned this to be the other way up but fine for now!
	STA fx_dotscroller_byte
	BCC fx_dotscroller_plot_column_skip_plot

	STX fx_dotscroller_plot_column_temp_x+1
	.fx_dotscroller_plot_column_table_x
	LDA fx_dotscroll_x, X
	.fx_dotscroller_plot_column_table_y
	LDY fx_dotscroll_y, X
	TAX
	
	{
		PLOT_PIXEL
	}

	.fx_dotscroller_plot_column_temp_x
	LDX #0

	.fx_dotscroller_plot_column_skip_plot
	INX
	BNE fx_dotscroller_plot_column_loop

	.fx_dotscroller_plot_column_return
	RTS
\\}

.fx_dotscroller_msg
EQUS "HELLO WORLD! This is a dot scroller which seems pretty unreadable to begin with... 0123456789    "
EQUB 0

.fx_dotscroller_char_idx
EQUB 0

.fx_dotscroller_cur_col
EQUB 0

.fx_dotscroller_col_idx
EQUB 0

.fx_dotscroller_update
{
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast

	LDA fx_dotscroller_char_idx
	STA char_idx + 1

IF _DOTSCROLL_SMOOTH
	LDA fx_dotscroller_col_idx
	LSR A
	STA first_col + 1
	BCC use_table_2

	\\ Use table 1
	LDA #LO(fx_dotscroll_x)
	STA fx_dotscroller_plot_column_table_x + 1
	LDA #HI(fx_dotscroll_x)
	STA fx_dotscroller_plot_column_table_x + 2
	LDA #LO(fx_dotscroll_y)
	STA fx_dotscroller_plot_column_table_y + 1
	LDA #HI(fx_dotscroll_y)
	STA fx_dotscroller_plot_column_table_y + 2
	JMP start

	.use_table_2
	LDA #LO(fx_dotscroll_x2)
	STA fx_dotscroller_plot_column_table_x + 1
	LDA #HI(fx_dotscroll_x2)
	STA fx_dotscroller_plot_column_table_x + 2
	LDA #LO(fx_dotscroll_y2)
	STA fx_dotscroller_plot_column_table_y + 1
	LDA #HI(fx_dotscroll_y2)
	STA fx_dotscroller_plot_column_table_y + 2
ELSE
	LDA fx_dotscroller_col_idx
	STA first_col + 1
ENDIF

	.start
	LDX #0
	STX fx_dotscroller_cur_col

	.char_loop

	.char_idx
	LDY #0
	LDA fx_dotscroller_msg, Y
	BNE not_zero
	STA char_idx + 1
	BEQ char_idx

	.not_zero
	INY
	STY char_idx + 1

	\\ Convert char to fb
	LDX #LO(fx_dotscroller_fb)
	LDY #HI(fx_dotscroller_fb)
	JSR billb_char_to_fb

	\\ Plot columns
	.first_col
	LDY #0
	.col_loop
	STY fb_idx + 1
	LDA fx_dotscroller_fb, Y

	LDX fx_dotscroller_cur_col
	JSR fx_dotscroller_plot_column

	LDX fx_dotscroller_cur_col
	INX
	STX fx_dotscroller_cur_col
	CPX #32
	BCS done

	.fb_idx
	LDY #0
	INY
	CPY #8
	BCC col_loop

	\\ Next char but from start of column
	LDA #0
	STA first_col + 1

	JMP char_loop

	.done

	LDX fx_dotscroller_col_idx
	LDY fx_dotscroller_char_idx

	\\ Next column next time
	INX
IF _DOTSCROLL_SMOOTH
	CPX #16
ELSE
	CPX #8
ENDIF

	BCC same_char

	\\ Next char next time
	LDX #0
	INY
	LDA fx_dotscroller_msg, Y
	BNE same_char
	LDY #0 

	.same_char
	STX fx_dotscroller_col_idx
	STY fx_dotscroller_char_idx

	.return
	RTS
}


\\ Pass character ASCII in A
\\ Pass fb address to write in X (LO) & Y (HI)
.billb_char_to_fb
{
	\\ Store passed in variables
	STA billb_charreq
	STX writeptr
	STY writeptr+1
	
	\\ Set up OSWORD call to obtain character definition
	LDX #LO(billb_charreq)
	LDY #HI(billb_charreq)
	LDA #&A
	JSR osword				; osword call
	\\ Or could use predefined font
	
	LDY #0					; index into our write buffer
	
	LDA #&80				; mask for char column, start top bit set
	STA t_charmask

	.rowtocol
	LDA #1					; mask for fb col byte, start bottom bit set
	STA t_fbmask

	LDA #0
	STA (writeptr),Y		; blank fb col byte first

	LDX #0
	.rowtoloop
	LDA t_charmask			; load mask for column
	AND billb_chardef,X		; mask against char row
	BEQ norowbit

	LDA (writeptr),Y		; load existing fb byte
	ORA t_fbmask			; mask in our bit
	STA (writeptr),Y		; store back

	.norowbit
	ASL t_fbmask			; next bit in fb mask
	INX
	CPX #8
	BNE rowtoloop

	INY						; next fb row
	BEQ endofloop			; break if overflow
	
	LSR t_charmask			; shift char mask right
	BNE rowtocol			; until zero
	
	.endofloop
	RTS
}

\\ Temporary workspace for character conversion
.t_charmask				SKIP 1		; character mask
.t_fbmask				SKIP 1		; framebuffer mask
.billb_charreq			SKIP 1			; character definition required
.billb_chardef			SKIP 8			; character definition bytes

.fx_dotscroller_fb		SKIP 8

ALIGN &100
.fx_dotscroll_x
{
	FOR c, 0, DOTSCROLL_num_columns-1, 1
	FOR r, 0, DOTSCROLL_num_rows-1, 1

	centre_x = 38
	centre_y = 60
	inner = 10
	outer = 30
	distance = inner + (outer - inner) * r / DOTSCROLL_num_rows

	angle = PI/2 + 1 * PI * c / DOTSCROLL_num_columns
	EQUB centre_x - distance * SIN(angle) 

	NEXT
	NEXT
}

.fx_dotscroll_y
{
	FOR c, 0, DOTSCROLL_num_columns-1, 1
	FOR r, 0, DOTSCROLL_num_rows-1, 1

	centre_x = 38
	centre_y = 60
	inner = 14
	outer = 36
	distance = inner + (outer - inner) * r / DOTSCROLL_num_rows

	angle = PI/2 + 1 * PI * c / DOTSCROLL_num_columns
	EQUB centre_y + distance * COS(angle) 

	NEXT
	NEXT
}

IF _DOTSCROLL_SMOOTH
.fx_dotscroll_x2
{
	FOR c, 0, DOTSCROLL_num_columns-1, 1
	FOR r, 0, DOTSCROLL_num_rows-1, 1

	centre_x = 38
	centre_y = 60
	inner = 10
	outer = 30
	distance = inner + (outer - inner) * r / DOTSCROLL_num_rows

	angle = PI/2 + PI / (2*DOTSCROLL_num_columns) + 1 * PI * c / DOTSCROLL_num_columns
	EQUB centre_x - distance * SIN(angle) 

	NEXT
	NEXT
}

.fx_dotscroll_y2
{
	FOR c, 0, DOTSCROLL_num_columns-1, 1
	FOR r, 0, DOTSCROLL_num_rows-1, 1

	centre_x = 38
	centre_y = 60
	inner = 14
	outer = 36
	distance = inner + (outer - inner) * r / DOTSCROLL_num_rows

	angle = PI/2 + PI / (2*DOTSCROLL_num_columns) + 1 * PI * c / DOTSCROLL_num_columns
	EQUB centre_y + distance * COS(angle) 

	NEXT
	NEXT
}
ENDIF
