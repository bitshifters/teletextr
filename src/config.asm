; Config script for the demo
; Makes things a bit more data driven and easier to fine tune

; Things to improve:
;   control over vsync
;   control over loading
;   set timed offsets within segments
;   animated memory variables for effect inputs (simple interpolators etc.)
;   set specific start times for segments (so effects can be timed to the music track) 
;   wait command?

;-----------------------------------------------
; Let's go mad with macros
; Here's some helpers to neaten things up a bit
;-----------------------------------------------


; quick segment containing one double buffered effect
MACRO RUN_EFFECT duration, routine, slot
    SCRIPT_SEGMENT_START    duration
        SCRIPT_CALL fx_buffer_swap 
        SCRIPT_CALLSLOT routine, slot
        SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
    SCRIPT_SEGMENT_END
ENDMACRO


; quick segment containing one double buffered effect, with a value
MACRO RUN_EFFECTV duration, routine, slot, value
    SCRIPT_SEGMENT_START    duration
        SCRIPT_CALL fx_buffer_swap 
    SCRIPT_CALL fx_buffer_clear        
        SCRIPT_CALLSLOTV routine, slot, value
        SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
    SCRIPT_SEGMENT_END
ENDMACRO

; gif animation macro, just pass in duration and the id of the gif anim to play
MACRO GIF_SEGMENT duration, gifid
    SCRIPT_CALL fx_buffer_clear
    SCRIPT_CALL shadow_set_single_buffer
    SCRIPT_CALLSLOTV fx_playgifs_init, FX_PLAYGIFS_SLOT, gifid

    SCRIPT_SEGMENT_START duration
        SCRIPT_CALLSLOTV fx_playgifs_playanim, FX_PLAYGIFS_SLOT, gifid
        SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
    SCRIPT_SEGMENT_END

    SCRIPT_CALL shadow_set_double_buffer


;    RUN_EFFECTV duration, fx_playgifs_playanim, FX_PLAYGIFS_SLOT, gifid

    SCRIPT_CALL fx_clear
ENDMACRO

; hide the screen for duration, then clear it and show again
MACRO BLANK_DISPLAY duration
    SCRIPT_SEGMENT_START    duration
        SCRIPT_CALL hide_vram
    SCRIPT_SEGMENT_END
    SCRIPT_CALL fx_clear    
    SCRIPT_CALL show_vram
ENDMACRO


;------------------------------------------------------------------------
; Demo script begins
;------------------------------------------------------------------------


.demo_script_start

; initialise routines
SCRIPT_CALL fx_copybuffer_init
SCRIPT_CALLSLOT  initialise_multiply, FX_3DCODE_SLOT
; 
; not sure if this is necessary here yet but hey ho
;SCRIPT_CALLSLOT fx_3dshape_init, FX_3DSHAPE_SLOT




















;-----------------------------------------------------------
; If Abug demo then we just play the following segment
;-----------------------------------------------------------
IF _ABUG
; vector text effect
SCRIPT_CALLSLOT fx_vectortext_init, FX_VECTORTEXT_SLOT
SCRIPT_SEGMENT_START    1000.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear
    SCRIPT_CALLSLOT fx_vectortext_update, FX_VECTORTEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END
; ABUG demo never exits this segment
ENDIF



;-----------------------------------------------------------
; some kind of "Bitshifters presents" sequence would be good here
; KC: Agree - a simple & reusable intro to each fx, maybe 5x5 font?
;-----------------------------------------------------------

; STARFIELD NEEDED!!! :)
; Starfield provided! :D

SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap              ; stars are self-erasing - optional!
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_starfield_update, FX_STARFIELD_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END



;-----------------------------------------------------------
; Screen off/on
;-----------------------------------------------------------
BLANK_DISPLAY 2.0

;-----------------------------------------------------------
; Tuning in....
;-----------------------------------------------------------
SCRIPT_CALL sfx_noise_on
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_noise_update
SCRIPT_SEGMENT_END
SCRIPT_CALL sfx_noise_off
SCRIPT_CALL fx_clear


;-----------------------------------------------------------
; scrolling bars
;-----------------------------------------------------------
SCRIPT_SEGMENT_START    2.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear
    SCRIPT_CALLSLOT fx_copperbars_update, FX_COPPERBARS_SLOT
SCRIPT_SEGMENT_END


IF 0
SCRIPT_SEGMENT_START    2.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_copperbars_update, FX_COPPERBARS_SLOT   
SCRIPT_SEGMENT_END
ENDIF

;----------------------------------------------------------- 
; Tuned - show testcard
;-----------------------------------------------------------
SCRIPT_CALL fx_clear
SCRIPT_CALLSLOT fx_testcard_init, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_testcard, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_END

;-----------------------------------------------------------
; Screen off/on
;-----------------------------------------------------------
SCRIPT_CALL fx_music_stop   ; kill testcard tone
BLANK_DISPLAY 2.0

;-----------------------------------------------------------
; teletext intro & jaunty ceefax type music
;-----------------------------------------------------------

SCRIPT_CALL fx_music_init_reg  ; reg
SCRIPT_CALL fx_music_start
SCRIPT_CALL fx_clear
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_teletext_showtestcard, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_teletext_showpages, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END









;-----------------------------------------------------------
; Next effect suggests that Teletext has gone wrong
; and bitshifters are taking over
; TODO: show "we interrupt this broadcast..."
;-----------------------------------------------------------


SCRIPT_CALL fx_music_stop


SCRIPT_CALL sfx_noise_on
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_colournoise_update
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END
SCRIPT_CALL sfx_noise_off

SCRIPT_CALL fx_music_init_en ; en
SCRIPT_CALL fx_music_start

;-----------------------------------------------------------
; Weather breaking
;-----------------------------------------------------------
GIF_SEGMENT 4.0, PLAYGIFS_WEATHER

;-----------------------------------------------------------
; look like we're loading/configuring
;-----------------------------------------------------------
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear        
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
    SCRIPT_CALL fx_buffer_swap              ; stars are self-erasing - optional!
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_starfield_update, FX_STARFIELD_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END



IF 1
; SM: this effect is knacked for some reason, causes demo to hang, not sure why
; SM: think its fixed now. not sure what it was tho. suspicious about some filesys code overwriting pages &0e00-&10ff
;----------------------------------------------------------
; vector text effect
;-----------------------------------------------------------
; SM: I'd like to get a full vector font in so we can show any text string with it

SCRIPT_CALLSLOT fx_vectortext_init, FX_VECTORTEXT_SLOT
SCRIPT_SEGMENT_START    30.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_starfield_update, FX_STARFIELD_SLOT    
    SCRIPT_CALLSLOT fx_vectortext_update, FX_VECTORTEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END


ENDIF





IF 1
; SM: gonna make the linebox demo do something more - like animated boxes/fractals etc.
; KC: I get the line box starting in the middle of the screen when I run through?  Uninitialised start pos?

; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_linebox_update, FX_LINEBOX_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END
ENDIF

; test segment
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

IF 1
;-----------------------------------------------------------
\\ And now combine with 3D shape
;-----------------------------------------------------------
; SM: need to cycle through the various shapes & animate the sequence better
SCRIPT_CALLSLOT fx_3dshape_init, FX_3DSHAPE_SLOT
SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_3dshape_update, FX_3DSHAPE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

ENDIF


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
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_set_fx_spurt, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_set_fx_drip, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_set_fx_spin, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_set_fx_spurt, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_set_fx_drip, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END


GIF_SEGMENT 5.0, PLAYGIFS_BIRD


IF 1
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
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_vectorballs_update, FX_VECTORBALLS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END


SCRIPT_CALLSLOT fx_vectorballs_set_medium, FX_VECTORBALLS_SLOT
SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear     
    SCRIPT_CALLSLOT fx_vectorballs_update, FX_VECTORBALLS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_vectorballs_set_large, FX_VECTORBALLS_SLOT
SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_vectorballs_update, FX_VECTORBALLS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

ENDIF

;-----------------------------------------------------------
; GIF player
; its GIPHY time!
;-----------------------------------------------------------

; SM: it would be good to be able to play different animations on demand
; so we can inject these through the whole sequence.
; Plus we should have MOAR animations - these are ACE!
IF 0
SCRIPT_CALLSLOT fx_playgifs_init, FX_PLAYGIFS_SLOT
SCRIPT_SEGMENT_START    20.0
    SCRIPT_CALL fx_buffer_swap 
    SCRIPT_CALLSLOT fx_playgifs_update, FX_PLAYGIFS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_buffer_clear
ENDIF

;-----------------------------------------------------------
; Interference
;-----------------------------------------------------------
; Cant help feeling we should switch to a rave track for this one
;  and inject this in a high speed pulsing fashion with the dancing man GIF!!
;  Agree :) - KC



GIF_SEGMENT 2.0, PLAYGIFS_BLUEBLOB


RUN_EFFECT 5.0, fx_interference_update, FX_INTERFERENCE_SLOT

GIF_SEGMENT 4.0, PLAYGIFS_DANCER

SCRIPT_CALLSLOT fx_interference_set_blend_ora, FX_INTERFERENCE_SLOT
RUN_EFFECT 5.0, fx_interference_update, FX_INTERFERENCE_SLOT

GIF_SEGMENT 4.0, PLAYGIFS_DANCER
RUN_EFFECT 2.0, fx_interference_update, FX_INTERFERENCE_SLOT
GIF_SEGMENT 2.0, PLAYGIFS_DANCER
RUN_EFFECT 1.0, fx_interference_update, FX_INTERFERENCE_SLOT
GIF_SEGMENT 1.0, PLAYGIFS_DANCER
RUN_EFFECT 0.5, fx_interference_update, FX_INTERFERENCE_SLOT
GIF_SEGMENT 0.5, PLAYGIFS_DANCER

IF 0
SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_interference_update, FX_INTERFERENCE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_interference_set_blend_ora, FX_INTERFERENCE_SLOT

SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_interference_update, FX_INTERFERENCE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END
ENDIF

;-----------------------------------------------------------
; Dot scroller
;-----------------------------------------------------------

SCRIPT_SEGMENT_START    20.0
    SCRIPT_CALL fx_buffer_swap  
    SCRIPT_CALL fx_buffer_clear    
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
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_plasma, FX_PLASMA_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END


;-----------------------------------------------------------
\\ Test cheapo rotozoom effect 
;-----------------------------------------------------------
; this is the best effect, just need to animate it, possibly add some different textures

SCRIPT_CALL fx_clear

;SCRIPT_CALL shadow_set_single_buffer

SCRIPT_SEGMENT_START    60.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_rotozoom3, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END


; Might kill this one - technically interesting, but way too slow
SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_rotozoom1, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT     
SCRIPT_SEGMENT_END

IF 0
; was just a technical concept really - dump it
SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_rotozoom2, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT         
SCRIPT_SEGMENT_END

ENDIF

;SCRIPT_CALL shadow_set_double_buffer


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
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALL fx_buffer_clear
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALL fx_buffer_clear


SCRIPT_CALL fx_music_init_exception ; exception
SCRIPT_CALL fx_music_start

SCRIPT_CALL shadow_set_single_buffer

SCRIPT_SEGMENT_START    34.5
;    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_creditscroll_update, FX_CREDITSCROLL_SLOT 
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
;    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
SCRIPT_SEGMENT_END

SCRIPT_CALL shadow_set_double_buffer


SCRIPT_CALL fx_music_stop
; clear the screen on finish
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALL fx_buffer_clear
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALL fx_buffer_clear




;----------------------------------------------------------- 
; Finish - show testcard
;-----------------------------------------------------------
SCRIPT_CALL fx_clear
SCRIPT_CALLSLOT fx_testcard_init, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap  
    SCRIPT_CALLSLOT fx_testcard, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_music_stop
.segment_end

SCRIPT_END

.demo_script_end



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