; cheezy & dog-slow rotozoom effect



.rz_sx EQUW 0
.rz_sy EQUW 0

.rz_dx EQUW 0
.rz_dy EQUW 0

.rz_px EQUW 0
.rz_py EQUW 0

; source texture size (pow of two)
TEXTURE_SIZE_BITS = 5
TEXTURE_SIZE = 2^TEXTURE_SIZE_BITS

; rendered image size
CANVAS_SIZE = 64
CANVAS_OFFS = 8

; 8 bits of fraction is useful enough, means that high byte is the integer part of the texture coordinate 
PRECISION_BITS = 8
ONE = 2^PRECISION_BITS

; hacky sin/cos table - ideally should re-use some other sin table
.rz_sinus_lo
    FOR n,0,256+64-1
        EQUB LO(SIN(n)*ONE)
    NEXT
.rz_sinus_hi
    FOR n,0,256+64-1
        EQUB HI(SIN(n)*ONE)
    NEXT
    
; hacky checkerboard texture
.fx_texture
{
    FOR y,0,TEXTURE_SIZE-1
        FOR x,0,TEXTURE_SIZE-1
 ;       PRINT x
            EQUB (x AND (TEXTURE_SIZE/2)) EOR (y AND (TEXTURE_SIZE/2))
;            EQUB (x AND 1) EOR (y AND 1)
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
.fx_texture_ytab_hi
{
    FOR n,0,TEXTURE_SIZE-1
        EQUB HI(TEXTURE_SIZE*n)
    NEXT
}

; animation values
.xoff EQUW 0
.yoff EQUW 0
.zrot EQUB 0

.fx_rotozoom
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
    clc
    adc #LO(fx_texture)
    sta read_addr+1
    lda fx_texture_ytab_hi,y
    adc #HI(fx_texture)
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
}


