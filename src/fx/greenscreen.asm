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
