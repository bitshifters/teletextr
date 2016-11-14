
; fakey testcard effect

.fx_testcard_text
;EQUS "0123456789012345678901234567890123456789"
EQUB 141
EQUS  "    BITSHIFTERS TV                     "

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