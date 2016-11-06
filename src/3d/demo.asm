
WIREFRAME=TRUE


ORG 0

; effect code header
INCLUDE "src/3d/code.h.asm"

; common code
INCLUDE "lib/bbc_utils.h.asm"
INCLUDE "lib/mode7_graphics.h.asm"
INCLUDE "lib/mode7_plot_pixel.h.asm"
INCLUDE "lib/bresenham.h.asm"

INCLUDE "lib/3d/3d.h.asm"





ORG &2000

.start

ALIGN 256
; included first to ensure page alignment
INCLUDE "lib/3d/fastmultiply.asm"
INCLUDE "lib/3d/maths.asm"




;----------------------------------------------------------------------------------------------------------
; Includes
;----------------------------------------------------------------------------------------------------------

; the following modules contain WIREFRAME conditional code, so cannot be earlier in the file without changing execution address
INCLUDE "lib/3d/culling.asm"


IF WIREFRAME
    INCLUDE "lib/3d/linedraw4.asm"
ELSE
    INCLUDE "lib/3d/linedraw5f.asm"
ENDIF

INCLUDE "lib/3d/renderer.asm"

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
    JSR code        ; init
.loop
    JSR code+2      ; update
    JMP loop           ; 
}

.end

PRINT "Code from", ~start, "to", ~end, ", size is", (end-start), "bytes"
PRINT " Trig table data size is ", trigtable_end-trigtable_start, " bytes"

SAVE "Main", start, end, entry