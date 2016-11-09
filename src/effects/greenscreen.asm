



.effect_greenscreen  EFFECT_HEADER  effect_greenscreen_update,0,0

.effect_greenscreen_update
{
	lda #144+2
	jsr mode7_set_graphics_shadow_fast	



    rts    
}
