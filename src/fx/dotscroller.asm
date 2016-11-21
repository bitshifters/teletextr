
; quick & dirty dot scroller
; written to try out Simon's fast PLOT_PIXEL macro
; was thinking about a fixed position (sparse) sprite plot routine for interesting scrollers
; but figured I would get it working with dots first to see if I like it
; uses OSWORD to get char definitions at runtime so clearly not optimal!
; need a 8x8 font but can't be bothered to convert one
; could also just convert the entire BBC font at initialisation time

DOTSCROLL_shadow_addr = &7800
DOTSCROLL_num_columns = 32
DOTSCROLL_num_rows = 8

_DOTSCROLL_SMOOTH = FALSE			; don't like this effect

\ ******************************************************************
\ *	Mirror FX
\ ******************************************************************


.fx_dotscroller_index
EQUB 0

.fx_dotscroller_byte
EQUB 0

.fx_dotscroller_cx
EQUB 0

.fx_dotscroller_cy
EQUB -10

.fx_dotscroller_vx
EQUB 2

.fx_dotscroller_vy
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

	ASL A						; I planned this to be the other way up but fine for now!
	STA fx_dotscroller_byte
	BCC fx_dotscroller_plot_column_skip_plot

	STX fx_dotscroller_plot_column_temp_x+1
	.fx_dotscroller_plot_column_table_x
	LDA fx_dotscroll_x, X
	.fx_dotscroller_plot_column_table_y
	LDY fx_dotscroll_y, X
	TAX

	\\ New centre
	{
		TXA
		CLC
		ADC fx_dotscroller_cx
		TAX

		TYA
		CLC
		ADC fx_dotscroller_cy
		TAY
	}

	\\ Clipping
	{
		CPX #(128 - 38)
		BCS left_ok
		LDX #(128 - 38)
		.left_ok
		CPX #(128 + 38)
		BCC right_ok
		LDX #(128 + 38)
		.right_ok
		CPY #(128 - 36)
		BCS top_ok
		LDY #(128 - 36)
		.top_ok
		CPY #(128 + 29)
		BCC bottom_ok
		LDY #(128 + 29)
		.bottom_ok
	}

	\\ Adjust to screen
	{
		TXA
		SEC
		SBC #(128 - 38)
		TAX

		TYA
		SEC
		SBC #(128 - 36)
		TAY
	}

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
EQUS "HELLO WORLD! THIS IS A BOUNCING DOT SCROLLER WHICH IS ALSO PRETTY UNREADABLE BUT BETTER IN UPPERCASE!... 0123456789    "
EQUB 0

.fx_dotscroller_char_idx
EQUB 0

.fx_dotscroller_cur_col
EQUB 0

.fx_dotscroller_col_idx
EQUB 0

.fx_dotscroller_update_centre
{
	\\ Update velocity
	CLC
	LDA fx_dotscroller_vy
	ADC #1						; gravity
	STA fx_dotscroller_vy

	\\ Update position
	CLC
	LDA fx_dotscroller_cx
	ADC fx_dotscroller_vx		; should be times delta
	STA fx_dotscroller_cx

	CLC
	LDA fx_dotscroller_cy
	ADC fx_dotscroller_vy		; should be times delta
	STA fx_dotscroller_cy

	\\ Collision detection
	LDA fx_dotscroller_cy
	BMI check_top

	\\ Check bottom
	CMP #30						; 10 lines below centre
	BCC y_ok

	\\ Flip velocity for bounce
	CLC
	LDA	fx_dotscroller_vy
	ADC #1
	EOR #&FF
	ADC #1 						; otherwise lose momentum
	STA fx_dotscroller_vy

	\\ Clamp y bottom
	LDA #30
	STA fx_dotscroller_cy
	JMP y_ok

	.check_top
	CMP #&DC		; -36
	BCS y_ok

	\\ Clamp y top
	LDA #&DC			; -36
	STA fx_dotscroller_cy

	.y_ok
	LDA fx_dotscroller_cx
	BMI check_left

	\\ Check right
	CMP #36						; 10 lines below centre
	BCC x_ok

	\\ Flip velocity for bounce
	CLC
	LDA	fx_dotscroller_vx
	EOR #&FF
	ADC #1 
	STA fx_dotscroller_vx

	\\ Clamp x right
	LDA #36
	STA fx_dotscroller_cx
	JMP x_ok
	
	.check_left
	CMP #&DC			; -36
	BCS x_ok

	\\ Flip velocity for bounce
	CLC
	LDA	fx_dotscroller_vx
	EOR #&FF
	ADC #1 
	STA fx_dotscroller_vx

	\\ Clamp x left
	LDA #&DC			; -36
	STA fx_dotscroller_cx

	.x_ok

	.return
	RTS
}

.fx_dotscroller_update
{
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast

\\ Update centre

	JSR fx_dotscroller_update_centre

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

	centre_x = 128
	centre_y = 128
	inner = 4
	outer = 20
	distance = inner + (outer - inner) * r / DOTSCROLL_num_rows

	angle = PI/4 + (12*PI/8) * c / DOTSCROLL_num_columns
	EQUB centre_x - distance * SIN(angle) 

	NEXT
	NEXT
}

.fx_dotscroll_y
{
	FOR c, 0, DOTSCROLL_num_columns-1, 1
	FOR r, 0, DOTSCROLL_num_rows-1, 1

	centre_x = 128
	centre_y = 128
	inner = 6
	outer = 22
	distance = inner + (outer - inner) * r / DOTSCROLL_num_rows

	angle = PI/4 + (12*PI/8) * c / DOTSCROLL_num_columns
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
