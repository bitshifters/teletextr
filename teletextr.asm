
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
INCLUDE "lib/mode7_sprites.h.asm"
INCLUDE "lib/mode7_gif_anim.h.asm"
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
GUARD &7800

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
INCLUDE "lib/vram.asm"
INCLUDE "lib/disksys.asm"

ALIGN 256
WIREFRAME=TRUE
MODE7=TRUE
; included first to ensure page alignment
INCLUDE "lib/3d/fastmultiply.asm"
INCLUDE "lib/3d/sincos.asm"
INCLUDE "lib/3d/maths.asm"
INCLUDE "lib/3d/culling.asm"
INCLUDE "lib/3d/zsort.asm"


INCLUDE "lib/mode7_graphics.asm"
INCLUDE "lib/mode7_plot_pixel.asm"
INCLUDE "lib/mode7_sprites.asm"
INCLUDE "lib/mode7_gif_anim.asm"
INCLUDE "lib/bresenham.asm"



INCLUDE "lib/3d/model.asm"

;----------------------------------------------------------------------------------------------------------
; demo config
;----------------------------------------------------------------------------------------------------------
_ABUG = FALSE
_VECTORBALLS = FALSE    ; temp define just to free up some ram prior to SWR optimizations 
_VECTORTEXT = FALSE
_ROTOZOOM = FALSE

INCLUDE "src/script.asm"
INCLUDE "src/config.asm"

;----------------------------------------------------------------------------------------------------------
; Effect code
;----------------------------------------------------------------------------------------------------------
; Include your effects here...
INCLUDE "src/fx/music.asm"


INCLUDE "src/fx/data.asm"	; should be in a bank!!

INCLUDE "src/fx/3dshape.asm"
INCLUDE "src/fx/copybuffer.asm"
INCLUDE "src/fx/greenscreen.asm"
INCLUDE "src/fx/copperbars.asm"
INCLUDE "src/fx/linebox.asm"
INCLUDE "src/fx/plasma.asm"
INCLUDE "src/fx/testcard.asm"
INCLUDE "src/fx/teletext.asm"
INCLUDE "src/fx/rasterbars.asm"

IF _VECTORBALLS == TRUE
INCLUDE "src/fx/vectorballs.asm"
ENDIF

IF _ABUG==FALSE ; no ram for these with the ABUG demo enabled
IF _ROTOZOOM
INCLUDE "src/fx/rotozoom.asm"
INCLUDE "src/fx/rotozoom1.asm"
INCLUDE "src/fx/rotozoom2.asm"
INCLUDE "src/fx/rotozoom3.asm"
ENDIF
ENDIF

INCLUDE "src/fx/mirrorfloor.asm"
INCLUDE "src/fx/interference.asm"
INCLUDE "src/fx/creditscroll.asm"
INCLUDE "src/fx/dotscroller.asm"
INCLUDE "src/fx/playgifs.asm"

IF _VECTORTEXT == TRUE
INCLUDE "src/fx/vectortext.asm"
ENDIF

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
.music_en
INCBIN "data/music_en.raw.exo" ; 16362 bytes
.bank0_end
SAVE "Bank0", bank0_start, bank0_end, &8000


;----------------------------------------------------------------------------------------------------------
; SWR Bank 1
;----------------------------------------------------------------------------------------------------------

CLEAR &8000, &BFFF
ORG &8000
GUARD &BFFF
.bank1_start
.music_exception
INCBIN "data/music_exception.raw.exo"   ; 4297 
.music_reg
INCBIN "data/music_reg.raw.exo"         ; 1548
;...
.bank1_end
SAVE "Bank1", bank1_start, bank1_end, &8000

;----------------------------------------------------------------------------------------------------------
; SWR Bank 2
;----------------------------------------------------------------------------------------------------------

CLEAR &8000, &BFFF
ORG &8000
GUARD &BFFF
.bank2_start
INCLUDE "src\sprites\circles.asm"
.bank2_end
SAVE "Bank2", bank2_start, bank2_end, &8000

;----------------------------------------------------------------------------------------------------------
; SWR Bank 3
;----------------------------------------------------------------------------------------------------------

CLEAR &8000, &BFFF
ORG &8000
GUARD &BFFF
.bank3_start

.animated_gif_bird
INCBIN "data\gifs\bird_beeb.bin"
.animated_gif_weather
INCBIN "data\gifs\weather_beeb.bin"
.animated_gif_dancer
INCBIN "data\gifs\dancer_beeb.bin"
.animated_gif_blueblob
INCBIN "data\gifs\blueblob_beeb.bin"

.bank3_end
SAVE "Bank3", bank3_start, bank3_end, &8000

PRINT "ZeroPage from", ~zp_start, "to", ~zp_end, ", size is", (zp_end-zp_start), "bytes"
PRINT "Code from", ~start, "to", ~end, ", size is", (end-start), "bytes"
PRINT "Bank0 from", ~bank0_start, "to", ~bank0_end, ", size is", (bank0_end-bank0_start), "bytes"
PRINT "Bank1 from", ~bank1_start, "to", ~bank1_end, ", size is", (bank1_end-bank1_start), "bytes"
PRINT "Bank2 from", ~bank2_start, "to", ~bank2_end, ", size is", (bank2_end-bank2_start), "bytes"
PRINT "Bank3 from", ~bank3_start, "to", ~bank3_end, ", size is", (bank3_end-bank3_start), "bytes"

PRINT "Code space remaining", &7800-end, "bytes"


PUTFILE "data/pages/holdtest.txt.bin", "HOLD", &7C00
PUTFILE "data/pages/testpage.txt.bin", "TEST", &7C00
PUTFILE "data/pages/Channl4","Channl4", &7C00
PUTFILE "data/pages/owl","owl", &7C00
PUTFILE "data/pages/TESTPAGE","TESTPAG", &7C00
PUTFILE "data/pages/TVB","TVB", &7C00
PUTFILE "data/pages/TVGuide","TVGuide", &7C00
PUTFILE "data/pages/Yorks","Yorks", &7C00

PUTBASIC "src/fx/6845.txt", "6845"


PRINT "Build successful."