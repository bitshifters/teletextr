
; wibbling logo
; using sprite data from mode7-sprites cracktro wip

_LOGOWIBBLE_SPARSE_DATA = FALSE			; uses 3x as much space for data

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
	ASL A
	CLC
	ADC fx_logowibble_index
	AND #(LOGOWIBBLE_table_size-1)
	TAX

	\\ Get x position
	LDA fx_logowibble_table, X			; X value for this sixel row
	STA fx_logowibble_x_pos + 1
	AND #&1
	ORA mode7_sprites_mod3_table, Y		; gives us 0-5 offset
	TAX

	IF _LOGOWIBBLE_SPARSE_DATA = FALSE
	LDA fx_logowibble_row_mask, X
	STA fx_logowibble_data_mask + 1
	ENDIF

	\\ Sprite address = logo_data_XY + char_row
	\\ There's probably a quicker way to do this by toggling sprite data index depending on X parity
	CLC
	LDA fx_logowibble_sprite_table_LO, X
	ADC fx_logowibble_y_mult_table, Y
	STA fx_logowibble_data_addr + 1

	LDA fx_logowibble_sprite_table_HI, X
	ADC #0
	STA fx_logowibble_data_addr + 2
	\\ Also don't need to calc sprite address each time if using dense data - to be optimised

	\\ X char position on screen
	.fx_logowibble_x_pos
	LDA #0
	LSR A
	TAX

	\\ Save sixel row index
	STY fx_logowibble_y_row+1
	LDY #0

	.fx_logowibble_plot_loop

	.fx_logowibble_data_addr
	LDA &2000, Y

	IF _LOGOWIBBLE_SPARSE_DATA = FALSE
	.fx_logowibble_data_mask
	AND #0
	ENDIF

	BEQ next_char

	.fx_logowibble_load_addr
	ORA &7800, X

	\\ Could mask out bits here to avoid having 6x copies of the sprite data

	.fx_logowibble_write_addr
	STA &7800, X

	\\ Next char
	.next_char
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

	\\ Could also move to next sprite data row if dense data
	\\ Might also be able to keep sprite index in register if data small enough...

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
EQUB 10 + 3.9 * SIN(2 * PI * n / LOGOWIBBLE_table_size)
NEXT

.fx_logowibble_sprite_table_LO
IF _LOGOWIBBLE_SPARSE_DATA
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)
EQUB LO(logo_data_01)
EQUB LO(logo_data_11)
EQUB LO(logo_data_02)
EQUB LO(logo_data_12)
ELSE
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)
ENDIF

.fx_logowibble_sprite_table_HI
IF _LOGOWIBBLE_SPARSE_DATA
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)
EQUB HI(logo_data_01)
EQUB HI(logo_data_11)
EQUB HI(logo_data_02)
EQUB HI(logo_data_12)
ELSE
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)
ENDIF

.fx_logowibble_y_mult_table
FOR n, 0, LOGOWIBBLE_sixel_height-1, 1
EQUB (n DIV 3) * LOGOWIBBLE_char_width
NEXT

IF _LOGOWIBBLE_SPARSE_DATA = FALSE
.fx_logowibble_row_mask
EQUB 3, 3, 12, 12, 80, 80
ENDIF

\ ******************************************************************
\ *	Sprite data
\ ******************************************************************

\\ Input file 'logo.png'
\\ Image size=60x18 pixels=60x18
.logo
\\ Data in ROW order
.logo_data
IF _LOGOWIBBLE_SPARSE_DATA
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
ELSE
.logo_data_00	; x_offset=0, y_offset=0
EQUB 55,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,51,53
EQUB 53,53,96,112,48,96,32,32,32,32,32,96,32,32,96,32,112,32,32,32,32,32,32,32,32,32,32,32,53,53
EQUB 53,53,106,112,58,104,40,61,36,60,36,106,44,52,104,40,61,110,44,104,44,52,104,44,104,44,32,32,53,53
EQUB 53,53,106,112,58,106,32,101,112,115,61,106,32,53,106,32,53,106,112,106,115,49,106,32,114,123,36,32,53,53
EQUB 53,53,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,53,53
EQUB 117,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,113,53
.logo_data_10	; x_offset=1, y_offset=0
EQUB 106,99,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,107
EQUB 106,106,32,112,112,32,48,32,32,32,32,32,48,32,32,48,96,48,32,32,32,32,32,32,32,32,32,32,106,106
EQUB 106,106,32,117,112,37,52,110,44,104,44,32,61,108,32,52,110,44,61,36,60,108,32,60,36,60,36,32,106,106
EQUB 106,106,32,117,112,37,53,42,112,114,123,36,53,106,32,53,106,32,117,48,119,115,32,53,96,115,61,32,106,106
EQUB 106,106,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,106,106
EQUB 106,114,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,115,122
ENDIF
.end_fx_logowibble
