
; animated logo
; using b&w bitshifters frame by @horsenburger for Bad Apple

\\ Letter positions (columns)
\\ b [2-4]
\\ i [5-6]
\\ t [7-10]
\\ s [11-13]
\\ h [14-17]
\\ i [18-19]
\\ f [20-22]
\\ t [23-26]
\\ e [27-30]
\\ r [31-33]
\\ s [34-36]

\\ Ascender/descender positions (columns)
\\ b [2-3] up - 0x20, 0x6a
\\ t [8-9] up - 0x20, 0x6a
\\ h [14-15] up - 0x35, 0x20
\\ t [24-25] up - 0x35, 0x20

\\ i [5-6] down - 0x35, 0x20
\\ h [17] down - 0x6a, 0x00
\\ i [18-19] down - 0x20, 0x6a
\\ f [20-21] down - 0x35, 0x20
\\ r [31-32] down - 0x20, 0x6a

\\ Main logo is 5x rows, so centred at (0,10) with 10 rows above & below
\\ Ideally want to be able to set each ascender/descender to 0-30 sixels independently
\\ So can animate over time.  Could also animate the logo

.start_fx_logoanim

LOGOANIM_shadow_addr = MODE7_VRAM_SHADOW

LOGOANIM_draw_addr = LOGOANIM_shadow_addr + 10 * MODE7_char_width
LOGOANIM_logo_rows = 5
LOGOANIM_logo_size = LOGOANIM_logo_rows * MODE7_char_width
LOGOANIM_draw_end = LOGOANIM_draw_addr + LOGOANIM_logo_size

LOGOANIM_num_columns = 9
LOGOANIM_num_sixel_rows = 30
LOGOANIM_num_char_rows = 10

MODE7_solid_block = &7F

\ ******************************************************************
\ *	Runtime vars
\ ******************************************************************

.fx_logoanim_ypos
EQUB 30, 25, 20, 15, 10, 15, 20, 25, 30

.fx_logoanim_dir
EQUB -1, -1, -1, -1, -1, -1, -1, -1, -1

.fx_logoanim_first_byte		EQUB 0
.fx_logoanim_second_byte   	EQUB 0
.fx_logoanim_num_rows   	EQUB 0
.fx_logoanim_sixel_mask   	EQUB 0
.fx_logoanim_row_step		EQUW 0


\ ******************************************************************
\ *	Code
\ ******************************************************************

.fx_logoanim_init
{
	\\ Clear screen to solid blocks
	LDA #&7F
	JSR mode7_clear_shadow_fast

	\\ Set graphics white
	lda #144+7
	JSR mode7_set_graphics_shadow_fast

	\\ Copy logo in place
	LDX #LOGOANIM_logo_size-1
	.loop
	LDA fx_logoanim_data, X
	STA LOGOANIM_draw_addr, X
	DEX
	BNE loop
	LDA fx_logoanim_data, X
	STA LOGOANIM_draw_addr, X

	\\ Annoyingly blank right edge for symmetry
	LDA #32
	LDX #39
	JSR mode7_set_column_shadow_fast

	.return
	RTS
}

.fx_logoanim_update
{
	\\ Update our y positions (could be more interesting than this)
	LDX #0
	.loop
	CLC
	LDA fx_logoanim_ypos, X
	ADC fx_logoanim_dir, X

	BMI clip_low

	; clip hi

	CMP #LOGOANIM_num_sixel_rows				; max
	BCC ok

	CLC
	LDA fx_logoanim_dir, X
	EOR #&FF
	ADC #1
	STA fx_logoanim_dir, X

	LDA #LOGOANIM_num_sixel_rows
	BNE ok

	.clip_low
	CLC
	LDA fx_logoanim_dir, X
	EOR #&FF
	ADC #1
	STA fx_logoanim_dir, X

	LDA #0

	.ok
	STA fx_logoanim_ypos, X

	INX
	CPX #LOGOANIM_num_columns
	BNE loop

	\\ Update our screen
	JSR fx_logoanim_draw

	.return
	RTS
}

.fx_logoanim_draw
{
	\\ Top columns drawn top down
	LDA #LO(MODE7_char_width)
	STA fx_logoanim_row_step
	LDA #HI(MODE7_char_width)
	STA fx_logoanim_row_step+1
	
	\\ First 4 are top
	LDX #0
	.top_loop

	LDA fx_logoanim_addr_LO, X
	STA writeptr
	LDA fx_logoanim_addr_HI, X
	STA writeptr+1

	LDA fx_logoanim_first_bytes, X
	STA fx_logoanim_first_byte

	LDA fx_logoanim_second_bytes, X
	STA fx_logoanim_second_byte
	
	LDY fx_logoanim_ypos, X
	LDA mode7_sprites_div3_table, Y
	STA fx_logoanim_num_rows

	LDA mode7_sprites_mod3_table, Y
	LSR A:TAY							; this table is shifted
	LDA fx_logoanim_sixel_mask_top, Y	; need to switch this
	STA fx_logoanim_sixel_mask

	STX top_loop_index+1
	JSR fx_logoanim_draw_col
	.top_loop_index
	LDX #0
	INX
	CPX #4
	BCC top_loop

	\\ Bottom columns drawn bottom up
	LDA #LO(0-MODE7_char_width)
	STA fx_logoanim_row_step
	LDA #HI(0-MODE7_char_width)
	STA fx_logoanim_row_step+1
	
	\\ Last 5 are bottom
	.bottom_loop

	LDA fx_logoanim_addr_LO, X
	STA writeptr
	LDA fx_logoanim_addr_HI, X
	STA writeptr+1

	LDA fx_logoanim_first_bytes, X
	STA fx_logoanim_first_byte

	LDA fx_logoanim_second_bytes, X
	STA fx_logoanim_second_byte
	
	LDY fx_logoanim_ypos, X
	LDA mode7_sprites_div3_table, Y
	STA fx_logoanim_num_rows

	LDA mode7_sprites_mod3_table, Y
	LSR A:TAY							; this table is shifted
	LDA fx_logoanim_sixel_mask_bot, Y	; need to switch this
	STA fx_logoanim_sixel_mask

	STX bot_loop_index+1
	JSR fx_logoanim_draw_col
	.bot_loop_index
	LDX #0
	INX
	CPX #LOGOANIM_num_columns
	BCC bottom_loop

	.return
	RTS
}

.fx_logoanim_draw_col
{
	LDX #0
	LDY #0

	\\ Draw N solid blocks
	.solid_loop
	CPX fx_logoanim_num_rows
	BCS done_solid_loop
	LDA #MODE7_solid_block
	STA (writeptr), Y

	LDA fx_logoanim_second_byte
	BEQ skip_solid
	ORA #MODE7_solid_block
	INY
	STA (writeptr), Y
	DEY
	.skip_solid
	INX

	\\ Next character row
	CLC
	LDA writeptr
	ADC fx_logoanim_row_step
	STA writeptr
	LDA writeptr+1
	ADC fx_logoanim_row_step+1
	STA writeptr+1
	BNE solid_loop
	.done_solid_loop

	\\ Middle bit!
	CPX #LOGOANIM_num_char_rows
	BCS done_middle_bit

	LDA fx_logoanim_sixel_mask
	BEQ done_middle_bit			; no sixel mask needed

	\\ Mask draw byte against sixel mask for row
	ORA fx_logoanim_first_byte
	STA (writeptr), Y
	
	\\ Is there a second byte?
	LDA fx_logoanim_second_byte
	BEQ skip_middle

	\\ Mask this as well
	ORA fx_logoanim_sixel_mask
	INY
	STA (writeptr), Y
	DEY
	.skip_middle
	INX

	\\ Next character row
	CLC
	LDA writeptr
	ADC fx_logoanim_row_step
	STA writeptr
	LDA writeptr+1
	ADC fx_logoanim_row_step+1
	STA writeptr+1
	.done_middle_bit

	\\ Draw 10-N bytes
	.byte_loop
	CPX #LOGOANIM_num_char_rows
	BCS done_byte_loop

	LDA fx_logoanim_first_byte
	STA (writeptr), Y

	LDA fx_logoanim_second_byte
	BEQ skip_write
	INY
	STA (writeptr), Y
	DEY
	.skip_write

	INX

	\\ Next character row
	CLC
	LDA writeptr
	ADC fx_logoanim_row_step
	STA writeptr
	LDA writeptr+1
	ADC fx_logoanim_row_step+1
	STA writeptr+1
	BNE byte_loop
	.done_byte_loop

	.return
	RTS
}


\ ******************************************************************
\ *	Look up tables
\ ******************************************************************

.fx_logoanim_sixel_mask_top
EQUB &0, 1+2, 1+2+4+8

.fx_logoanim_sixel_mask_bot
EQUB &0, 16+64, 16+64+4+8

.fx_logoanim_addr_LO
EQUB LO(LOGOANIM_shadow_addr + 2)
EQUB LO(LOGOANIM_shadow_addr + 8)
EQUB LO(LOGOANIM_shadow_addr + 14)
EQUB LO(LOGOANIM_shadow_addr + 24)
EQUB LO(LOGOANIM_shadow_addr + 5 + 24 * MODE7_char_width)
EQUB LO(LOGOANIM_shadow_addr + 17 + 24 * MODE7_char_width)
EQUB LO(LOGOANIM_shadow_addr + 18 + 24 * MODE7_char_width)
EQUB LO(LOGOANIM_shadow_addr + 20 + 24 * MODE7_char_width)
EQUB LO(LOGOANIM_shadow_addr + 31 + 24 * MODE7_char_width)

.fx_logoanim_addr_HI
EQUB HI(LOGOANIM_shadow_addr + 2)
EQUB HI(LOGOANIM_shadow_addr + 8)
EQUB HI(LOGOANIM_shadow_addr + 14)
EQUB HI(LOGOANIM_shadow_addr + 24)
EQUB HI(LOGOANIM_shadow_addr + 5 + 24 * MODE7_char_width)
EQUB HI(LOGOANIM_shadow_addr + 17 + 24 * MODE7_char_width)
EQUB HI(LOGOANIM_shadow_addr + 18 + 24 * MODE7_char_width)
EQUB HI(LOGOANIM_shadow_addr + 20 + 24 * MODE7_char_width)
EQUB HI(LOGOANIM_shadow_addr + 31 + 24 * MODE7_char_width)

.fx_logoanim_first_bytes
EQUB &20, &20, &35, &35, &35, &6A, &20, &35, &20

.fx_logoanim_second_bytes
EQUB &6A, &6A, &20, &20, &20, &00, &6A, &20, &6A


\ ******************************************************************
\ *	Sprite data
\ ******************************************************************

.fx_logoanim_data
INCBIN "data/pages/bslogo/bslogo.txt.bin"			; actually just 5x rows

.end_fx_logoanim
