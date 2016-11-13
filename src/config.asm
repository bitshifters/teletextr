
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

.demo_sequence_start

; initialise routines
SCRIPT_CALL     effect_copybuffer_init
SCRIPT_CALL     effect_3dshape_init

.segment1

IF TRUE
; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY effect_copybuffer_update
    SCRIPT_PLAY effect_greenscreen_update
    SCRIPT_PLAY effect_linebox_update
;    SCRIPT_PLAY effect_copperbars_update
;    SCRIPT_PLAY effect_3dshape_update    
SCRIPT_SEGMENT_END
ENDIF


IF TRUE
.segment2

; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY effect_copybuffer_update
;    SCRIPT_PLAY effect_greenscreen_update
;    SCRIPT_PLAY effect_linebox_update
    SCRIPT_PLAY effect_copperbars_update
;    SCRIPT_PLAY effect_3dshape_update
SCRIPT_SEGMENT_END
ENDIF

IF FALSE
.segment3


; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY effect_copybuffer_update
    SCRIPT_PLAY effect_greenscreen_update
 ;   SCRIPT_PLAY effect_linebox_update
;    SCRIPT_PLAY effect_copperbars_update
    SCRIPT_PLAY effect_3dshape_update
SCRIPT_SEGMENT_END
ENDIF

; clear the screen
SCRIPT_CALL effect_copybuffer_update
SCRIPT_CALL effect_copybuffer_update

.segment_end

SCRIPT_END

.demo_sequence_end

PRINT "Demo Sequence data from", ~demo_sequence_start, "to", ~demo_sequence_end, ", size is", (demo_sequence_end-demo_sequence_start), "bytes"

