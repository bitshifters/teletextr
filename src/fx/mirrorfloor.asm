
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

.fx_mirrorfloor_update
{
	LDX #MIRROR_start_column
	.loop0
	LDA MIRROR_read_row0_addr,X
	AND #&3
	STA mirror_byte_1+1
	LDA MIRROR_read_row1_addr,X
	AND #&3
	ASL A: ASL A				; bits 0&1 become 2&3
	.mirror_byte_1
	ORA #0
	STA mirror_byte_2+1
	LDA MIRROR_read_row2_addr,X
	AND #&3
	ASL A: ASL A
	ASL A: ASL A				; bits 0&1 become 4&5
	STA mirror_byte_3+1
	AND #&20					; take bit 5 and make it bit 6
	ASL A
	ORA #&20
	.mirror_byte_3
	ORA #0
	.mirror_byte_2
	ORA #0
	STA MIRROR_write_row0_addr,X
	INX
	CPX #MODE7_char_width
	BCC loop0

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
