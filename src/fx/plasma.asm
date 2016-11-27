
; cheezy plasma demo
; achieves single-colour-character "pixels" by abusing hold graphics
; doesn't seem to work in jsbeeb for some reason

IF 1
SCREEN_W = 40
SCREEN_H = 25
ELSE
; puts mode7 into 32x32 screen mode with 2/3 height pixels (producting square characters effectively)
; decided to leave this out as it isn't 'pure' teletext.
SCREEN_W = 32
SCREEN_H = 32
ENDIF



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
; could easily be optimized to used less memory but slower to render

IF 1
.fx_plasma_colour
    FOR i, 0, 32:EQUB 144+1:NEXT
    FOR i, 0, 32:EQUB 144+1:NEXT
    FOR i, 0, 32:EQUB 144+3:NEXT
    FOR i, 0, 32:EQUB 144+2:NEXT
    FOR i, 0, 32:EQUB 144+6:NEXT
    FOR i, 0, 32:EQUB 144+4:NEXT
    FOR i, 0, 32:EQUB 144+5:NEXT
    FOR i, 0, 32:EQUB 144+5:NEXT
ELSE
.fx_plasma_colour
    FOR i, 0, 32:EQUB 144+7:NEXT
    FOR i, 0, 32:EQUB 144+7:NEXT
    FOR i, 0, 32:EQUB 144+6:NEXT
    FOR i, 0, 32:EQUB 144+6:NEXT
    FOR i, 0, 32:EQUB 144+4:NEXT
    FOR i, 0, 32:EQUB 144+4:NEXT
    FOR i, 0, 32:EQUB 144+6:NEXT
    FOR i, 0, 32:EQUB 144+6:NEXT
ENDIF

.fx_plasma_counter EQUB 0
.fx_plasma_char EQUB 160+1

; A contains char
; X contains column
.fx_plasma_column
{
    FOR n,0,SCREEN_H-1
        sta &7800+n*SCREEN_W,X
    NEXT    
    rts
}


; call once before the animation routine
.fx_plasma_init
{
    jsr fx_buffer_clear


	lda #144+7  ; white graphics
    ldx #0
	jsr fx_plasma_column;mode7_set_column_shadow_fast

    lda #158    ; hold graphics
    ldx #1
	jsr fx_plasma_column;mode7_set_column_shadow_fast



;    lda #160+1+2+4+8+16+64    ; full block (used as control character for rest of line)
;    lda #160+1+8+16    ; full block (used as control character for rest of line)
    lda #160+1+2+4+8    ; top quarter block (used as control character for rest of line)


    ldx #2
	jsr fx_plasma_column;mode7_set_column_shadow_fast    

;    lda #144+7  ; white block 
;    ldx #39
;	jsr mode7_set_column_shadow_fast   


    lda #0
    sta fx_plasma_counter
    rts
}


.fx_mode7fx
{
    IF SCREEN_W != 40
        lda #9:sta &fe00:lda #13:sta &fe01  ; 18
        lda #1:sta &fe00:lda #SCREEN_W:sta &fe01  ; 40
        lda #4:sta &fe00:lda #36:sta &fe01
        lda #6:sta &fe00:lda #31:sta &fe01
        lda #7:sta &fe00:lda #32:sta &fe01
        lda #6:sta &fe00:lda #32:sta &fe01
    ENDIF
    rts
}



.fx_plasma
{
;    jsr fx_plasma_rand
;   rts
    jsr fx_mode7fx

 ;   lda fx_plasma_char
 ;   ldx #2
;	jsr mode7_set_column_shadow_fast    
IF 0
IF 0
    FOR n,0,24,2
;        lda #160+1+8+16
        lda #160+1+64
        sta &7800+2+n*40
    NEXT
    FOR n,1,24,2
;        lda #160+2+4+64
        lda #160+2+16
        sta &7800+2+n*40
    NEXT
ELSE

    FOR n,0,24,4
        lda #160+1+64
        sta &7800+2+n*40
    NEXT
    FOR n,1,24,4
        lda #160+4
        sta &7800+2+n*40
    NEXT
    FOR n,2,24,4
        lda #160+2+16
        sta &7800+2+n*40
    NEXT
    FOR n,3,24,4
        lda #160+8
        sta &7800+2+n*40
    NEXT
ENDIF



ELSE



    lda #255
    ldx #2
    jsr fx_plasma_column;    jsr mode7_set_column_shadow_fast    
ENDIF


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

    tya
    pha


; first pixel rendered manually







    ldx #0
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
    ;lda #255
.addr
    sta &ffff,x

    inc t3
    inc t3
    inc t3
    inc t4
    inc t4
    inc t4

    cpx #0
    bne skip_first
    inx ; skip white gfx
    inx ; skip hold
    inx ; skip gfx char
    jmp nextchar
.skip_first

IF SCREEN_W == 40
;    inx        ; extra inx if you want square 'pixels' since teletext chars are rectangular
ENDIF
    inx
.nextchar
    cpx #SCREEN_W
    bne xloop


    inc t1
    inc t1
    inc t2


    lda addr+1
    clc
    adc #SCREEN_W
    sta addr+1
    lda addr+2
    adc #0
    sta addr+2

    pla
    tay
    iny
    cpy #SCREEN_H
    bne yloop

    ldx delta_time
.delta_loop
    inc pnt_tab+0
    inc pnt_tab+1
;    inc pnt_tab+1
    inc pnt_tab+2
;    inc pnt_tab+2
;    inc pnt_tab+2
    inc pnt_tab+3
;    inc pnt_tab+3
;    inc pnt_tab+3
;    inc pnt_tab+3


IF 1
    inc fx_plasma_counter
    lda fx_plasma_counter
    lsr a ;:lsr a:lsr a:lsr a:lsr a   ; /32 is a speed modifier
    and #7:tay
    lda fx_plasma_chrs,y
    sta fx_plasma_char
ENDIF




    dex
    bne delta_loop

    rts

.fx_plasma_chrs
    EQUB 160+1+8
    EQUB 160+1+64
    EQUB 160+1+64
    EQUB 160+1+64
    EQUB 160+1+64
    EQUB 160+1+64
    EQUB 160+1+64
    EQUB 160+1+64

.fx_plasma_chrs2 
    EQUB 160+1
    EQUB 160+1+16
    EQUB 160+1+64
    EQUB 160+4+8
    EQUB 160+1+8+16
    EQUB 160+1+2+16+64
    EQUB 160+2+4+8+16
    EQUB 160+1+2+4+8+16+64




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

    ; hold graphics control works differently on beeb to standard teletext
    ; 

    lda #158    ; hold
    ldx #0
	jsr mode7_set_column_shadow_fast

	lda #144+7  ; colour
    ldx #1
	jsr mode7_set_column_shadow_fast

    lda #160+1+2+4+8+16+64    ; graphics code used for hold char
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

; Hold graphics example:
; http://edit.tf/#0:QIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBBD37unLfsQbNO7Kg6b0GfL0Qb92VBj37N_Xkg4ZeSBAgQIEGPRh5YcfTLyQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgPEcxMmSJFixUqUKF0CBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIC55CTLEipEoXJliRUiULkyxIqRKFyZYkVIlC5MsSKkShcmWQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECAueYkyxIqRKFyZYkVIlC5MsSKkShcmWJFSJQuTLEipEoXJlkCBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgLnsJMsSKkShcmWJFSJQuTLEipEoXJliRUiULkyxIqRKFyZZAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIC55YTLEipEoXJliRUiULkyxIqRKFyZYkVIlC5MsSKkShcmWQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECAueckyxIqRKFyZYkVIlC5MsSKkShcmWJFSJQuTLEipEoXJlkCBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgLnuZMsSKkShcmWJFSJQuTLEipEoXJliRUiULkyxIqRKFyZZAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIC558TLEipEoXJliRUiULkyxIqRKFyZYkVIlC5MsSKkShcmWQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECAueekyxIqRKFyZYkVIlC5MsSKkShcmWJFSJQuTLEipEoXJlkCBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgLnu5MsSKkShcmWJFSJQuTLEipEoXJliRUiULkyxIqRKFyZZAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIC57-TLEipEoXJliRUiULkyxIqRKFyZYkVIlC5MsSKkShcmWQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECBAgQIECA
