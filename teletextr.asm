


;----------------------------------------------------------------------------------------------------------
; Build defines
;----------------------------------------------------------------------------------------------------------
DEBUG = TRUE
_ABUG = FALSE
_HEADER = TRUE  ; teletext header is visible, so adjust line offsets +1 in effects
USE_SHADOW_RAM = TRUE




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




\ ******************************************************************
\ *	Code
\ ******************************************************************


; Master 128 PAGE is &0E00 since MOS uses  memory is available from 
ORG &0E00
SCRATCH_RAM_ADDR = *

; 0E00 - &11FF is a 1Kb buffer 
; used by disksys and filesys as scratch RAM
; also used by 3d model system as scratch RAM
; also used as an offscreen draw buffer
SKIP 1024


ORG &1200 ; setting the load address here means it can load & boot on a non-Master 128 (but will quickly exit if not a master).

; new guard position of &3000 which is where shadow ram begins
; we cannot put code into video ram address range if we are to use shadow ram
GUARD &3000

.start




;----------------------------------------------------------------------------------------------------------
; Common code
;----------------------------------------------------------------------------------------------------------
; Include common code used by effects here...
.start_lib


ALIGN 256
WIREFRAME=TRUE
MODE7=TRUE


INCLUDE "lib/mode7_graphics.asm"
INCLUDE "lib/mode7_plot_pixel.asm"
INCLUDE "lib/mode7_sprites.asm"
INCLUDE "lib/mode7_gif_anim.asm"




INCLUDE "lib/shadowram.asm"
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

INCLUDE "src/fx/noise.asm"








.end_fx_code



.end



SAVE "Teletxr", start, end, main


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

IF TRUE
; included first to ensure page alignment
FX_3DCODE_SLOT = 0
.graphics_3d_start
INCLUDE "lib/3d/fastmultiply.asm"
INCLUDE "lib/3d/sincos.asm"
INCLUDE "lib/3d/maths.asm"
INCLUDE "lib/3d/culling.asm"
INCLUDE "lib/3d/zsort.asm"
INCLUDE "lib/3d/model.asm"
INCLUDE "lib/bresenham.asm"
.graphics_3d_end


; All of the following effects make use of the 3d & bresenham routines which are now in SWR

;----------------------------------------------------------------------------------------------------------
FX_VECTORBALLS_SLOT = 0
INCLUDE "src/fx/vectorballs.asm"

;----------------------------------------------------------------------------------------------------------
FX_3DSHAPE_SLOT = 0
INCLUDE "src/fx/3dshape.asm"

;----------------------------------------------------------------------------------------------------------
FX_LINEBOX_SLOT = 0
INCLUDE "src/fx/linebox.asm"

;----------------------------------------------------------------------------------------------------------
FX_VECTORTEXT_SLOT = 0
INCLUDE "src/fx/vectortext.asm"
ENDIF

;----------------------------------------------------------------------------------------------------------
FX_ROTOZOOM_SLOT = 0
.start_fx_rotozoom
INCLUDE "src/fx/rotozoom.asm"
INCLUDE "src/fx/rotozoom1.asm"
INCLUDE "src/fx/rotozoom2.asm"
INCLUDE "src/fx/rotozoom3.asm"
.end_fx_rotozoom


;----------------------------------------------------------------------------------------------------------
IF MUSIC_SHADOW == FALSE
.music_en
    ; hack demo to temporarily use small music track to free up 16Kb SWR bank, and put music in main RAM instead
    IF FALSE
        MUSIC_EN_SLOT = 0
        INCBIN "data/music_en.raw.exo" ; 16362 bytes
    ELSE
        MUSIC_EN_SLOT = 0
        INCBIN "data/music_reg.raw.exo"         ; 1548
    ENDIF
ENDIF





.bank0_end
SAVE "Bank0", bank0_start, bank0_end, &8000


;----------------------------------------------------------------------------------------------------------
; SWR Bank 1
;----------------------------------------------------------------------------------------------------------

CLEAR &8000, &BFFF
ORG &8000
GUARD &BFFF
.bank1_start

IF MUSIC_SHADOW == FALSE
    MUSIC_REG_SLOT = 1
    .music_reg
    INCBIN "data/music_reg.raw.exo"         ; 1548

    MUSIC_EXCEPTION_SLOT = 1
    .music_exception
    INCBIN "data/music_exception.raw.exo"   ; 4297 
ENDIF

;...

;----------------------------------------------------------------------------------------------------------
; common overlay effects
;----------------------------------------------------------------------------------------------------------

FX_MIRRORFLOOR_SLOT = 1
INCLUDE "src/fx/mirrorfloor.asm"



FX_GREENSCREEN_SLOT = 1
INCLUDE "src/fx/greenscreen.asm"
FX_COPPERBARS_SLOT = 1
INCLUDE "src/fx/copperbars.asm"

FX_RASTERBARS_SLOT = 1
INCLUDE "src/fx/rasterbars.asm"
FX_STARFIELD_SLOT = 1
INCLUDE "src/fx/starfield.asm"



;----------------------------------------------------------------------------------------------------------
; Dot scroller
FX_DOTSCROLLER_SLOT = 1
INCLUDE "src/fx/dotscroller.asm"

;----------------------------------------------------------------------------------------------------------
; Teletext effect
FX_TELETEXT_SLOT = 1
INCLUDE "src/fx/teletext.asm"


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

;----------------------------------------------------------------------------------------------------------
; Particle system
FX_PARTICLES_SLOT = 2
INCLUDE "src/fx/particles.asm"

;----------------------------------------------------------------------------------------------------------
; Credit scroller
FX_CREDITSCROLL_SLOT = 2
INCLUDE "src/fx/creditscroll.asm"




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
FX_PLASMA_SLOT = 3
INCLUDE "src/fx/plasma.asm"



;----------------------------------------------------------------------------------------------------------
FX_TESTCARD_SLOT = 3
INCLUDE "src/fx/testcard.asm"


.bank3_end
SAVE "Bank3", bank3_start, bank3_end, &8000



;----------------------------------------------------------------------------------------------------------
; Shadow Bank 0 (20Kb) Main
;----------------------------------------------------------------------------------------------------------

CLEAR &3000, &7BFF
ORG &3000
GUARD &7BFF
.shadow_bank0_start


MUSIC_EN_SLOT_S = SELECT_RAM_MAIN
.music_en_s
INCBIN "data/music_en.raw.exo" ; 16362 bytes


MUSIC_REG_SLOT_S = SELECT_RAM_MAIN
.music_reg_s
INCBIN "data/music_reg.raw.exo"         ; 1548



.shadow_bank0_end
SAVE "SBank0", shadow_bank0_start, shadow_bank0_end, &3000


;----------------------------------------------------------------------------------------------------------
; Shadow Bank 1 (20Kb)
;----------------------------------------------------------------------------------------------------------

CLEAR &3000, &7BFF
ORG &3000
GUARD &7BFF
.shadow_bank1_start

MUSIC_EXCEPTION_SLOT_S = SELECT_RAM_SHADOW
.music_exception_s
INCBIN "data/music_exception.raw.exo"   ; 4297 

.shadow_bank1_end
SAVE "SBank1", shadow_bank1_start, shadow_bank1_end, &3000


; Another 8Kb bank for &C000-&DFFF ?
; Another 4Kb bank for &8000-&8FFF ?


;----------------------------------------------------------------------------------------------------------
; Effect stats
;----------------------------------------------------------------------------------------------------------
PRINT "------------------------------------------------------------"
PRINT "Demo Sequence data from", ~demo_script_start, "to", ~demo_script_end, ", size is", (demo_script_end-demo_script_start), "bytes"
PRINT " fx_code size is", (end_fx_code-start_fx_code), "bytes"
PRINT "Main RAM effects:"

PRINT "SW RAM effects:"
PRINT " fx_teletext size is", (end_fx_teletext-start_fx_teletext), "bytes"
PRINT " fx_vectortext size is", (end_fx_vectortext-start_fx_vectortext), "bytes"
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
PRINT " fx_particles size is", (end_fx_particles-start_fx_particles), "bytes"
PRINT " fx_starfield size is", (end_fx_starfield-start_fx_starfield), "bytes"
PRINT " fx_creditscroll size is", (end_fx_creditscroll-start_fx_creditscroll), "bytes"
PRINT " fx_dotscroller size is", (end_fx_dotscroller-start_fx_dotscroller), "bytes"


PRINT "------------------------------------------------------------"

PRINT " mode7_graphics.asm lib size is", (mode7_graphics_end-mode7_graphics_start), "bytes"
PRINT " graphics_3d lib size is ", (graphics_3d_end-graphics_3d_start), "bytes" 
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
PRINT ""
PRINT "Shadow Bank0 from", ~shadow_bank0_start, "to", ~shadow_bank0_end, ", free mem is", 19456-(shadow_bank0_end-shadow_bank0_start), "bytes"
PRINT "Shadow Bank1 from", ~shadow_bank1_start, "to", ~shadow_bank1_end, ", free mem is", 19456-(shadow_bank1_end-shadow_bank1_start), "bytes"
PRINT ""
PRINT "Code space remaining", &3000-end, "bytes"


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


; need to free up 10Kb in main RAM.

; move 3d stuff into one SWR bank0

; 3d routines
; fx_vectorballs
; fx_linebox
; fx_3dshape
; fx_vectortext