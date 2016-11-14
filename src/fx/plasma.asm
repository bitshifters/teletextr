
;http://www.pygame.org/pcr/numpy_plasma/index.php


.random
{
    lda random_seed
    beq doEor
    asl a
    beq noEor ;if the input was $80, skip the EOR
    bcc noEor
.doEor
    eor #&1d
.noEor  
    sta random_seed
    rts
}
.random_seed EQUB 59    
.random_seed2 EQUB 59

.fx_bitmap
{
    lda random_seed2
    sta random_seed
;    inc random_seed2

	lda #144+7
    ldx #1
	jsr mode7_set_column_shadow_fast

    lda #158
    ldx #0
	jsr mode7_set_column_shadow_fast

    lda #255
    ldx #2
	jsr mode7_set_column_shadow_fast    

    lda #144+7
    ldx #39
	jsr mode7_set_column_shadow_fast  

    lda #LO(MODE7_VRAM_SHADOW)
    sta store+1
    lda #HI(MODE7_VRAM_SHADOW)
    sta store+2

    ldy #25
.yloop
    ldx #3
    tya:pha
.xloop



    jsr random
    and #7
    tay
    lda colour_table,y
.store
    sta &ffff,x
    inx
    cpx #39
    bne xloop

    pla:tay

    lda store+1
    clc
    adc #40
    sta store+1
    lda store+2
    adc #0
    sta store+2

    dey
    bne yloop

    rts
.colour_table EQUB 158,145,146,147,148,149,150,151
}