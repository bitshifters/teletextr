; green screen
; Turned this into generic fg/bg colour screen

.fx_greenscreen_fg
EQUB 144+2

.fx_greenscreen_bg
EQUB 0

.fx_greenscreen_update
{
	LDX #0

	LDA fx_greenscreen_bg
	BEQ no_bg
	jsr mode7_set_column_shadow_fast
	INX
	LDA #MODE7_new_bg
	jsr mode7_set_column_shadow_fast
	INX
	.no_bg

	LDA fx_greenscreen_fg
	BEQ no_fg
	jsr mode7_set_column_shadow_fast
	INX
	.no_fg

    rts    
}

.fx_greenscreen_set_fg
{
	STA fx_greenscreen_fg
	RTS
}

.fx_greenscreen_set_bg
{
	STA fx_greenscreen_bg
	RTS
}

.fx_greenscreen_set_default
{
	LDA #0: STA fx_greenscreen_bg
	LDA #144+2: STA fx_greenscreen_fg
	RTS	
}

.fx_greenscreen_bright_ramp
{
	EQUB 144+4,144+4,144+4,144+4
	EQUB 144+1,144+1,144+1
	EQUB 144+5,144+5,144+5
	EQUB 144+2,144+2,144+2
	EQUB 144+6,144+6,144+6
	EQUB 144+3,144+3,144+3
	EQUB 144+7,144+7,144+7,144+7,144+7
}

.fx_greenscreen_hue_ramp
{
	EQUB 144+1,144+1,144+1,144+1
	EQUB 144+3,144+3,144+3
	EQUB 144+2,144+2,144+2
	EQUB 144+6,144+6,144+6
	EQUB 144+4,144+4,144+4
	EQUB 144+5,144+5,144+5
	EQUB 144+1,144+1,144+1,144+1,144+1
}

.fx_greenscreen_update_ramp
{
	LDY #0

	FOR n,1,24,1
	LDA (readptr), Y
	INY
	STA MODE7_VRAM_SHADOW + n*40
	LDA #MODE7_separated
	STA MODE7_VRAM_SHADOW + n*40 + 1
	NEXT

	RTS
}

.fx_greenscreen_update_bright
{
	LDA #LO(fx_greenscreen_bright_ramp)
	STA readptr
	LDA #HI(fx_greenscreen_bright_ramp)
	STA readptr+1
	JMP fx_greenscreen_update_ramp
}

.fx_greenscreen_update_hue
{
	LDA #LO(fx_greenscreen_hue_ramp)
	STA readptr
	LDA #HI(fx_greenscreen_hue_ramp)
	STA readptr+1
	JMP fx_greenscreen_update_ramp
}
