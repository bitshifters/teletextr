.vsync_count		SKIP 1	; elapsed time in 1/50ths second - updated by IRQ
.vsync_time			SKIP 2	; elapsed time in 1/50ths second (16 bits gives us 1310 seconds of demo time) - updated by IRQ
.delta_time			SKIP 1	; elapsed time for effect updates (in 1/50ths second)

.readptr            SKIP 2  ; generic read pointer that is available to any module
.writeptr           SKIP 2  ; generic write pointer that is available to any module

.fx_dotscroller_ptr SKIP 2  ; super-lazy, should be in own module header
