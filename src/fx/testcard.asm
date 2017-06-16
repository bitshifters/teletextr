
; fakey testcard effect

.start_fx_testcard

.fx_testcard_text
;EQUS "0123456789012345678901234567890123456789"
EQUB 141
EQUS  "    BITSHIFTERS TV                     "




FREQ = 1000

.fx_testcard_init
{
IF 1
    CHIPSOUND   FREQ, 0, 15
ELSE
    SNV = 4000000 / (2.0 * FREQ * 16.0 )
	LDA #&9F: JSR psg_strobe    ; ch0 zero vol
	LDA #&80 + (SNV AND 15): JSR psg_strobe    ; ch0 tone bits 0-4
	LDA #SNV/16: JSR psg_strobe    ; ch0 tone bits 5-10
	LDA #&90: JSR psg_strobe    ; ch0 max vol
    rts
ENDIF
}

.fx_testcard
{

    




    lda #157
    ldx #0
    jsr mode7_set_column

    lda #3+128
    ldx #5
	jsr fx_testcard_fill

    lda #6+128
    ldx #10
	jsr fx_testcard_fill

    lda #2+128
    ldx #15
	jsr fx_testcard_fill

    lda #5+128
    ldx #20
	jsr fx_testcard_fill

    lda #1+128
    ldx #25
	jsr fx_testcard_fill

    lda #4+128
    ldx #30
	jsr fx_testcard_fill


    lda #156
    ldx #35
    jsr mode7_set_column

    ldx #0
.charloop
    lda fx_testcard_text,x
    sta &7c00+5*40,x
    sta &7c00+6*40,x
    inx
    cpx #40
    bne charloop
    

    rts
}



.fx_testcard_fill
{
    dex
    jsr mode7_set_column
    inx
    lda #157
    jsr mode7_set_column
    rts    
}



.fx_testcard_dot
{
	lda #144+7
	jsr mode7_set_graphics_shadow_fast

    LDA #32+16
    STA MODE7_VRAM_SHADOW + (((MODE7_char_height-1)/2) * MODE7_char_width) + (MODE7_char_width/2) - 1
    RTS
}


.end_fx_testcard