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
SCRIPT_CALL fx_music_start
SCRIPT_CALL fx_copybuffer_init
SCRIPT_CALL fx_3dshape_init

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