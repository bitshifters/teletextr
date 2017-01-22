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
SCRIPT_CALL fx_copybuffer_init

; not sure if this is necessary here yet but hey ho
SCRIPT_SLOT FX_3DSHAPE_SLOT     
SCRIPT_CALL fx_3dshape_init



;-----------------------------------------------------------
; If Abug demo then we just play the following segment
;-----------------------------------------------------------
IF _ABUG
; vector text effect
SCRIPT_CALLSLOT fx_vectortext_init, FX_VECTORTEXT_SLOT
SCRIPT_SEGMENT_START    1000.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_vectortext_update, FX_VECTORTEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END
; ABUG demo never exits this segment
ENDIF




;-----------------------------------------------------------
; Screen off/on
;-----------------------------------------------------------
SCRIPT_SEGMENT_START    2.0
    SCRIPT_CALL hide_vram
SCRIPT_SEGMENT_END
SCRIPT_CALL show_vram




;-----------------------------------------------------------
; Tuning in....
;-----------------------------------------------------------
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALL fx_noise_update
SCRIPT_SEGMENT_END
SCRIPT_CALL fx_clear


;-----------------------------------------------------------
; scrolling bars
;-----------------------------------------------------------

SCRIPT_SEGMENT_START    2.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_copperbars_update, FX_COPPERBARS_SLOT   
SCRIPT_SEGMENT_END

;----------------------------------------------------------- 
; Tuned - show testcard
;-----------------------------------------------------------
SCRIPT_CALL fx_clear
SCRIPT_CALLSLOT fx_testcard_init, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALLSLOT fx_testcard, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_END

;-----------------------------------------------------------
; Screen off/on
;-----------------------------------------------------------
SCRIPT_CALL fx_music_stop   ; kill testcard tone
SCRIPT_SEGMENT_START    2.0
    SCRIPT_CALL hide_vram
SCRIPT_SEGMENT_END
SCRIPT_CALL show_vram

;-----------------------------------------------------------
; teletext intro & jaunty ceefax type music
;-----------------------------------------------------------


SCRIPT_CALL fx_music_start
SCRIPT_CALL fx_clear
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_teletext_showtestcard, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_teletext_showpages, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END






;-----------------------------------------------------------
\\ Test cheapo rasterbars effect 
;-----------------------------------------------------------
SCRIPT_SEGMENT_START    3.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_SLOT FX_RASTERBARS_SLOT  
    SCRIPT_PLAY fx_rasterbars_update
    SCRIPT_PLAY fx_rasterbars_write_shadow
SCRIPT_SEGMENT_END









SCRIPT_CALL fx_music_stop

SCRIPT_SEGMENT_START    2.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALL fx_noise_update
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_music_init
SCRIPT_CALL fx_music_start

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALL fx_colournoise_update
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_clear






IF 0
;-----------------------------------------------------------
; vector text effect
;-----------------------------------------------------------
SCRIPT_CALLSLOT fx_vectortext_init, FX_VECTORTEXT_SLOT
SCRIPT_SEGMENT_START    30.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_vectortext_update, FX_VECTORTEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END


ENDIF





; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_linebox_update, FX_LINEBOX_SLOT
   
;    SCRIPT_CALLSLOT fx_copperbars_update, FX_COPPERBARS_SLOT     
;    SCRIPT_CALLSLOT fx_3dshape_update,FX_3DSHAPE_SLOT 
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END

; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_linebox_update, FX_LINEBOX_SLOT
    SCRIPT_CALLSLOT fx_copperbars_update, FX_COPPERBARS_SLOT   
;    SCRIPT_CALLSLOT fx_3dshape_update,FX_3DSHAPE_SLOT 
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END




; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
;    SCRIPT_CALLSLOT fx_linebox_update, FX_LINEBOX_SLOT
;    SCRIPT_CALLSLOT fx_copperbars_update, FX_COPPERBARS_SLOT   
    SCRIPT_CALLSLOT fx_3dshape_update,FX_3DSHAPE_SLOT 
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_copperbars_update, FX_COPPERBARS_SLOT
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_3dshape_update,FX_3DSHAPE_SLOT 
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

;-----------------------------------------------------------
\\ And now combine with 3D shape
;-----------------------------------------------------------

SCRIPT_CALLSLOT fx_3dshape_init, FX_3DSHAPE_SLOT
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_SLOT FX_RASTERBARS_SLOT      
    SCRIPT_PLAY fx_rasterbars_update
    SCRIPT_PLAY fx_rasterbars_write_shadow
    SCRIPT_CALLSLOT fx_3dshape_update, FX_3DSHAPE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END







;-----------------------------------------------------------
\\ Test cheapo rotozoom effect 
;-----------------------------------------------------------
SCRIPT_CALL fx_clear
SCRIPT_SEGMENT_START    60.0
;    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_rotozoom3, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    10.0
;    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_rotozoom1, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT     
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    10.0
;    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_rotozoom2, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT         
SCRIPT_SEGMENT_END


;-----------------------------------------------------------
; plasma segment
;-----------------------------------------------------------
SCRIPT_CALL fx_clear
SCRIPT_CALLSLOT fx_plasma_init, FX_PLASMA_SLOT
SCRIPT_SEGMENT_START    30.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALLSLOT fx_plasma, FX_PLASMA_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END







;-----------------------------------------------------------
; GIF player
;-----------------------------------------------------------

SCRIPT_CALLSLOT fx_playgifs_init, FX_PLAYGIFS_SLOT
SCRIPT_SEGMENT_START    20.0
    SCRIPT_PLAY fx_buffer_copy 
    SCRIPT_CALLSLOT fx_playgifs_update, FX_PLAYGIFS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_buffer_clear

;-----------------------------------------------------------
; Interference
;-----------------------------------------------------------

SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALLSLOT fx_interference_update, FX_INTERFERENCE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_interference_set_blend_ora, FX_INTERFERENCE_SLOT

SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALLSLOT fx_interference_update, FX_INTERFERENCE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END


;-----------------------------------------------------------
; Dot scroller
;-----------------------------------------------------------

SCRIPT_SEGMENT_START    20.0
    SCRIPT_PLAY fx_copybuffer_update  
    SCRIPT_CALLSLOT fx_dotscroller_update, FX_DOTSCROLLER_SLOT
    SCRIPT_CALLSLOT fx_mirrorfloor_update, FX_MIRRORFLOOR_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END









;-----------------------------------------------------------
; Vector balls
;-----------------------------------------------------------

; point cube effect
SCRIPT_CALLSLOT fx_vectorballs_init, FX_VECTORBALLS_SLOT
SCRIPT_CALLSLOT fx_vectorballs_set_small, FX_VECTORBALLS_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_vectorballs_update, FX_VECTORBALLS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END


SCRIPT_CALLSLOT fx_vectorballs_set_medium, FX_VECTORBALLS_SLOT
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_copybuffer_update 
    SCRIPT_CALLSLOT fx_vectorballs_update, FX_VECTORBALLS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_vectorballs_set_large, FX_VECTORBALLS_SLOT
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_vectorballs_update, FX_VECTORBALLS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END



.segment1
.segment2
.segment3




;-----------------------------------------------------------
; Credits scroll
;-----------------------------------------------------------



; clear the screen on finish
SCRIPT_CALL fx_copybuffer_update
SCRIPT_CALL fx_copybuffer_update


SCRIPT_SEGMENT_START    30.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALLSLOT fx_creditscroll_update, FX_CREDITSCROLL_SLOT 
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
SCRIPT_SEGMENT_END






SCRIPT_CALL fx_music_stop
; clear the screen on finish
SCRIPT_CALL fx_copybuffer_update
SCRIPT_CALL fx_copybuffer_update




;----------------------------------------------------------- 
; Finish - show testcard
;-----------------------------------------------------------
SCRIPT_CALL fx_clear
SCRIPT_CALLSLOT fx_testcard_init, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALLSLOT fx_testcard, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_END

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