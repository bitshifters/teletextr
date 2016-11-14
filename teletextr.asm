
\ ******************************************************************
\ *	Headers
\ ******************************************************************
DEBUG=TRUE

; Allocate vars in ZP
.zp_start
ORG 0
GUARD &8f

;----------------------------------------------------------------------------------------------------------
; Common global defines
;----------------------------------------------------------------------------------------------------------
INCLUDE "lib/bbc.h.asm"
INCLUDE "lib/bbc_utils.h.asm"

;----------------------------------------------------------------------------------------------------------
; Common code headers
;----------------------------------------------------------------------------------------------------------
; Include common code headers here - these can declare ZP vars from the pool using SKIP...

INCLUDE "lib/exomiser.h.asm"


INCLUDE "lib/mode7_graphics.h.asm"
INCLUDE "lib/mode7_plot_pixel.h.asm"
INCLUDE "lib/bresenham.h.asm"

INCLUDE "lib/3d/3d.h.asm"
INCLUDE "src/main.h.asm"

.zp_end


;----------------------------------------------------------------------------------------------------------
; Effect code headers
;----------------------------------------------------------------------------------------------------------



\ ******************************************************************
\ *	Code
\ ******************************************************************

ORG &1100


.start

;----------------------------------------------------------------------------------------------------------
; Common code
;----------------------------------------------------------------------------------------------------------
; Include common code used by effects here...

INCLUDE "lib/print.asm"
INCLUDE "lib/exomiser.asm"
INCLUDE "lib/vgmplayer.h.asm"
INCLUDE "lib/vgmplayer.asm"
INCLUDE "lib/swr.asm"
INCLUDE "lib/filesys.asm"
INCLUDE "lib/irq.asm"

ALIGN 256
WIREFRAME=TRUE
MODE7=TRUE
; included first to ensure page alignment
INCLUDE "lib/3d/fastmultiply.asm"
INCLUDE "lib/3d/sincos.asm"
INCLUDE "lib/3d/maths.asm"
INCLUDE "lib/3d/culling.asm"

INCLUDE "lib/mode7_graphics.asm"
INCLUDE "lib/mode7_plot_pixel.asm"
INCLUDE "lib/bresenham.asm"



INCLUDE "lib/3d/model.asm"

;----------------------------------------------------------------------------------------------------------
; demo config
;----------------------------------------------------------------------------------------------------------
INCLUDE "src/sequencer.asm"
INCLUDE "src/config.asm"

;----------------------------------------------------------------------------------------------------------
; Effect code
;----------------------------------------------------------------------------------------------------------
; Include your effects here...



INCLUDE "src/3d/data.asm"	; should be in a bank

INCLUDE "src/effects/3dshape.asm"
INCLUDE "src/effects/copybuffer.asm"
INCLUDE "src/effects/greenscreen.asm"
INCLUDE "src/effects/copperbars.asm"
INCLUDE "src/effects/linebox.asm"
INCLUDE "src/effects/bitmap.asm"

\ ******************************************************************
\ *	Code entry
\ ******************************************************************

INCLUDE "src/main.asm"

.end



SAVE "Main", start, end, main


\ ******************************************************************
\ *	Data
\ ******************************************************************

;----------------------------------------------------------------------------------------------------------
; SWR Bank 0
;----------------------------------------------------------------------------------------------------------

CLEAR &8000, &BFFF
ORG &8000
GUARD &BFFF
.bank0_start
INCBIN "src/music/data/music.raw.exo" 
.bank0_end
SAVE "Bank0", bank0_start, bank0_end, &8000


;----------------------------------------------------------------------------------------------------------
; SWR Bank 1
;----------------------------------------------------------------------------------------------------------

CLEAR &8000, &BFFF
ORG &8000
GUARD &BFFF
.bank1_start
;...
.bank1_end

;----------------------------------------------------------------------------------------------------------
; SWR Bank 2
;----------------------------------------------------------------------------------------------------------

CLEAR &8000, &BFFF
ORG &8000
GUARD &BFFF
.bank2_start
;...
.bank2_end

;----------------------------------------------------------------------------------------------------------
; SWR Bank 3
;----------------------------------------------------------------------------------------------------------

CLEAR &8000, &BFFF
ORG &8000
GUARD &BFFF
.bank3_start
;...
.bank3_end

PRINT "ZeroPage from", ~zp_start, "to", ~zp_end, ", size is", (zp_end-zp_start), "bytes"
PRINT "Code from", ~start, "to", ~end, ", size is", (end-start), "bytes"

PRINT "Build successful."