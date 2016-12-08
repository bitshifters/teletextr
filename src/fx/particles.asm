
; extremely dodgy particle fx

MODE7_particles_addr = &7800

PARTICLES_max = 128
_PARTICLES_ENABLE_BANG = TRUE
_PARTICLES_ENABLE_SPIN = TRUE
_PARTICLES_ENABLE_COLOUR = TRUE

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
;	STX loop_test+1
	CLC
	.loop
	LDA fx_particles_state, X
	BEQ return
	INX
;	AND #LO(PARTICLES_max-1)
	.loop_test
	CPX #LO(PARTICLES_max)
	BCC loop
	LDX #0
	.return
	RTS
}

.fx_particles_bang_idx
EQUB 20

.fx_particles_bang
{
	LDX #0
	LDY #0	;fx_particles_bang_idx

	.loop
	JSR fx_particles_get_next_free_X
	BCS return

	TXA
	AND #&1
	CLC
	ADC #149
	STA fx_particles_state, X

	LDA #0
	STA fx_particles_xpos, X
	STA fx_particles_ypos, X

	LDA fx_particles_bang_idx
	STA fx_particles_xposh, X
	LDA #15
	STA fx_particles_yposh, X

	JSR fx_particles_set_vel_Y

	TYA
	CLC
	ADC #32
	TAY
	CPY #0
	BNE loop

	.return
	LDA fx_particles_bang_idx
	EOR #40
	STA fx_particles_bang_idx

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
	TYA
	AND #&3
	CLC
	ADC #145
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

	INY			; assumes 256 entries in spin table

	.return
	RTS
}

.fx_particles_update
{
IF _PARTICLES_ENABLE_COLOUR = FALSE
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast
ENDIF

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
;	INY:INY:INY:INY
	TYA:CLC:ADC #&40:TAY
	STY fx_particles_spin_idx

; This gives 4x particles generated per frame - a bit much!
;	TYA:CLC:ADC #&40:TAY
;	JSR fx_particles_spin_Y
;	TYA:CLC:ADC #&40:TAY
;	JSR fx_particles_spin_Y
;	TYA:CLC:ADC #&40:TAY
;	JSR fx_particles_spin_Y
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

	\\ MACRO PLOT_PIXEL
	{
		clc							;[2]
		lda plot_pixel_xtable,x		;[4]	get chr offset on row (Xcoord / 2)
		adc plot_pixel_ytable_lo,y	;[4]	C may be set after this addition.

		sta plot_lo 					;[3]

		lda plot_pixel_ytable_hi,y	;[4]	C will be clear after this addition
		adc draw_buffer_addr 		;[3]	for double buffering - add the base drawbuffer address, uses 1 more cycle than fixed addressing

		sta plot_hi						;[3]

		lda plot_pixel_ytable_chr,y	;[4]	get 2-pixel wide teletext glyph for Y coord
		and plot_pixel_xtable_chr,x	;[4]	apply odd/even X coord mask  

		ora (plot_lo),y					;[5]		
		sta (plot_lo),y					;[5]
	}

	LDX fx_particles_draw_idx

	.next
	INX
	CPX #LO(PARTICLES_max)
	BNE loop

	IF _PARTICLES_ENABLE_COLOUR
	{
		LDX #0

		.colloop
		STX fx_particles_draw_idx
		LDA fx_particles_state, X
		BEQ colnext

		STA plot_tmp

		LDA fx_particles_yposh, X
		TAY

		LDA fx_particles_xposh, X
		TAX

		\\ MACRO PLOT_PIXEL
		{
			clc							;[2]
			lda plot_pixel_xtable,x		;[4]	get chr offset on row (Xcoord / 2)
			adc fx_particles_pixel_ytable_lo,y	;[4]	C may be set after this addition.

			sta plot_lo 					;[3]

			lda fx_particles_pixel_ytable_hi,y	;[4]	C will be clear after this addition
			adc draw_buffer_addr 		;[3]	for double buffering - add the base drawbuffer address, uses 1 more cycle than fixed addressing

			sta plot_hi						;[3]

			lda (plot_lo),y
			cmp #32
			bne skipcol

			lda plot_tmp
			sta (plot_lo),y					;[5]

			.skipcol
		}

		LDX fx_particles_draw_idx

		.colnext
		INX
		CPX #LO(PARTICLES_max)
		BNE colloop
	}
	ENDIF

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

.fx_particles_pixel_ytable_lo
	FOR i, 0, PLOT_PIXEL_RANGE_Y-1
	  y = (i DIV 3) * 40		; +1 due to graphics chr
	  EQUB LO(y-i)	; adjust for (zp),y style addressing, where Y will be the y coordinate
	NEXT
.fx_particles_pixel_ytable_hi
	FOR i, 0, PLOT_PIXEL_RANGE_Y-1
	  y = (i DIV 3) * 40		; +1 due to graphics chr
	  EQUB HI(y-i)	; adjust for (zp),y style addressing, where Y will be the y coordinate
	NEXT
