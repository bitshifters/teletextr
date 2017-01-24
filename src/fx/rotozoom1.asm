; cheezy & dog-slow rotozoom effect
; Uses teletext pixels



PIXEL_FULL = TRUE       ; uses 2x3 teletext pixels if TRUE, 2x2 teletext pixels if FALSE
PIXEL_THIRD = FALSE      ; forces 6845 to show 2x2 teletext pixels



    


.fx_rotozoom1
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
    ; px1 = px0-dy
    ; py1 = py0+dx
    SUBOFFSET rz_px0,rz_dy,rz_px1
    ADDOFFSET rz_py0,rz_dx,rz_py1

IF PIXEL_FULL
    ; px2 = px1-dy
    ; py2 = py1+dx
    SUBOFFSET rz_px1,rz_dy,rz_px2
    ADDOFFSET rz_py1,rz_dx,rz_py2
ENDIF


    ldx #0
.xloop


    LOADTEXTUREADDR rz_px0,rz_py0,read_addr0

    LOADTEXTUREADDR rz_px1,rz_py1,read_addr1

    ; px = px+dx
    ; py = py+dy
    ADDOFFSET rz_px0,rz_dx,rz_px0
    ADDOFFSET rz_py0,rz_dy,rz_py0

    ADDOFFSET rz_px1,rz_dx,rz_px1
    ADDOFFSET rz_py1,rz_dy,rz_py1

    LOADTEXTUREADDR rz_px0,rz_py0,read_addr3
    LOADTEXTUREADDR rz_px1,rz_py1,read_addr4

IF PIXEL_FULL    
    LOADTEXTUREADDR rz_px2,rz_py2,read_addr2

    ADDOFFSET rz_px2,rz_dx,rz_px2
    ADDOFFSET rz_py2,rz_dy,rz_py2

    LOADTEXTUREADDR rz_px2,rz_py2,read_addr5
ENDIF

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

IF PIXEL_FULL
.read_addr0 lda &ffff:and #1:ora #128+32:sta rz_c
.read_addr1 lda &ffff:and #4:ora rz_c:sta rz_c
.read_addr2 lda &ffff:and #16:ora rz_c:sta rz_c
.read_addr3 lda &ffff:and #2:ora rz_c:sta rz_c
.read_addr4 lda &ffff:and #8:ora rz_c:sta rz_c
.read_addr5 lda &ffff:and #64:ora rz_c ;:sta rz_c
ELSE
.read_addr0 lda &ffff:and #1:ora #128+32:sta rz_c
.read_addr1 lda &ffff:and #4:ora rz_c:sta rz_c
.read_addr3 lda &ffff:and #2:ora rz_c:sta rz_c
.read_addr4 lda &ffff:and #8:ora rz_c

ENDIF

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

    ADDOFFSET rz_px1,rz_dx,rz_px1
    ADDOFFSET rz_py1,rz_dy,rz_py1

IF PIXEL_FULL
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



; original slow version, plot pixel
.fx_rotozoom_slow
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


