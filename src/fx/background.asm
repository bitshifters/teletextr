; background fx


SCREEN_ADDR = &7C00+40
BG_LINES = 24

; alt lines
;FILL_0 = 1+2+16+64+32
;FILL_X = 1+2+16+64+4+8

; horz lines
;FILL_0 = 1+2+32
;FILL_X = 0

; dot pattern
;FILL_0 = 1+64+32
;FILL_X = 1+64+4

; filled
FILL_0 = 1+2+4+8+16+64+32
FILL_X = 0


FG_COL = 144+7
BG_COL = 144+5

lastchar = &8F

; in
; for X each character on row
;   pixel = row[X]
;   if pixel is nonzero
;       if lastpixel was zero
;           plot FG col at X-1
;   else
;       if lastpixel was nonzero
;           plot BG col at X-1
;       else
;           plot BG char at X
;   lastpixel = pixel

.fx_background_fill
{
    lda #HI(SCREEN_ADDR)
    sta read_addr+2
    sta write_addr1+2
    sta write_addr2+2
    sta write_addr3+2

    lda #LO(SCREEN_ADDR)
    sta read_addr+1
    sta write_addr1+1
    sta write_addr2+1
    sta write_addr3+1

    lda #FILL_0
    sta fill_bg+1

    ldy #BG_LINES
.yloop

    ldx #0
    stx lastchar
.xloop

.read_addr
    lda &FF00,x
    beq empty

    lda lastchar
    bne nextchar

    lda #FG_COL
    sta lastchar
    dex
.write_addr1
    sta &FF00,x
    inx
    bra nextchar


.empty

    lda lastchar
    beq bg

    lda #BG_COL
    stz lastchar    
.write_addr2    
    sta &FF00,x

    bra nextchar    

.bg

.fill_bg
    lda #FILL_0
.write_addr3    
    sta &FF00,x

    stz lastchar

.nextchar



    inx
    cpx #40
    bne xloop

    lda read_addr+1:clc:adc #40:sta read_addr+1:lda read_addr+2:adc #0:sta read_addr+2
    lda write_addr1+1:clc:adc #40:sta write_addr1+1:lda write_addr1+2:adc #0:sta write_addr1+2
    lda write_addr2+1:clc:adc #40:sta write_addr2+1:lda write_addr2+2:adc #0:sta write_addr2+2
    lda write_addr3+1:clc:adc #40:sta write_addr3+1:lda write_addr3+2:adc #0:sta write_addr3+2

    lda fill_bg+1
    eor #FILL_X
    sta fill_bg+1


    dey
    beq fin
    jmp yloop
.fin


    rts

}

.fx_background_update
{
   jsr fx_background_fill

IF 0
    ldx #0
    lda #1+2+4+8+16+64+32
.loop
    sta &7c00,x
    sta &7d00,x
    sta &7e00,x
    sta &7f00,x
    inx
    bne loop
ENDIF

    lda #BG_COL
    ldx #0
	jsr mode7_set_column_shadow_fast

    rts

}
