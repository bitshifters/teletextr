


;----------------------------------------------------------------------------------------------------------
; Build defines
;----------------------------------------------------------------------------------------------------------
DEBUG = TRUE
_ABUG = FALSE






\ ******************************************************************
\ *	Headers
\ ******************************************************************


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
.start_lib


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


INCLUDE "lib/print.asm"
INCLUDE "lib/exomiser.asm"
INCLUDE "lib/vgmplayer.h.asm"
INCLUDE "lib/vgmplayer.asm"
INCLUDE "lib/swr.asm"
INCLUDE "lib/filesys.asm"
INCLUDE "lib/irq.asm"
INCLUDE "lib/vram.asm"
INCLUDE "lib/disksys.asm"

;----------------------------------------------------------------------------------------------------------
; demo config
;----------------------------------------------------------------------------------------------------------


INCLUDE "src/script.asm"
INCLUDE "src/config.asm"


\ ******************************************************************
\ *	Code entry
\ ******************************************************************

INCLUDE "src/main.asm"

.end_lib

;----------------------------------------------------------------------------------------------------------
; Effect code
;----------------------------------------------------------------------------------------------------------
; Include your effects here...



.start_fx_code

INCLUDE "src/fx/music.asm"
INCLUDE "src/fx/copybuffer.asm"


; SM: these two dont work in SWR for some reason? No font data coming thru...
;----------------------------------------------------------------------------------------------------------
FX_CREDITSCROLL_SLOT = -1

INCLUDE "src/fx/creditscroll.asm"

;----------------------------------------------------------------------------------------------------------
FX_DOTSCROLLER_SLOT = -1
INCLUDE "src/fx/dotscroller.asm"


;----------------------------------------------------------------------------------------------------------
FX_PARTICLES_SLOT = -1
INCLUDE "src/fx/particles.asm"


;----------------------------------------------------------------------------------------------------------
; Teletext effect
FX_TELETEXT_SLOT = -1
INCLUDE "src/fx/teletext.asm"

;----------------------------------------------------------------------------------------------------------
FX_VECTORTEXT_SLOT = -1
INCLUDE "src/fx/vectortext.asm"




.end_fx_code



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

MUSICA_SLOT_NO = 0
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

MUSICB_SLOT_NO = 1
.music_exception
INCBIN "data/music_exception.raw.exo"   ; 4297 
.music_reg
INCBIN "data/music_reg.raw.exo"         ; 1548
;...

;----------------------------------------------------------------------------------------------------------
; common overlay effects
;----------------------------------------------------------------------------------------------------------

FX_MIRRORFLOOR_SLOT = 1
INCLUDE "src/fx/mirrorfloor.asm"
FX_3DSHAPE_SLOT = 1
INCLUDE "src/fx/3dshape.asm"
FX_GREENSCREEN_SLOT = 1
INCLUDE "src/fx/greenscreen.asm"
FX_COPPERBARS_SLOT = 1
INCLUDE "src/fx/copperbars.asm"
FX_LINEBOX_SLOT = 1
INCLUDE "src/fx/linebox.asm"
FX_RASTERBARS_SLOT = 1
INCLUDE "src/fx/rasterbars.asm"



FX_ROTOZOOM_SLOT = 1
.start_fx_rotozoom
INCLUDE "src/fx/rotozoom.asm"
INCLUDE "src/fx/rotozoom1.asm"
INCLUDE "src/fx/rotozoom2.asm"
INCLUDE "src/fx/rotozoom3.asm"
.end_fx_rotozoom



.bank1_end
SAVE "Bank1", bank1_start, bank1_end, &8000

;----------------------------------------------------------------------------------------------------------
; SWR Bank 2
;----------------------------------------------------------------------------------------------------------

CLEAR &8000, &BFFF
ORG &8000
GUARD &BFFF
.bank2_start

;----------------------------------------------------------------------------------------------------------
; Interference effect

FX_INTERFERENCE_SLOT = 2
INCLUDE "src/fx/interference.asm"



.bank2_end
SAVE "Bank2", bank2_start, bank2_end, &8000
;----------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------------
; SWR Bank 3
;----------------------------------------------------------------------------------------------------------

CLEAR &8000, &BFFF
ORG &8000
GUARD &BFFF
.bank3_start

;----------------------------------------------------------------------------------------------------------
; GIF player effect data
FX_PLAYGIFS_SLOT = 3
INCLUDE "src/fx/playgifs.asm"

;----------------------------------------------------------------------------------------------------------
FX_VECTORBALLS_SLOT = 3
INCLUDE "src/fx/vectorballs.asm"

;----------------------------------------------------------------------------------------------------------
FX_PLASMA_SLOT = 3
INCLUDE "src/fx/plasma.asm"



;----------------------------------------------------------------------------------------------------------
FX_TESTCARD_SLOT = 3
INCLUDE "src/fx/testcard.asm"

.bank3_end
SAVE "Bank3", bank3_start, bank3_end, &8000


;----------------------------------------------------------------------------------------------------------
; Effect stats
;----------------------------------------------------------------------------------------------------------
PRINT "------------------------------------------------------------"
PRINT " fx_code size is", (end_fx_code-start_fx_code), "bytes"
PRINT "Main RAM effects:"
PRINT " fx_dotscroller size is", (end_fx_dotscroller-start_fx_dotscroller), "bytes"
PRINT " fx_creditscroll size is", (end_fx_creditscroll-start_fx_creditscroll), "bytes"
PRINT " fx_teletext size is", (end_fx_teletext-start_fx_teletext), "bytes"
PRINT " fx_vectortext size is", (end_fx_vectortext-start_fx_vectortext), "bytes"

PRINT "SW RAM effects:"
PRINT " fx_plasma size is", (end_fx_plasma-start_fx_plasma), "bytes"
PRINT " fx_vectorballs size is", (end_fx_vectorballs-start_fx_vectorballs), "bytes"
PRINT " fx_rotozoom size is", (end_fx_rotozoom-start_fx_rotozoom), "bytes"
PRINT " fx_interference size is", (end_fx_interference-start_fx_interference), "bytes"
PRINT " fx_playgifs size is", (end_fx_playgifs-start_fx_playgifs), "bytes"
PRINT " fx_testcard size is", (end_fx_testcard-start_fx_testcard), "bytes"
PRINT " fx_3dshape size is", (end_fx_3dshape-start_fx_3dshape), "bytes"
PRINT " fx_rasterbars size is", (end_fx_rasterbars-start_fx_rasterbars), "bytes"
PRINT " fx_mirrorfloor size is", (end_fx_mirrorfloor-start_fx_mirrorfloor), "bytes"
PRINT " fx_linebox size is", (end_fx_linebox-start_fx_linebox), "bytes"
PRINT " fx_copperbars size is", (end_fx_copperbars-start_fx_copperbars), "bytes"


PRINT "------------------------------------------------------------"

;----------------------------------------------------------------------------------------------------------
; Build stats
;----------------------------------------------------------------------------------------------------------
PRINT "ZeroPage from", ~zp_start, "to", ~zp_end, ", size is", (zp_end-zp_start), "bytes"
PRINT "Lib code from", ~start_lib, "to", ~end_lib, ", size is", (end_lib-start_lib), "bytes"
PRINT " FX code from", ~start_fx_code, "to", ~end_fx_code, ", size is", (end_fx_code-start_fx_code), "bytes"
PRINT "All code from", ~start, "to", ~end, ", size is", (end-start), "bytes"
PRINT "Bank0 from", ~bank0_start, "to", ~bank0_end, ", free mem is", 16384-(bank0_end-bank0_start), "bytes"
PRINT "Bank1 from", ~bank1_start, "to", ~bank1_end, ", free mem is", 16384-(bank1_end-bank1_start), "bytes"
PRINT "Bank2 from", ~bank2_start, "to", ~bank2_end, ", free mem is", 16384-(bank2_end-bank2_start), "bytes"
PRINT "Bank3 from", ~bank3_start, "to", ~bank3_end, ", free mem is", 16384-(bank3_end-bank3_start), "bytes"

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