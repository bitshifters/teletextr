


.effect_copperbars_update
{
CB_XOFFSET = 0

;bg
    lda #157
FOR n, 0, 24
	sta MODE7_VRAM_SHADOW + n*40 + CB_XOFFSET + 1
NEXT    


;    lda #144+7
;FOR n, 0, 24
;	sta MODE7_VRAM_SHADOW + n*40 + 2
;NEXT    


    lda #LO(MODE7_VRAM_SHADOW+CB_XOFFSET)
    sta copper_addr+1
    lda #HI(MODE7_VRAM_SHADOW)
    sta copper_addr+2



    lda copper_id
    pha

    ldy #25
.copper_loop




    lda copper_id

    lsr a
    lsr a
    lsr a
    and #7
    tax
    lda copper_cycle,x
    inc copper_id
    clc
    adc #128
.copper_addr
    sta &ffff
    lda copper_addr+1
    clc
    adc #40
    sta copper_addr+1
    lda copper_addr+2
    adc #0
    sta copper_addr+2
    dey
    bne copper_loop

    pla
    sta copper_id


    ldx delta_time
.delta_loop
    inc copper_id
    dex
    bne delta_loop

;FOR n, 0, 24
;	sta MODE7_VRAM_SHADOW + n*40
;NEXT


    rts    
}


MACRO GCOLOUR n
    EQUB n
ENDMACRO
.copper_id EQUB 0
.copper_cycle 

IF TRUE
    GCOLOUR 4
    GCOLOUR 1
    GCOLOUR 5
    GCOLOUR 2
    GCOLOUR 6
    GCOLOUR 2
    GCOLOUR 5
    GCOLOUR 1
ELSE
    GCOLOUR 4
    GCOLOUR 4
    GCOLOUR 5
    GCOLOUR 1
    GCOLOUR 3
    GCOLOUR 3
    GCOLOUR 1
    GCOLOUR 5
ENDIF    
    