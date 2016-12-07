
; extremely dodgy raster bars
; copied from Kieran's mode7-sprites cracktro wip
; uses way too much memory for the quality of the effect!

MODE7_particles_addr = &7800

PARTICLES_max = 256


.fx_particles_init
{
	LDA #0
	LDX #0

	.loop
	STA fx_particles_state, X
	STA fx_particles_xpos, X
	STA fx_particles_ypos, X
	STA fx_particles_xvel, X
	STA fx_particles_yvel, X

	INX
	CPX #LO(PARTICLES_max)
	BNE loop

	\\ Gravity
	LDA #2
	STA fx_particles_yacc

	.return
	RTS
}

.fx_particles_bang
{
	LDY #0
	LDX #0

	.loop
	LDA fx_particles_state, X
	BNE next

	LDA #1
	STA fx_particles_state, X

	LDA #40*2
	STA fx_particles_xpos, X
	LDA #25*2
	STA fx_particles_ypos, X

	TXA
	SEC
	SBC #16
	STA fx_particles_xvel, X

	TXA
	SEC
	SBC #16
	STA fx_particles_yvel, X

	INY
	CPY #32
	BCS return

	.next
	INX
	CPX #LO(PARTICLES_max)
	BNE loop

	.return
	RTS
}

.fx_particles_spin_idx
EQUB 0

.fx_particles_spin
{
	LDY fx_particles_spin_idx
	LDX #0
	.loop
	LDA fx_particles_state,X
	BNE next

	\\ Found a free one!
	LDA #1
	STA fx_particles_state,X

	LDA #40*2
	STA fx_particles_xpos, X
	LDA #25*2
	STA fx_particles_ypos, X

	LDA fx_particles_table,Y
	STA fx_particles_xvel, X

	LDA fx_particles_table_cos,Y
	STA fx_particles_yvel, X

	JMP return

	.next
	INX
	CPX #LO(PARTICLES_max)
	BNE loop

	.return

	INC fx_particles_spin_idx

	RTS
}

.fx_particles_update
{
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast

;	LDA #121
;	LDX #0
;	JSR osbyte
;	CPX #81
;	BNE not_s
;	JSR fx_particles_bang
;	.not_s

	JSR fx_particles_spin

	JSR fx_particles_tick
	JSR fx_particles_draw

	.return
	RTS
}

.fx_particles_xacc
EQUB 0

.fx_particles_yacc
EQUB 0

.fx_particles_tick
{
	LDX #0

	.loop
	LDA fx_particles_state, X
	BEQ next

	CLC
	LDA fx_particles_xvel, X
	ADC fx_particles_xacc
	STA fx_particles_xvel, X

	CLC
	LDA fx_particles_yvel, X
	ADC fx_particles_yacc
	STA fx_particles_yvel, X

	CLC
	LDA fx_particles_xpos, X
	ADC fx_particles_xvel, X
	STA fx_particles_xpos, X

	CLC
	LDA fx_particles_ypos, X
	ADC fx_particles_yvel, X
	STA fx_particles_ypos, X
	
	\\ Need to determine state update conditions
	CMP #75*2
	BCC next

	LDA #0
	STA fx_particles_state, X

	.next
	INX
	CPX #LO(PARTICLES_max)
	BNE loop

	.return
	RTS
}

.fx_particles_draw_idx
EQUB 0

.fx_particles_draw
{
	LDX #0

	.loop
	STX fx_particles_draw_idx

	LDA fx_particles_ypos, X
	LSR A:TAY
	LDA fx_particles_xpos, X
	LSR A:TAX

	{
		PLOT_PIXEL_CLIPPED
	}

	LDX fx_particles_draw_idx
	INX
	CPX #LO(PARTICLES_max)
	BNE loop

	.return
	RTS
}



\\ How much precision do we need?
\\ Run everything *2 to give small bit of extra precision?

.fx_particles_state
SKIP PARTICLES_max

.fx_particles_xpos
SKIP PARTICLES_max

.fx_particles_ypos
SKIP PARTICLES_max

.fx_particles_xvel
SKIP PARTICLES_max

.fx_particles_yvel
SKIP PARTICLES_max

.fx_particles_table
FOR n,0,&13F,1
EQUB 8 * SIN(2 * PI * n / 255)
NEXT

fx_particles_table_cos = fx_particles_table + 64
