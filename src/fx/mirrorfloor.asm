
; quick & dirty mirrored floor effect
; copied from Kieran's mode7-sprites cracktro wip
; hardcoded to only take top row of pixels from a row

MIRROR_shadow_addr = &7800

MIRROR_read_row = 21			; and the 8 rows above it
MIRROR_write_row = 22			; and the 2 rows below it

MIRROR_start_column = 4			; could be as low as 1

\ ******************************************************************
\ *	Mirror FX
\ ******************************************************************

MIRROR_read_row0_addr = (MIRROR_shadow_addr + ((MIRROR_read_row-0) * MODE7_char_width))
MIRROR_read_row1_addr = (MIRROR_shadow_addr + ((MIRROR_read_row-1) * MODE7_char_width))
MIRROR_read_row2_addr = (MIRROR_shadow_addr + ((MIRROR_read_row-2) * MODE7_char_width))
MIRROR_read_row3_addr = (MIRROR_shadow_addr + ((MIRROR_read_row-3) * MODE7_char_width))
MIRROR_read_row4_addr = (MIRROR_shadow_addr + ((MIRROR_read_row-4) * MODE7_char_width))
MIRROR_read_row5_addr = (MIRROR_shadow_addr + ((MIRROR_read_row-5) * MODE7_char_width))
MIRROR_read_row6_addr = (MIRROR_shadow_addr + ((MIRROR_read_row-6) * MODE7_char_width))
MIRROR_read_row7_addr = (MIRROR_shadow_addr + ((MIRROR_read_row-7) * MODE7_char_width))
MIRROR_read_row8_addr = (MIRROR_shadow_addr + ((MIRROR_read_row-8) * MODE7_char_width))

MIRROR_write_row0_addr = (MIRROR_shadow_addr + ((MIRROR_write_row+0) * MODE7_char_width))
MIRROR_write_row1_addr = (MIRROR_shadow_addr + ((MIRROR_write_row+1) * MODE7_char_width))
MIRROR_write_row2_addr = (MIRROR_shadow_addr + ((MIRROR_write_row+2) * MODE7_char_width))

\\ Probably quicker and more flexible to do the bit conversion as a lookup table
\\ But this will do for now.

\\ Top two pixels bits 0&1 -> top/middle/bottom pixels requires 2 more bits = 12 entry table
\\ Middle two pixels bits 2&3 -> top/middle/bottom pixels use lower 2 bits = 16 entry table
\\ Bottom two pixels bits 4&6 -> top/middle/bottom pixels use lower 2 bits = 128 entry sparse table :\
\\ Could probably embed the first two tables into the unreachable parts of the last table to save mem :)

\\ Would enable dynamically set which lines of read row are transposed to which lines or written row
\\ So could put reflection on a sinewave to make a simple rippling water effect :D

.fx_mirrorfloor_bottom_lookup			; maybe OR in 32?
\\{
	\\ Bits 4&5&6 = 000 
	EQUB 0, 0, 0, 0						; 000 00XX = top/middle/bottom/unused
	EQUB 0, 0, 0, 0						; 000 01XX = invalid
	EQUB 0, 0, 0, 0						; 000 10XX = invalid
	EQUB 0, 0, 0, 0						; 000 11XX = invalid

	\\ Bits 4&5&6 = 001
	EQUB (16>>4), (16>>2), 16, 0		; 001 00XX = top/middle/bottom/unused
	EQUB 0, 0, 0, 0						; 001 01XX = invalid
	EQUB 0, 0, 0, 0						; 001 10XX = invalid
	EQUB 0, 0, 0, 0						; 001 11XX = invalid

	\\ Bits 4&5&6 = 010 = invalid
	.fx_mirrorfloor_top_lookup					; maybe OR in 32?
	{
		\\ Top to top - bits 0&1 stay as 0&1
		EQUB 0, 1, 2, 3

		\\ Top to middle - bits 0&1 become 2&3
		EQUB 0, (1<<2), (2<<2), (3<<2)

		\\ Top to bottom - bit 0 becomes bit 4, bit 1 becomes bit 6
		EQUB 0, (1<<4), (2<<5), (1<<4) OR (2<<5) 
	}
	EQUB 0, 0, 0, 0

	\\ Bits 4&5&6 = 011 = invalid
	.fx_mirrorfloor_middle_lookup				; maybe OR in 32?
	{
		\\ Bits 2&3 both clear - top/middle/bottom/unused
		EQUB 0, 0, 0, 0

		\\ Bit 2 set, bit 3 is clear - top/middle/bottom/unused
		EQUB (4>>2), 4, (4<<2), 0

		\\ Bit 2 is clear, bit 3 is set - top/middle/bottom/unused
		EQUB (8>>2), 8, (8<<3), 0

		\\ Bits 2&3 both set - top/middle/bottom/unused
		EQUB (12>>2), 12, (4<<2) OR (8<<3), 0
	}

	\\ Bits 4&5&6 = 100
	EQUB (64>>5), (64>>3), 64, 0		; 100 00XX = top/middle/bottom/unused
	EQUB 0, 0, 0, 0						; 100 01XX = invalid
	EQUB 0, 0, 0, 0						; 100 10XX = invalid
	EQUB 0, 0, 0, 0						; 100 11XX = invalid

	\\ Bits 4&5&6 = 101
	EQUB (64>>5) OR (16>>4), (64>>3) OR (16>>2), 64 OR 16, 0	; 101 00XX = top/middle/bottom/unused
;	EQUB 0, 0, 0, 0						; 101 01XX = invalid
;	EQUB 0, 0, 0, 0						; 101 10XX = invalid
;	EQUB 0, 0, 0, 0						; 101 11XX = invalid

	\\ Bits 4&5&6 = 110 = invalid
	\\ Bits 4&5&6 = 111 = invalid
\\}

\\ Or could have a table that rotates pixel lines by 0, 1 or 2.  Use two spare bits (7&5) as lookup?
\\ Then to turn top into bottom just rotate by 2, top into top rotate by 0, top into middle rotate by 1 etc.
\\ Needs to be a full 256 byte table.
;LDA read,X
;AND #&20
;ORA #rotation_bits
;TAY
;LDA rotation_table, Y
\\ Still need to mask out the line we're after and mask into final result...
\\ But does give us complete run-time control over the lookup for fixed cost

.fx_mirrorfloor_update_lookup
{
	LDX #MIRROR_start_column

	.loop0
	LDA MIRROR_read_row0_addr, X					; 4c
	AND #&3						; top becomes		; 2c
	ORA #0 << 2					; top				; 2c
	TAY												; 2c
	LDA fx_mirrorfloor_top_lookup, Y				; 4c
	STA byte_to_write_1 + 1							; 4c

	LDA MIRROR_read_row1_addr, X					; 4c
	AND #&3						; top becomes		; 2c
	ORA #1 << 2					; middle			; 2c
	TAY												; 2c
	LDA fx_mirrorfloor_top_lookup, Y				; 4c
	STA byte_to_write_2 + 1							; 4c

	LDA MIRROR_read_row1_addr, X					; 4c
	AND #&3						; top becomes		; 2c
	ORA #2 << 2					; bottom			; 2c
	TAY												; 2c
	LDA fx_mirrorfloor_top_lookup, Y				; 4c
	.byte_to_write_1
	ORA #0											; 2c
	.byte_to_write_2
	ORA #0											; 2c

	ORA #&20										; 2c

	STA MIRROR_write_row0_addr, X					; 5c
	INX												; 2c
	CPX #MODE7_char_width							; 2c
	BCC loop0										; 3c

	\\ 68c

	\\ Do other lines...

	RTS
}


.fx_mirrorfloor_update
{
	LDX #MIRROR_start_column
	.loop0
	LDA MIRROR_read_row0_addr,X						; 4c
	AND #&3											; 2c
	STA mirror_byte_1+1								; 4c
	LDA MIRROR_read_row1_addr,X						; 4c
	AND #&3											; 2c
	ASL A: ASL A				; bits 0&1 become 2&3	; 4c
	.mirror_byte_1
	ORA #0											; 2c
	STA mirror_byte_2+1								; 4c
	LDA MIRROR_read_row2_addr,X						; 4c
	AND #&3											; 2c
	ASL A: ASL A									; 4c
	ASL A: ASL A				; bits 0&1 become 4&5	; 4c
	STA mirror_byte_3+1								; 4c
	AND #&20					; take bit 5 and make it bit 6	; 2c
	ASL A											; 2c
	ORA #&20										; 2c
	.mirror_byte_3
	ORA #0											; 2c
	.mirror_byte_2
	ORA #0											; 2c
	STA MIRROR_write_row0_addr,X					; 5c
	INX												; 2c
	CPX #MODE7_char_width							; 2c
	BCC loop0										; 3c

	\\ 62c

	LDX #MIRROR_start_column
	.loop1
	LDA MIRROR_read_row3_addr,X
	AND #&3
	STA mirror_byte_4+1
	LDA MIRROR_read_row4_addr,X
	AND #&3
	ASL A: ASL A				; bits 0&1 become 2&3
	.mirror_byte_4
	ORA #0
	STA mirror_byte_5+1
	LDA MIRROR_read_row5_addr,X
	AND #&3
	ASL A: ASL A
	ASL A: ASL A				; bits 0&1 become 4&5
	STA mirror_byte_6+1
	AND #&20					; take bit 5 and make it bit 6
	ASL A
	ORA #&20
	.mirror_byte_6
	ORA #0
	.mirror_byte_5
	ORA #0
	STA MIRROR_write_row1_addr,X
	INX
	CPX #MODE7_char_width
	BCC loop1

	LDX #MIRROR_start_column
	.loop2
	LDA MIRROR_read_row6_addr,X
	AND #&3
	STA mirror_byte_7+1
	LDA MIRROR_read_row7_addr,X
	AND #&3
	ASL A: ASL A				; bits 0&1 become 2&3
	.mirror_byte_7
	ORA #0
	STA mirror_byte_8+1
	LDA MIRROR_read_row8_addr,X
	AND #&3
	ASL A: ASL A
	ASL A: ASL A				; bits 0&1 become 4&5
	STA mirror_byte_9+1
	AND #&20					; take bit 5 and make it bit 6
	ASL A
	ORA #&20
	.mirror_byte_9
	ORA #0
	.mirror_byte_8
	ORA #0
	STA MIRROR_write_row2_addr,X
	INX
	CPX #MODE7_char_width
	BCC loop2

	.return
	RTS
}



\\ Super lazy put code at bottom of this file ZOMG

_DOTS_ALT = TRUE

.fx_test_draw_dots
{
	LDA #LO(&7800)
	STA dots_ptr
	LDA #HI(&7800)
	STA dots_ptr+1

	LDX #0
	LDY #0

	.loop
	IF _DOTS_ALT
	LDA dots_alt_data, X		; 4c
	ELSE
	LDA dots_data, X			; 4c
	ENDIF
	\\ LO byte is offset

	CLC							; 2c
	ADC dots_ptr				; 3c
	STA dots_ptr				; 3c

	IF _DOTS_ALT
	{
		BCC no_carry
		INC dots_ptr+1
		.no_carry
	}
	ELSE
	INX							; 2c
	LDA dots_data, X			; 4c

	\\ HI byte has offset in lowest 2 bits
	AND #&3						; 2c
	ADC dots_ptr+1				; 3c
	STA dots_ptr+1				; 3c
	ENDIF

	\\ HI byte has screen bits in to 6 bits

	\\ Decode pixels into MODE 7 byte (6 bits)
	\\ 00X1 1111
	\\ 0X01 1111
	\\ 0X11 1111

	IF _DOTS_ALT
	INX 
	LDA dots_alt_data, X			; 4c
	BEQ skip
	ELSE
	LDA dots_data, X			; 4c
	AND #128					; 2c - top bit 7
	LSR A						; 2c - shift down to bit 6
	STA shifted_bit + 1			; 4c

	LDA dots_data, X			; 4c
	LSR A						; 2c
	LSR A						; 2c - shift down twice
	ORA #32						; 2c - always need 32 for MODE 7
	.shifted_bit
	ORA #0						; 2c - mask in bit 6
	ENDIF

	\\ Write to screen! (do this without indirect write?)
	ORA (dots_ptr),Y			; 5c
	STA (dots_ptr),Y			; 6c
	
	INX							; 2c
	IF _DOTS_ALT
	.skip
	CPX dots_alt_count
	ELSE
	CPX dots_count				; 4c
	ENDIF
	BCC loop					; 3c

	\\ 70c per char to draw - obviously more pixels is better!
	\\ 74c per char to erase (2x EOR to flip bits)

	\\ Using 3 bytes per char would save lots of cycles..
	\\ Could use 2 bytes per char and just have zero pads
	\\ Comes out at 45c per char for 2 bytes (offset + gfx char) encode
	\\ Can only plot at whole character offset not pixel
	\\ But could be useful as basis of animation engine...

	\\ Simon's plot pixel macro (using X&Y registers) is 41c
	\\ Sprite plot routine is 26c per char with ~4 char setup overhead

	\\ This is better for groups of sparse pixels! (video codec)

	\\ Use 0 offset as terminator as can't have zero offset
	\\ Use hi-byte offset as first byte in stream

	.return
	RTS
}

.fx_test_erase_dots
{
	LDA #LO(&7800)
	STA dots_ptr
	LDA #HI(&7800)
	STA dots_ptr+1

	LDX #0
	LDY #0

	.loop
	IF _DOTS_ALT
	LDA dots_alt_data, X			; 4c
	ELSE
	LDA dots_data, X			; 4c
	ENDIF
	\\ LO byte is offset

	CLC
	ADC dots_ptr
	STA dots_ptr

	IF _DOTS_ALT
	{
		BCC no_carry
		INC dots_ptr+1
		.no_carry
	}
	ELSE
	INX							; 2c
	LDA dots_data, X			; 4c

	\\ HI byte has offset in lowest 2 bits
	AND #&3						; 2c
	ADC dots_ptr+1				; 3c
	STA dots_ptr+1				; 3c
	ENDIF

	\\ HI byte has screen bits in to 6 bits

	\\ Decode pixels into MODE 7 byte (6 bits)
	\\ 00X1 1111
	\\ 0X01 1111
	\\ 0X11 1111

	IF _DOTS_ALT
	INX 
	LDA dots_alt_data, X			; 4c
	EOR #&DF
	ELSE
	LDA dots_data, X
	AND #128					; top bit 7
	EOR #128
	LSR A						; shift down to bit 6
	STA shifted_bit + 1

	LDA dots_data, X
	EOR #&FC
	LSR A
	LSR A						; shift down twice
	ORA #32						; always need 32 for MODE 7
	.shifted_bit
	ORA #0						; mask in bit 6
	ENDIF

	\\ Write to screen!
	AND (dots_ptr),Y
	STA (dots_ptr),Y
	
	INX
	IF _DOTS_ALT
	CPX dots_alt_count
	ELSE
	CPX dots_count				; 4c
	ENDIF
	BCC loop

	.return
	RTS
}

INCLUDE "src\sprites\dots_alt.asm"
