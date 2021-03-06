
;----------------------------------------------------------------------------------------------------------
; De-serialise triplet byte vertex data (for vertices & surfaces)
;----------------------------------------------------------------------------------------------------------
; inputs - A=npts
;          X/Y=points array address lo/hi
;
; Function is necessary since BeebAsm doesn't allow arbitrary memory
; layouts/data writes.
; We assemble the data interleaved X/Y/Z
; then this function copies the buffer to temp memory
; before copying it back, de-interleaved
;----------------------------------------------------------------------------------------------------------
TEMP_ADDR = SCRATCH_RAM_ADDR
.fix_verts
{
    sta npts
    stx adr+0
    sty adr+1
    lda #LO(TEMP_ADDR)
    sta odr+0
    lda #HI(TEMP_ADDR)
    sta odr+1
    
    ; *3
    lda npts
    clc
    adc npts
    adc npts
    tay
    dey


    ; copy points to spare memory
    .copyloop
    lda (adr),y
    sta (odr),y
    dey
    bpl copyloop

    ; copy back de-interleaved
    lda #0
    sta rx
    lda npts
    sta ry    
    clc
    adc npts
    sta rz
    ldx npts
    .fixloop
    ldy #0:lda (odr),y:ldy rx:sta (adr),y
    ldy #1:lda (odr),y:ldy ry:sta (adr),y
    ldy #2:lda (odr),y:ldy rz:sta (adr),y
    inc rx:inc ry:inc rz
    lda odr+0
    clc
    adc #3
    sta odr+0
    lda odr+1
    adc #0
    sta odr+1
    dex
    bne fixloop
    rts
}

MACRO FIX_MODEL    model_data, vert_data, surfs_data
    lda model_data+0    ; npts
    clc
    adc #1
    ldx #LO(vert_data)
    ldy #HI(vert_data)
    jsr fix_verts

    lda model_data+2    ; nsurfs
    clc
    adc #1
    ldx #LO(surfs_data)
    ldy #HI(surfs_data)
    jsr fix_verts    
ENDMACRO

; use this macros for models with only vertex data (ie. no surfaces)
MACRO FIX_MODEL_VERTS    model_data, vert_data
    lda model_data+0    ; npts
    clc
    adc #1
    ldx #LO(vert_data)
    ldy #HI(vert_data)
    jsr fix_verts
ENDMACRO


; models comprise:
;   header
;   vertex data     - 3 bytes per vertex (x,y,z)
;   surface data    - 3 bytes per surface (v0,v1,v2), describe a CW triangle/plane of the surface
;   opposites data  - 1 byte per surface
;   lines data      - 8 bytes per surface, a 64-bit array of the lines rendered by each surface
;   linelist data   - 2 bytes per surface, the start and end vertex index for each line in the model 

MACRO MD_HEADER npts, nlines, nsurfs, maxvis
    EQUB npts-1
    EQUB nlines-1
    EQUB nsurfs-1
    EQUB maxvis
ENDMACRO    

; store a signed X,Y,Z vertex, scaled by 'scale' 
; stored in 8 bits unsigned format
MACRO MD_POINT x, y, z, scale
    EQUB INT(x * scale + 128)
    EQUB INT(y * scale + 128)
    EQUB INT(z * scale + 128)
ENDMACRO



; store the first three indices of vertices that describe
; a surface.
; presented in clockwise orientation
; if rendered CCW they are considered hidden 
MACRO MD_SURF  p0, p1, p2
    EQUB p0
    EQUB p1
    EQUB p2
ENDMACRO


; opposites array describes any surfaces that are opposite to the current surface
; in this way they can be eliminated without extra clockwisetest's
; stored as a 16-bit bitfield, where #bit is set for the opposite surface id
MACRO MD_OPP    opps
    IF opps > &7f
        EQUW 0
    ELSE
; sdm: some shapes use opps ids > 15 which is larger than 16bit
        A = 2^ opps
        EQUB LO(A)
        EQUB HI(A)
    ENDIF
ENDMACRO

; declare lines that are rendered for a given surface
; stored as 64-bit array (8 bytes)
; each bit in the array corresponds to an MD_LINE object
; There must be one MD_LINE declared for each MD_SURF
MACRO MD_LINE   p0, p1
    EQUD    p1
    EQUD    p0
ENDMACRO


; add a line to the linelist for the model
; where p0 and p1 are the two vertex indices for the line
MACRO MD_INDEX  p0, p1
    EQUB p0
    EQUB p1
ENDMACRO





;----------------------------------------------------------------------------------------------------------
; Reset to the first model, then fall into the load model data routine
;----------------------------------------------------------------------------------------------------------

.reset_model 
{
    lda #0:sta transx:sta transy:sta transz
    ldx #coordinates_start AND &FF
    ldy #coordinates_start DIV 256
    ; falls through to select_model
}

;----------------------------------------------------------------------------------------------------------
; Select a model by providing its memory location
;----------------------------------------------------------------------------------------------------------
; on entry
; X/Y point to address of the model (lsb/msb)
.select_model
{
    stx odr
    sty odr+1
    ; falls through to load_next_model    
}

;----------------------------------------------------------------------------------------------------------
; Load model data
; Sets up variables and address pointers for the next model in the model data array
;----------------------------------------------------------------------------------------------------------

.load_next_model
{
    ; initialise all surfaces to hidden
    LDA#&FF:STA oldsurfs:STA oldsurfs+1

    LDY#0
    LDA(odr),Y
    ; if first byte of model data is 255 we have reached
    ; end of model list, so reset to the beginnning
    BMI reset_model
    
    ; otherwise capture model data
    STA npts:INY
    LDA(odr),Y:STA nlines:INY
    LDA(odr),Y:STA nsurfs:INY
    LDA(odr),Y:STA maxvis

    ; setup transform routine to load vertices from this model
    LDA odr:SEC:ADC#3:STA odr:STA x+1
    LDA odr+1:ADC#0:STA odr+1:STA x+2
    LDA odr:SEC:ADC npts:STA odr:STA y+1
    LDA odr+1:ADC#0:STA odr+1:STA y+2
    LDA odr:SEC:ADC npts:STA odr:STA z+1
    LDA odr+1:ADC#0:STA odr+1:STA z+2

    ; if num surfs is 0 then we only have verts so exit
    ; DO NOT CALL HIDDEN SURFACE OR OTHER SURFACE BASED MODEL RENDERING ROUTINES IN THIS SCENARIO
    ; only the transform routines are valid
    lda nsurfs
    bne has_surfaces
    rts

.has_surfaces

    ; setup clockwisetest routine 
    ; - load ptrs to surfaces for this model 

    ; store ptr to surfaces p0
    LDA odr:SEC:ADC npts:STA odr:STA clock0+1
    LDA odr+1:ADC#0:STA odr+1:STA clock0+2
    ; store ptr to surfaces p1
    LDA odr:SEC:ADC nsurfs:STA odr:STA clock1+1
    LDA odr+1:ADC#0:STA odr+1:STA clock1+2
    ; store ptr to surfaces p2
    LDA odr:SEC:ADC nsurfs:STA odr:STA clock2+1
    LDA odr+1:ADC#0:STA odr+1:STA clock2+2

    ; setup hiddensurfaceremoval routine
    ; - load ptrs to opposites data array for this model
    LDA odr:SEC:ADC nsurfs:STA odr:STA opposite0+1:STA opposite1+1:STA opposite2+1:STA opposite3+1
    LDA odr+1:ADC#0:STA odr+1:STA opposite0+2:STA opposite1+2:STA opposite2+2:STA opposite3+2

    ; setup lines address (ZP) to point to the lines array for this model
    LDA odr:SEC:ADC nsurfs:STA odr
    LDA odr+1:ADC#0:STA odr+1
    LDA odr:SEC:ADC nsurfs:STA odr:STA lines
    LDA odr+1:ADC#0:STA odr+1:STA lines+1
    
    ; setup the drawlines routine 
    ; - load ptr to the vertex indices for this model
    LDY#7
    .loopE
    LDA odr:SEC:ADC nsurfs:STA odr
    LDA odr+1:ADC#0:STA odr+1
    DEY:BPL loopE
    LDA odr:STA linestarts+1:SEC:ADC nlines:STA odr:STA lineends+1
    LDA odr+1:STA linestarts+2:ADC#0:STA odr+1:STA lineends+2
    LDA odr:SEC:ADC nlines:STA odr
    LDA odr+1:ADC#0:STA odr+1
    RTS
}

; set the linedraw routine for the model_draw routine
; on entry X/Y contain the routine address lsb/msb
.model_set_linedraw
{
    stx linedraw_call+1
    sty linedraw_call+2
    rts
}

;----------------------------------------------------------------------------------------------------------
; present the list of visible lines for the current model to the line renderer
;----------------------------------------------------------------------------------------------------------
; inputs -
;   line[] contains 64-bit array of visible lines to be rendered
;   linestarts - points to the current models line indices array (p0)
;   lineends - points to the current models line indices array (p1)
;   (linestarts & lineends addresses are set by the 'load_next_model' routine)
;----------------------------------------------------------------------------------------------------------
; for each linestart and lineend vertex index (p0,p1) the routine fetches the transformed 2D screen coordinate
; and submits these coordinates to the line renderer.
; 2D screen coordinates are cached, so they are only ever transformed once, even if referenced by multiple lines
;----------------------------------------------------------------------------------------------------------


IF WIREFRAME
.model_draw

    ; index of current line in the line list for this model
    LDA#0:STA lhs+1
    ; number of lines in the line list for this model
    LDA nlines:STA lhs

    ; for each line in the linelist
    ;  fetch low bit of the 64 bit line[] array to determine
    ;   its visibility, draw only if marked as visible
    .loopD
    LSR line+7
    ROR line+6
    ROR line+5
    ROR line+4
    ROR line+3
    ROR line+2
    ROR line+1
    ROR line
    BCC nolineD

    ; get the current line index
    LDY lhs+1

    ; linestarts and lineends are setup when model first loaded
    ; they point to the line list buffer
    .linestarts LDA &8000,Y:PHA
    .lineends LDA &8000,Y:TAX
    ; fetch screen coords for vertex linelist[1]
    JSR getcoordinates
    STA x0:STY y0
    PLA:TAX
    ; fetch screen coords for vertex linelist[0]
    JSR getcoordinates
    STA x1:STY y1

    ; render the line from x0,y0 to x1,y1
.linedraw_call
    JSR linedraw

    .nolineD
    INC lhs+1   ; next line in list
    DEC lhs     ; for each line in list
    BPL loopD
    RTS

ELSE

; in fill mode, the line bit array contains 2 bits per line.
; so a maximum of 32 lines for filled objects. (non filled have 64 lines)
.model_draw

    LDA#0:STA lhs+1
    LDA nlines:STA lhs
    .loopD
    ; two bits per pixel for each line, to indicate colour. 
    LDA line:AND #3:BEQ nolineD:PHA
    LDY lhs+1
    .linestarts LDA &8000,Y:PHA
    .lineends LDA &8000,Y:TAX
    JSR getcoordinates
    STA x0:STY y0
    PLA:TAX
    JSR getcoordinates
    STA x1:STY y1
    PLA:TAX ; line colour in X

.linedraw_call    
    JSR linedraw
    .nolineD
    ; shift two bits per pixel rather than one
    LSR line+7
    ROR line+6
    ROR line+5
    ROR line+4
    ROR line+3
    ROR line+2
    ROR line+1
    ROR line
    LSR line+7
    ROR line+6
    ROR line+5
    ROR line+4
    ROR line+3
    ROR line+2
    ROR line+1
    ROR line
    INC lhs+1:DEC lhs:BPL loopD
    RTS
ENDIF