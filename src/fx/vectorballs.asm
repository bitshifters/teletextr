

ZSORT = TRUE    ; turn zsorting on or off

; minimum of 2, maximum 3, 4 breaks it. Need to add support for >63 verts. TODO!!!
VCUBE_RES = 3

DRAWLINES = FALSE       ; draw connecting lines (cube only)
DRAWCOORDS = FALSE      ; debug draw z coords on screen



.fx_vectorballs_init
{
    ; lazy static initialise - only do this routine once per app lifecycle since it juggles mem
    lda init_done
    bne do_init
    lda #1
    sta init_done
    ; sort the verts mem layout
    FIX_MODEL_VERTS   fx_vectorballs_model, fx_vectorballs_model_verts
.do_init

    ; select the cube point cloud
    ldx #LO(fx_vectorballs_model)
    ldy #HI(fx_vectorballs_model)
    jsr select_model

    LDA#0:STA rx
    LDA#&7B:STA ry
    LDA#&C3:STA rz    
    rts
.init_done EQUB 0    
}


.fx_vectorballs_set_small
{
    JSR mode7_sprites_set_size_8
	LDA #LO(ball7_data)
	STA mode7_sprites_data_ptr
	LDA #HI(ball7_data)
	STA mode7_sprites_data_ptr+1
    RTS
}

.fx_vectorballs_set_medium
{
    JSR mode7_sprites_set_size_12
	LDA #LO(ball11_data)
	STA mode7_sprites_data_ptr
	LDA #HI(ball11_data)
	STA mode7_sprites_data_ptr+1
    RTS
}

.fx_vectorballs_set_large
{
    JSR mode7_sprites_set_size_16
	LDA #LO(ball15_data)
	STA mode7_sprites_data_ptr
	LDA #HI(ball15_data)
	STA mode7_sprites_data_ptr+1
    RTS
}


.fx_vectorballs_update
{
;    jsr fx_vectorballs_set_large

	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast

    ; compute rotation matrix
    JSR matrix

    ; clear transformed vertex buffer
    JSR newpoints

IF ZSORT
    jsr zsort
ENDIF

IF 0
; debug code to draw the sorted vertex ids
    lda zorder+0:clc:adc#48:sta&7c00+40*24+0
    lda zorder+1:clc:adc#48:sta&7c00+40*24+1
    lda zorder+2:clc:adc#48:sta&7c00+40*24+2
    lda zorder+3:clc:adc#48:sta&7c00+40*24+3
    lda zorder+4:clc:adc#48:sta&7c00+40*24+4
    lda zorder+5:clc:adc#48:sta&7c00+40*24+5
    lda zorder+6:clc:adc#48:sta&7c00+40*24+6
    lda zorder+7:clc:adc#48:sta&7c00+40*24+7
ENDIF


IF DRAWCOORDS
; debug code to visualize the zcoord of each vertex on the screen
    ldx #0
.zpoints_loop
    txa
    pha

    ; plot zcoord of vertex on x
    jsr getscreenz ; returns A=Z
    lsr a
    lsr a   ; 8 bit to 6 bit (so X coord range is 0-64 )
    tax
    pla
    pha

    tay
    
    PLOT_PIXEL_CLIPPED
    ldx #64
    PLOT_PIXEL_CLIPPED
    


    pla
    tax
    inx
    cpx #8
    bne zpoints_loop
ENDIF   ; DRAWCOORDS



; daft effect to plot lines between balls (only works if VCUBE_RES is 2)
IF DRAWLINES
IF 1
    lda #0:jsr getcoordinatesXY:jsr move_to
    lda #1:jsr getcoordinatesXY:jsr draw_to
    lda #3:jsr getcoordinatesXY:jsr draw_to
    lda #2:jsr getcoordinatesXY:jsr draw_to      
    lda #0:jsr getcoordinatesXY:jsr draw_to          
ENDIF 
IF 1
    lda #4:jsr getcoordinatesXY:jsr move_to
    lda #5:jsr getcoordinatesXY:jsr draw_to
    lda #7:jsr getcoordinatesXY:jsr draw_to
    lda #6:jsr getcoordinatesXY:jsr draw_to      
    lda #4:jsr getcoordinatesXY:jsr draw_to  
ENDIF
IF 1
    lda #0:jsr getcoordinatesXY:jsr move_to
    lda #4:jsr getcoordinatesXY:jsr draw_to
    lda #1:jsr getcoordinatesXY:jsr move_to
    lda #5:jsr getcoordinatesXY:jsr draw_to
    lda #3:jsr getcoordinatesXY:jsr move_to
    lda #7:jsr getcoordinatesXY:jsr draw_to
    lda #2:jsr getcoordinatesXY:jsr move_to
    lda #6:jsr getcoordinatesXY:jsr draw_to
ENDIF
ENDIF   ; DRAWLINES


    ; render the sprites in zsorted back to front order
    ldx npts
.points_loop
    txa
    pha

IF ZSORT
    ; fetch the vertex id from the sorted array instead
    lda zorder,x
    tax
ENDIF


    jsr getcoordinatesXY ; returns A=X, Y=Y, bit cack would be better coming back in X/Y obvs. 

;    tax

	JSR mode7_sprites_plot_centred

    pla
    tax

    dex
    bpl points_loop





    ; rotate the model
    ldx delta_time
.delta_loop

    ; rotate
IF 0
    lda #0:sta rx
;    lda #0:sta ry
    inc ry
    lda #0:sta rz
ELSE
    INC rx:INC rx
    INC ry:INC ry
    INC rz
ENDIF
    dex
    BNE delta_loop    
    rts
}


.fx_vectorballs_model


IF VCUBE_RES==3
    VCUBE_NPTS = VCUBE_RES^3-1
ELSE
    VCUBE_NPTS = VCUBE_RES^3
ENDIF

VCUBE_NLINES = 0
VCUBE_NSURFS = 0
VCUBE_MAXVIS = 0
VCUBE_SCALE = 50

MD_HEADER VCUBE_NPTS,VCUBE_NLINES,VCUBE_NSURFS,VCUBE_MAXVIS

.fx_vectorballs_model_verts
VCUBE_STEP = 2.0 / (VCUBE_RES-1)
FOR ZC, -1.0, 1.0, VCUBE_STEP
    FOR YC, -1.0, 1.0, VCUBE_STEP
        FOR XC, -1.0, 1.0, VCUBE_STEP
            IF XC==0.0 AND YC==0.0 AND ZC=0.0 AND VCUBE_RES==3
            ELSE
                MD_POINT XC, YC, ZC, VCUBE_SCALE
            ENDIF
        NEXT
    NEXT
NEXT


\\ Sprite data
INCLUDE "src\sprites\ball7.asm"
INCLUDE "src\sprites\ball11.asm"
INCLUDE "src\sprites\ball15.asm"
