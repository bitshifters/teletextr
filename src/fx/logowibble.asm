
; wibbling logo
; using sprite data from mode7-sprites cracktro wip

.start_fx_logowibble

LOGOWIBBLE_shadow_addr = &7800

LOGOWIBBLE_char_width = 30
LOGOWIBBLE_char_height = 6
LOGOWIBBLE_sixel_height = (LOGOWIBBLE_char_height * 3)

LOGOWIBBLE_y_scr_addr = LOGOWIBBLE_shadow_addr + (4 * MODE7_char_width)
LOGOWIBBLE_table_size = 64

\ ******************************************************************
\ *	Logo Wibble FX
\ ******************************************************************

\\ Drawing complete sprite
\\ Each sixel line can have a separate X value
\\ For each sixel line
\\ Get x value
\\ Switch data block even/odd
\\ Start at x char, mask in all sprite data for that sixel line
\\ Need function to mask in 30 bytes starting at screen address for given sixel line
\\ Copy sprite plot routine and adapt it...

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

	TYA
	ASL A
	CLC
	ADC fx_logowibble_index
	AND #(LOGOWIBBLE_table_size-1)
	TAX

	LDA fx_logowibble_table, X			; X value for this sixel row
	STA fx_logowibble_x_pos + 1
	AND #&1
	ORA mode7_sprites_mod3_table, Y		; gives us 0-5 offset
	TAX

	\\ Sprite address = logo_data_XY + char_row

	CLC
	LDA fx_logowibble_sprite_table_LO, X
	ADC fx_logowibble_y_mult_table, Y
	STA fx_logowibble_data_addr + 1

	LDA fx_logowibble_sprite_table_HI, X
	ADC #0
	STA fx_logowibble_data_addr + 2

	\\ X char position on screen
	.fx_logowibble_x_pos
	LDA #0
	LSR A
	TAX

	\\ Save sixel row index
	STY fx_logowibble_y_row+1
	LDY #0

	.fx_logowibble_plot_loop

	.fx_logowibble_load_addr
	LDA &7800, X

	\\ Could mask out bits here to avoid having 6x copies of the sprite data

	.fx_logowibble_data_addr
	ORA &2000, Y

	.fx_logowibble_write_addr
	STA &7800, X

	\\ Next char
	INX
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
	BNE sixel_row_loop

	.return
	LDX fx_logowibble_index
	INX
	AND #(LOGOWIBBLE_table_size-1)
	STX fx_logowibble_index

	RTS
}

\ ******************************************************************
\ *	Look up tables
\ ******************************************************************

.fx_logowibble_table
FOR n, 0, LOGOWIBBLE_table_size-1, 1
EQUB 10 + 4 * SIN(2 * PI * n / LOGOWIBBLE_table_size)
NEXT

.fx_logowibble_sprite_table_LO
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)
EQUB LO(logo_data_01)
EQUB LO(logo_data_11)
EQUB LO(logo_data_02)
EQUB LO(logo_data_12)

.fx_logowibble_sprite_table_HI
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)
EQUB HI(logo_data_01)
EQUB HI(logo_data_11)
EQUB HI(logo_data_02)
EQUB HI(logo_data_12)

.fx_logowibble_y_mult_table
FOR n, 0, LOGOWIBBLE_sixel_height-1, 1
EQUB (n DIV 3) * LOGOWIBBLE_char_width
NEXT

\ ******************************************************************
\ *	Sprite data
\ ******************************************************************

\\ Input file 'logo.png'
\\ Image size=60x18 pixels=60x18
.logo
\\ Data in ROW order
EQUB 60, 6	;pixel width, char height
.logo_data
.logo_data_00	; x_offset=0, y_row=0
EQUB 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1
EQUB 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
EQUB 1,1,2,0,2,0,0,1,0,0,0,2,0,0,0,0,1,2,0,0,0,0,0,0,0,0,0,0,1,1
EQUB 1,1,2,0,2,2,0,1,0,3,1,2,0,1,2,0,1,2,0,2,3,1,2,0,2,3,0,0,1,1
EQUB 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1
EQUB 1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,1
.logo_data_10	; x_offset=1, y_row=0
EQUB 2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
EQUB 2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2
EQUB 2,2,0,1,0,1,0,2,0,0,0,0,1,0,0,0,2,0,1,0,0,0,0,0,0,0,0,0,2,2
EQUB 2,2,0,1,0,1,1,2,0,2,3,0,1,2,0,1,2,0,1,0,3,3,0,1,0,3,1,0,2,2
EQUB 2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2
EQUB 2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2
.logo_data_01	; x_offset=0, y_row=1
EQUB 4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4
EQUB 4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,4
EQUB 4,4,8,0,8,8,8,12,4,12,4,8,12,4,8,8,12,12,12,8,12,4,8,12,8,12,0,0,4,4
EQUB 4,4,8,0,8,8,0,4,0,0,12,8,0,4,8,0,4,8,0,8,0,0,8,0,0,8,4,0,4,4
EQUB 4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,4
EQUB 4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4
.logo_data_11	; x_offset=1, y_row=1
EQUB 8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8
EQUB 8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8
EQUB 8,8,0,4,0,4,4,12,12,8,12,0,12,12,0,4,12,12,12,4,12,12,0,12,4,12,4,0,8,8
EQUB 8,8,0,4,0,4,4,8,0,0,8,4,4,8,0,4,8,0,4,0,4,0,0,4,0,0,12,0,8,8
EQUB 8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8
EQUB 8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8
.logo_data_02	; x_offset=0, y_row=2
EQUB 16,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,16,16
EQUB 16,16,64,80,16,64,0,0,0,0,0,64,0,0,64,0,80,0,0,0,0,0,0,0,0,0,0,0,16,16
EQUB 16,16,64,80,16,64,0,16,0,16,0,64,0,16,64,0,16,64,0,64,0,16,64,0,64,0,0,0,16,16
EQUB 16,16,64,80,16,64,0,64,80,80,16,64,0,16,64,0,16,64,80,64,80,16,64,0,80,80,0,0,16,16
EQUB 16,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16,16
EQUB 80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,16
.logo_data_12	; x_offset=1, y_row=2
EQUB 64,64,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,64
EQUB 64,64,0,80,80,0,16,0,0,0,0,0,16,0,0,16,64,16,0,0,0,0,0,0,0,0,0,0,64,64
EQUB 64,64,0,80,80,0,16,64,0,64,0,0,16,64,0,16,64,0,16,0,16,64,0,16,0,16,0,0,64,64
EQUB 64,64,0,80,80,0,16,0,80,80,80,0,16,64,0,16,64,0,80,16,80,80,0,16,64,80,16,0,64,64
EQUB 64,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,64,64
EQUB 64,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80

.end_fx_logowibble
