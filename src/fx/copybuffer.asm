


.fx_copybuffer_init
{
    lda#&7c:sta disp_buffer_addr
    lda#&78:sta draw_buffer_addr

 ;   lda #&7c:sta draw_buffer_addr
    rts
}
.fx_copybuffer_update
{
	jsr mode7_copy_screen_fast
    lda #32
	jsr mode7_clear_shadow_fast

    rts    
}

; back buffer copy only, no clear
.fx_buffer_copy
{
	jsr mode7_copy_screen_fast
    rts    
}

; clear back buffer
.fx_buffer_clear
{
    lda #32
	jsr mode7_clear_shadow_fast
    rts    
}