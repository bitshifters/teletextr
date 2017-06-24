
; vertical credits scroller
; somewhat generalised so will scroll all MODE 7 characters up by one pixel at a time
; then adds new row of pixels at the bottom from a fixed array

; separate routine fills the new line buffer with font data from an array of text

.start_fx_creditscroll

\\ Change these to adjust window that is scrolled
CREDITS_shadow_addr = MODE7_VRAM_SHADOW
CREDITS_end_addr = CREDITS_shadow_addr + (MODE7_char_width * MODE7_char_height)
CREDITS_first_char = 4
CREDITS_last_char = MODE7_char_width


\ ******************************************************************
\ *	Credit Scroll FX
\ ******************************************************************

\\ Scrolls entire screen up by one pixel adding new pixels from array

\\ Scrolls entire screen up by one pixel adding new pixels from array
FAST_SCROLL = TRUE
.fx_creditscroll_scroll_up
{
	\\ Start by updating the top line
	LDA #LO(CREDITS_shadow_addr)
	STA writeptr
	LDA #HI(CREDITS_shadow_addr)
	STA writeptr+1

	\\ But we'll also be reading from the next line
	LDA #LO(CREDITS_shadow_addr + MODE7_char_width)
	STA readptr
	LDA #HI(CREDITS_shadow_addr + MODE7_char_width)
	STA readptr+1

	\\ For each character row
	.y_loop





IF FAST_SCROLL
	lda writeptr+0
	sta readaddr+1
	sta writeaddr2+1

	lda writeptr+1
	sta readaddr+2
	sta writeaddr2+2

	lda readptr+0
	sta writeaddr1+1

	lda readptr+1
	sta writeaddr1+2
ENDIF



IF FAST_SCROLL
	\\ First char in row
	LDY #CREDITS_first_char
.x_loop

.readaddr
	LDX &ffff, Y			; [4*]
	LDA glyph_shift_table_1-32,X	; [4*]
	STA top_bits+1			; [4]
.writeaddr1
	LDX &ffff, Y			; [4*]
	LDA glyph_shift_table_2-32,X	; [4*]
	.top_bits
	ORA #0					; [2]
	\\ Write the byte back to the screen
.writeaddr2
	STA &ffff, Y		; [4*]
	\\ Full width
	.skip
	INY						; [2]
	CPY #CREDITS_last_char	; [2]
	BCC x_loop				; [2*]

; 32 cycles
ELSE
	\\ First char in row
	LDY #CREDITS_first_char
.x_loop
	\\ Get top pixels from row below
	LDA (readptr), Y		; [5*]
	TAX						; [2]
	AND #&3					; [2]
	STA top_bits + 1		; [4]

	\\ Get bottom pixels from current row
	LDA (writeptr), Y		; [5*]
	AND #&FC				; [2]

	\\ Merge them together
	.top_bits
	ORA #0					; [2]

	\\ Always add 32
	ORA #32					; [2]

	\\ Rotate the pixels to scroll up
	TAX						; [2]
	LDA fx_creditscroll_rotate, X	; [4*]

	\\ Write the byte back to the screen
	STA (writeptr), Y		; [5*]

	\\ Full width
	.skip
	INY						; [2]
	CPY #CREDITS_last_char	; [2]
	BCC x_loop				; [2*]
	; 41 cycles per char

ENDIF


	\\ Move down a row

	LDA readptr
	STA writeptr
	LDA readptr+1
	STA writeptr+1

	CLC
	LDA readptr
	ADC #MODE7_char_width
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

	\\ Do last line separately

	LDY #CREDITS_first_char
	.last_loop

	\\ Mask in top pixels from our new line
	LDA fx_creditscroll_new_line, Y
	AND #&3
	STA top_bits_last+1

	\\ Load last line bottom pixels
	LDA (writeptr), Y
	AND #&FC

	\\ Merge them together
	.top_bits_last
	ORA #0

	\\ Always add 32...
	ORA #32

	\\ Rotate them
	TAX
	LDA fx_creditscroll_rotate, X

	\\ Store back to screen
	STA (writeptr), Y

	\\ Entire row
	INY
	CPY #CREDITS_last_char
	BCC last_loop

	.return
	RTS
}

.fx_creditscroll_rotate_new_line
{
	\\ First char in row
	LDY #CREDITS_first_char
	.x_loop

	\\ Get bottom pixels from current row
	LDA fx_creditscroll_new_line, Y
	AND #&FC

	ORA #32

	\\ Rotate the pixels to scroll up
	TAX
	LDA fx_creditscroll_rotate, X

	\\ Write the byte back to the screen
	STA fx_creditscroll_new_line, Y

	\\ Full width
	.skip
	INY
	CPY #CREDITS_last_char
	BCC x_loop

	.return
	RTS
}

\\ Main update function

.fx_creditscroll_update
{
	\\ Set graphics white
	lda #144+7
	jsr mode7_set_graphics_shadow_fast			; can remove this if other routine handling colours	

	\\ Write new line of text to array
	JSR fx_creditscroll_write_text_line

	\\ Scroll everything up
	JSR fx_creditscroll_scroll_up

	.return
	RTS
}


\ ******************************************************************
\ *	Credit Text FX
\ ******************************************************************

.fx_creditscroll_text_ptr
EQUW fx_creditscroll_text

.fx_creditscroll_text_row
EQUB 0

.fx_creditscroll_text_idx
EQUB 0

.fx_creditscroll_write_text_line
{
	\\ Write text into our new line
	LDA fx_creditscroll_text_ptr
	STA readptr
	LDA fx_creditscroll_text_ptr+1
	STA readptr+1

	LDX fx_creditscroll_text_row
	BEQ write_new_text
	CPX #3
	BEQ write_new_text

	\\ Just rotate existing line
	JSR fx_creditscroll_rotate_new_line
	JMP reached_end_of_row

	.write_new_text

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
	;JSR fx_creditscroll_get_char		; preserves X&Y

	\\ A is index into our font data
	TAY

	.font_addr_1
	LDA mode7_font_data, Y
	INY
	STA fx_creditscroll_new_line, X

	\\ Next char cell
	INX
	CPX #MODE7_char_width
	BCS reached_end_of_row

	.font_addr_2
	LDA mode7_font_data, Y
	INY
	STA fx_creditscroll_new_line, X

	\\ Next char cell
	INX
	CPX #MODE7_char_width
	BCS reached_end_of_row

	.font_addr_3
	LDA mode7_font_data, Y
	INY
	STA fx_creditscroll_new_line, X

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
	CPX #3
	BNE not_three

	\\ At row 3 need to swap to next line of font data
	LDA #LO(mode7_font_data_second_row)
	STA font_addr_1+1
	STA font_addr_2+1
	STA font_addr_3+1
	LDA #HI(mode7_font_data_second_row)
	STA font_addr_1+2
	STA font_addr_2+2
	STA font_addr_3+2

	\\ There are 6 rows in total	
	.not_three
	CPX #6	
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

	\\ Next line of text
	.continue_text

	\\ Need to reset font data
	LDA #LO(mode7_font_data)
	STA font_addr_1+1
	STA font_addr_2+1
	STA font_addr_3+1
	LDA #HI(mode7_font_data)
	STA font_addr_1+2
	STA font_addr_2+2
	STA font_addr_3+2

	\\ Start from row 0
	LDX #0

	.still_same_text
	STX fx_creditscroll_text_row

	.return
	RTS
}


\ ******************************************************************
\ *	Individual chars + typing
\ ******************************************************************

; char in A, at writeptr
.fx_textscreen_plot_char
{
	TAX
	LDY #0

	LDA mode7_font_data, X
	STA (writeptr), Y

	INY
	LDA mode7_font_data+1, X
	STA (writeptr), Y

	INY
	LDA mode7_font_data+2, X
	STA (writeptr), Y

	LDY #MODE7_char_width

	LDA mode7_font_data_second_row, X
	STA (writeptr), Y

	INY
	LDA mode7_font_data_second_row+1, X
	STA (writeptr), Y

	INY
	LDA mode7_font_data_second_row+2, X
	STA (writeptr), Y
	
	RTS
}

.fx_textscreen_char_count
EQUB 0

.fx_textscreen_max_chars
EQUB 0

.fx_textscreen_type_delay
EQUB 0

.fx_textscreen_type_timer
EQUB 0

.fx_textscreen_plot_string
{
	CLC
	TXA
	ADC mode7_sprites_row_addr_LO, Y
	STA writeptr
	LDA #HI(MODE7_VRAM_SHADOW)
	ADC mode7_sprites_row_addr_HI, Y
	STA writeptr+1

	LDY #0
	.loop
	LDA (readptr), Y
	BEQ done_loop
	STY loop_idx+1

	JSR fx_textscreen_plot_char

	\\ Terminate after X chars
	LDX fx_textscreen_char_count
	INX
	STX fx_textscreen_char_count
	CPX fx_textscreen_max_chars
	BCS done_loop

	CLC
	LDA writeptr
	ADC #3
	STA writeptr
	LDA writeptr+1
	ADC #0
	STA writeptr+1

	.loop_idx
	LDY #0
	INY
	BNE loop
	.done_loop

	RTS
}

.fx_textscreen_type_update
{
	INC fx_textscreen_type_timer
	LDA fx_textscreen_type_timer
	CMP fx_textscreen_type_delay
	BCC no_inc

	INC fx_textscreen_max_chars
	LDA #0
	STA fx_textscreen_type_timer

	.no_inc
	JMP fx_textscreen_plot_to_max
}

; address of data in X,Y
.fx_textscreen_plot_all
{
	LDA #&FF
	STA fx_textscreen_max_chars
}
\\ Fall through
.fx_textscreen_plot_to_max
{
	STX fx_creditscroll_ptr
	STY fx_creditscroll_ptr+1

	LDA #0
	STA fx_textscreen_char_count

	.loop
	LDY #0
	LDA (fx_creditscroll_ptr), Y
	CMP #&FF
	BEQ done_loop
	TAX
	INY
	LDA (fx_creditscroll_ptr), Y
	INY
	STA y_pos+1

	TYA
	CLC
	ADC fx_creditscroll_ptr
	STA readptr
	LDA fx_creditscroll_ptr+1
	STA readptr+1

	.y_pos
	LDY #0
	JSR fx_textscreen_plot_string

	LDX fx_textscreen_char_count
	CPX fx_textscreen_max_chars
	BCS done_loop

	; y is updated
	INY
	TYA
	CLC
	ADC readptr
	STA fx_creditscroll_ptr
	LDA readptr+1
	ADC #0
	STA fx_creditscroll_ptr+1
	JMP loop

	.done_loop
	RTS
}

.fx_textscreen_reset_type_delay
{
	STA fx_textscreen_type_delay

	LDA #1
	STA fx_textscreen_max_chars

	LDA #0
	STA fx_textscreen_type_timer

	RTS
}

\ ******************************************************************
\ *	Credit Font FX
\ ******************************************************************

.fx_creditscroll_rotate_table
{
	FOR n, 32, 127, 1	; teletext codes range from 32-127
	a = n AND 1
	b = n AND 2
	c = n AND 4
	d = n AND 8
	e = n AND 16
	f = n AND 64
	
	; Pixel pattern becomes
	;  1  2  ->  a b  ->  c d
	;  4  8  ->  c d  ->  e f 
	; 64 16  ->  e f  ->  a b

	IF (n AND 32)
	PRINT a,b,c,d,e,f
	EQUB 32 + (a * 16) + (b * 32) + (c / 4) + (d / 4) + (e / 4) + (f / 8) + (n AND 128)
	ELSE
	EQUB n
	ENDIF
	NEXT
}

fx_creditscroll_rotate = fx_creditscroll_rotate_table-32

IF FAST_SCROLL
; table to shift 3x2 teletext graphic up by 1 pixel row 
.glyph_shift_table_1
{
	FOR n, 32, 127, 1	; teletext codes range from 32-127
		a = n AND 1
		b = (n AND 2)/2
		c = (n AND 4)/4
		d = (n AND 8)/8
		e = (n AND 16)/16
		f = (n AND 64)/64

		EQUB 32 + (c*1) + (d*2) + (e*4) + (f*8)
		;PRINT n
	NEXT
}
; table to translate top 2 teletext pixels to bottom 2
.glyph_shift_table_2
{
	FOR n, 32, 127, 1	; teletext codes range from 32-127
		a = n AND 1
		b = (n AND 2)/2
		c = (n AND 4)/4
		d = (n AND 8)/8
		e = (n AND 16)/16
		f = (n AND 64)/64

		EQUB (a*16) + (b*64)
	NEXT
}
ENDIF


\\ Spare character row which will get added to bottom of scroll
\\ Update fn so only top two pixels (1+2) get added to bottom of scroll
\\ Can rotate this row itself to shuffle new pixels onto bottom of screen

.fx_creditscroll_new_line
FOR n, 0, MODE7_char_width-1, 1
EQUB 0
NEXT


\\ Map character ASCII values to the byte offset into our MODE 7 font
\\ This is "cunning" but only works because the font has fewer than 256/6 (42) glyphs..

MACRO SET_TELETEXT_FONT_CHAR_MAP

	MAPCHAR 'A', 1
	MAPCHAR 'B', 4
	MAPCHAR 'C', 7
	MAPCHAR 'D', 10
	MAPCHAR 'E', 13
	MAPCHAR 'F', 16
	MAPCHAR 'G', 19
	MAPCHAR 'H', 22
	MAPCHAR 'I', 25
	MAPCHAR 'J', 28
	MAPCHAR 'K', 31
	MAPCHAR 'L', 34
	MAPCHAR 'M', 37

	MAPCHAR 'a', 1
	MAPCHAR 'b', 4
	MAPCHAR 'c', 7
	MAPCHAR 'd', 10
	MAPCHAR 'e', 13
	MAPCHAR 'f', 16
	MAPCHAR 'g', 19
	MAPCHAR 'h', 22
	MAPCHAR 'i', 25
	MAPCHAR 'j', 28
	MAPCHAR 'k', 31
	MAPCHAR 'l', 34
	MAPCHAR 'm', 37

	MAPCHAR 'N', 81
	MAPCHAR 'O', 84
	MAPCHAR 'P', 87
	MAPCHAR 'Q', 90
	MAPCHAR 'R', 93
	MAPCHAR 'S', 96
	MAPCHAR 'T', 99
	MAPCHAR 'U', 102
	MAPCHAR 'V', 105
	MAPCHAR 'W', 108
	MAPCHAR 'X', 111
	MAPCHAR 'Y', 114
	MAPCHAR 'Z', 117

	MAPCHAR 'n', 81
	MAPCHAR 'o', 84
	MAPCHAR 'p', 87
	MAPCHAR 'q', 90
	MAPCHAR 'r', 93
	MAPCHAR 's', 96
	MAPCHAR 't', 99
	MAPCHAR 'u', 102
	MAPCHAR 'v', 105
	MAPCHAR 'w', 108
	MAPCHAR 'x', 111
	MAPCHAR 'y', 114
	MAPCHAR 'z', 117

	MAPCHAR '0', 161
	MAPCHAR '1', 164
	MAPCHAR '2', 167
	MAPCHAR '3', 170
	MAPCHAR '4', 173
	MAPCHAR '5', 176
	MAPCHAR '6', 179
	MAPCHAR '7', 182
	MAPCHAR '8', 185
	MAPCHAR '9', 188
	MAPCHAR '?', 191
	MAPCHAR '!', 194
	MAPCHAR '.', 197

	MAPCHAR ' ', 241

ENDMACRO

SET_TELETEXT_FONT_CHAR_MAP

\\ Credit text strings
\\ First byte is character offset from left side of screen
\\ Then text string terminted by 0
\\ If character offset is &FF this indicates no more strings
\\ Currently strings just loop but could just stop!

\\ New font is 3 chars wide = max 13 letters per line from 1

.fx_creditscroll_text
EQUS 4,"ABCDEFGHIJKL",0
EQUS 4,"MNOPQRSTUVWX",0
EQUS 4,"YZ0123456789",0
EQUS 4,"?!.",0
EQUS 4," ",0
EQUS 4,"Bitshifters",0
EQUS 5,"Presents",0
EQUS 6,"Teletextr",0
EQUS 4," ",0
EQUS 4,"A new demo",0
EQUS 5,"By Henley",0
EQUS 6,"and Kieran..",0
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

\\ How to do a single string
;.fx_textscreen_plot_bs
;{
;	LDA #LO(text_addr):STA readptr:LDA #HI(text_addr):STA readptr+1
;	LDX #4:LDY#4:JMP fx_textscreen_plot_string
;	.text_addr EQUS "BITSHIFTERS", 0
;}

.fx_textscreen_type_presents
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 3,14,"PRESENTS...", 0
	EQUS &FF
}

.fx_textscreen_type_weather
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 4,6,"WEATHER",0
	EQUS 4,8, "FORECAST", 0
	EQUS 17,11,"FOR", 0
	EQUS 8,14, "BUDLEIGH", 0
	EQUS 5,16, "SALTERTON", 0
	EQUS &FF
}

.fx_textscreen_type_oldschool
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 4,6,"OUR",0
	EQUS 4,8, "TELETEXT", 0
	EQUS 17,10,"TRIBUTE", 0
	EQUS 2,13,"TO", 0
	EQUS 2,16, "OLD SCHOOL", 0
	EQUS 10,19, "CREATED",0
	EQUS 20,21, "FOR...", 0
	EQUS &FF
}

.fx_textscreen_type_plasma
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 4,6,"LETS START",0
	EQUS 4,9, "WITH", 0
	EQUS 17,12,"SOME", 0
	EQUS 8,15, "PLASMA...", 0
	EQUS &FF
}

.fx_textscreen_type_interference
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 14,6,"RUN",0
	EQUS 24,9, "THE", 0
	EQUS 3,12,"INTERFERENCE", 0
	EQUS &FF
}

.fx_textscreen_type_rotozoom
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 5,9,"ROTOZOOM..",0
	EQUS &FF
}

.fx_textscreen_type_particles
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 4,6,"PARTICLE",0
	EQUS 8,9, "SYSTEM", 0
	EQUS 12,12,"ENGAGE!", 0
	EQUS &FF
}

.fx_textscreen_type_vectortext
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 4,6,"TIME TO",0
	EQUS 5,9, "CALL", 0
	EQUS 5,12,"BRESENHAM", 0
	EQUS &FF
}

.fx_textscreen_type_vectorballs
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 4,6,"SPRITES",0
	EQUS 5,9,"PLUS",0
	EQUS 5,12,"VECTORS", 0
	EQUS 4,15,"EQUALS...", 0
	EQUS &FF
}

.fx_textscreen_type_3dshapes
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 4,6,"BRINGING",0
	EQUS 5,9, "TELETEXT", 0
	EQUS 5,12,"TO THE 3RD", 0
	EQUS 4,15,"DIMENSION!", 0
	EQUS &FF
}

.fx_textscreen_type_dotscroller
{
	LDX #LO(textscreen_data):LDY #HI(textscreen_data):JMP fx_textscreen_type_update
	.textscreen_data
	EQUS 4,6,"SCROLLER",0
	EQUS 5,9, "THAT IS", 0
	EQUS 5,12,"IMPOSSIBLE", 0
	EQUS 4,15,"TO READ", 0
	EQUS &FF
}

RESET_MAPCHAR

.mode7_font_data				; we use 16/25 lines of this screen
INCBIN "data/font_5x5_shifted_trimmed.mode7.bin"
mode7_font_data_second_row = mode7_font_data + 40

.end_fx_creditscroll
