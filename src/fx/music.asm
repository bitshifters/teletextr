
MUSIC_SHADOW = TRUE

\\ Initialise music player - pass in VGM_stream_data address
\\ parses header from stream
.fx_music_init_en
{
    jsr fx_music_stop
    lda #19:jsr osbyte

IF MUSIC_SHADOW
    jsr shadow_get_ram
    pha
    lda #MUSIC_EN_SLOT_S
    sta fx_music_slot
    jsr shadow_select_ram

	LDX #LO(music_en_s)
	LDY #HI(music_en_s)
	JSR	vgm_init_stream

    pla
    jsr shadow_select_ram
ELSE
    lda #MUSIC_EN_SLOT
    sta fx_music_slot
    jsr swr_select_slot

	LDX #LO(music_en)
	LDY #HI(music_en)
	JSR	vgm_init_stream
ENDIF
    rts
}
\\ Initialise music player - pass in VGM_stream_data address
\\ parses header from stream
.fx_music_init_reg
{
    jsr fx_music_stop
    lda #19:jsr osbyte

IF MUSIC_SHADOW
    jsr shadow_get_ram
    pha
    lda #MUSIC_REG_SLOT_S
    sta fx_music_slot
    jsr shadow_select_ram

	LDX #LO(music_reg_s)
	LDY #HI(music_reg_s)
	JSR	vgm_init_stream

    pla
    jsr shadow_select_ram
ELSE

    lda #MUSIC_REG_SLOT
    sta fx_music_slot
    jsr swr_select_slot

	LDX #LO(music_reg)
	LDY #HI(music_reg)
	JSR	vgm_init_stream
ENDIF
    rts
}


\\ Initialise music player - pass in VGM_stream_data address
\\ parses header from stream
.fx_music_init_exception
{
    jsr fx_music_stop
    lda #19:jsr osbyte

IF MUSIC_SHADOW
    jsr shadow_get_ram
    pha
    lda #MUSIC_EXCEPTION_SLOT_S
    sta fx_music_slot
    jsr shadow_select_ram

	LDX #LO(music_exception_s)
	LDY #HI(music_exception_s)
	JSR	vgm_init_stream

    pla
    jsr shadow_select_ram
ELSE
    lda #MUSIC_EXCEPTION_SLOT
    sta fx_music_slot
    jsr swr_select_slot

	LDX #LO(music_exception)
	LDY #HI(music_exception)
	JSR	vgm_init_stream
ENDIF
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
    bra exit
    jsr teletext_update
    lda fx_music_on
    beq exit

IF MUSIC_SHADOW
    ; page in the music bank
    jsr shadow_get_ram
    pha
    lda fx_music_slot
    jsr shadow_select_ram

	\\ Poll the music player
	jsr poll_player
    
    ; restore previously paged ROM bank
    pla
    jsr shadow_select_ram

ELSE

    lda &f4
    PHA

    ; page in the music bank
    lda fx_music_slot
    jsr swr_select_slot


	\\ Poll the music player
	jsr poll_player
    
    ; restore previously paged ROM bank
    PLA
    jsr swr_select_bank
ENDIF
.exit
    rts    
}



; Also updating the teletext page info continuously here
; so that the clock is reasonably accurate throughout

.teletext_header
;"0123456789012345678901234567890123456789"
EQUS " P100  ",130,"CEEFAX "
.page
EQUS "100  Sat 24 Jun ",131,"20:49/1"
.second EQUS "0"
.counter EQUB 0

.teletext_update
{

    inc page_count
    lda page_count
    and #3
    sta page_count    
    and #3
    bne ok1

    inc page+2
    lda page+2
    cmp #48+10
    bne ok1
    lda #48
    sta page+2
    inc page+1
    lda page+1
    cmp #48+10
    bne ok1
    lda #48
    sta page+1
    inc page+0
    lda page+0
    cmp #48+10
    bne ok1
    lda #49
    sta page+0

.ok1      



    inc counter
    lda counter
    cmp #50
    bne skip


    lda #0
    sta counter


    ; seconds units
    inc second
    lda second
    cmp #48+10
    bne nosecond
    lda #48
    sta second

    ; seconds tens
    inc second-1
    lda second-1
    cmp #48+6
    bne nosecond
    lda #48
    sta second-1

    ; minutes units
    inc second-3
    lda second-3
    cmp #48+10
    bne nosecond
    lda #48
    sta second-3

    ; minutes tens
    inc second-4
    lda second-4
    cmp #48+6
    bne nosecond
    lda #48
    sta second-4

    ; hours units
    inc second-6
    lda second-6
    cmp #48+10
    bne nosecond
    lda #48
    sta second-6

   ; hours tens
    inc second-7
    lda second-7
    cmp #48+10
    bne nosecond
    lda #48
    sta second-7    



.nosecond
    


.skip



    rts
.page_count EQUB 0
}


.sfx_noise_on
{
    CHIPNOISE 5,7
    rts   
}

.sfx_noise_off
{
    CHIPNOISE 5,0
    rts   
}