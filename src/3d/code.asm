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

IF MODE7
    lda#22:jsr &ffee:lda#7:jsr&ffee
    
    
    lda#&7c:sta disp_buffer_addr
    lda#&78:sta draw_buffer_addr




ELSE
    lda#22:jsr &ffee:lda#4:jsr&ffee
ENDIF
    rts
}
.update_3d
{
    lda #19:jsr &FFF4

IF MODE7
	jsr mode7_copy_screen_fast
    lda #0
    
	jsr mode7_clear_shadow_fast

IF FALSE
	lda #144+7	
	jsr mode7_set_graphics_shadow_fast	
ELSE


    lda #157
FOR n, 0, 24
	sta MODE7_VRAM_SHADOW + n*40 + 1
NEXT    
    lda #144+7
FOR n, 0, 24
	sta MODE7_VRAM_SHADOW + n*40 + 2
NEXT    


    lda #LO(MODE7_VRAM_SHADOW)
    sta copper_addr+1
    lda #HI(MODE7_VRAM_SHADOW)
    sta copper_addr+2



    lda copper_id
    pha

    ldy #25
.copper_loop




    lda copper_id

    lsr a
    lsr a
    lsr a
    and #7
    tax
    lda copper_cycle,x
    inc copper_id
    clc
    adc #128
.copper_addr
    sta &ffff
    lda copper_addr+1
    clc
    adc #40
    sta copper_addr+1
    lda copper_addr+2
    adc #0
    sta copper_addr+2
    dey
    bne copper_loop

    pla
    sta copper_id
    inc copper_id

;FOR n, 0, 24
;	sta MODE7_VRAM_SHADOW + n*40
;NEXT



ENDIF


;	lda #0
;	ldx draw_buffer_addr	
;	jsr clear_screen_buffer
	
;	lda #145
;	ldx draw_buffer_addr	
;	jsr mode7_set_graphics_fast


IF FALSE	
	ldx #0
	ldy #0
	jsr move_to

	ldx #PLOT_PIXEL_RANGE_X-1
	ldy #0
	jsr draw_to

	ldx #PLOT_PIXEL_RANGE_X-1
	ldy #PLOT_PIXEL_RANGE_Y-1
	jsr draw_to	

	ldx #0
	ldy #PLOT_PIXEL_RANGE_Y-1
	jsr draw_to		

	ldx #0
	ldy #0
	jsr draw_to		

    	
ENDIF

ENDIF


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
    JMP frame

MACRO GCOLOUR n
    EQUB n
ENDMACRO
.copper_id EQUB 0
.copper_cycle 

IF TRUE
    GCOLOUR 4
    GCOLOUR 1
    GCOLOUR 5
    GCOLOUR 2
    GCOLOUR 6
    GCOLOUR 2
    GCOLOUR 5
    GCOLOUR 1
ELSE
    GCOLOUR 4
    GCOLOUR 4
    GCOLOUR 5
    GCOLOUR 1
    GCOLOUR 3
    GCOLOUR 3
    GCOLOUR 1
    GCOLOUR 5
ENDIF    
    

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




IF MODE7

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

ENDIF


.effect_3d_end


