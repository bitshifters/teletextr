MUSICA_SLOT_NO = 0
MUSICB_SLOT_NO = 1

\\ Initialise music player - pass in VGM_stream_data address
\\ parses header from stream
.fx_music_init
{
    jsr fx_music_stop
    lda #19:jsr osbyte
    
    sei
    lda #MUSICA_SLOT_NO
    sta fx_music_slot
    jsr swr_select_slot
    cli

	LDX #LO(music_exception)
	LDY #HI(music_exception)
	JSR	vgm_init_stream
    rts
}
\\ Initialise music player - pass in VGM_stream_data address
\\ parses header from stream
.fx_music_initb
{
    jsr fx_music_stop
    lda #19:jsr osbyte


    sei
    lda #MUSICB_SLOT_NO
    sta fx_music_slot
    jsr swr_select_slot
    cli

	LDX #LO(music_reg)
	LDY #HI(music_reg)
	JSR	vgm_init_stream
    rts
}


.fx_music_on    EQUB 0
.fx_music_slot  EQUB 0

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
    lda fx_music_slot
    jsr swr_select_slot

	\\ Poll the music player
	jsr poll_player
    
    ; restore previously paged ROM bank
    tya
    jsr swr_select_bank
.exit
    rts    
}