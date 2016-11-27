; cheezy & dog-slow rotozoom effect
; uses hold graphics trick for pixel rendering



ROTOZOOM3_DEBUG = FALSE

ROTOZOOM3_SCALE = TRUE
ROTOZOOM3_KEYS = TRUE
ROTOZOOM3_ANIMATE = TRUE

USE_TEXTURE2 = TRUE



; hacky checkerboard texture
ALIGN 256   ; align to page so theres no lsb element


.fx_texture2
EQUB 147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147
EQUB 147,147,147,147,147,147,145,145,145,145,147,147,147,147,147,147,147,147,147,147,147,147,149,149,149,149,147,147,147,147,147,147
EQUB 147,147,147,147,145,145,145,145,145,145,145,145,147,147,147,147,147,147,147,147,149,149,149,149,149,149,149,149,147,147,147,147
EQUB 147,147,147,145,145,145,145,145,145,145,145,145,145,147,147,147,147,147,147,149,149,149,149,149,149,149,149,149,149,147,147,147
EQUB 147,147,145,145,145,151,151,145,145,145,145,151,151,145,147,147,147,147,149,149,149,149,149,149,149,149,149,149,149,149,147,147
EQUB 147,147,145,145,151,151,151,151,145,145,151,151,151,151,147,147,147,147,149,149,151,151,149,149,149,149,151,151,149,149,147,147
EQUB 147,147,145,145,151,151,148,148,145,145,151,151,148,148,147,147,147,147,149,151,151,151,151,149,149,151,151,151,151,149,147,147
EQUB 147,145,145,145,151,151,148,148,145,145,151,151,148,148,145,147,147,149,149,151,151,151,151,149,149,151,151,151,151,149,149,147
EQUB 147,145,145,145,145,151,151,145,145,145,145,151,151,145,145,147,147,149,149,151,148,148,151,149,149,151,148,148,151,149,149,147
EQUB 147,145,145,145,145,145,145,145,145,145,145,145,145,145,145,147,147,149,149,149,148,148,149,149,149,149,148,148,149,149,149,147
EQUB 147,145,145,145,145,145,145,145,145,145,145,145,145,145,145,147,147,149,149,149,149,149,149,149,149,149,149,149,149,149,149,147
EQUB 147,145,145,145,145,145,145,145,145,145,145,145,145,145,145,147,147,149,149,149,149,149,149,149,149,149,149,149,149,149,149,147
EQUB 147,145,145,145,145,145,145,145,145,145,145,145,145,145,145,147,147,149,149,149,149,149,149,149,149,149,149,149,149,149,149,147
EQUB 147,145,145,147,145,145,145,147,147,145,145,145,147,145,145,147,147,149,149,149,149,147,149,149,149,149,147,149,149,149,149,147
EQUB 147,145,147,147,147,145,145,147,147,145,145,147,147,147,145,147,147,147,149,149,147,147,147,149,149,147,147,147,149,149,147,147
EQUB 147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147
EQUB 147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147
EQUB 147,147,147,147,147,147,148,148,148,148,147,147,147,147,147,147,147,147,147,147,147,147,150,150,150,150,147,147,147,147,147,147
EQUB 147,147,147,147,148,148,148,148,148,148,148,148,147,147,147,147,147,147,147,147,150,150,150,150,150,150,150,150,147,147,147,147
EQUB 147,147,147,148,148,148,148,148,148,148,148,148,148,147,147,147,147,147,147,150,150,150,150,150,150,150,150,150,150,147,147,147
EQUB 147,147,148,148,148,148,148,148,148,148,148,148,148,148,147,147,147,147,150,151,151,150,150,150,150,151,151,150,150,150,147,147
EQUB 147,147,148,148,148,148,148,148,148,148,148,148,148,148,147,147,147,147,151,151,151,151,150,150,151,151,151,151,150,150,147,147
EQUB 147,147,148,148,148,146,146,148,148,146,146,148,148,148,147,147,147,147,148,148,151,151,150,150,148,148,151,151,150,150,147,147
EQUB 147,148,148,148,148,146,146,148,148,146,146,148,148,148,148,147,147,150,148,148,151,151,150,150,148,148,151,151,150,150,150,147
EQUB 147,148,148,148,148,148,148,148,148,148,148,148,148,148,148,147,147,150,150,151,151,150,150,150,150,151,151,150,150,150,150,147
EQUB 147,148,148,148,148,148,148,148,148,148,148,148,148,148,148,147,147,150,150,150,150,150,150,150,150,150,150,150,150,150,150,147
EQUB 147,148,148,146,146,148,148,146,146,148,148,146,146,148,148,147,147,150,150,150,150,150,150,150,150,150,150,150,150,150,150,147
EQUB 147,148,146,148,148,146,146,148,148,146,146,148,148,146,148,147,147,150,150,150,150,150,150,150,150,150,150,150,150,150,150,147
EQUB 147,148,148,148,148,148,148,148,148,148,148,148,148,148,148,147,147,150,150,150,150,150,150,150,150,150,150,150,150,150,150,147
EQUB 147,148,148,148,148,147,148,148,148,148,147,148,148,148,148,147,147,150,150,147,150,150,150,147,147,150,150,150,147,150,150,147
EQUB 147,147,148,148,147,147,147,148,148,147,147,147,148,148,147,147,147,150,147,147,147,150,150,147,147,150,150,147,147,147,150,147
EQUB 147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147,147

IF ROTOZOOM3_DEBUG
CANVAS_ADDR2 = &7C00+40*4
CANVAS_W2 = 40-4
CANVAS_H2 = 25-4
ELSE
CANVAS_ADDR2 = &7C00
CANVAS_W2 = 40-4
CANVAS_H2 = 25

ENDIF

; high byte incorporates MSB of texture address
.fx_texture_ytab_hi_texture2
{
    FOR n,0,TEXTURE_SIZE-1
        EQUB HI(TEXTURE_SIZE*n) + HI(fx_texture2)
    NEXT
}

MACRO LOADTEXTUREADDR_TEXTURE2   xreg,yreg,addr
    LOADTEXTUREADDRT xreg,yreg,addr,fx_texture_ytab_hi_texture2
ENDMACRO


.zoomscale EQUW ONE
.zoomanim EQUB 0

.fx_rotozoom3_animate
{

IF ROTOZOOM3_ANIMATE
    inc zoomanim
;    inc zoomanim
    lda zoomanim
    tax

IF 1    
    lda rz_sinus_lo,x
    sta zoomscale+0
    lda rz_sinus_hi,x
    sta zoomscale+1

    asl zoomscale+0
    rol zoomscale+1
ENDIF

IF 0
    lda rz_sinus_lo+64,x
    sta xoff+0
    lda rz_sinus_hi+64,x
    sta xoff+1

    lda rz_sinus_lo,x
    sta yoff+0
    lda rz_sinus_hi,x
    sta yoff+1


    for n,0,4:asl xoff+0:rol xoff+1:next
    for n,0,4:asl yoff+0:rol yoff+1:next
ENDIF

    inc xoff+1
    inc yoff+1
;    inc xoff+1
;    inc yoff+1

    inc zrot
;    inc zrot    
ENDIF

    rts
}


.fx_rotozoom3
{

;	ldx #0:lda #144+1:jsr mode7_set_column
    ldx #1:lda #158:jsr mode7_set_column
    ldx #2:lda #255:jsr mode7_set_column


    ldx delta_time
.uloop
;    inc zrot
;    inc zrot

    dex
;    bne uloop  ; too slow atm



IF ROTOZOOM3_KEYS
    ; check for key presses
    LDA#&81:LDX#LO(-66):LDY#&FF:JSR &FFF4:TYA:BEQ nok0:jsr fx_rotozoom3_animate:.nok0     ; A
    LDA#&81:LDX#LO(-26):LDY#&FF:JSR &FFF4:TYA:BEQ nok1:dec xoff+1:.nok1     ; left
    LDA#&81:LDX#LO(-122):LDY#&FF:JSR &FFF4:TYA:BEQ nok2:inc xoff+1:.nok2    ; right
    LDA#&81:LDX#LO(-58):LDY#&FF:JSR &FFF4:TYA:BEQ nok3:dec yoff+1:.nok3     ; up
    LDA#&81:LDX#LO(-42):LDY#&FF:JSR &FFF4:TYA:BEQ nok4:inc yoff+1:.nok4     ; down
    LDA#&81:LDX#LO(-17):LDY#&FF:JSR &FFF4:TYA:BEQ nok5:dec zrot:.nok5     ; q
    LDA#&81:LDX#LO(-34):LDY#&FF:JSR &FFF4:TYA:BEQ nok6:inc zrot:.nok6     ; w
    
    LDA#&81:LDX#LO(-55):LDY#&FF:JSR &FFF4:TYA:BEQ nok7
    lda zoomscale+0:sec:sbc #1:sta zoomscale+0:lda zoomscale+1:sbc #0:sta zoomscale+1
    .nok7     ; o
    LDA#&81:LDX#LO(-56):LDY#&FF:JSR &FFF4:TYA:BEQ nok8
    lda zoomscale+0:clc:adc #1:sta zoomscale+0:lda zoomscale+1:adc #0:sta zoomscale+1
    .nok8     ; p
ENDIF


    ; sx = xoff
    ; sy = yoff
    lda xoff+0:sta rz_sx+0:lda xoff+1:sta rz_sx+1
    lda yoff+0:sta rz_sy+0:lda yoff+1:sta rz_sy+1

    ; calc gradients
    ; dx = cos(a) * scale
    ; dy = sin(a) * scale

    lda zrot
    tax
    lda rz_sinus_lo+64,x
    sta rz_dx+0
    lda rz_sinus_hi+64,x
    sta rz_dx+1


    lda rz_sinus_lo,x
    sta rz_dy+0
    lda rz_sinus_hi,x
    sta rz_dy+1

IF ROTOZOOM3_DEBUG
    MPRINTMEM txt_m1,&7c00
    MPRINTMEM txt_m2,&7c00+10
    MPRINTMEM txt_m3,&7c00+20
ENDIF

    ; * scale
IF ROTOZOOM3_SCALE
    lda rz_dx+0:sta T1+0:lda rz_dx+1:sta T1+1
    lda zoomscale+0:sta T2+0:lda zoomscale+1:sta T2+1
    sec
    jsr maths_multiply_16bit_signed
    ; get bits 8-24 >> 8
    lda PRODUCT+1:sta rz_dx+0:lda PRODUCT+2:sta rz_dx+1

    lda rz_dy+0:sta T1+0:lda rz_dy+1:sta T1+1
    lda zoomscale+0:sta T2+0:lda zoomscale+1:sta T2+1
    sec
    jsr maths_multiply_16bit_signed
    ; get bits 8-24 >> 8
    lda PRODUCT+1:sta rz_dy+0:lda PRODUCT+2:sta rz_dy+1    
ENDIF

IF ROTOZOOM3_DEBUG
    MPRINTMEM txt_m2,&7c00+40
    MPRINTMEM txt_m3,&7c00+50
ENDIF


    ; set write address
    lda #LO(CANVAS_ADDR2)
    sta write_addr+1
    lda #HI(CANVAS_ADDR2)
    sta write_addr+2

; this method of sampling doesn't require the render buffer to be power of two
    ldy #CANVAS_H2
.yloop

    ; stash y coord
    sty &9f


    ; px0 = sx
    ; py0 = sy
    lda rz_sx+0:sta rz_px0+0:lda rz_sx+1:sta rz_px0+1
    lda rz_sy+0:sta rz_py0+0:lda rz_sy+1:sta rz_py0+1


    ldx #0
.xloop



    LOADTEXTUREADDR_TEXTURE2 rz_px0,rz_py0,read_addr0


.read_addr0 lda &ffff
.write_addr
    sta &ffff,x     ; modified

    cpx #0
    bne skipx
    ldx #2
.skipx
    inx
    cpx #CANVAS_W2
    beq endx

    ; move to next column
    ; px = px+dx
    ; py = py+dy
    ADDOFFSET rz_px0,rz_dx,rz_px0
    ADDOFFSET rz_py0,rz_dy,rz_py0


    jmp xloop
.endx

    ; move write ptr to next line
    lda write_addr+1
    clc
    adc #40
    sta write_addr+1
    lda write_addr+2
    adc #0
    sta write_addr+2

    ; advance start texture v coord to next line
    ; sx -= dy
    ; sy += dx
    SUBOFFSET   rz_sx,rz_dy,rz_sx
    ADDOFFSET   rz_sy,rz_dx,rz_sy

    ldy &9f
    dey
    beq done
    jmp yloop
.done





    rts
    .zero EQUW 0
}





IF ROTOZOOM3_DEBUG
.txt_m1 EQUS "zoom %w", LO(zoomscale), HI(zoomscale), "  ", 0
.txt_m2 EQUS "rz_dx %w", LO(rz_dx), HI(rz_dx), "  ", 0
.txt_m3 EQUS "rz_dy %w", LO(rz_dy), HI(rz_dy), "  ", 0

ENDIF