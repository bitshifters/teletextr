
; particle fx
; less dodgy than before but a bit slow
; might be a race against raster with back to front buffer copy?

.start_fx_particles

MODE7_particles_addr = MODE7_VRAM_SHADOW

PARTICLES_max = 128
_PARTICLES_ENABLE_BANG = TRUE
_PARTICLES_ENABLE_SPIN = TRUE
_PARTICLES_ENABLE_SPURT = TRUE
_PARTICLES_ENABLE_DRIP = TRUE
_PARTICLES_ENABLE_COLOUR = TRUE
_PARTICLES_ENABLE_DELTA_TIME = TRUE

PARTICLES_gravity = &0F				; fractional part only

PARTICLES_BANG_num = 8
PARTICLES_BANG_ypos = 15

PARTICLES_SPIN_xpos = 40
PARTICLES_SPIN_ypos = 25

PARTICLES_SPURT_xpos = 40
PARTICLES_SPURT_ypos = 60
PARTICLES_SPURT_centre = 128
PARTICLES_SPURT_width = 20
PARTICLES_SPURT_speed = 3

PARTICLES_DRIP_xpos = 40
PARTICLES_DRIP_ypos = 37

.fx_particles_fn_table
{
	EQUW fx_particles_spin_Y
	EQUW fx_particles_spurt_Y
	EQUW fx_particles_drip_Y
}

.fx_particle_fx
EQUB 0

.fx_particles_init
{
	LDA #0
	STA fx_particle_fx

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

	LDA #PARTICLES_gravity
	STA fx_particles_yacc

	.return
	RTS
}

.fx_particles_get_next_free_X
{
	CLC
	.loop
	LDA fx_particles_state, X
	BEQ return
	INX
	.loop_test
	CPX #LO(PARTICLES_max)
	BCC loop
	LDX #0
	.return
	RTS
}

IF _PARTICLES_ENABLE_BANG
.fx_particles_bang_xpos
EQUB 20

.fx_particles_bang_idx
EQUB 0

.fx_particles_bang
{
	LDX #0
	LDY fx_particles_bang_idx
	STY loop_test+1

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

	LDA fx_particles_bang_xpos
	STA fx_particles_xposh, X
	LDA #PARTICLES_BANG_ypos
	STA fx_particles_yposh, X

	JSR fx_particles_set_vel2_Y

	TYA
	CLC
	ADC #(256 / PARTICLES_BANG_num)
	TAY
	.loop_test
	CPY #0
	BNE loop

	.return
	LDA fx_particles_bang_xpos
	EOR #40
	STA fx_particles_bang_xpos

	INC fx_particles_bang_idx

	RTS
}
ENDIF

.fx_particles_set_vel2_Y
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

	\\ X vel * 2
	CLC
	LDA fx_particles_table, Y
	ASL A
	ROL fx_particles_xvelh, X
	STA fx_particles_xvel, X

	\\ Y vel * 2
	CLC
	LDA fx_particles_table_cos, Y
	ASL A
	ROL fx_particles_yvelh, X
	STA fx_particles_yvel, X

	RTS
}

.fx_particles_set_vel4_Y
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
	ASL A
	ROL fx_particles_xvelh, X
	ASL A
	ROL fx_particles_xvelh, X
	STA fx_particles_xvel, X

	\\ Y vel * 4
	CLC
	LDA fx_particles_table_cos, Y
	ASL A
	ROL fx_particles_yvelh, X
	ASL A
	ROL fx_particles_yvelh, X
	STA fx_particles_yvel, X

	RTS
}

IF _PARTICLES_ENABLE_SPIN
.fx_particles_spin_idx
EQUB 0

.fx_particles_spin_Y
{
	JSR fx_particles_get_next_free_X
	BCS return

	\\ Found a free one!

	LDY fx_particles_spin_idx

	\\ Derive colour
	TYA
	AND #&7
	LSR A
	CLC
	ADC #145
	STA fx_particles_state, X

	\\ Set X&Y pos
	LDA #0
	STA fx_particles_xpos, X
	STA fx_particles_ypos, X

	LDA #PARTICLES_SPIN_xpos
	STA fx_particles_xposh, X
	LDA #PARTICLES_SPIN_ypos
	STA fx_particles_yposh, X

	\\ Must have Y here
	JSR fx_particles_set_vel2_Y

	INY			; assumes 256 entries in spin table
	INY			; assumes 256 entries in spin table
	TYA:CLC:ADC #&40
	STA fx_particles_spin_idx

	.return
	RTS
}
ENDIF

IF _PARTICLES_ENABLE_SPURT
.fx_particles_spurt_idx
EQUB PARTICLES_SPURT_centre

.fx_particles_spurt_dir
EQUB PARTICLES_SPURT_speed

.fx_particles_spurt_Y
{
	JSR fx_particles_get_next_free_X
	BCS return

	\\ Found a free particle
	LDY fx_particles_spurt_idx
	TYA
	AND #&3
	CLC
	ADC #145
	STA fx_particles_state, X

	\\ Set X&Y pos
	LDA #0
	STA fx_particles_xpos, X
	STA fx_particles_ypos, X

	LDA #PARTICLES_SPURT_xpos
	STA fx_particles_xposh, X
	LDA #PARTICLES_SPURT_ypos
	STA fx_particles_yposh, X

	JSR fx_particles_set_vel4_Y

	LDA fx_particles_spurt_dir
	BMI neg

	CLC
	ADC fx_particles_spurt_idx
	CMP #(PARTICLES_SPURT_centre+PARTICLES_SPURT_width)
	BCC continue
	LDA #(256-PARTICLES_SPURT_speed)
	STA fx_particles_spurt_dir
	LDA #(PARTICLES_SPURT_centre+PARTICLES_SPURT_width)
	JMP continue
	
	.neg
	CLC
	ADC fx_particles_spurt_idx
	CMP #(PARTICLES_SPURT_centre-PARTICLES_SPURT_width)
	BCS continue
	LDA #PARTICLES_SPURT_speed
	STA fx_particles_spurt_dir
	LDA #(PARTICLES_SPURT_centre-PARTICLES_SPURT_width)

	.continue
	STA fx_particles_spurt_idx

	.return
	RTS
}
ENDIF

IF _PARTICLES_ENABLE_DRIP
.fx_particles_drip_idx
EQUB 0

.fx_particles_drip_idy
EQUB 0

.fx_particles_drip_addx
EQUB 3

.fx_particles_drip_addy
EQUB 4

.fx_particles_drip_col
EQUB 0

.fx_particles_drip_Y					; do lissajous pattern instead?
{
	JSR fx_particles_get_next_free_X
	BCS return

	\\ Found a free particle
	LDA fx_particles_drip_col

	\\ Increment colour
	ADC #1
	AND #&3
	STA fx_particles_drip_col

	\\ Turn this into teletext code
	ADC #145
	STA fx_particles_state, X

	\\ Set X&Y pos fraction
	LDA #0
	STA fx_particles_xpos, X
	STA fx_particles_ypos, X

	\\ No velocity!
	STA fx_particles_xvel, X
	STA fx_particles_xvelh, X
	STA fx_particles_yvel, X
	STA fx_particles_yvelh, X

	\\ X = 40 + sin(iy) / 4
	LDY fx_particles_drip_idx
	LDA fx_particles_table, Y
	CMP #&80
	ROR A
	CMP #&80
	ROR A
	CLC
	ADC #PARTICLES_DRIP_xpos
	STA fx_particles_xposh, X

	\\ Y = 37 + cos(iy) / 4
	LDY fx_particles_drip_idy
	LDA fx_particles_table_cos, Y
	CMP #&80
	ROR A
	CMP #&80
	ROR A
	CLC
	ADC #PARTICLES_DRIP_ypos
	STA fx_particles_yposh, X

	\\ Update sin/cos table lookups
	CLC
	LDA fx_particles_drip_idx
	ADC fx_particles_drip_addx
	STA fx_particles_drip_idx

	CLC
	LDA fx_particles_drip_idy
	ADC fx_particles_drip_addy
	STA fx_particles_drip_idy

	.return
	RTS
}
ENDIF

\\ Would be better if we could call this from config directly with a parameter
.fx_particles_set_fx_A
{
	ASL A
	TAX
	LDA fx_particles_fn_table, X
	STA fx_particles_update_emitter+1
	LDA fx_particles_fn_table+1, X
	STA fx_particles_update_emitter+2

	.return
	RTS
}

.fx_particles_set_fx_spin
{
	LDA #0
	JMP fx_particles_set_fx_A
}

.fx_particles_set_fx_spurt
{
	LDA #1
	JMP fx_particles_set_fx_A
}

.fx_particles_set_fx_drip
{
	LDA #2
	JMP fx_particles_set_fx_A
}

.fx_particles_update
\\{
IF _PARTICLES_ENABLE_COLOUR = FALSE
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast
ENDIF

IF 0		;_PARTICLES_ENABLE_BANG
	LDA #121
	LDX #0
	JSR osbyte
	CPX #81
	BNE not_s
	JSR fx_particles_bang
	.not_s
ENDIF

	LDX #0

	\\ Do emitter
	.fx_particles_update_emitter
	JSR fx_particles_spin_Y

IF _PARTICLES_ENABLE_DELTA_TIME
	LDY delta_time
	.tick_loop
ENDIF

	JSR fx_particles_tick

IF _PARTICLES_ENABLE_DELTA_TIME
	DEY
	BNE tick_loop
ENDIF

	JSR fx_particles_draw

	.fx_particles_update_return
	RTS
\\}

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
			; sm: buffer now cleared to 0, not 32
			;cmp #32
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
\\ Each particle requires 9 bytes so 128 particles = 1152 bytes

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
EQUB 127 * SIN(2 * PI * n / 255)	; 255 or 256?
NEXT

fx_particles_table_cos = fx_particles_table + 64

\\ Fast x,y coordinates to character address lookup
\\ Copied from plot_pixel but offset by -1 for the colour byte - can this be shared?
IF _PARTICLES_ENABLE_COLOUR
.fx_particles_pixel_ytable_lo
	FOR i, 0, PLOT_PIXEL_RANGE_Y-1
	  y = (i DIV 3) * 40		; +1 due to graphics chr - actually want cell before for colour!
	  EQUB LO(y-i)	; adjust for (zp),y style addressing, where Y will be the y coordinate
	NEXT
.fx_particles_pixel_ytable_hi
	FOR i, 0, PLOT_PIXEL_RANGE_Y-1
	  y = (i DIV 3) * 40		; +1 due to graphics chr - actually want cell before for colour!
	  EQUB HI(y-i)	; adjust for (zp),y style addressing, where Y will be the y coordinate
	NEXT
ENDIF

.end_fx_particles
