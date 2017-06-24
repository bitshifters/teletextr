
; quick & dirty dot scroller
; written to try out Simon's fast PLOT_PIXEL macro
; was thinking about a fixed position (sparse) sprite plot routine for interesting scrollers
; but figured I would get it working with dots first to see if I like it
; now uses own font (pre-rotated) but currently takes up 3 pages (96 characters)
; entire dot map can be moved at runtime by updating cx, cy but that isn't required can optimise out

.start_fx_dotscroller

_DOTSCROLL_SMOOTH = FALSE			; don't like this effect
_DOTSCROLL_BALL = FALSE				; not compatible with _SMOOTH!
_DOTSCROLL_ANGLE = FALSE				; otherwise half circle

\\ Definitions
DOTSCROLL_shadow_addr = &7800
DOTSCROLL_num_columns = 32
DOTSCROLL_num_rows = 8
DOTSCROLL_cols_per_glyph = 8

\\ Dots are defined in this space
DOTSCROLL_dot_centre_x = 128
DOTSCROLL_dot_centre_y = 128

\\ Transformed into teletext pixel space
DOTSCROLL_screen_centre_x = 38
DOTSCROLL_screen_centre_y = 36									; row 12

\\ Clamping / clipping coordinates
DOTSCROLL_dot_left_clip =  DOTSCROLL_dot_centre_x - DOTSCROLL_screen_centre_x
DOTSCROLL_dot_right_clip =  DOTSCROLL_dot_centre_x + DOTSCROLL_screen_centre_x
DOTSCROLL_dot_top_clip =  DOTSCROLL_dot_centre_y - DOTSCROLL_screen_centre_y		; odd number of pixels vertically
DOTSCROLL_dot_bottom_clip =  DOTSCROLL_dot_centre_y + 29		; ignore bottom 3 lines for reflection


\ ******************************************************************
\ *	Dotscroller Plot FX
\ ******************************************************************

.fx_dotscroller_byte
EQUB 0

.fx_dotscroller_cx			; 0 = centre of screen, -ve left, +ve right
EQUB 0

.fx_dotscroller_cy			; 0 = centre of screen, -ve up, +ve down
IF _DOTSCROLL_BALL
EQUB 10
ELSE
IF _DOTSCROLL_ANGLE
EQUB 0
ELSE
EQUB 28
ENDIF
ENDIF

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

	\\ New centre / offset
	\\ Could remove this if not going to animte dot scroller
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

	\\ Clamping
	\\ Could also clip and not draw if out of bounds
	{
		CPX #DOTSCROLL_dot_left_clip
		BCS left_ok
		LDX #DOTSCROLL_dot_left_clip
		.left_ok
		CPX #DOTSCROLL_dot_right_clip
		BCC right_ok
		LDX #DOTSCROLL_dot_right_clip
		.right_ok
		CPY #DOTSCROLL_dot_top_clip
		BCS top_ok
		LDY #DOTSCROLL_dot_top_clip
		.top_ok
		CPY #DOTSCROLL_dot_bottom_clip
		BCC bottom_ok
		LDY #DOTSCROLL_dot_bottom_clip
		.bottom_ok
	}

	\\ Adjust to screen
	\\ Could remove this if not going to animte dot scroller
	{
		TXA
		SEC
		SBC #(DOTSCROLL_dot_centre_x - DOTSCROLL_screen_centre_x)
		TAX

		TYA
		SEC
		SBC #(DOTSCROLL_dot_centre_y - DOTSCROLL_screen_centre_y)
		TAY
	}

	\\ Plot that pixel, yo!
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


\ ******************************************************************
\ *	Dotscroller Scroll FX
\ ******************************************************************

.fx_dotscroller_set_text
{
	STX fx_dotscroller_ptr
	STY fx_dotscroller_ptr+1

	LDA 0
	STA fx_dotscroller_char_idx
	STA fx_dotscroller_col_idx

	RTS
}

MACRO FX_DOTSCROLLER_SET_FN text_string
{
	LDX #LO(text_addr):LDY #HI(text_addr):JMP fx_dotscroller_set_text
	.text_addr EQUS text_string, 0			; sadly MACROs don't like text parameters :(
}
ENDMACRO

IF 0
.fx_dotscroller_set_text_3d
{
	LDX #LO(text_addr):LDY #HI(text_addr):JMP fx_dotscroller_set_text
	.text_addr EQUS "        HOW ABOUT SOME 3D SHAPES?        ", 0
}

.fx_dotscroller_set_text_vb
{
	LDX #LO(text_addr):LDY #HI(text_addr):JMP fx_dotscroller_set_text
	.text_addr EQUS "        VECTORBALLS IN TELETEXT?!        ", 0
}

.fx_dotscroller_set_text_part
{
	LDX #LO(text_addr):LDY #HI(text_addr):JMP fx_dotscroller_set_text
	.text_addr EQUS "        PARTICLES ON A BEEB? SURE!        ", 0
}

.fx_dotscroller_set_text_int
{
	LDX #LO(text_addr):LDY #HI(text_addr):JMP fx_dotscroller_set_text
	.text_addr EQUS "        OLD SCHOOL INTERFERENCE FTW!        ", 0
}

.fx_dotscroller_set_text_rot
{
	LDX #LO(text_addr):LDY #HI(text_addr):JMP fx_dotscroller_set_text
	.text_addr EQUS "        ROTOZOOM!!...        ", 0
}

.fx_dotscroller_set_text_pl
{
	LDX #LO(text_addr):LDY #HI(text_addr):JMP fx_dotscroller_set_text
	.text_addr EQUS "        GOTTA HAVE SOME PLASMA        ", 0
}

\\ NB. Can only have 255 characters max at the moment
.fx_dotscroller_msg
EQUS "HELLO WORLD! THIS IS A DOT SCROLLER WHICH IS SOMEWHAT UNREADABLE BUT BETTER IN UPPERCASE!... 0123456789    "
EQUB 0
ENDIF

.fx_dotscroller_set_text_hello
{
	LDX #LO(text_addr):LDY #HI(text_addr):JMP fx_dotscroller_set_text
	.text_addr EQUS "    HELLO TO EVERYONE AT THE PARTY!!   ", 0
}

.fx_dotscroller_char_idx
EQUB 0

.fx_dotscroller_cur_col				; temp during fn
EQUB 0

.fx_dotscroller_col_idx
EQUB 0

.fx_dotscroller_update
{
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast

\\ Update the centre of our dots

	IF _DOTSCROLL_BALL
	JSR fx_dotscroller_bounce_centre
	ENDIF

\\ Do the scroll text bit

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
	LDA (fx_dotscroller_ptr), Y
	BNE not_zero
	STA char_idx + 1
	BEQ char_idx

	.not_zero
	INY
	STY char_idx + 1

	\\ Convert char to fb
	JSR fx_dotscroller_get_char

	\\ Plot columns
	.first_col
	LDY #0
	.col_loop
	STY fb_idx + 1
	LDA (readptr), Y

	LDX fx_dotscroller_cur_col
	JSR fx_dotscroller_plot_column

	LDX fx_dotscroller_cur_col
	INX
	STX fx_dotscroller_cur_col
	CPX #DOTSCROLL_num_columns
	BCS done

	.fb_idx
	LDY #0
	INY
	CPY #DOTSCROLL_cols_per_glyph
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
	CPX #DOTSCROLL_cols_per_glyph * 2
ELSE
	CPX #DOTSCROLL_cols_per_glyph
ENDIF

	BCC same_char

	\\ Next char next time
	LDX #0
	INY
	LDA (fx_dotscroller_ptr), Y
	BNE same_char
	LDY #0 

	.same_char
	STX fx_dotscroller_col_idx
	STY fx_dotscroller_char_idx

	.return
	RTS
}


\ ******************************************************************
\ *	Dotscroller Font FX
\ ******************************************************************

\\ Pass character ASCII in A
\\ Return in readptr
.fx_dotscroller_get_char
{
	SEC
	SBC #32
	STA readptr
	LDA #0
	STA readptr+1

	\\ Multiply by 8

	ASL readptr
	ROL readptr+1
	ASL readptr
	ROL readptr+1
	ASL readptr
	ROL readptr+1

	\\ Add font address

	CLC
	LDA #LO(bbc_font_rotated)
	ADC readptr
	STA readptr
	LDA #HI(bbc_font_rotated)
	ADC readptr+1
	STA readptr+1

	\\ Don't bother copying, just return in readptr

	.return
	RTS
}


\ ******************************************************************
\ *	Dotscroller Ball FX
\ ******************************************************************

IF _DOTSCROLL_BALL
.fx_dotscroller_vx
EQUB 2

.fx_dotscroller_vy
EQUB 0

.fx_dotscroller_bounce_centre
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
	CMP #&DC			; -36
	BCS y_ok

	\\ Clamp y top
	LDA #&DC			; -36
	STA fx_dotscroller_cy

	.y_ok
	LDA fx_dotscroller_cx
	BMI check_left

	\\ Check right
	CMP #36				; 10 lines below centre
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
ENDIF


\ ******************************************************************
\ *	Dotscroller Lookup Tables
\ ******************************************************************

ALIGN &100
.fx_dotscroll_x
{
IF _DOTSCROLL_ANGLE
	FOR c, 0, DOTSCROLL_num_columns-1, 1
	FOR r, 0, DOTSCROLL_num_rows-1, 1

	dx=(c - (DOTSCROLL_num_columns/2))*2
	dy=(r - (DOTSCROLL_num_rows/2))*2

	EQUB DOTSCROLL_dot_centre_x + dx * SIN(3*PI/4) + dy * COS(3*PI/4)

	NEXT
	NEXT
ELSE	; half circle
	FOR c, 0, DOTSCROLL_num_columns-1, 1
	FOR r, 0, DOTSCROLL_num_rows-1, 1

	centre_x = DOTSCROLL_dot_centre_x
	centre_y = DOTSCROLL_dot_centre_y

	IF _DOTSCROLL_BALL
	inner = 4
	outer = 20
	angle = PI/4 + (12*PI/8) * c / DOTSCROLL_num_columns
	ELSE
	inner = 10
	outer = 35
	angle = PI/2 + 1 * PI * c / DOTSCROLL_num_columns
	ENDIF

	distance = inner + (outer - inner) * r / DOTSCROLL_num_rows
	EQUB centre_x - distance * SIN(angle) 

	NEXT
	NEXT
ENDIF
}

.fx_dotscroll_y
{
IF _DOTSCROLL_ANGLE
	FOR c, 0, DOTSCROLL_num_columns-1, 1
	FOR r, 0, DOTSCROLL_num_rows-1, 1

	dx=(c - (DOTSCROLL_num_columns/2))*2
	dy=(r - (DOTSCROLL_num_rows/2))*2

	EQUB DOTSCROLL_dot_centre_y - dy * SIN(3*PI/4) + dx * COS(3*PI/4)

	NEXT
	NEXT
ELSE	; half circle
	FOR c, 0, DOTSCROLL_num_columns-1, 1
	FOR r, 0, DOTSCROLL_num_rows-1, 1

	centre_x = DOTSCROLL_dot_centre_x
	centre_y = DOTSCROLL_dot_centre_y

	IF _DOTSCROLL_BALL
	inner = 6
	outer = 22
	angle = PI/4 + (12*PI/8) * c / DOTSCROLL_num_columns
	ELSE
	inner = 14
	outer = 36
	angle = PI/2 + 1 * PI * c / DOTSCROLL_num_columns
	ENDIF

	distance = inner + (outer - inner) * r / DOTSCROLL_num_rows
	EQUB centre_y + distance * COS(angle) 

	NEXT
	NEXT
ENDIF
}

IF _DOTSCROLL_SMOOTH
.fx_dotscroll_x2
{
	FOR c, 0, DOTSCROLL_num_columns-1, 1
	FOR r, 0, DOTSCROLL_num_rows-1, 1

	centre_x = DOTSCROLL_dot_centre_x
	centre_y = DOTSCROLL_dot_centre_y
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

	centre_x = DOTSCROLL_dot_centre_x
	centre_y = DOTSCROLL_dot_centre_y
	inner = 14
	outer = 36
	distance = inner + (outer - inner) * r / DOTSCROLL_num_rows

	angle = PI/2 + PI / (2*DOTSCROLL_num_columns) + 1 * PI * c / DOTSCROLL_num_columns
	EQUB centre_y + distance * COS(angle) 

	NEXT
	NEXT
}
ENDIF

.bbc_font_rotated
;INCBIN ".\data\bbc_font_90_deg_cw.bin"
;INCBIN ".\data\bold_font_90_deg_cw.bin"
INCBIN ".\data\square_font_90_deg_cw.bin"

.end_fx_dotscroller