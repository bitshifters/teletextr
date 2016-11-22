
; quick & dirty mirrored floor effect
; copied from Kieran's mode7-sprites cracktro wip
; hardcoded to only take top row of pixels from a row

INTERFERENCE_shadow_addr = &7800 + 4
INTERFERENCE_slot_no = 2

\ ******************************************************************
\ *	Mirror FX
\ ******************************************************************

.fx_interference_table_LO
{
	EQUB LO(circles_data_00)
	EQUB LO(circles_data_10)
	EQUB LO(circles_data_01)
	EQUB LO(circles_data_11)
	EQUB LO(circles_data_02)
	EQUB LO(circles_data_12)
}

.fx_interference_table_HI
{
	EQUB HI(circles_data_00)
	EQUB HI(circles_data_10)
	EQUB HI(circles_data_01)
	EQUB HI(circles_data_11)
	EQUB HI(circles_data_02)
	EQUB HI(circles_data_11)
}

.fx_interference_plot_x
EQUB 0

.fx_interference_plot_y
EQUB 0

.fx_interference_char_x
EQUB 0

.fx_interference_char_y
EQUB 0

.fx_interference_set_ptrs
{
	\\ X coordinate to char
	STX fx_interference_plot_x			; 4c
	TXA									; 2c
	AND #&1
	CLC
	ADC fx_interference_plot_x			; char x = (x + (x&1)) DIV 2 as effectively negative
	LSR A								; 2c

	\\ Y coordinate to char
	STY fx_interference_plot_y

	\\ X,Y are effectively negative so:
	\\ 0->0,0  1->1,2  2->1,1  3->1,0  4->2,2  5->2,1  6->3,0

	INY:INY
	LDX mode7_sprites_div3_table, Y		; 4c

	\\ A still contains fx_interference_char_x

	\\ Calculate internal sprite address
	CLC									; 2c
	ADC fx_interference_mult_LO, X		; 4c
	STA readptr
	LDA fx_interference_mult_HI, X		; 4c
	ADC #0
	STA readptr+1

	\\ Where are we reading data from?

	\\ Calculate offset 0 - 5
	.mode7_sprites_plot_x
	LDY fx_interference_plot_y
	SEC
	LDA #3
	SBC mode7_sprites_mod3_table, Y		; 4c
	CMP #3
	BCC y_offset_ok
	LDA #0								; y_offset actually (3 - (y MOD 3))
	.y_offset_ok
	TAY

	LDA fx_interference_plot_x			; 2c
	AND #&1								; 2c x_offset
	ORA mode7_sprites_mod3_table, Y		; 4c y_offset

	\\ Multiply by our offset to locate sprite data
	TAX									; 2c
	CLC
	LDA readptr
	ADC fx_interference_table_LO, X						; 4c
	STA readptr
	LDA readptr+1
	ADC fx_interference_table_HI, X						; 4c
	STA readptr+1

	LDA #LO(INTERFERENCE_shadow_addr)
	STA writeptr
	LDA #HI(INTERFERENCE_shadow_addr)
	STA writeptr+1

	.return
	RTS
}

.fx_interference_draw_screen
{
	JSR fx_interference_set_ptrs

	LDX #0
	.y_loop

	LDY #0
	.x_loop
	LDA (readptr), Y
	STA (writeptr), Y
	INY
	CPY #36
	BNE x_loop

	CLC
	LDA readptr
	ADC #54
	STA readptr
	LDA readptr+1
	ADC #0
	STA readptr+1

	CLC
	LDA writeptr
	ADC #40
	STA writeptr
	LDA writeptr+1
	ADC #0
	STA writeptr+1

	INX
	CPX #22
	BNE y_loop

	.return
	RTS
}

.fx_interference_eor_screen
{
	JSR fx_interference_set_ptrs

	LDX #0
	.y_loop

	LDY #0
	.x_loop
	LDA (readptr), Y
	EOR (writeptr), Y
	ORA #32
	STA (writeptr), Y
	INY
	CPY #36
	BNE x_loop

	CLC
	LDA readptr
	ADC #54
	STA readptr
	LDA readptr+1
	ADC #0
	STA readptr+1

	CLC
	LDA writeptr
	ADC #40
	STA writeptr
	LDA writeptr+1
	ADC #0
	STA writeptr+1

	INX
	CPX #22
	BNE y_loop

	.return
	RTS
}

.fx_interference_ora_screen
{
	JSR fx_interference_set_ptrs

	LDX #0
	.y_loop

	LDY #0
	.x_loop
	LDA (readptr), Y
	ORA (writeptr), Y
	STA (writeptr), Y
	INY
	CPY #36
	BNE x_loop

	CLC
	LDA readptr
	ADC #54
	STA readptr
	LDA readptr+1
	ADC #0
	STA readptr+1

	CLC
	LDA writeptr
	ADC #40
	STA writeptr
	LDA writeptr+1
	ADC #0
	STA writeptr+1

	INX
	CPX #22
	BNE y_loop

	.return
	RTS
}

.fx_interference_x
EQUB 0

.fx_interference_dx
EQUB 1

.fx_interference_y
EQUB 0

.fx_interference_dy
EQUB 1

.fx_interference_x_idx
EQUB 0

.fx_interference_sin_table_x
FOR n, 0, 63, 1
EQUB 18 + 17 * SIN(2 * PI * n / 64)
NEXT

.fx_interference_update
{
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast

	\\ Select RAM bank with data
    sei
    lda &f4
    PHA

    lda #INTERFERENCE_slot_no
    jsr swr_select_slot
    cli

	LDX fx_interference_x
	LDY fx_interference_y
	JSR fx_interference_draw_screen

	LDY fx_interference_x_idx
	LDX fx_interference_sin_table_x, Y
	LDY #16
	JSR fx_interference_eor_screen

    ; restore previously paged ROM bank
    sei
    PLA
    jsr swr_select_bank
	cli

	CLC
	lda fx_interference_x
	ADC fx_interference_dx
	BMI x_hit_left

	CMP #36
	BCC x_ok
	
	\\ X hit right
	LDA #&FF
	STA fx_interference_dx
	LDA #36
	JMP x_ok

	.x_hit_left
	LDA #1
	STA fx_interference_dx
	LDA #0

	.x_ok
	STA fx_interference_x

	CLC
	lda fx_interference_y
	ADC fx_interference_dy
	BMI y_hit_top

	CMP #33
	BCC y_ok
	
	\\ Y hit bottom
	LDA #&FF
	STA fx_interference_dy
	LDA #33
	JMP y_ok

	.y_hit_top
	LDA #1
	STA fx_interference_dy
	LDA #0

	.y_ok
	STA fx_interference_y

	CLC
	LDA fx_interference_x_idx
	ADC #&1
	AND #63
	STA fx_interference_x_idx

	.return
	RTS
}

.fx_interference_mult_LO
FOR n, 0, 24, 1
EQUB LO(54 * n)				; sprite width
NEXT

.fx_interference_mult_HI
FOR n, 0, 24, 1
EQUB HI(54 * n)				; sprite width
NEXT
