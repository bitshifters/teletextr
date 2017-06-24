
; wibbling logo
; using sprite data from mode7-sprites cracktro wip

.start_fx_logowibble

LOGOWIBBLE_shadow_addr = MODE7_VRAM_SHADOW

LOGOWIBBLE_char_width = 40
LOGOWIBBLE_char_height = 5
LOGOWIBBLE_sixel_height = (LOGOWIBBLE_char_height * 3)

LOGOWIBBLE_x_position = 1
LOGOWIBBLE_y_scr_addr = LOGOWIBBLE_shadow_addr + (7 * MODE7_char_width) + LOGOWIBBLE_x_position
LOGOWIBBLE_table_size = 224

\ ******************************************************************
\ *	Logo Wibble FX
\ ******************************************************************

\\ Drawing complete sprite at fixed vertical position
\\ Each sixel line can have a separate X value
\\ For each sixel line
\\ Get x value
\\ Switch data block even/odd
\\ Start at x char, mask in all sprite data for that sixel line

.fx_logowibble_index
EQUB 0

.fx_logowibble_update
{
	\\ Set graphics white
	lda #144+7
	jsr mode7_set_graphics_shadow_fast	

	\\ Reset screen write address for this frame
	LDA #LO(LOGOWIBBLE_y_scr_addr)
	STA fx_logowibble_load_addr + 1
	STA fx_logowibble_write_addr + 1

	LDA #HI(LOGOWIBBLE_y_scr_addr)
	STA fx_logowibble_load_addr + 2
	STA fx_logowibble_write_addr + 2

	LDY #0					; sixel row

	.sixel_row_loop

	\\ Index into table for X lookup
	TYA
;	ASL A
	CLC
	ADC fx_logowibble_index
	CMP #LOGOWIBBLE_table_size
	BCC no_table_wrap
	SBC #LOGOWIBBLE_table_size
	.no_table_wrap
;	AND #(LOGOWIBBLE_table_size-1)
	TAX

	\\ Get x position
	LDA fx_logowibble_table, X			; X value for this sixel row
	STA fx_logowibble_x_pos + 1
	AND #&1
	ORA mode7_sprites_mod3_table, Y		; gives us 0-5 offset
	TAX

	LDA fx_logowibble_row_mask, X
	STA fx_logowibble_data_mask + 1
	
	\\ Sprite address = logo_data_XY + char_row
	\\ There's probably a quicker way to do this by toggling sprite data index depending on X parity
	CLC
	LDA fx_logowibble_sprite_table_LO, X
	ADC fx_logowibble_y_mult_table_LO, Y
	STA fx_logowibble_data_addr + 1

	LDA fx_logowibble_sprite_table_HI, X
	ADC fx_logowibble_y_mult_table_HI, Y
	STA fx_logowibble_data_addr + 2
	\\ Also don't need to calc sprite address each time if using dense data - to be optimised

	\\ Save sixel row index
	STY fx_logowibble_y_row+1

	\\ X char position on screen
	.fx_logowibble_x_pos
	LDA #0

	CMP #80
	BCS no_left_clip

	\\ Left clip
	EOR #&FF
	ADC #82
	LSR A
	TAY

; 77 -> X=0 Y=4/2=2
; 78 => X=0 Y=3/2=1
; 79 => X=0 Y=2/2=1
; 80 => X=0/2=0 Y=0
; 81 => X=1/2=0 Y=0

	LDX #0					; clip left to X=1
	JMP fx_logowibble_plot_loop

	.no_left_clip
	SEC
	SBC #80

	LSR A
	TAX

	LDY #0

	.fx_logowibble_plot_loop

	.fx_logowibble_data_addr
	LDA &2000, Y

	.fx_logowibble_data_mask
	AND #0
	
	BEQ next_char

	ORA #32

	.fx_logowibble_load_addr
	ORA &7800, X

	\\ Could mask out bits here to avoid having 6x copies of the sprite data

	.fx_logowibble_write_addr
	STA &7800, X

	\\ Next char
	.next_char
	INX
	CPX #MODE7_char_width-1
	BCS fx_logowibble_y_row
	INY
	CPY #LOGOWIBBLE_char_width
	BNE fx_logowibble_plot_loop

	\\ Next sixel row
	.fx_logowibble_y_row
	LDY #0
	INY
	CPY #LOGOWIBBLE_sixel_height
	BCS return

	\\ Did we move onto next character row?
	LDA mode7_sprites_mod3_table, Y
	BNE sixel_row_loop

	\\ Need to update screen pointers
	;CLC		; cleared above
	LDA fx_logowibble_load_addr + 1
	ADC #MODE7_char_width
	STA fx_logowibble_load_addr + 1
	STA fx_logowibble_write_addr + 1
	BCC sixel_row_loop

	\\ Carry
	INC fx_logowibble_load_addr + 2
	INC fx_logowibble_write_addr + 2
	BEQ return
	JMP sixel_row_loop

	\\ Could also move to next sprite data row if dense data
	\\ Might also be able to keep sprite index in register if data small enough...

	.return
	LDX fx_logowibble_index
	INX
	CPX #LOGOWIBBLE_table_size
	BCC no_index_wrap
	TXA
	SBC #LOGOWIBBLE_table_size
	TAX
	.no_index_wrap
;	AND #(LOGOWIBBLE_table_size-1)
	STX fx_logowibble_index

	RTS
}

\ ******************************************************************
\ *	Look up tables
\ ******************************************************************

.fx_logowibble_table
FOR n, 0, 63, 1
EQUB 80
NEXT
FOR n, 0, 63, 1
EQUB 80 + 15.9 * SIN(2 * PI * n / 64)
NEXT
FOR n, 0, 31, 1
EQUB 80
NEXT
FOR n, 0, 63, 1
EQUB 80 + 30.9 * SIN(2 * PI * n / 64)
NEXT

;FOR n, 0, LOGOWIBBLE_table_size-1, 1
;EQUB 80 + 3.9 * SIN(2 * PI * n / LOGOWIBBLE_table_size)
;NEXT

.fx_logowibble_sprite_table_LO
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)

.fx_logowibble_sprite_table_HI
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)

.fx_logowibble_y_mult_table_LO
FOR n, 0, LOGOWIBBLE_sixel_height-1, 1
EQUB LO((n DIV 3) * LOGOWIBBLE_char_width)
NEXT

.fx_logowibble_y_mult_table_HI
FOR n, 0, LOGOWIBBLE_sixel_height-1, 1
EQUB HI((n DIV 3) * LOGOWIBBLE_char_width)
NEXT

.fx_logowibble_row_mask
EQUB 3, 3, 12, 12, 80, 80

\ ******************************************************************
\ *	Sprite data
\ ******************************************************************

\\ Input file 'logo.png'
\\ Image size=60x18 pixels=60x18
.logo
\\ Data in ROW order
.logo_data
.logo_data_00	; x_offset=0, y_offset=0
;INCBIN "data/pages/logo_left.txt.bin"
INCBIN "data/pages/bslogo_white_left.txt.bin"			; actually just 5x rows

.logo_data_10	; x_offset=1, y_offset=0
;INCBIN "data/pages/logo_right.txt.bin"
INCBIN "data/pages/bslogo_white_right.txt.bin"			; actually just 5x rows
.end_fx_logowibble
