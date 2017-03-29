
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

LOGOANIM_shadow_addr = &7800

LOGOANIM_draw_addr = LOGOANIM_shadow_addr + 10 * MODE7_char_width
LOGOANIM_logo_rows = 5
LOGOANIM_logo_size = LOGOANIM_logo_rows * MODE7_char_width
LOGOANIM_draw_end = LOGOANIM_draw_addr + LOGOANIM_logo_size

.fx_logoanim_ypos
EQUB 30, 25, 20, 15, 10, 15, 20, 25, 30

.fx_logoanim_dir
EQUB -1, -1, -1, -1, -1, -1, -1, -1, -1


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
	FOR n, 0, 24, 1
	STA LOGOANIM_shadow_addr+n*40+39
	NEXT

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

	CMP #30					; max
	BCC ok

	CLC
	LDA fx_logoanim_dir, X
	EOR #&FF
	ADC #1
	STA fx_logoanim_dir, X

	LDA #30
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
	CPX #9
	BNE loop

	\\ Update our screen
	JSR fx_logoanim_draw

	.return
	RTS
}

\\ Something like set writeptr to top of column before entry
\\ Draw Y rows of blocks and 10-Y rows of bytes A&X
.fx_logoanim_draw_col_top
{
	STA first_byte+1
	STX second_byte+1
	STX second_solid+1

	STY solid_loop+1

	LDX #0
	LDY #0

	.solid_loop
	CPX #0
	BCS done_solid_loop
	LDA #&7F
	STA (writeptr), Y
	.second_solid
	LDA #&0
	BEQ skip_solid
	ORA #&7F
	INY
	STA (writeptr), Y
	DEY
	.skip_solid
	INX

	CLC
	LDA writeptr
	ADC #MODE7_char_width
	STA writeptr
	BCC solid_loop
	INC writeptr+1
	BNE solid_loop
	.done_solid_loop

	.byte_loop
	CPX #10
	BCS done_byte_loop

	.first_byte
	LDA #&7F
	STA (writeptr), Y
	.second_byte
	LDA #&7F
	BEQ skip_write
	INY
	STA (writeptr), Y
	DEY
	.skip_write

	INX

	CLC
	LDA writeptr
	ADC #MODE7_char_width
	STA writeptr
	BCC byte_loop
	INC writeptr+1
	BNE byte_loop
	.done_byte_loop

	RTS
}

.fx_logoanim_draw_col_bot
{
	STA first_byte+1
	STX second_byte+1
	STX second_solid+1

	STY solid_loop+1

	LDX #0
	LDY #0

	.solid_loop
	CPX #0
	BCS done_solid_loop
	LDA #&7F
	STA (writeptr), Y
	.second_solid
	LDA #&0
	BEQ skip_solid
	ORA #&7F
	INY
	STA (writeptr), Y
	DEY
	.skip_solid
	INX

	SEC
	LDA writeptr
	SBC #MODE7_char_width
	STA writeptr
	BCS solid_loop
	DEC writeptr+1
	BNE solid_loop
	.done_solid_loop

	.byte_loop
	CPX #10
	BCS done_byte_loop

	.first_byte
	LDA #&7F
	STA (writeptr), Y
	.second_byte
	LDA #&7F
	BEQ skip_write
	INY
	STA (writeptr), Y
	DEY
	.skip_write

	INX

	SEC
	LDA writeptr
	SBC #MODE7_char_width
	STA writeptr
	BCS byte_loop
	DEC writeptr+1
	BNE byte_loop
	.done_byte_loop

	RTS
}


.fx_logoanim_draw
{
	\\ First four go up
	\\ For each x pos, draw (y pos/3) of chars and the rest as blocks
	\\ Worry about masking to get sixel animation later

	LDA #LO(LOGOANIM_shadow_addr + 2)
	STA writeptr
	LDA #HI(LOGOANIM_shadow_addr + 2)
	STA writeptr+1

	LDX fx_logoanim_ypos + 0
	LDY mode7_sprites_div3_table, X

	LDA #&20
	LDX #&6A
	JSR fx_logoanim_draw_col_top

	LDA #LO(LOGOANIM_shadow_addr + 8)
	STA writeptr
	LDA #HI(LOGOANIM_shadow_addr + 8)
	STA writeptr+1

	LDX fx_logoanim_ypos + 1
	LDY mode7_sprites_div3_table, X

	LDA #&20
	LDX #&6A
	JSR fx_logoanim_draw_col_top

	LDA #LO(LOGOANIM_shadow_addr + 14)
	STA writeptr
	LDA #HI(LOGOANIM_shadow_addr + 14)
	STA writeptr+1

	LDX fx_logoanim_ypos + 2
	LDY mode7_sprites_div3_table, X

	LDA #&35
	LDX #&20
	JSR fx_logoanim_draw_col_top

	LDA #LO(LOGOANIM_shadow_addr + 24)
	STA writeptr
	LDA #HI(LOGOANIM_shadow_addr + 24)
	STA writeptr+1

	LDX fx_logoanim_ypos + 3
	LDY mode7_sprites_div3_table, X

	LDA #&35
	LDX #&20
	JSR fx_logoanim_draw_col_top

	LDA #LO(LOGOANIM_shadow_addr + 5 + 24 * MODE7_char_width)
	STA writeptr
	LDA #HI(LOGOANIM_shadow_addr + 5 + 24 * MODE7_char_width)
	STA writeptr+1

	LDX fx_logoanim_ypos + 4
	LDY mode7_sprites_div3_table, X

	LDA #&35
	LDX #&20
	JSR fx_logoanim_draw_col_bot

	LDA #LO(LOGOANIM_shadow_addr + 17 + 24 * MODE7_char_width)
	STA writeptr
	LDA #HI(LOGOANIM_shadow_addr + 17 + 24 * MODE7_char_width)
	STA writeptr+1

	LDX fx_logoanim_ypos + 5
	LDY mode7_sprites_div3_table, X

	LDA #&6A
	LDX #&00
	JSR fx_logoanim_draw_col_bot

	LDA #LO(LOGOANIM_shadow_addr + 18 + 24 * MODE7_char_width)
	STA writeptr
	LDA #HI(LOGOANIM_shadow_addr + 18 + 24 * MODE7_char_width)
	STA writeptr+1

	LDX fx_logoanim_ypos + 6
	LDY mode7_sprites_div3_table, X

	LDA #&20
	LDX #&6A
	JSR fx_logoanim_draw_col_bot

	LDA #LO(LOGOANIM_shadow_addr + 20 + 24 * MODE7_char_width)
	STA writeptr
	LDA #HI(LOGOANIM_shadow_addr + 20 + 24 * MODE7_char_width)
	STA writeptr+1

	LDX fx_logoanim_ypos + 7
	LDY mode7_sprites_div3_table, X

	LDA #&35
	LDX #&20
	JSR fx_logoanim_draw_col_bot

	LDA #LO(LOGOANIM_shadow_addr + 31 + 24 * MODE7_char_width)
	STA writeptr
	LDA #HI(LOGOANIM_shadow_addr + 31 + 24 * MODE7_char_width)
	STA writeptr+1

	LDX fx_logoanim_ypos + 8
	LDY mode7_sprites_div3_table, X

	LDA #&20
	LDX #&6A
	JSR fx_logoanim_draw_col_bot

	.return
	RTS
}

\ ******************************************************************
\ *	Look up tables
\ ******************************************************************


\ ******************************************************************
\ *	Sprite data
\ ******************************************************************

.fx_logoanim_data
INCBIN "data/pages/bslogo.txt.bin"			; actually just 5x rows

.end_fx_logoanim
