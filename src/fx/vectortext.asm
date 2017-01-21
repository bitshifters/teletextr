
.fx_vectortext_init
{
    ; lazy static initialise - only do this routine once per app lifecycle since it juggles mem
    lda init_done
    bne do_init
    lda #1
    sta init_done
    ; sort the verts mem layout
    FIX_MODEL_VERTS   fx_vectortext_model, fx_vectortext_model_verts
.do_init

    ; select the vector lines point cloud
    ldx #LO(fx_vectortext_model)
    ldy #HI(fx_vectortext_model)
    jsr select_model

    LDA#0:STA rx
    LDA#0:STA ry
    LDA#0:STA rz    
    rts
.init_done EQUB 0    
}




.fx_vectortext_update
{
	;lda #144+5

    lda page+0
    and #7
    bne do3d

    jsr fx_teletext_drawpage
    rts

.do3d


    clc
    adc #144

    ldx #0
	jsr mode7_set_column_shadow_fast

    ; compute rotation matrix
    JSR matrix

    ; clear transformed vertex buffer
    JSR newpoints

IF 1

    ldy #0
.lineloop
    lda fx_vectortext_linearray,y
    tax
    tya:pha
    jsr getcoordinates:sta x0:sty y0
    pla:tay
    iny

    lda fx_vectortext_linearray,y
    tax
    tya:pha
    jsr getcoordinates:sta x1:sty y1
    pla:tay
    iny

    tya:pha

    jsr linedraw	

    pla:tay

    cpy #VTEXT_NLINES*2
    bne lineloop

ELSE
    ldx #0
.points_loop
    txa
    pha

    jsr getcoordinates ; returns A=X, Y=Y, bit cack would be better coming back in X/Y obvs. 
    ; also would be good to get screen Z too for sorting...TODO
    tax

    PLOT_PIXEL
;	JSR mode7_sprites_plot_centred
    




    pla
    tax
    inx
    cpx npts
    bne points_loop

ENDIF




IF 0
;    INC rx
;   INC ry
;    INC rz
        ;LDA #0:sta rx:sta rx:sta rx
        jsr fx_vectortext_animate
ELSE
    ; rotate the model
    ldx delta_time
.delta_loop
        jsr fx_vectortext_animate
    dex
    BNE delta_loop    
ENDIF
    rts
}

.fx_vectortext_animate
{
    lda type

    cmp #0
    beq wait
    cmp #2
    beq wait
    cmp #4
    beq wait
    cmp #6
    beq wait
    cmp #8
    bne rotx

.wait
    dec prop
    dec prop
    dec prop
    dec prop
    beq nextv
    bne done



.rotx
    cmp #1
    bne roty
    inc rx
    inc rx
    beq nextv
    bne done

.roty
    cmp #3
    bne rotz
    inc ry
    inc ry
    beq nextv
    bne done

.rotz
    cmp #5
    bne rota
    inc rz
    inc rz
    beq nextv
    bne done

.rota
    cmp#7
    bne done
    inc rx
    inc ry
    inc rz
    bne done
    
.nextv
    inc type
    lda type
    cmp #9
    bne done
    lda #0
    sta type
.done
    rts
.type EQUB 0
.prop EQUB 0
}

.fx_vectortext_model


VTEXT_NPTS = 35

VTEXT_NLINES = 28
VTEXT_NSURFS = 0
VTEXT_MAXVIS = 0
VTEXT_SCALE = 50

MD_HEADER VTEXT_NPTS,VTEXT_NLINES,VTEXT_NSURFS,VTEXT_MAXVIS

MACRO VT_POINT  x,y
    scale=3.5
    xo=-27.0
    yo=-5.0
    zo=0.0
    MD_POINT (x+xo)*scale,(y+yo)*scale,0.0,1.0
ENDMACRO


.fx_vectortext_model_verts
; A (0-6)
VT_POINT 0,10
VT_POINT 0,4
VT_POINT 4,0
VT_POINT 8,4
VT_POINT 8,10
VT_POINT 0,7
VT_POINT 8,7
; B (7-16)
VT_POINT 10,10
VT_POINT 10,0
VT_POINT 16,0
VT_POINT 18,2
VT_POINT 18,3
VT_POINT 16,5
VT_POINT 18,7
VT_POINT 18,8
VT_POINT 16,10
VT_POINT 10,5
; U (17-20)
VT_POINT 20,0
VT_POINT 20,10
VT_POINT 28,10
VT_POINT 28,0
; G (21-27)
VT_POINT 34,6
VT_POINT 38,6
VT_POINT 38,10
VT_POINT 30,10
VT_POINT 30,0
VT_POINT 38,0
VT_POINT 38,2
; ' (28-29)
VT_POINT 41,0
VT_POINT 41,2
; 1 (30-31)
VT_POINT 44,0
VT_POINT 44,10
; 7 (32-34)
VT_POINT 47,0
VT_POINT 55,0
VT_POINT 55,10

MACRO VT_LINE a,b,offset
    EQUB a+offset,b+offset
ENDMACRO

.fx_vectortext_linearray
; A
VT_LINE 0,1,0
VT_LINE 1,2,0
VT_LINE 2,3,0
VT_LINE 3,4,0
VT_LINE 5,6,0
; B
VT_LINE 0,1,7
VT_LINE 1,2,7
VT_LINE 2,3,7
VT_LINE 3,4,7
VT_LINE 4,5,7
VT_LINE 5,6,7
VT_LINE 6,7,7
VT_LINE 7,8,7
VT_LINE 8,0,7
VT_LINE 5,9,7
; U
VT_LINE 0,1,17
VT_LINE 1,2,17
VT_LINE 2,3,17
; G
VT_LINE 0,1,21
VT_LINE 1,2,21
VT_LINE 2,3,21
VT_LINE 3,4,21
VT_LINE 4,5,21
VT_LINE 5,6,21
; '
VT_LINE 0,1,28
; 1
VT_LINE 0,1,30
; 7
VT_LINE 0,1,32
VT_LINE 1,2,32
 
 







