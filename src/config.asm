; Config script for the demo
; Makes things a bit more data driven and easier to fine tune

; Things to improve:
;   control over vsync
;   control over loading
;   set timed offsets within segments
;   animated memory variables for effect inputs (simple interpolators etc.)
;   set specific start times for segments (so effects can be timed to the music track) 
;   wait command?



.demo_script_start

; initialise routines
SCRIPT_CALL fx_music_initb

IF _ABUG == FALSE
SCRIPT_CALL fx_music_start
ENDIF

SCRIPT_CALL fx_copybuffer_init
SCRIPT_CALL fx_3dshape_init


IF _ABUG
; vector text effect
SCRIPT_SLOT FX_VECTORTEXT_SLOT
SCRIPT_CALL fx_vectortext_init
SCRIPT_SEGMENT_START    1000.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALL fx_vectortext_update
        SCRIPT_CALL fx_teletext_header
SCRIPT_SEGMENT_END
ENDIF

SCRIPT_SLOT FX_PLAYGIFS_SLOT
SCRIPT_CALL fx_playgifs_init
SCRIPT_SEGMENT_START    20.0
    SCRIPT_PLAY fx_buffer_copy 
    SCRIPT_CALL fx_playgifs_update
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_buffer_clear

SCRIPT_SLOT FX_INTERFERENCE_SLOT
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALL fx_interference_update
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_interference_set_blend_ora

SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALL fx_interference_update
SCRIPT_SEGMENT_END

SCRIPT_SLOT FX_CREDITSCROLL_SLOT
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALL fx_creditscroll_update
SCRIPT_SEGMENT_END

SCRIPT_SLOT FX_CREDITSCROLL_SLOT
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALL fx_creditscroll_update
    SCRIPT_PLAY fx_rasterbars_update
    SCRIPT_PLAY fx_rasterbars_write_shadow
SCRIPT_SEGMENT_END

SCRIPT_SLOT FX_DOTSCROLLER_SLOT
SCRIPT_SEGMENT_START    20.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALL fx_dotscroller_update
    SCRIPT_CALL fx_mirrorfloor_update
SCRIPT_SEGMENT_END




IF _VECTORTEXT
; vector text effect
SCRIPT_SLOT FX_VECTORTEXT_SLOT
SCRIPT_CALL fx_vectortext_init
SCRIPT_SEGMENT_START    30.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALL fx_vectortext_update
        SCRIPT_CALL fx_teletext_header
SCRIPT_SEGMENT_END
ENDIF


\\ Test cheapo rotozoom effect 
IF _ROTOZOOM
SCRIPT_SLOT FX_ROTOZOOM_SLOT
SCRIPT_SEGMENT_START    60.0
;    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_PLAY fx_rotozoom3
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    10.0
;    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_PLAY fx_rotozoom1
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    10.0
;    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_PLAY fx_rotozoom2
SCRIPT_SEGMENT_END
ENDIF


; plasma segment
SCRIPT_SLOT FX_PLASMA_SLOT
SCRIPT_CALL fx_plasma_init
SCRIPT_SEGMENT_START    30.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_PLAY fx_plasma
SCRIPT_SEGMENT_END


IF _VECTORBALLS == TRUE
SCRIPT_SLOT FX_VECTORBALLS_SLOT

; point cube effect
SCRIPT_CALL fx_vectorballs_init
SCRIPT_CALL fx_vectorballs_set_small

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALL fx_vectorballs_update
SCRIPT_SEGMENT_END


SCRIPT_CALL fx_vectorballs_set_medium
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_copybuffer_update 
    SCRIPT_CALL fx_vectorballs_update
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_vectorballs_set_large
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALL fx_vectorballs_update
SCRIPT_SEGMENT_END
ENDIF

\\ Test cheapo rasterbars effect 
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_PLAY fx_rasterbars_update
    SCRIPT_PLAY fx_rasterbars_write_shadow
SCRIPT_SEGMENT_END

\\ And now combine with 3D shape
SCRIPT_CALL fx_3dshape_init
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_PLAY fx_rasterbars_update
    SCRIPT_PLAY fx_rasterbars_write_shadow
    SCRIPT_PLAY fx_3dshape_update
SCRIPT_SEGMENT_END

; teletext intro
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_teletext
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_music_stop

.segment1
SCRIPT_CALL fx_testcard_init
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_testcard
SCRIPT_SEGMENT_END



SCRIPT_SEGMENT_START    1.0
    SCRIPT_CALL hide_vram
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_music_init
SCRIPT_CALL fx_music_start

SCRIPT_SEGMENT_START    3.0
    SCRIPT_CALL hide_vram
SCRIPT_SEGMENT_END

; plasma segment
SCRIPT_SLOT FX_PLASMA_SLOT
SCRIPT_CALL fx_plasma_init
SCRIPT_CALL show_vram
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_PLAY fx_plasma
SCRIPT_SEGMENT_END







; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_PLAY fx_greenscreen_update
    SCRIPT_PLAY fx_linebox_update
;    SCRIPT_PLAY fx_copperbars_update
;    SCRIPT_PLAY fx_3dshape_update    
SCRIPT_SEGMENT_END




.segment2

; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
;    SCRIPT_PLAY fx_greenscreen_update
;    SCRIPT_PLAY fx_linebox_update
    SCRIPT_PLAY fx_copperbars_update
;    SCRIPT_PLAY fx_3dshape_update
SCRIPT_SEGMENT_END



.segment3


; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_PLAY fx_greenscreen_update
 ;   SCRIPT_PLAY fx_linebox_update
;    SCRIPT_PLAY fx_copperbars_update
    SCRIPT_PLAY fx_3dshape_update
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_PLAY fx_copperbars_update
    SCRIPT_PLAY fx_greenscreen_update
    SCRIPT_PLAY fx_3dshape_update
SCRIPT_SEGMENT_END



; clear the screen on finish
SCRIPT_CALL fx_copybuffer_update
SCRIPT_CALL fx_copybuffer_update
SCRIPT_CALL fx_music_stop
.segment_end

SCRIPT_END

.demo_script_end

PRINT "Demo Sequence data from", ~demo_script_start, "to", ~demo_script_end, ", size is", (demo_script_end-demo_script_start), "bytes"



; IDEAS


; Fade off the BBC Computer screen
; CEEFAX page
; bzz with TESTCARD "BITSHIFTERS TV" & 1Khz tone
; flicker off
; music starts
;
; bitshifters presents
; 'teletextr demo'

; plasma demo with hold/block graphics
; do lazy initialization using init bytes
; no need for init routines this way.

; use separated graphics as a half brite effect

; RGB overlapping circles sprites
; giphy sequences