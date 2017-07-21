.vsync_count		SKIP 1	; elapsed time in 1/50ths second - updated by IRQ
.vsync_time			SKIP 2	; elapsed time in 1/50ths second (16 bits gives us 1310 seconds of demo time) - updated by IRQ
.delta_time			SKIP 1	; elapsed time for effect updates (in 1/50ths second)

.readptr            SKIP 2  ; generic read pointer that is available to any module
.writeptr           SKIP 2  ; generic write pointer that is available to any module

.fx_dotscroller_ptr     SKIP 2  ; super-lazy, should be in own module header
.fx_creditscroll_ptr    SKIP 2  ; super-lazy, should be in own module header

\\ From rotozoom...

IF 1
;rz_sx = &80
;rz_sy = &82
.rz_sx              SKIP 2
.rz_sy              SKIP 2

;rz_dx = &84
;rz_dy = &86
.rz_dx              SKIP 2
.rz_dy              SKIP 2

;rz_px0 = &88
;rz_px1 = &8A
;rz_px2 = &8C
.rz_px0             SKIP 2
.rz_px1             SKIP 2
.rz_px2             SKIP 2

;rz_py0 = &8E
;rz_py1 = &90
;rz_py2 = &92
.rz_py0             SKIP 2
.rz_py1             SKIP 2
.rz_py2             SKIP 2

;rz_tx = &94
;rz_c = &95
.rz_tx              SKIP 1
.rz_c               SKIP 1
.rz_stash_y         SKIP 1
ELSE
.rz_sx EQUW 0
.rz_sy EQUW 0

.rz_dx EQUW 0
.rz_dy EQUW 0

.rz_px0 EQUW 0
.rz_px1 EQUW 0
.rz_px2 EQUW 0


.rz_py0 EQUW 0
.rz_py1 EQUW 0
.rz_py2 EQUW 0


.rz_tx EQUB 0

.rz_c   EQUB 0
ENDIF
