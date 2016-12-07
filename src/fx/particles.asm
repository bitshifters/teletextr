
; extremely dodgy particle fx

MODE7_particles_addr = &7800

PARTICLES_max = 256
_PARTICLES_ENABLE_BANG = TRUE
_PARTICLES_ENABLE_SPIN = TRUE

.fx_particles_init
{
	LDA #0
	LDX #0

	.loop
	STA fx_particles_state, X
	STA fx_particles_xpos, X
	STA fx_particles_xposh, X
	STA fx_particles_ypos, X
	STA fx_particles_yposh, X
	STA fx_particles_xvel, X
	STA fx_particles_xvelh, X
	STA fx_particles_yvel, X
	STA fx_particles_yvelh, X

	INX
	CPX #LO(PARTICLES_max)
	BNE loop

	\\ Gravity
	STA fx_particles_xacc
	STA fx_particles_xacc+1
	STA fx_particles_yacc+1

	LDA #&0f
	STA fx_particles_yacc

	.return
	RTS
}

.fx_particles_get_next_free_X
{
	.loop
	LDA fx_particles_state, X
	CLC
	BEQ return
	INX
	CPX #LO(PARTICLES_max)
	BNE loop
	SEC
	.return
	RTS
}

.fx_particles_bang_idx
EQUB 0

.fx_particles_bang
{
	LDX #0
	LDY fx_particles_bang_idx

	.loop
	JSR fx_particles_get_next_free_X
	BCS return

	LDA #1
	STA fx_particles_state, X

	LDA #0
	STA fx_particles_xpos, X
	STA fx_particles_ypos, X

	LDA #20
	STA fx_particles_xposh, X
	LDA #15
	STA fx_particles_yposh, X

	JSR fx_particles_set_vel_Y

	INX

	TYA
	CLC
	ADC #16
	TAY
	CPY #0
	BNE loop

	.return
	INC fx_particles_bang_idx

	RTS
}

.fx_particles_set_vel_Y
{
	\\ Sign extend X&Y vel
	{
		LDA fx_particles_table, Y
		ORA #&7F
		BMI neg
		LDA #0
		.neg
		STA fx_particles_xvelh, X
	}

	{
		LDA fx_particles_table_cos, Y
		ORA #&7F
		BMI neg
		LDA #0
		.neg
		STA fx_particles_yvelh, X
	}

	\\ X vel * 4
	CLC
	LDA fx_particles_table, Y
;	ASL A
;	ROL fx_particles_xvelh, X
	ASL A
	ROL fx_particles_xvelh, X
	STA fx_particles_xvel, X

	\\ Y vel * 4
	CLC
	LDA fx_particles_table_cos, Y
;	ASL A
;	ROL fx_particles_yvelh, X
	ASL A
	ROL fx_particles_yvelh, X
	STA fx_particles_yvel, X

	RTS
}

.fx_particles_spin_idx
EQUB 0

.fx_particles_spin_Y
{
	JSR fx_particles_get_next_free_X
	BCS return

	\\ Found a free one!
	LDA #1
	STA fx_particles_state, X

	\\ Set X&Y pos
	LDA #0
	STA fx_particles_xpos, X
	STA fx_particles_ypos, X

	LDA #40
	STA fx_particles_xposh, X
	LDA #25
	STA fx_particles_yposh, X

	JSR fx_particles_set_vel_Y

	INY
	INX

	.return
	RTS
}

.fx_particles_update
{
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast

IF _PARTICLES_ENABLE_BANG
	LDA #121
	LDX #0
	JSR osbyte
	CPX #81
	BNE not_s
	JSR fx_particles_bang
	.not_s
ENDIF

IF _PARTICLES_ENABLE_SPIN
	LDX #0
	LDY fx_particles_spin_idx
	JSR fx_particles_spin_Y
	INY:INY
	STY fx_particles_spin_idx

	TYA:CLC:ADC #&40:TAY
	JSR fx_particles_spin_Y
	TYA:CLC:ADC #&40:TAY
	JSR fx_particles_spin_Y
	TYA:CLC:ADC #&40:TAY
	JSR fx_particles_spin_Y
ENDIF

	JSR fx_particles_tick
	JSR fx_particles_draw

	.return
	RTS
}

.fx_particles_xacc
EQUB 0
EQUB 0

.fx_particles_yacc
EQUB 0
EQUB 0

.fx_particles_tick
{
	LDX #0

	.loop
	LDA fx_particles_state, X
	BEQ next

	\\ Update velocities

	CLC
	LDA fx_particles_xvel, X
	ADC fx_particles_xacc
	STA fx_particles_xvel, X
	LDA fx_particles_xvelh, X
	ADC fx_particles_xacc+1
	STA fx_particles_xvelh, X

	CLC
	LDA fx_particles_yvel, X
	ADC fx_particles_yacc
	STA fx_particles_yvel, X
	LDA fx_particles_yvelh, X
	ADC fx_particles_yacc+1
	STA fx_particles_yvelh, X

	\\ Update positions

	CLC
	LDA fx_particles_xpos, X
	ADC fx_particles_xvel, X
	STA fx_particles_xpos, X
	LDA fx_particles_xposh, X
	ADC fx_particles_xvelh, X
	STA fx_particles_xposh, X

	CMP #PLOT_PIXEL_RANGE_X
	BCS remove_particle

	CLC
	LDA fx_particles_ypos, X
	ADC fx_particles_yvel, X
	STA fx_particles_ypos, X
	LDA fx_particles_yposh, X
	ADC fx_particles_yvelh, X
	STA fx_particles_yposh, X

	CMP #PLOT_PIXEL_RANGE_Y
	BCC next
	
	\\ Need to determine state update conditions
	.remove_particle
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
	LDA fx_particles_state, X
	BEQ next

	LDA fx_particles_yposh, X
	TAY

	LDA fx_particles_xposh, X
	TAX

	{
		PLOT_PIXEL	; CLIPPED?
	}

	LDX fx_particles_draw_idx
	.next
	INX
	CPX #LO(PARTICLES_max)
	BNE loop

	.return
	RTS
}



\\ Let's try everything with 16-bit precision

.fx_particles_state
SKIP PARTICLES_max

.fx_particles_xpos
SKIP PARTICLES_max

.fx_particles_xposh
SKIP PARTICLES_max

.fx_particles_ypos
SKIP PARTICLES_max

.fx_particles_yposh
SKIP PARTICLES_max

.fx_particles_xvel
SKIP PARTICLES_max

.fx_particles_xvelh
SKIP PARTICLES_max

.fx_particles_yvel
SKIP PARTICLES_max

.fx_particles_yvelh
SKIP PARTICLES_max

\\ Apart from sin/cos table - could be reused from another fx?
.fx_particles_table
FOR n,0,&13F,1
EQUB 127 * SIN(2 * PI * n / 255)
NEXT

fx_particles_table_cos = fx_particles_table + 64
