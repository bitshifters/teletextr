; Simon's 3d effect data module

.effect_3d



.initialise EQUW init_3d
.update     EQUW update_3d


;----------------------------------------------------------------------------------------------------------
; Initialisation function to fix-up the model data
; Converts model data from an assembled data format into a runtime data format
;----------------------------------------------------------------------------------------------------------

.initialise_models
{
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
}




;----------------------------------------------------------------------------------------------------------
; main loop
;----------------------------------------------------------------------------------------------------------

.init_3d
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



IF WIREFRAME
    LDA#&58:STA scrstrt
ELSE
    LDA#&35:STA scrstrt
ENDIF

    rts
}
.update_3d
{




    ; main loop
    .frame

    ; check for space bar pressed
    LDA#&81:LDX#&9D:LDY#&FF:JSR &FFF4
    TYA:BEQ nopress:LDA space:BNE nopress
    JSR load_next_model:LDA#1
    .nopress STA space


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
    JSR rotate

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
    JSR drawlines

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
    JMP frame

}

;----------------------------------------------------------------------------------------------------------
; Display initialisation table
;----------------------------------------------------------------------------------------------------------
.vdus
IF WIREFRAME
    EQUB 22,4
ELSE
    EQUB 22,5
ENDIF

    EQUB 23,0,10,32,0,0,0,0,0,0
    EQUB 255


.effect_3d_end


