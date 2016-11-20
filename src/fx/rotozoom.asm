; cheezy & dog-slow rotozoom effect





; source texture size (pow of two)
; makes no difference to performance what size it is, just memory
TEXTURE_SIZE_BITS = 5
TEXTURE_SIZE = 2^TEXTURE_SIZE_BITS

; rendered image size
CANVAS_SIZE = 64
CANVAS_OFFS = 8

CANVAS_W = 39
CANVAS_H = 25
CANVAS_ADDR = &7c01

PIXEL_PERFECT = TRUE

; 8 bits of fraction is useful enough, means that high byte is the integer part of the texture coordinate 
PRECISION_BITS = 8
ONE = 2^PRECISION_BITS

; hacky sin/cos table - ideally should re-use some other sin table
.rz_sinus_lo
    FOR n,0,256+64-1
        EQUB LO(SIN(n*2*PI/256)*ONE)
    NEXT
.rz_sinus_hi
    FOR n,0,256+64-1
        EQUB HI(SIN(n*2*PI/256)*ONE)
    NEXT
    
; hacky checkerboard texture
ALIGN 256   ; align to page so theres no lsb element
.fx_texture
{
    FOR y,0,TEXTURE_SIZE-1
        FOR x,0,TEXTURE_SIZE-1
 ;       PRINT x
            EQUB (((x AND (TEXTURE_SIZE/2)) EOR (y AND (TEXTURE_SIZE/2)))/(TEXTURE_SIZE/2))*255
        NEXT
    NEXT
}

; texture line lookup offset table
.fx_texture_ytab_lo
{
    FOR n,0,TEXTURE_SIZE-1
 ;       PRINT n
        EQUB LO(TEXTURE_SIZE*n)
    NEXT
}
; high byte incorporates MSB of texture address
.fx_texture_ytab_hi
{
    FOR n,0,TEXTURE_SIZE-1
        EQUB HI(TEXTURE_SIZE*n) + HI(fx_texture)
    NEXT
}

; animation values
.xoff EQUW 0
.yoff EQUW 0
.zrot EQUB 0


IF 1
rz_sx = &80
rz_sy = &82

rz_dx = &84
rz_dy = &86

rz_px0 = &88
rz_px1 = &8A
rz_px2 = &8C


rz_py0 = &8E
rz_py1 = &90
rz_py2 = &92

rz_tx = &94
rz_c = &95
ELSE
.rz_sx EQUW 0
.rz_sy EQUW 0

.rz_dx EQUW 0
.rz_dy EQUW 0

.rz_px0 EQUW 0
.rz_px1 EQUW 0
.rz_px2 EQUW 0


.rz_py0 EQUW 0
.rz_py1 EQUW 0
.rz_py2 EQUW 0


.rz_tx EQUB 0

.rz_c   EQUB 0
ENDIF

rz_px = rz_px0
rz_py = rz_py0

; [ 1][ 2] + 160
; [ 4][ 8]
; [16][64]

; [0][3]
; [1][4]
; [2][5]

.fx_rotozoom
{
	lda #144+7
    ldx #0
;	jsr mode7_set_column_shadow_fast
    jsr mode7_set_column

    ldx delta_time
.uloop
    inc zrot
    inc zrot

    dex
;    bne uloop  ; too slow atm

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
    
    ; set write address
    lda #LO(CANVAS_ADDR)
    sta write_addr+1
    lda #HI(CANVAS_ADDR)
    sta write_addr+2

; this method of sampling doesn't require the render buffer to be power of two
    ldy #CANVAS_H
.yloop

    ; stash y coord
    sty &9f

    ; we sample the texture 3 vertical lines at time
    ; creating a character block which is written once every other horizontal step

MACRO ADDOFFSET    src,offset,dst
    lda src+0:clc:adc offset+0:sta dst+0:lda src+1:adc offset+1:sta dst+1    
ENDMACRO
MACRO SUBOFFSET    src,offset,dst
    lda src+0:sec:sbc offset+0:sta dst+0:lda src+1:sbc offset+1:sta dst+1    
ENDMACRO

    ; compute the x,y offsets for the 2 pixel below the current pixel
    ; so we can render teletext chars in 2x3 chunks

    ; px0 = sx
    ; py0 = sy
    lda rz_sx+0:sta rz_px0+0:lda rz_sx+1:sta rz_px0+1
    lda rz_sy+0:sta rz_py0+0:lda rz_sy+1:sta rz_py0+1

IF PIXEL_PERFECT
    ; px1 = px0-dy
    ; py1 = py0+dx
    SUBOFFSET rz_px0,rz_dy,rz_px1
    ADDOFFSET rz_py0,rz_dx,rz_py1

    ; px2 = px1-dy
    ; py2 = py1+dx
    SUBOFFSET rz_px1,rz_dy,rz_px2
    ADDOFFSET rz_py1,rz_dx,rz_py2
ENDIF

    ldx #0
.xloop


MACRO LOADTEXTUREADDR   xreg,yreg,addr
   ; bits 8-15 are the integer part of the coordinate
    ; convert u coord to x index
    lda xreg+1
    and #TEXTURE_SIZE-1
    sta rz_tx

    ; convert v coord to read address
    lda yreg+1
    and #TEXTURE_SIZE-1
    tay ; y contains v coord (0-TEXTURE_SIZE-1)
    lda fx_texture_ytab_lo,y
    clc
    adc rz_tx
    sta addr+1
    lda fx_texture_ytab_hi,y
;    adc #0  ; dont think this is needed since texture rows are pow2 aligned and width==height
    sta addr+2
ENDMACRO

    LOADTEXTUREADDR rz_px0,rz_py0,read_addr0

IF PIXEL_PERFECT    
    LOADTEXTUREADDR rz_px1,rz_py1,read_addr1
    LOADTEXTUREADDR rz_px2,rz_py2,read_addr2

    ; px = px+dx
    ; py = py+dy
    ADDOFFSET rz_px0,rz_dx,rz_px0
    ADDOFFSET rz_py0,rz_dy,rz_py0

    ADDOFFSET rz_px1,rz_dx,rz_px1
    ADDOFFSET rz_py1,rz_dy,rz_py1

    ADDOFFSET rz_px2,rz_dx,rz_px2
    ADDOFFSET rz_py2,rz_dy,rz_py2

    LOADTEXTUREADDR rz_px0,rz_py0,read_addr3
    LOADTEXTUREADDR rz_px1,rz_py1,read_addr4
    LOADTEXTUREADDR rz_px2,rz_py2,read_addr5
ENDIF    

IF PIXEL_PERFECT

IF 0
; simulate faster pixel pack if we have 6 bit planes
.read_addr0 
.read_addr1 
.read_addr2 
.read_addr3 
.read_addr4 
.read_addr5 
    lda &ffff:and #1:ora #128+32
    ora zero
    ora zero
    ora zero
    ora zero
    ora zero
    
ELSE
.read_addr0 lda &ffff:and #1:ora #128+32:sta rz_c
.read_addr1 lda &ffff:and #4:ora rz_c:sta rz_c
.read_addr2 lda &ffff:and #16:ora rz_c:sta rz_c
.read_addr3 lda &ffff:and #2:ora rz_c:sta rz_c
.read_addr4 lda &ffff:and #8:ora rz_c:sta rz_c
.read_addr5 lda &ffff:and #64:ora rz_c ;:sta rz_c
ENDIF
    
ELSE

.read_addr0 lda &ffff:and #1+2+4+8+16+64+32+128:sta rz_c
ENDIF


.write_addr
    sta &ffff,x     ; modified


    inx
    cpx #CANVAS_W
    beq endx

    ; move to next column
    ; px = px+dx
    ; py = py+dy
    ADDOFFSET rz_px0,rz_dx,rz_px0
    ADDOFFSET rz_py0,rz_dy,rz_py0

IF PIXEL_PERFECT
    ADDOFFSET rz_px1,rz_dx,rz_px1
    ADDOFFSET rz_py1,rz_dy,rz_py1

    ADDOFFSET rz_px2,rz_dx,rz_px2
    ADDOFFSET rz_py2,rz_dy,rz_py2
ENDIF

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

    ; advance start texture v coord by 3 steps
    ; sx -= dy
    ; sy += dx
    SUBOFFSET   rz_sx,rz_dy,rz_sx
    ADDOFFSET   rz_sy,rz_dx,rz_sy

    SUBOFFSET   rz_sx,rz_dy,rz_sx
    ADDOFFSET   rz_sy,rz_dx,rz_sy

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



; original slow version
.fx_rotozoom2
{
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast


    ldx delta_time
.uloop
    inc zrot
    dex
;    bne uloop  ; too slow atm

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
    

    ldy #CANVAS_OFFS
.yloop
    ldx #CANVAS_OFFS

    ; px = sx
    ; py = sy
    lda rz_sx+0:sta rz_px+0:lda rz_sx+1:sta rz_px+1
    lda rz_sy+0:sta rz_py+0:lda rz_sy+1:sta rz_py+1

.xloop

    ; stash x,y coords
    stx &90
    sty &91

    ; bits 8-15 are the integer part of the coordinate
    lda rz_py+1
    and #TEXTURE_SIZE-1
    tay

    ; convert y coord to read address
    lda fx_texture_ytab_lo,y
;    clc
;    adc #LO(fx_texture)
    sta read_addr+1
    lda fx_texture_ytab_hi,y
;    adc #HI(fx_texture)
    sta read_addr+2

    ; x coord can be an index
    lda rz_px+1
    and #TEXTURE_SIZE-1
    tax

.read_addr
    lda &ffff,x
    beq no_pixel

    ; restore x,y screen pixel coords
    ldx &90
    ldy &91
    PLOT_PIXEL

.no_pixel

    ; dupe because code is super hacked for now
    ; just while we get it working
    ldx &90
    ldy &91



    ; px += dx
    ; py += dy
    lda rz_px+0:clc:adc rz_dx+0:sta rz_px+0:lda rz_px+1:adc rz_dx+1:sta rz_px+1
    lda rz_py+0:clc:adc rz_dy+0:sta rz_py+0:lda rz_py+1:adc rz_dy+1:sta rz_py+1

    inx
    cpx #CANVAS_OFFS+CANVAS_SIZE
    bne xloop

    ; sx -= dy
    ; sy += dx
    lda rz_sx+0:sec:sbc rz_dy+0:sta rz_sx+0:lda rz_sx+1:sbc rz_dy+1:sta rz_sx+1
    lda rz_sy+0:clc:adc rz_dx+0:sta rz_sy+0:lda rz_sy+1:adc rz_dx+1:sta rz_sy+1

    iny
    cpy #CANVAS_OFFS+CANVAS_SIZE
    beq done
    jmp yloop
.done

    rts
IF 0
.rz_sx EQUW 0
.rz_sy EQUW 0

.rz_dx EQUW 0
.rz_dy EQUW 0

.rz_px EQUW 0
.rz_py EQUW 0    
ENDIF
}


