
.fx_vectorballs_init
{
    ; sort the verts mem layout
    FIX_MODEL_VERTS   fx_vectorballs_model, fx_vectorballs_model_verts

    ; select the cube point cloud
    ldx #LO(fx_vectorballs_model)
    ldy #HI(fx_vectorballs_model)
    jsr select_model

    LDA#0:STA rx
    LDA#&7B:STA ry
    LDA#&C3:STA rz    
    rts
}

.fx_vectorballs
{
	lda #144+7
    ldx #0
	jsr mode7_set_column_shadow_fast


    ; compute rotation matrix
    JSR matrix

    ; clear transformed vertex buffer
    JSR newpoints

    ldx #0
.points_loop
    txa
    pha

    jsr getcoordinates ; returns A=X, Y=Y, bit cack would be better coming back in X/Y obvs. 
    ; also would be good to get screen Z too for sorting...TODO
    tax

    PLOT_PIXEL
    
    pla
    tax
    inx
    cpx npts
    bne points_loop



    ; rotate the model
    ldx delta_time
.delta_loop
    JSR rotate
    dex
    BNE delta_loop    
    rts
}


.fx_vectorballs_model

; minimum of 2, maximum 3, 4 breaks it. Need to add support for >63 verts. TODO!!!
VCUBE_RES = 3

VCUBE_NPTS = VCUBE_RES^3

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
            MD_POINT XC, YC, ZC, VCUBE_SCALE
        NEXT
    NEXT
NEXT
