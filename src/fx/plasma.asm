
; cheezy plasma demo
; achieves single-colour-character "pixels" by abusing hold graphics


; plasma animation vars
.pnt_tab EQUD 0
.t1 EQUB 0
.t2 EQUB 0
.t3 EQUB 0
.t4 EQUB 0

; hacky cos table
.fx_plasma_cos
    FOR i, 0, 256
        EQUB 60*(COS(i*PI/32))
    NEXT

; rainbow-ish palette
.fx_plasma_colour
    FOR i, 0, 32:EQUB 144+1:NEXT
    FOR i, 0, 32:EQUB 144+1:NEXT
    FOR i, 0, 32:EQUB 144+3:NEXT
    FOR i, 0, 32:EQUB 144+2:NEXT
    FOR i, 0, 32:EQUB 144+6:NEXT
    FOR i, 0, 32:EQUB 144+4:NEXT
    FOR i, 0, 32:EQUB 144+5:NEXT
    FOR i, 0, 32:EQUB 144+5:NEXT
    

; call once before the animation routine
.fx_plasma_init
{
    jsr fx_buffer_clear



    lda #158    ; hold graphics
    ldx #0
	jsr mode7_set_column_shadow_fast

	lda #144+7  ; white graphics
    ldx #1
	jsr mode7_set_column_shadow_fast


    lda #255    ; full block (used as control character for rest of line)
    ldx #2
	jsr mode7_set_column_shadow_fast    

    lda #144+7  ; white block 
    ldx #39
	jsr mode7_set_column_shadow_fast      
    rts
}




.fx_plasma
{
;    jsr fx_plasma_rand
;   rts



    lda pnt_tab+0
    sta t1
    lda pnt_tab+1
    sta t2

    lda #LO(MODE7_VRAM_SHADOW)
    sta addr+1
    lda #HI(MODE7_VRAM_SHADOW)
    sta addr+2

    ldy #0
.yloop
    lda pnt_tab+2
    sta t3
    lda pnt_tab+3
    sta t4

    ldx #3
    tya
    pha
.xloop
    ldy t1
    lda fx_plasma_cos,y
    ldy t2
    clc
    adc fx_plasma_cos,y
    ldy t3
    adc fx_plasma_cos,y
    ldy t4
    adc fx_plasma_cos,y

    tay
    lda fx_plasma_colour,y
.addr
    sta &ffff,x

    inc t3
    inc t3
    inc t3
    inc t4
    inc t4


    inx
    cpx #39
    bne xloop


    inc t1
    inc t1
    inc t2


    lda addr+1
    clc
    adc #40
    sta addr+1
    lda addr+2
    adc #0
    sta addr+2

    pla
    tay
    iny
    cpy #25
    bne yloop


    inc pnt_tab+0
    inc pnt_tab+1
    inc pnt_tab+1
    inc pnt_tab+2
    inc pnt_tab+2
    inc pnt_tab+2
    inc pnt_tab+3
    inc pnt_tab+3
    inc pnt_tab+3
    inc pnt_tab+3



    rts
}


; some test junk functions
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

.fx_plasma_rand
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