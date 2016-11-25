ALIGN 256

SCREEN_OFFSET_X = 39 ;128
SCREEN_OFFSET_Y = 37
MAX_VERTS = 64

;----------------------------------------------------------------------------------------------------------
; screen space 3D perspective projection table
;----------------------------------------------------------------------------------------------------------
; 256 x 8-bit entries. Uses unsigned Z as a table index.
; [page aligned]
.perspective 
    d=&100
    oz=&80
    FOR Z%, -128, 127
        EQUB &FF*d/(d+oz+Z%)+.5
    NEXT 

;----------------------------------------------------------------------------------------------------------
; transformed vertex buffers (max 64 verts per model)
;----------------------------------------------------------------------------------------------------------

; array of bytes to indicate if vertex N has already been transformed in the current render frame
;  0=untransformed, 255=transformed 
.ptsdone SKIP MAX_VERTS

;----------------------------------------------------------------------------------------------------------
; screen space vertex coordinates, max 64 verts per model
;----------------------------------------------------------------------------------------------------------
; calculated by 'transform' routine
.sx SKIP MAX_VERTS
.sy SKIP MAX_VERTS
.sz SKIP MAX_VERTS



;----------------------------------------------------------------------------------------------------------
; clear/reset the transformed vertex buffer array
;----------------------------------------------------------------------------------------------------------
; called once per frame
; ptsdone contains 0 if vertex has not yet been transformed
; or 255 if vertex has been transformed
;----------------------------------------------------------------------------------------------------------
.newpoints
{
    LDA#0:LDX npts
    .loop4
    STA ptsdone,X
    DEX:BPL loop4
    RTS
}


;----------------------------------------------------------------------------------------------------------
; update model rotation angles
; shouldnt be in here.
;----------------------------------------------------------------------------------------------------------
.rotate
{
    INC rx
    INC ry:INC ry
    INC rz:INC rz:INC rz
    RTS
}

;----------------------------------------------------------------------------------------------------------
; fetch a 2D screen space transformed vertex coordinate
;----------------------------------------------------------------------------------------------------------
; input - X=vertex id to fetch
; output - A is screen space X coord, Y is screen space Y coord
;  X is preserved
; (transformed vertices are cached)
;----------------------------------------------------------------------------------------------------------
.getcoordinates
{
    LDA ptsdone,X:BNE transformed
    JSR transform
.transformed
    LDA sx,X
    LDY sy,X
    RTS
}

;----------------------------------------------------------------------------------------------------------
; fetch a 2D screen space transformed vertex coordinate, returned in X/Y 
; (transformed vertices are cached)
;----------------------------------------------------------------------------------------------------------

; where A is vertex id
; returns vertex X,Y in X,Y
.getcoordinatesXY
{
    TAX
    LDA ptsdone,X:BNE transformed
    JSR transform
.transformed
    LDA sy,X
    TAY
    LDA sx,X
    TAX
    RTS
}

;----------------------------------------------------------------------------------------------------------
; fetch a 2D screen space Z coordinate
; (transformed vertices are cached)
;----------------------------------------------------------------------------------------------------------
; On entry:
;  X contains vertex id
; On exit:
;  A contains screen z
;  X is preserved
.getscreenz
{
    LDA ptsdone,X:BNE transformed
    JSR transform
.transformed
    LDA sz,X
    RTS    
}


;----------------------------------------------------------------------------------------------------------
; table of addresses pointing to each address in the transform routine
;  that uses a coefficent of the 3x3 rotation matrix
;----------------------------------------------------------------------------------------------------------
; the 'matrix' routine uses this address table to load the computed
;  rotation matrix coefficients directly into the transform routine
;  for speed. (since transform is called multiple times per frame) 
;----------------------------------------------------------------------------------------------------------
.unitvectors
; offset 0 = lsb of each address
EQUB u00 AND &FF:EQUB u01 AND &FF:EQUB u02 AND &FF
EQUB u10 AND &FF:EQUB u11 AND &FF:EQUB u12 AND &FF
EQUB u20 AND &FF:EQUB u21 AND &FF:EQUB u22 AND &FF
; offset 9 = msb of each address
EQUB u00 DIV 256:EQUB u01 DIV 256:EQUB u02 DIV 256
EQUB u10 DIV 256:EQUB u11 DIV 256:EQUB u12 DIV 256
EQUB u20 DIV 256:EQUB u21 DIV 256:EQUB u22 DIV 256



;----------------------------------------------------------------------------------------------------------
; Apply 3D -> 2D perspective projection transform to given vertex id
;----------------------------------------------------------------------------------------------------------
; inputs - 
;          X is vertex index N (0-npts)
;          .x, .y, .z addresses preloaded with vertex buffer address for current model
;          .u00...u22 addresses preloaded with rotation matrix coefficients by 'matrix' routine
; output - 
;           A, sx[N] = screen X coord
;           Y, sy[N] = screen Y coord
;           ptsdone[N] = 255
;           X is preserved
;----------------------------------------------------------------------------------------------------------
; uses table lookups for all multiplies for speed

; prior to calling this routine, the following address setup modifications have been completed:
;    1 - the X/Y/Z vertex buffer address for the currently selected model has been applied to .x, .y, .z
;    2 - the unit vectors for the current rotation matrix has been applied to u00 ... u22 by the matrix routine

; Matrix * Vector
; V' = M * V
;
;	x' = x*a + y*b + z*c
;	y' = x*d + y*e + z*f
;	z' = x*g + y*h + z*i
; 
; 9 multiplies, 6 adds

; where M = [ a b c ]
;           [ d e f ]
;           [ g h i ]
; and   V = [ x y z ]
;----------------------------------------------------------------------------------------------------------

.transform

    ; mark this vertex as transformed, so that it will be cached if re-used
    LDA#&FF:STA ptsdone,X

    ; fetch & transform vertex X coord
    ; (vertex buffer address set by load_next_model)
    .x LDY &8000,X

    ; x' = x*a
    SEC:.u00
    LDA SQUARETABLE2_LSB,Y:SBC SQUARETABLE2_LSB,Y:STA xr
    LDA SQUARETABLE2_MSB,Y:SBC SQUARETABLE2_MSB,Y:STA xr+1

    ; y' = x*b
    SEC:.u10
    LDA SQUARETABLE2_LSB,Y:SBC SQUARETABLE2_LSB,Y:STA yr
    LDA SQUARETABLE2_MSB,Y:SBC SQUARETABLE2_MSB,Y:STA yr+1

    ; z' = x*c
    SEC:.u20
    LDA SQUARETABLE2_LSB,Y:SBC SQUARETABLE2_LSB,Y:STA zr
    LDA SQUARETABLE2_MSB,Y:SBC SQUARETABLE2_MSB,Y:STA zr+1

    ; fetch & transform vertex Y coord
    ; (vertex buffer address set by load_next_model)    
    .y LDY &8000,X

    ; x' += y*d
    SEC:.u01
    LDA SQUARETABLE2_LSB,Y:SBC SQUARETABLE2_LSB,Y:STA product
    LDA SQUARETABLE2_MSB,Y:SBC SQUARETABLE2_MSB,Y:STA product+1
    LDA product:CLC:ADC xr:STA xr
    LDA product+1:ADC xr+1:STA xr+1

    ; y' += y*e
    SEC:.u11
    LDA SQUARETABLE2_LSB,Y:SBC SQUARETABLE2_LSB,Y:STA product
    LDA SQUARETABLE2_MSB,Y:SBC SQUARETABLE2_MSB,Y:STA product+1
    LDA product:CLC:ADC yr:STA yr
    LDA product+1:ADC yr+1:STA yr+1

    ; z' += y*f
    SEC:.u21
    LDA SQUARETABLE2_LSB,Y:SBC SQUARETABLE2_LSB,Y:STA product
    LDA SQUARETABLE2_MSB,Y:SBC SQUARETABLE2_MSB,Y:STA product+1
    LDA product:CLC:ADC zr:STA zr
    LDA product+1:ADC zr+1:STA zr+1

    ; fetch & transform vertex Z coord
    ; (vertex buffer address set by load_next_model)    
    .z LDY &8000,X

    ; x' += z*g
    SEC:.u02
    LDA SQUARETABLE2_LSB,Y:SBC SQUARETABLE2_LSB,Y:STA product
    LDA SQUARETABLE2_MSB,Y:SBC SQUARETABLE2_MSB,Y:STA product+1
    LDA product:CLC:ADC xr:STA xr
    LDA product+1:ADC xr+1:STA xr+1

    ; y' += z*h
    SEC:.u12
    LDA SQUARETABLE2_LSB,Y:SBC SQUARETABLE2_LSB,Y:STA product
    LDA SQUARETABLE2_MSB,Y:SBC SQUARETABLE2_MSB,Y:STA product+1
    LDA product:CLC:ADC yr:STA yr
    LDA product+1:ADC yr+1:STA yr+1

    ; z' += z*i
    SEC:.u22
    LDA SQUARETABLE2_LSB,Y:SBC SQUARETABLE2_LSB,Y:STA product
    LDA SQUARETABLE2_MSB,Y:SBC SQUARETABLE2_MSB,Y:STA product+1
    LDA product:CLC:ADC zr:STA zr
    LDA product+1:ADC zr+1

    ; xr, yr, zr now contain the rotated vertex coordinate
    ; A contains the msb of the z coordinate

; translate
;    sta zr+1
 ;   lda xr+1:clc:adc transx:sta xr+1;:lda xr+1:adc#0:sta xr+1
  ;  lda yr+1:clc:adc transy:sta yr+1;:lda yr+1:adc#0:sta yr+1
   ; lda zr+1:clc:adc transz:sta zr+1;:lda zr+1:adc#0:sta zr+1


    ; now calculate screen space coordinates using perspective projection
    ASL zr:ROL A:ASL zr

    ROL A:ASL zr    ; SM: added an extra bit of z precision here; it improves z range & perspective 
    
    ADC#&80:TAY     ; convert to unsigned
    STA sz,X        ; store screen z (before perspective correction)
    
    CLC   
    LDA#&80:ADC perspective,Y:STA adr:STA adr+2

IF CONTIGUOUS_TABLES
    ; This routine assumes the square tables are contiguous in memory
    LDA#HI(SQUARETABLE2_LSB):ADC#0:STA adr+1
    ADC#3:STA adr+3 ; SQUARETABLE2_MSB
    CLC
    LDA adr:ADC#1:STA adr+4:STA adr+6
    CLC
    LDA adr+1:ADC#0:STA adr+5
    ADC#3:STA adr+7 ; SQUARETABLE2_MSB
ELSE
    LDA #0:ADC#0:STA adr+1:STA adr+3
    LDA adr:ADC#1:STA adr+4:STA adr+6
    LDA adr+1:ADC#0:STA adr+5:STA adr+7

    LDA#HI(SQUARETABLE2_LSB):CLC:ADC adr+1:STA adr+1
    LDA#HI(SQUARETABLE2_MSB):CLC:ADC adr+3:STA adr+3
    LDA#HI(SQUARETABLE2_LSB):CLC:ADC adr+5:STA adr+5
    LDA#HI(SQUARETABLE2_MSB):CLC:ADC adr+7:STA adr+7
ENDIF




    ; compute screen space Y coord
    LDA yr+1:ASL yr:ROL A:ASL yr
    ADC#&80:TAY:SEC:EOR #&FF:STY zr:STA zr+1
    LDA(adr),Y:LDY zr+1:SBC(adr+4),Y:STA yr
    LDY zr:LDA(adr+2),Y:LDY zr+1:SBC(adr+6),Y
    ASL yr:ADC#SCREEN_OFFSET_Y:STA sy,X

    ; compute screen space X coord
    LDA xr+1:ASL xr:ROL A:ASL xr
    ADC#&80:TAY:SEC:EOR #&FF:STY zr:STA zr+1
    LDA(adr),Y:LDY zr+1:SBC(adr+4),Y:STA xr
    LDY zr:LDA(adr+2),Y:LDY zr+1:SBC(adr+6),Y
    ASL xr:ADC#SCREEN_OFFSET_X:STA sx,X

    LDY sy,X
    ; A contains screen space X coord
    ; Y contains screen space Y coord
    RTS

;----------------------------------------------------------------------------------------------------------
; construct a standard 3D XYZ rotation matrix 
;----------------------------------------------------------------------------------------------------------
; inputs - rx,ry,rz contain rotation angles (8 bit precision)
; outputs - m00 ... m22 contain the rotation matrix (16-bits precision)
;         - this routine also updates the transform routine directly with the
;             computed matrix coefficients, which is a useful optimization
;             since transform is called multiple times when transforming the model vertices
;----------------------------------------------------------------------------------------------------------

.matrix
{
    ; rx, ry, rz are the input X/Y/Z unsigned 8-bit rotation angles, 0-255

    ; m12 = -sin(rx)
    LDY rx
    SEC
    LDA#0:SBC slsb,Y:STA m12lsb
    LDA#0:SBC smsb,Y:ASL m12lsb
    ROL A:ASL m12lsb:ROL A:STA m12msb

    ; X = rx-ry
    ; adr[3] = rx-ry+rz
    TYA:SEC:SBC ry:TAX
    CLC:ADC rz:STA adr+3
    ; Y = rx+ry
    ; adr[2] = rx+ry+rz    
    TYA:CLC:ADC ry:TAY
    CLC:ADC rz:STA adr+2
    
    ; m02 = sin(rx-ry)-sin(rx+ry) 
    SEC
    LDA slsb,X:SBC slsb,Y:STA m02lsb
    LDA smsb,X:SBC smsb,Y:ASL m02lsb
    ROL A:STA m02msb
    
    ; m22 = cos(rx+ry)-cos(rx-ry)
    CLC
    LDA clsb,Y:ADC clsb,X:STA m22lsb
    LDA cmsb,Y:ADC cmsb,X:ASL m22lsb
    ROL A:STA m22msb

    ; m10
    ; adr[4] = rx+ry-rz
    ; adr[5] = rx-ry-rz
    TYA:SEC:SBC rz:STA adr+4
    TXA:SEC:SBC rz:STA adr+5
    LDA rx:CLC:ADC rz:TAY
    LDA rx:SEC:SBC rz:TAX
    
    SEC
    LDA slsb,Y:SBC slsb,X:STA m10lsb
    LDA smsb,Y:SBC smsb,X:ASL m10lsb
    ROL A:STA m10msb
    
    ; m11
    CLC
    LDA clsb,X:ADC clsb,Y:STA m11lsb
    LDA cmsb,Y:ADC cmsb,X:ASL m11lsb
    ROL A:STA m11msb

    ; m21
    LDA ry:SEC:SBC rz:TAY
    LDA rz:CLC:ADC ry:TAX:SEC
    LDA clsb,X:SBC clsb,Y:STA m21lsb
    LDA cmsb,X:SBC cmsb,Y:ASL m21lsb
    ROL A:STA m21msb
    
    ; m01
    SEC
    LDA slsb,Y:SBC slsb,X:STA m01lsb
    LDA smsb,Y:SBC smsb,X:ASL m01lsb
    ROL A:STA m01msb
    
    ; m00
    CLC
    LDA clsb,Y:ADC clsb,X:STA m00lsb
    LDA cmsb,X:ADC cmsb,Y:ASL m00lsb
    ROL A:STA m00msb
    
    ; m20
    CLC
    LDA slsb,X:ADC slsb,Y:STA m20lsb
    LDA smsb,Y:ADC smsb,X:ASL m20lsb
    ROL A:STA m20msb

    ; Y=
    LDY adr+4:LDX adr+3
    
    SEC
    LDA m00lsb:SBC slsb,X:STA m00lsb
    LDA m00msb:SBC smsb,X:STA m00msb
    
    CLC
    LDA slsb,Y:ADC m21lsb:STA m21lsb
    LDA m21msb:ADC smsb,Y:STA m21msb
    
    CLC
    LDA clsb,Y:ADC m20lsb:STA m20lsb
    LDA cmsb,Y:ADC m20msb:STA m20msb
    
    SEC
    LDA m01lsb:SBC clsb,X:STA m01lsb
    LDA m01msb:SBC cmsb,X:STA m01msb
    
    CLC
    LDA clsb,Y:ADC m01lsb:STA m01lsb
    LDA cmsb,Y:ADC m01msb:STA m01msb
    
    CLC
    LDA m21lsb:ADC slsb,X:STA m21lsb
    LDA m21msb:ADC smsb,X:STA m21msb
    
    SEC
    LDA m20lsb:SBC clsb,X:STA m20lsb
    LDA m20msb:SBC cmsb,X:STA m20msb
    
    SEC
    LDA m00lsb:SBC slsb,Y:STA m00lsb
    LDA m00msb:SBC smsb,Y:STA m00msb

    LDX adr+5:LDY adr+2
    
    SEC
    LDA m20lsb:SBC clsb,Y:STA m20lsb
    LDA m20msb:SBC cmsb,Y:STA m20msb
    
    CLC
    LDA m00lsb:ADC slsb,X:STA m00lsb
    LDA m00msb:ADC smsb,X:STA m00msb
    
    CLC
    LDA m21lsb:ADC slsb,X:STA m21lsb
    LDA m21msb:ADC smsb,X:STA m21msb
    
    CLC
    LDA clsb,Y:ADC m01lsb:STA m01lsb
    LDA cmsb,Y:ADC m01msb:STA m01msb
    
    CLC
    LDA slsb,Y:ADC m21lsb:STA m21lsb
    LDA smsb,Y:ADC m21msb:STA m21msb
    
    CLC
    LDA slsb,Y:ADC m00lsb:STA m00lsb
    LDA smsb,Y:ADC m00msb:STA m00msb
    
    CLC
    LDA clsb,X:ADC m20lsb:STA m20lsb
    LDA cmsb,X:ADC m20msb:STA m20msb
    
    SEC
    LDA m01lsb:SBC clsb,X:STA m01lsb
    LDA m01msb:SBC cmsb,X:STA m01msb

    ; m00 ... m22 lsb & msb
    ; now contain the 3x3 rotation matrix elements

    ; next, 
    ; for each element of the 3x3 matrix;
    ;   transfer the rotation matrix coefficients directly
    ;   into each related part of the (vector * matrix) vertex transform routine 

    LDX#8
    .loop7
    ; fetch the transform routine coefficient address for the current element of the matrix
    ; [ u00, u01, u02 ]
    ; [ u10, u11, u12 ]
    ; [ u20, u21, u22 ]

    LDA unitvectors,X:STA adr       ; lsb
    LDA unitvectors+9,X:STA adr+1   ; msb

    ; get the high byte of the coefficent
    ; complement with high bit of low byte and convert from signed to unsigned (for lookup table access)
    LDA m00msb,X:ASL m00lsb,X:ADC#&80
    
    ; store sin table offset lsb's for this coefficient directly into the transform routine

    ; (+1 is lsb after LDA instruction)
    ; (+9 is lsb after SBC instruction)
    LDY#1:STA(adr),Y:LDY#9:STA(adr),Y
    
    ; A = -A (two's complement negate)
    CLC:EOR #&FF:ADC#1    

    ; (+4 is lsb after second LDA instruction)
    ; (+12 is lsb after second SBC instruction)
    LDY#4:STA(adr),Y:LDY#&C:STA(adr),Y
    
    DEX:BPL loop7
    RTS
}