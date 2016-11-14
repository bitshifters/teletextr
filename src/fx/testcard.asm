

.colours
;    0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9
;    7,3,6,2,5,1,4,0


.fx_testcard_fill
{
    dex
    jsr mode7_set_column
    inx
    lda #157
    jsr mode7_set_column
    rts    
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


    rts
}