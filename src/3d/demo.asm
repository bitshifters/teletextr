
WIREFRAME=TRUE
MODE7=TRUE

ORG &70
GUARD &9f

; effect code header
INCLUDE "src/3d/code.h.asm"

ORG 0
GUARD &6f

; common code
INCLUDE "lib/bbc_utils.h.asm"

IF MODE7
INCLUDE "lib/mode7_graphics.h.asm"
INCLUDE "lib/mode7_plot_pixel.h.asm"
INCLUDE "lib/bresenham.h.asm"
ENDIF

INCLUDE "lib/3d/3d.h.asm"





ORG &1400

.start

ALIGN 256
; included first to ensure page alignment
INCLUDE "lib/3d/fastmultiply.asm"
INCLUDE "lib/3d/sincos.asm"
INCLUDE "lib/3d/maths.asm"






;----------------------------------------------------------------------------------------------------------
; Common Code
;----------------------------------------------------------------------------------------------------------

; the following modules contain WIREFRAME conditional code, so cannot be earlier in the file without changing execution address
INCLUDE "lib/3d/culling.asm"

IF MODE7
INCLUDE "lib/mode7_graphics.asm"
INCLUDE "lib/mode7_plot_pixel.asm"
INCLUDE "lib/bresenham.asm"


ELSE


IF WIREFRAME
    INCLUDE "lib/3d/linedraw4.asm"
ELSE
    INCLUDE "lib/3d/linedraw5f.asm"
ENDIF

INCLUDE "lib/3d/renderer.asm"

ENDIF


INCLUDE "lib/3d/model.asm"




;----------------------------------------------------------------------------------------------------------
; Data
;----------------------------------------------------------------------------------------------------------

INCLUDE "src/3d/data.asm"

;----------------------------------------------------------------------------------------------------------
; effect code source
;----------------------------------------------------------------------------------------------------------
.code
INCLUDE "src/3d/code.asm"

.entry
{
    lda code+0:sta init+1
    lda code+1:sta init+2
    lda code+2:sta loop+1
    lda code+3:sta loop+2

.init JSR &ffff        ; init
.loop JSR &ffff      ; update

IF FALSE
    lda #0
    sta x0:sta y0
    lda #250
    sta x1:sta y1
    jsr linedraw
ENDIF

    JMP loop           ; 
}

.end

PRINT "Code from", ~start, "to", ~end, ", size is", (end-start), "bytes"
PRINT " Trig table data size is ", trigtable_end-trigtable_start, " bytes"

SAVE "Main", start, end, entry