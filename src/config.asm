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
SCRIPT_CALL fx_copybuffer_init

; not sure if this is necessary here yet but hey ho
SCRIPT_CALLSLOT fx_3dshape_init, FX_3DSHAPE_SLOT


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

SCRIPT_CALL fx_music_init_reg  ; reg
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
; Next effect suggests that Teletext has gone wrong
; and bitshifters are taking over
; TODO: show "we interrupt this broadcast..."
;-----------------------------------------------------------


SCRIPT_CALL fx_music_stop



SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALL fx_colournoise_update
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END


SCRIPT_CALL fx_music_init_en ; en
SCRIPT_CALL fx_music_start

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_clear


;-----------------------------------------------------------
; some kind of "Bitshifters presents" sequence would be good here
; KC: Agree - a simple & reusable intro to each fx, maybe 5x5 font?
;-----------------------------------------------------------

; STARFIELD NEEDED!!! :)
; Starfield provided! :D

SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_buffer_copy              ; stars are self-erasing - optional!
    SCRIPT_CALLSLOT fx_starfield_update, FX_STARFIELD_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END



IF 0
; SM: this effect is knacked for some reason, causes demo to hang, not sure why
;-----------------------------------------------------------
; vector text effect
;-----------------------------------------------------------
; SM: I'd like to get a full vector font in so we can show any text string with it

SCRIPT_CALLSLOT fx_vectortext_init, FX_VECTORTEXT_SLOT
SCRIPT_SEGMENT_START    30.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_vectortext_update, FX_VECTORTEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END


ENDIF



; SM: gonna make the linebox demo do something more - like animated boxes/fractals etc.
; KC: I get the line box starting in the middle of the screen when I run through?  Uninitialise start pos?

; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_linebox_update, FX_LINEBOX_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END


; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END


;-----------------------------------------------------------
\\ And now combine with 3D shape
;-----------------------------------------------------------
; SM: need to cycle through the various shapes & animate the sequence better
SCRIPT_CALLSLOT fx_3dshape_init, FX_3DSHAPE_SLOT
SCRIPT_SEGMENT_START    10.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_3dshape_update, FX_3DSHAPE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END




; SM: might be good to inject a scroll text in between each segment
; giving some text on why the next segment is so amazing!
; eg. "How about some 3D shapes"
;     "Particles on a BEEB?! Here we go!"
; etc. 


;-----------------------------------------------------------
; Particles!
;-----------------------------------------------------------

SCRIPT_CALLSLOT fx_particles_init, FX_PARTICLES_SLOT
SCRIPT_CALLSLOT fx_particles_set_fx_spin, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_set_fx_spurt, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_set_fx_drip, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_set_fx_spin, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_set_fx_spurt, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_set_fx_drip, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END



;-----------------------------------------------------------
; Vector balls
;-----------------------------------------------------------
; These are cool
; I'm sure we could get more mileage out of these...
; possibly setup a spinning rotating circle of them
; bit of mirror floor action going on too?


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



;-----------------------------------------------------------
; GIF player
; its GIPHY time!
;-----------------------------------------------------------

; SM: it would be good to be able to play different animations on demand
; so we can inject these through the whole sequence.
; Plus we should have MOAR animations - these are ACE!

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
; Cant help feeling we should switch to a rave track for this one
;  and inject this in a high speed pulsing fashion with the dancing man GIF!!
;  Agree :) - KC

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
; plasma segment
;-----------------------------------------------------------
; SM: fairly happy with this, but I just want to add some animation params so its less uniform and more interesting
SCRIPT_CALL fx_clear
SCRIPT_CALLSLOT fx_plasma_init, FX_PLASMA_SLOT
SCRIPT_SEGMENT_START    30.0
    SCRIPT_PLAY fx_buffer_copy
    SCRIPT_CALLSLOT fx_plasma, FX_PLASMA_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END


;-----------------------------------------------------------
\\ Test cheapo rotozoom effect 
;-----------------------------------------------------------
; this is the best effect, just need to animate it, possibly add some different textures

SCRIPT_CALL fx_clear
SCRIPT_SEGMENT_START    60.0
;    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_rotozoom3, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END


; Might kill this one - technically interesting, but way too slow
SCRIPT_SEGMENT_START    10.0
;    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_rotozoom1, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT     
SCRIPT_SEGMENT_END

IF 0
; was just a technical concept really - dump it
SCRIPT_SEGMENT_START    10.0
;    SCRIPT_PLAY fx_copybuffer_update
    SCRIPT_CALLSLOT fx_rotozoom2, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT         
SCRIPT_SEGMENT_END

ENDIF




.segment1
.segment2
.segment3

; SM: we should somehow maybe start winding the demo down now toward the credits?
; its a bit of a jolt when they come in.

; Perhaps a vertical scrolling art gallery would be cool - some horsenburger masterpieces?
; A reminder of how cool teletext is.

;-----------------------------------------------------------
; Credits scroll
; lasts 35 seconds - same as music (34s)
;-----------------------------------------------------------



; clear the screen on finish
SCRIPT_CALL fx_copybuffer_update
SCRIPT_CALL fx_copybuffer_update


SCRIPT_CALL fx_music_init_exception ; exception
SCRIPT_CALL fx_music_start

SCRIPT_SEGMENT_START    35.0
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