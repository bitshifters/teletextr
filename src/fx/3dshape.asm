
; hacked mode7 version of Nick Jamesons 3d renderer

EFFECT_3DSHAPE_ORG = *

;ORG &90

; logic vars
.space SKIP 1
.p  SKIP 1
.f SKIP 1
.flicker SKIP 1
.pause SKIP 1
;.culling SKIP 1    ; culling = 0=disabled, 255=enabled
.cullingdb SKIP 1  ; culling key debounce
.opt_filled SKIP 1
.opt_filled_db SKIP 1

;ORG EFFECT_3DSHAPE_ORG

.fx_3dshape_update
{





    ; main loop
    .frame

    ; check for space bar pressed
    LDA#&81:LDX#&9D:LDY#&FF:JSR &FFF4
    TYA:BEQ nopress:LDA space:BNE nopress
    JSR load_next_model:LDA#1
    .nopress STA space


;    LDA#&81:LDX#&9E:LDY#&FF:JSR &FFF4:TYA:BEQ skipkey1:INC transx:.skipkey1 ; 'Z'





IF MODE7==FALSE
IF WIREFRAME
    ; wireframe mode runs in 10K mode 4, 1 bit per pixel
    ; and uses a double buffer
    LDA scrstrt:LSR A:LSR A:LSR A
    LDX#&C:STX &FE00:STA &FE01

    ; check for "F" keypress to toggle vsync
    LDA#&81:LDX#&BC:LDY#&FF:JSR &FFF4
    TYA:BEQ nof:LDA f:BNE nof
    LDA flicker:EOR #1:STA flicker:LDA#1
    .nof STA f
    LDA flicker:AND pause:BNE fastandflicker
    LDA#19:JSR &FFF4:SEI
    .fastandflicker
    LDA scrstrt:EOR #&68:STA scrstrt
ENDIF

    ; clear the draw buffer
    JSR wipe
ENDIF

    ; check for "C" pressed to toggle backface culling
    LDA#&81:LDX#&AD:LDY#&FF:JSR &FFF4
    TYA:BEQ noc:LDA cullingdb:BNE noc
    LDA culling:EOR #255:STA culling:LDA#1
    .noc STA cullingdb

IF WIREFRAME==FALSE
    ; check for "L" pressed to toggle XOR poly filler
    LDA#&81:LDX#&A9:LDY#&FF:JSR &FFF4
    TYA:BEQ nol:LDA opt_filled_db:BNE nol
    LDA opt_filled:EOR #1:STA opt_filled:LDA#1
    .nol STA opt_filled_db
ENDIF


    ; check for "P" pressed to pause rotation
    LDA#&81:LDX#&C8:LDY#&FF:JSR &FFF4
    TYA:BEQ nop:LDA p:BNE nop
    LDA pause:EOR #1:STA pause:LDA#1
    .nop STA p
    LDA pause:BEQ nrot

    ; rotate the model
    ldx delta_time
.delta_loop
    JSR rotate
    dex
    BNE delta_loop

    .nrot

    ; compute rotation matrix
    JSR matrix

    ; clear transformed vertex buffer
    JSR newpoints

    ; initialise visibility of lines array for this frame
    JSR resetvisibility

    ; check if back face culling is enabled, skip if not
    LDA culling
    BEQ noculling

    ; eliminate hidden surfaces
    JSR hiddensurfaceremoval

    ; determine visible lines to be rendered
    JSR hiddenlineremoval

.noculling

    ; render the model
    JSR model_draw

IF WIREFRAME == FALSE
    ; apply shading
    LDA opt_filled
    BNE dofill
    JSR fill_copy   ; copy back buffer to front rather than xor fill from back to front
    JMP filldone
    
    .dofill
    JSR fill        ; xor fill back buffer to front buffer

    .filldone
ENDIF









    rts    
}


.fx_3dshape_init
{
    ; initialise variables
    LDX#0
    STX adr
    STX space:STX p:STX f:STX flicker:STX cullingdb:STX opt_filled_db
    LDA#1:STA pause
    LDA#255:STA culling
    LDA#1:STA opt_filled



    ; prepare model data for runtime
    JSR initialise_models


    ; setup multiplication tables
    jsr initialise_multiply


    ; load first model
    JSR reset_model


    ; initialise rotation angles of model
    LDA#0:STA rx
    LDA#&7B:STA ry
    LDA#&C3:STA rz


    rts
}

.linedraw
{
 ;   ldx #0
 ;   ldy #0
 
    ldx x0
    ldy y0
;    lda x0
;    sec
;    sbc #128
;    tax
;    lda y0
;    sec
;    sbc #128
;    tay
    jsr move_to
;    lda x1
;    sec
;    sbc #128
;    tax
;    lda y1
 ;   sec
 ;   sbc #128
 ;   tay
    
    ldx x1
    ldy y1
    jsr draw_to
    rts
    ldx x0
    ldy y0
    jsr move_to
    ldx x1
    ldy y1
    jsr draw_to
    rts

;	jsr move_to
;	ldx output_verts+2
;	ldy output_verts+3
;	jsr draw_to

}


;----------------------------------------------------------------------------------------------------------
; Initialisation function to fix-up the model data
; Converts model data from an assembled data format into a runtime data format
;----------------------------------------------------------------------------------------------------------

.initialise_models
{
    ; lazy static initialise - only do this routine once per app lifecycle since it juggles mem
    lda init_done
    beq do_init
    rts
.do_init
    lda #1
    sta init_done

IF WIREFRAME
    FIX_MODEL   model_data_tetra, verts_data_tetra, surfs_data_tetra
ENDIF
    FIX_MODEL   model_data_cube, verts_data_cube, surfs_data_cube

IF WIREFRAME
    FIX_MODEL   model_data_octa, verts_data_octa, surfs_data_octa
    FIX_MODEL   model_data_dodeca, verts_data_dodeca, surfs_data_dodeca
; icosa not compatible with code, as it has >15 surfaces
;    FIX_MODEL   model_data_icosa, verts_data_icosa, surfs_data_icosa
ENDIF


    FIX_MODEL   model_data_viper, verts_data_viper, surfs_data_viper
    FIX_MODEL   model_data_cobra, verts_data_cobra, surfs_data_cobra
    rts
.init_done EQUB 0
}