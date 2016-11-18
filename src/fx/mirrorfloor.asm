
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
