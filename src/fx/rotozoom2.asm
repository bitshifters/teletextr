; cheezy & dog-slow rotozoom effect
; Uses character graphics


.fx_rotozoom2
{
IF PIXEL_THIRD
    lda #9:sta &fe00
    lda #9:sta &fe01       ; normally 18
ENDIF

	lda #144+7
    ldx #0
;	jsr mode7_set_column_shadow_fast
    jsr mode7_set_column


    ldx delta_time
.uloop
;    inc zrot
    inc zrot

    dex
;    bne uloop  ; too slow atm

 ;   lda #LO(ONE):sta xoff+0:lda #HI(ONE):sta xoff+1
 ;   lda #LO(ONE):sta yoff+0:lda #HI(ONE):sta yoff+1
    
    inc xoff+1
    inc yoff+1

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


    ; compute the x,y offsets for the 2 pixel below the current pixel
    ; so we can render teletext chars in 2x3 chunks

    ; px0 = sx
    ; py0 = sy
    lda rz_sx+0:sta rz_px0+0:lda rz_sx+1:sta rz_px0+1
    lda rz_sy+0:sta rz_py0+0:lda rz_sy+1:sta rz_py0+1


    ldx #0
.xloop


    LOADTEXTUREADDR rz_px0,rz_py0,read_addr0


.read_addr0 lda &ffff:and #1+2+4+8+16+64+32+128:sta rz_c



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

    ; advance start texture v coord by 2 steps
    ; sx -= dy
    ; sy += dx
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

