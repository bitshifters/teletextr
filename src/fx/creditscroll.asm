
; quick & dirty mirrored floor effect
; copied from Kieran's mode7-sprites cracktro wip
; hardcoded to only take top row of pixels from a row

CREDITS_shadow_addr = &7800
CREDITS_end_addr = CREDITS_shadow_addr + (25 * 40)

_CREDITS_NARROW_FONT = TRUE

\ ******************************************************************
\ *	Credit Scroll FX
\ ******************************************************************

.fx_creditscroll_scroll_up
{
	LDA #LO(CREDITS_shadow_addr)
	STA writeptr
	LDA #HI(CREDITS_shadow_addr)
	STA writeptr+1

	LDA #LO(CREDITS_shadow_addr + 40)
	STA readptr
	LDA #HI(CREDITS_shadow_addr + 40)
	STA readptr+1

	.y_loop

	LDY #4
	.x_loop

	\\ Get top pixels from row below
	LDA (readptr), Y
	AND #&3
	STA top_bits + 1

	\\ Get bottom pixels from current row
	LDA (writeptr), Y
	AND #&FC

	\\ Merge them together
	.top_bits
	ORA #0

	\\ Always add 32
	ORA #32

	\\ Rotate the pixels to scroll up
	TAX
	LDA fx_creditscroll_rotate, X

	\\ Write the byte back to the screen
	STA (writeptr), Y

	\\ Full width
	.skip
	INY
	CPY #40
	BCC x_loop

	\\ Move down a row

	LDA readptr
	STA writeptr
	LDA readptr+1
	STA writeptr+1

	CLC
	LDA readptr
	ADC #40
	STA readptr
	LDA readptr+1
	ADC #0
	STA readptr+1

	\\ Check if we've reached the end?
	LDA readptr
	CMP #LO(CREDITS_end_addr)
	BNE y_loop
	LDA readptr+1
	CMP #HI(CREDITS_end_addr)
	BNE y_loop

	\\ Do last line!

	LDY #4
	.last_loop

	\\ Load last line bottom pixels
	LDA (writeptr), Y
	AND #&FC

	\\ Mask in top pixesl from our new line
	ORA fx_creditscroll_new_line, Y

	\\ Always 32
	ORA #32

	\\ Rotate them
	TAX
	LDA fx_creditscroll_rotate, X

	\\ Store back to screen
	STA (writeptr), Y

	\\ Entire row
	INY
	CPY #40
	BCC last_loop

	.return
	RTS
}

.fx_creditscroll_text_ptr
EQUW fx_creditscroll_text

.fx_creditscroll_text_row
EQUB 0

.fx_creditscroll_text_idx
EQUB 0

.fx_creditscroll_update
{
	\\ Write new line of text
	JSR fx_creditscroll_write_text_line

	\\ Scroll everything up
	JSR fx_creditscroll_scroll_up

	.return
	RTS
}

.fx_creditscroll_write_text_line
{
	\\ Write text into our new line
	LDA fx_creditscroll_text_ptr
	STA readptr
	LDA fx_creditscroll_text_ptr+1
	STA readptr+1

	LDX #MODE7_char_width-1
	LDA #0
	.clear_loop
	STA fx_creditscroll_new_line, X
	DEX
	BPL clear_loop

	\\ Get X start
	LDY #0
	LDA (readptr), Y
	TAX

	\\ Set row

	INY
	.char_loop
	STY fx_creditscroll_text_idx

	\\ Get text char
	LDA (readptr), Y
	BNE not_end_of_string

	\\ If EOS assume EOR
	JMP reached_end_of_row

	.not_end_of_string
	JSR fx_creditscroll_get_char		; preserves X&Y

	\\ Just bit-shift for now - we have time & its our name :)

	LDY fx_creditscroll_text_row

	IF _CREDITS_NARROW_FONT
	\\ 128 -> 1
	{
		LDA fx_creditscroll_def, Y
		AND #128
		BEQ no_bit
		LDA #1
		STA fx_creditscroll_new_line, X
		.no_bit
	}

	\\ 32 -> 2
	{
		LDA fx_creditscroll_def, Y
		AND #32
		BEQ no_bit
		LDA #2
		ORA fx_creditscroll_new_line, X
		STA fx_creditscroll_new_line, X
		.no_bit
	}

	\\ Next char cell
	INX
	CPX #MODE7_char_width
	BCS reached_end_of_row

	\\ 8 -> 1
	{
		LDA fx_creditscroll_def, Y
		AND #8
		BEQ no_bit
		LDA #1
		STA fx_creditscroll_new_line, X
		.no_bit
	}

	\\ 2 -> 2
	{
		LDA fx_creditscroll_def, Y
		AND #2
		BEQ no_bit
		LDA #2
		ORA fx_creditscroll_new_line, X
		STA fx_creditscroll_new_line, X
		.no_bit
	}
	ELSE
	\\ 128 + 64 -> 1 + 2
	{
		LDA fx_creditscroll_def, Y
		AND #128
		BEQ no_bit
		LDA #1
		STA fx_creditscroll_new_line, X
		.no_bit
	}

	{
		LDA fx_creditscroll_def, Y
		AND #64
		BEQ no_bit
		LDA #2
		ORA fx_creditscroll_new_line, X
		STA fx_creditscroll_new_line, X
		.no_bit
	}

	\\ Next char cell
	INX
	CPX #MODE7_char_width
	BCS reached_end_of_row

	\\ 32 + 16 -> 1 + 2
	{
		LDA fx_creditscroll_def, Y
		AND #32
		BEQ no_bit
		LDA #1
		STA fx_creditscroll_new_line, X
		.no_bit
	}

	{
		LDA fx_creditscroll_def, Y
		AND #16
		BEQ no_bit
		LDA #2
		ORA fx_creditscroll_new_line, X
		STA fx_creditscroll_new_line, X
		.no_bit
	}

	\\ Next char cell
	INX
	CPX #MODE7_char_width
	BCS reached_end_of_row

	\\ 8 + 4 -> 1 + 2
	{
		LDA fx_creditscroll_def, Y
		AND #8
		BEQ no_bit
		LDA #1
		STA fx_creditscroll_new_line, X
		.no_bit
	}

	{
		LDA fx_creditscroll_def, Y
		AND #4
		BEQ no_bit
		LDA #2
		ORA fx_creditscroll_new_line, X
		STA fx_creditscroll_new_line, X
		.no_bit
	}

	\\ Next char cell
	INX
	CPX #MODE7_char_width
	BCS reached_end_of_row

	\\ 2 + 1 -> 1 + 2
	{
		LDA fx_creditscroll_def, Y
		AND #2
		BEQ no_bit
		LDA #1
		STA fx_creditscroll_new_line, X
		.no_bit
	}

	{
		LDA fx_creditscroll_def, Y
		AND #1
		BEQ no_bit
		LDA #2
		ORA fx_creditscroll_new_line, X
		STA fx_creditscroll_new_line, X
		.no_bit
	}
	ENDIF

	\\ Next char cell
	INX
	CPX #MODE7_char_width
	BCS reached_end_of_row

	LDY fx_creditscroll_text_idx

	\\ Next text char
	INY
	JMP char_loop

	.reached_end_of_row

	\\ Next time do next row
	LDX fx_creditscroll_text_row
	INX
	CPX #8
	BCC still_same_text

	\\ Next line of text
	LDY fx_creditscroll_text_idx

	\\ Skip to EOS
	{
		.loop
		LDA (readptr), Y
		BEQ done
		INY
		BNE loop
		.done
	}

	\\ Check whether there are any more strings
	INY
	LDA (readptr), Y
	CMP #&FF
	BNE next_line_text

	\\ Reset to start of text
	LDA #LO(fx_creditscroll_text)
	STA fx_creditscroll_text_ptr
	LDA #HI(fx_creditscroll_text)
	STA fx_creditscroll_text_ptr+1

	\\ Or just flag not to write any more text..
	JMP continue_text

	\\ Update text pointer
	.next_line_text
	TYA
	CLC
	ADC fx_creditscroll_text_ptr
	STA fx_creditscroll_text_ptr
	LDA fx_creditscroll_text_ptr+1
	ADC #0
	STA fx_creditscroll_text_ptr+1

	\\ Start from first row
	.continue_text
	LDX #0

	.still_same_text
	STX fx_creditscroll_text_row

	.return
	RTS

	
	\\ Could stop adding text...
	RTS
}

.fx_creditscroll_get_char
{
	\\ Set up OSWORD call to obtain character definition
	STA fx_creditscroll_char
	TXA:PHA:TYA:PHA

	LDX #LO(fx_creditscroll_char)
	LDY #HI(fx_creditscroll_char)
	LDA #&A
	JSR osword				; osword call
	\\ Or could use predefined font

	PLA:TAY:PLA:TAX
	.return
	RTS
}

.fx_creditscroll_char		SKIP 1			; character definition required
.fx_creditscroll_def		SKIP 8			; character definition bytes

.fx_creditscroll_rotate
{
	FOR n, 0, 255, 1
	a = n AND 1
	b = n AND 2
	c = n AND 4
	d = n AND 8
	e = n AND 16
	f = n AND 64
	
	IF (n AND 32)
	PRINT a,b,c,d,e,f
	EQUB 32 + (a * 16) + (b * 32) + (c / 4) + (d / 4) + (e / 4) + (f / 8) + (n AND 128)
	ELSE
	EQUB n
	ENDIF
	NEXT
}

.fx_creditscroll_new_line
FOR n, 0, MODE7_char_width-1, 1
EQUB 0
NEXT

.fx_creditscroll_text
EQUS 4,"Bitshifters",0
EQUS 5,"Presents",0
EQUS 6,"Teletextr",0
EQUS 4," ",0
EQUS 4,"A new demo",0
EQUS 5,"By Henley",0
EQUS 6,"& Kieran..",0
EQUS 4," ",0
EQUS 4,"BBC rulez!",0
EQUS 5,"Etc.",0
EQUS 4," ",0
EQUS 4," ",0
EQUS 4," ",0
EQUS 4," ",0
EQUS 4," ",0
EQUS 4," ",0
EQUS 4," ",0
EQUS 4," ",0
EQUS &FF

IF 0
.fx_creditscroll_test
{
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast

	LDY #4
	.loop

	LDA #(1 + 2)
	STA fx_creditscroll_new_line, Y

	INY
	CPY #40
	BCC loop

	.return
	RTS
}
ENDIF
