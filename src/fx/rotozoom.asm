; cheezy & dog-slow rotozoom effect





; source texture size (pow of two)
; makes no difference to performance what size it is, just memory
TEXTURE_SIZE_BITS = 5
TEXTURE_SIZE = 2^TEXTURE_SIZE_BITS

; rendered image size
CANVAS_SIZE = 32
CANVAS_OFFS = 0

CANVAS_W = 32

IF _HEADER
CANVAS_ADDR = &7c03+40
CANVAS_H = 24
ELSE
CANVAS_ADDR = &7c03
CANVAS_H = 25
ENDIF

; 8 bits of fraction is useful enough, means that high byte is the integer part of the texture coordinate 
PRECISION_BITS = 8
ONE = 2^PRECISION_BITS
TWO = ONE*2
HALF = ONE/2

; hacky sin/cos table - ideally should re-use some other sin table
.rz_sinus_lo
    FOR n,0,256+64-1
        EQUB LO(SIN(n*(2*PI/256))*ONE)
    NEXT
.rz_sinus_hi
    FOR n,0,256+64-1
        EQUB HI(SIN(n*(2*PI/256))*ONE)
    NEXT
    
MACRO ADDOFFSET    src,offset,dst
    lda src+0:clc:adc offset+0:sta dst+0:lda src+1:adc offset+1:sta dst+1    
ENDMACRO
MACRO SUBOFFSET    src,offset,dst
    lda src+0:sec:sbc offset+0:sta dst+0:lda src+1:sbc offset+1:sta dst+1    
ENDMACRO


MACRO LOADTEXTUREADDRT   xreg,yreg,addr,ytable
   ; bits 8-15 are the integer part of the coordinate
    ; convert u coord to x index
    lda xreg+1
    and #TEXTURE_SIZE-1
    sta rz_tx

    ; convert v coord to read address
    lda yreg+1
    and #TEXTURE_SIZE-1
    tay ; y contains v coord (0-TEXTURE_SIZE-1)
    lda fx_texture_ytab_lo,y
    clc
    adc rz_tx
    sta addr+1
    lda ytable,y
;    adc #0  ; dont think this is needed since texture rows are pow2 aligned and width==height
    sta addr+2
ENDMACRO


MACRO LOADTEXTUREADDR   xreg,yreg,addr
    LOADTEXTUREADDRT xreg,yreg,addr,fx_texture_ytab_hi
ENDMACRO




; hacky checkerboard texture
ALIGN 256   ; align to page so theres no lsb element
.fx_texture
{
    FOR y,0,TEXTURE_SIZE-1
        FOR x,0,TEXTURE_SIZE-1
 ;       PRINT x
            EQUB (((x AND (TEXTURE_SIZE/2)) EOR (y AND (TEXTURE_SIZE/2)))/(TEXTURE_SIZE/2))*255
        NEXT
    NEXT
}

; texture line lookup offset table
.fx_texture_ytab_lo
{
    FOR n,0,TEXTURE_SIZE-1
 ;       PRINT n
        EQUB LO(TEXTURE_SIZE*n)
    NEXT
}
; high byte incorporates MSB of texture address
.fx_texture_ytab_hi
{
    FOR n,0,TEXTURE_SIZE-1
        EQUB HI(TEXTURE_SIZE*n) + HI(fx_texture)
    NEXT
}



; animation values
.xoff EQUW 0
.yoff EQUW 0
.zrot EQUB 0



rz_px = rz_px0
rz_py = rz_py0

; [ 1][ 2] + 160
; [ 4][ 8]
; [16][64]

; [0][3]
; [1][4]
; [2][5]
