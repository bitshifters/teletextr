


.effect_copybuffer  EFFECT_HEADER  effect_copybuffer_update,0,0


.effect_copybuffer_init
{
    lda#&7c:sta disp_buffer_addr
    lda#&78:sta draw_buffer_addr

    rts
}
.effect_copybuffer_update
{
	jsr mode7_copy_screen_fast
    lda #0
	jsr mode7_clear_shadow_fast
    rts    
}

