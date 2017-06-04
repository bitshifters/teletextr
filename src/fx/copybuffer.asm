


.fx_copybuffer_init
{
IF USE_SHADOW_RAM
    lda #&7c
    sta disp_buffer_addr
    sta draw_buffer_addr
ELSE

    lda#&7c:sta disp_buffer_addr
    lda#&78:sta draw_buffer_addr

 ;   lda #&7c:sta draw_buffer_addr
ENDIF
    rts
}
.fx_buffer_swap
{
IF USE_SHADOW_RAM
    jsr shadow_swap_buffers
;    lda #32
;	jsr mode7_clear_screen_fast    
ELSE
	jsr mode7_copy_screen_fast
;    lda #32
;	jsr mode7_clear_shadow_fast
ENDIF
    rts    
}

IF 0
; back buffer copy only, no clear
.fx_buffer_copy
{
IF USE_SHADOW_RAM
ELSE
	jsr mode7_copy_screen_fast
ENDIF
    rts    
}
ENDIF

; clear back buffer
.fx_buffer_clear
{
IF USE_SHADOW_RAM 
    lda #32
    jsr mode7_clear_screen_fast    
ELSE
    lda #32
	jsr mode7_clear_shadow_fast
ENDIF
    rts    
}

IF 0
; clear front buffer
.fx_screen_clear
{
    lda #32
	jsr mode7_clear_screen_fast
    rts    
}
ENDIF

; clear all buffers by swapping screens & clearing as we go
.fx_clear
{
    jsr fx_buffer_clear
    jsr fx_buffer_swap
    jsr fx_buffer_clear
    jsr fx_buffer_swap
    rts
IF 0    
IF USE_SHADOW_RAM
    rts
ELSE
    jsr fx_screen_clear
    jmp fx_buffer_clear
ENDIF
ENDIF
}


; SM: NEW Shadow RAM double buffering routines
; Draw buffer is ALWAYS &7C00


IF 0
; swap front and back buffers between main and shadow ram
; 6845 displays the opposite of whichever ram is currently paged in 
; does NOT clear the new draw buffer, since some effects will fill the whole screen so is faster not to clear.
.fx_buffer_swap
{
    ; 
    jsr shadow_swap_buffers

    rts
}

; Clear the current draw buffer
.fx_buffer_clear
{
    lda #32
	jsr mode7_clear_screen_fast        
    rts
}
ENDIF