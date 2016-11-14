

.fx_music_init
{
	LDX #&00
	LDY #&80
	JSR	vgm_init_stream
    rts
}

.fx_music_on    EQUB 0


.fx_music_start
{
    lda #1
    sta fx_music_on
    rts
}

.fx_music_stop
{
    lda #0
    sta fx_music_on
    jsr deinit_player    
    rts
}

; called by vsync handler
.fx_music_irq
{
    lda fx_music_on
    beq exit

    lda &f4
    tay

    ; page in the music bank
    lda #MUSIC_SLOT_NO
    jsr swr_select_slot

	\\ Poll the music player
	jsr poll_player
    
    ; restore previously paged ROM bank
    tya
    jsr swr_select_bank
.exit
    rts    
}