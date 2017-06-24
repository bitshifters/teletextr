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
    SCRIPT_CALLSLOTV fx_playgifs_init, gifid, FX_PLAYGIFS_SLOT

    SCRIPT_SEGMENT_START duration
        SCRIPT_CALLSLOTV fx_playgifs_playanim, gifid, FX_PLAYGIFS_SLOT
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

MACRO DOTSCOLLER_SEGMENT duration, set_text_fn
    SCRIPT_CALLSLOT set_text_fn, FX_DOTSCROLLER_SLOT
    SCRIPT_SEGMENT_START duration
        SCRIPT_CALL fx_buffer_swap  
        SCRIPT_CALL fx_buffer_clear    
        SCRIPT_CALLSLOT fx_dotscroller_update, FX_DOTSCROLLER_SLOT
        SCRIPT_CALLSLOT fx_mirrorfloor_update, FX_MIRRORFLOOR_SLOT
        SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
    SCRIPT_SEGMENT_END
ENDMACRO

MACRO TEXTTYPE_SEGMENT duration, delay, text_fn
    SCRIPT_CALLSLOTV fx_textscreen_reset_type_delay, delay, FX_CREDITSCROLL_SLOT
    SCRIPT_SEGMENT_START    duration
        SCRIPT_CALL fx_buffer_swap              ; stars are self-erasing - optional!
        SCRIPT_CALL fx_buffer_clear    
        SCRIPT_CALLSLOT fx_starfield_update, FX_STARFIELD_SLOT
        SCRIPT_CALLSLOT text_fn, FX_CREDITSCROLL_SLOT
        SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
    SCRIPT_SEGMENT_END
ENDMACRO

;------------------------------------------------------------------------
; DEMOS START
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







;------------------------------------------------------------------------
; PART 1: SETUP
;  a) Tuning in the TV
;  b) Pages from Ceefax
;  c) Bitshifters hijack
;------------------------------------------------------------------------


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
    SCRIPT_CALLSLOT fx_noise_update, FX_NOISE_SLOT
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
SCRIPT_SEGMENT_START    2.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_colournoise_update, FX_NOISE_SLOT
    ;SCRIPT_CALL fx_colournoise_update
;    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END
SCRIPT_CALL sfx_noise_off

SCRIPT_CALLSLOT fx_logoanim_init, FX_LOGOANIM_SLOT                ; initialises a single screen with the logo
SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALLSLOT fx_logoanim_init, FX_LOGOANIM_SLOT                ; initialises a single screen with the logo
SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_SEGMENT_START    0.1
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_SEGMENT_END

SCRIPT_CALL sfx_noise_on
SCRIPT_SEGMENT_START    1.5
    SCRIPT_CALL fx_buffer_swap
;    SCRIPT_CALL fx_colournoise_update
    SCRIPT_CALLSLOT fx_colournoise_update, FX_NOISE_SLOT
SCRIPT_SEGMENT_END
SCRIPT_CALL sfx_noise_off

SCRIPT_CALLSLOT fx_logoanim_init, FX_LOGOANIM_SLOT                ; initialises a single screen with the logo
SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALLSLOT fx_logoanim_init, FX_LOGOANIM_SLOT                ; initialises a single screen with the logo
SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_SEGMENT_END

SCRIPT_CALL sfx_noise_on
SCRIPT_SEGMENT_START    0.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_colournoise_update, FX_NOISE_SLOT

;    SCRIPT_CALL fx_colournoise_update
;    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END
SCRIPT_CALL sfx_noise_off

SCRIPT_CALLSLOT fx_logoanim_init, FX_LOGOANIM_SLOT                ; initialises a single screen with the logo
SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALLSLOT fx_logoanim_init, FX_LOGOANIM_SLOT                ; initialises a single screen with the logo
SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_SEGMENT_END

SCRIPT_CALL sfx_noise_on
SCRIPT_SEGMENT_START    0.1
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_colournoise_update, FX_NOISE_SLOT
;    SCRIPT_CALL fx_colournoise_update
;    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END
SCRIPT_CALL sfx_noise_off

SCRIPT_CALLSLOT fx_logoanim_init, FX_LOGOANIM_SLOT                ; initialises a single screen with the logo
SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALLSLOT fx_logoanim_init, FX_LOGOANIM_SLOT                ; initialises a single screen with the logo
SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_SEGMENT_START    2.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_SEGMENT_END


;-----------------------------------------------------------
; START DEMO SECTION
;-----------------------------------------------------------

BLANK_DISPLAY 1.0

SCRIPT_CALL fx_clear
SCRIPT_SEGMENT_START    1.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT        ; but should have changed from CEEFAX to BITFAX?
SCRIPT_SEGMENT_END

SCRIPT_CALL fx_music_init_en ; en
SCRIPT_CALL fx_music_start

IF 1
SCRIPT_CALLSLOTV fx_textscreen_reset_type_delay, 2, FX_CREDITSCROLL_SLOT
SCRIPT_CALLSLOTV fx_greenscreen_set_fg, 144+6, FX_GREENSCREEN_SLOT
SCRIPT_SEGMENT_START    2.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_textscreen_type_weather, FX_CREDITSCROLL_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END
ENDIF

;-----------------------------------------------------------
; GIF SEGUE - Weather breaking
;-----------------------------------------------------------

GIF_SEGMENT 6.3, PLAYGIFS_WEATHER
; would be cute to add "Weather forecast for Budleigh Salterton..."

;-----------------------------------------------------------
; "Bitshifters presents" sequence would be good here
;-----------------------------------------------------------

;-----------------------------------------------------------
; Wibbling logo
;-----------------------------------------------------------

IF 1
SCRIPT_CALLSLOTV fx_textscreen_reset_type_delay, 8, FX_CREDITSCROLL_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap              ; stars are self-erasing - optional!
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_logowibble_update, FX_LOGOWIBBLE_SLOT
    SCRIPT_CALLSLOT fx_starfield_update, FX_STARFIELD_SLOT
    SCRIPT_CALLSLOT fx_textscreen_type_presents, FX_CREDITSCROLL_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END
ENDIF

;-----------------------------------------------------------
; Teletextr logo
;-----------------------------------------------------------

IF 1
SCRIPT_SEGMENT_START    3.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear        
    SCRIPT_CALLSLOTV fx_teletext_drawpage, PAGE_TELETEXTR, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END
ENDIF

;-----------------------------------------------------------
; Old School
;-----------------------------------------------------------

IF 1
SCRIPT_CALLSLOTV fx_textscreen_reset_type_delay, 4, FX_CREDITSCROLL_SLOT

SCRIPT_SEGMENT_START    4.0
    SCRIPT_CALL fx_buffer_swap              ; stars are self-erasing - optional!
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_starfield_update, FX_STARFIELD_SLOT
    SCRIPT_CALLSLOT fx_textscreen_type_oldschool, FX_CREDITSCROLL_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END
ENDIF

;-----------------------------------------------------------
; Nova logo
;-----------------------------------------------------------

IF 1
SCRIPT_SEGMENT_START    3.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear        
    SCRIPT_CALLSLOTV fx_teletext_drawpage, PAGE_NOVA, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END
ENDIF




SCRIPT_CALL fx_clear

;------------------------------------------------------------------------
; PART 2: OLD-SCHOOL 2D
;  a) Plasma
;  b) Interference
;  c) Rotozoomer
;  d) Particles
;
; Additional ideas: linebox, bouncing sprites, wibbling logos etc.
;------------------------------------------------------------------------

;-----------------------------------------------------------
; plasma segment
;-----------------------------------------------------------
; SM: fairly happy with this, but I just want to add some animation params so its less uniform and more interesting

; dot scroll an intro message
IF 1
;DOTSCOLLER_SEGMENT      5.0, fx_dotscroller_set_text_pl
TEXTTYPE_SEGMENT        3.0, 3, fx_textscreen_type_plasma

SCRIPT_CALL fx_clear
SCRIPT_CALLSLOT fx_plasma_init, FX_PLASMA_SLOT
SCRIPT_SEGMENT_START    8.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_plasma, FX_PLASMA_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END
ENDIF

;-----------------------------------------------------------
; GIF SEGUE - Blue Blob
;-----------------------------------------------------------

GIF_SEGMENT 2.0, PLAYGIFS_BLUEBLOB

;-----------------------------------------------------------
; Interference
;-----------------------------------------------------------
; Cant help feeling we should switch to a rave track for this one
;  and inject this in a high speed pulsing fashion with the dancing man GIF!!

IF 1
; dot scroll an intro message
;DOTSCOLLER_SEGMENT      4.0, fx_dotscroller_set_text_int
TEXTTYPE_SEGMENT        3.0, 3, fx_textscreen_type_interference

SCRIPT_CALL fx_clear
SCRIPT_CALLSLOTV fx_greenscreen_set_fg, 144+3, FX_GREENSCREEN_SLOT
SCRIPT_CALLSLOTV fx_greenscreen_set_bg, 144+1, FX_GREENSCREEN_SLOT
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_interference_update, FX_INTERFERENCE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

GIF_SEGMENT 3.0, PLAYGIFS_DANCER

; Don't like this blend mode
;SCRIPT_CALLSLOT fx_interference_set_blend_ora, FX_INTERFERENCE_SLOT
SCRIPT_CALLSLOTV fx_greenscreen_set_fg, 144+5, FX_GREENSCREEN_SLOT
SCRIPT_CALLSLOTV fx_greenscreen_set_bg, 144+4, FX_GREENSCREEN_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_interference_update, FX_INTERFERENCE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

; reset green screen
SCRIPT_CALLSLOT fx_greenscreen_set_default, FX_GREENSCREEN_SLOT
ENDIF

IF 0        ; don't think this works at this point in the sequence
GIF_SEGMENT 3.0, PLAYGIFS_DANCER
RUN_EFFECT 2.0, fx_interference_update, FX_INTERFERENCE_SLOT
GIF_SEGMENT 2.0, PLAYGIFS_DANCER
RUN_EFFECT 1.0, fx_interference_update, FX_INTERFERENCE_SLOT
GIF_SEGMENT 1.0, PLAYGIFS_DANCER
RUN_EFFECT 0.5, fx_interference_update, FX_INTERFERENCE_SLOT
GIF_SEGMENT 0.5, PLAYGIFS_DANCER
ENDIF

;-----------------------------------------------------------
; Dotscroller effect 
;-----------------------------------------------------------

IF 1
TEXTTYPE_SEGMENT        3.0, 3, fx_textscreen_type_dotscroller
DOTSCOLLER_SEGMENT      5.5, fx_dotscroller_set_text_hello
ENDIF

;-----------------------------------------------------------
; Rotozoom effect 
;-----------------------------------------------------------
; this is the best effect, just need to animate it, possibly add some different textures

IF 1
; dot scroll an intro message
;DOTSCOLLER_SEGMENT      4.0, fx_dotscroller_set_text_rot
TEXTTYPE_SEGMENT        2.5, 3, fx_textscreen_type_rotozoom

SCRIPT_CALL fx_clear

SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_rotozoom3_animate, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_rotozoom3, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END
ENDIF

;-----------------------------------------------------------
; GIF SEGUE - Bird
;-----------------------------------------------------------

GIF_SEGMENT 3.5, PLAYGIFS_BIRD

;-----------------------------------------------------------
; Particles!
;-----------------------------------------------------------

IF 1
; dot scroll an intro message
;DOTSCOLLER_SEGMENT      4.0, fx_dotscroller_set_text_part
TEXTTYPE_SEGMENT        3.0, 3, fx_textscreen_type_particles

SCRIPT_CALLSLOT fx_particles_init, FX_PARTICLES_SLOT
SCRIPT_CALLSLOT fx_particles_set_fx_spin, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_bang, FX_PARTICLES_SLOT
SCRIPT_CALLSLOT fx_particles_bang, FX_PARTICLES_SLOT
SCRIPT_CALLSLOT fx_particles_set_fx_spurt, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_particles_bang, FX_PARTICLES_SLOT
SCRIPT_CALLSLOT fx_particles_bang, FX_PARTICLES_SLOT
SCRIPT_CALLSLOT fx_particles_set_fx_drip, FX_PARTICLES_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END
ENDIF




;------------------------------------------------------------------------
; PART 3: OLD-SCHOOL 3D
;  a) Vector text
;  b) Vector balls
;  c) 3D wireframe
;------------------------------------------------------------------------

;----------------------------------------------------------
; vector text effect
;-----------------------------------------------------------
; SM: this effect is knacked for some reason, causes demo to hang, not sure why
; SM: think its fixed now. not sure what it was tho. suspicious about some filesys code overwriting pages &0e00-&10ff
; SM: I'd like to get a full vector font in so we can show any text string with it
; KC: This doesn't work on my machine at the moment :(
; Seems ok now - KC - I concur!
IF 1
TEXTTYPE_SEGMENT        3.0, 3, fx_textscreen_type_vectortext

SCRIPT_CALLSLOT fx_vectortext_init, FX_VECTORTEXT_SLOT
SCRIPT_SEGMENT_START    6.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
;    SCRIPT_CALLSLOT fx_starfield_update, FX_STARFIELD_SLOT    
    SCRIPT_CALLSLOT fx_vectortext_update, FX_VECTORTEXT_SLOT
;    SCRIPT_CALLSLOT fx_background_update, FX_BACKGROUND_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END
ENDIF

;-----------------------------------------------------------
; Vector balls
;-----------------------------------------------------------
; These are cool
; I'm sure we could get more mileage out of these...
; possibly setup a spinning rotating circle of them
; bit of mirror floor action going on too?

IF 1
; dot scroll an intro message
;DOTSCOLLER_SEGMENT      5.0, fx_dotscroller_set_text_vb
TEXTTYPE_SEGMENT        3.0, 3, fx_textscreen_type_vectorballs

; point cube effect
SCRIPT_CALLSLOT fx_vectorballs_init, FX_VECTORBALLS_SLOT
SCRIPT_CALLSLOT fx_vectorballs_set_small, FX_VECTORBALLS_SLOT

SCRIPT_SEGMENT_START    3.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_vectorballs_update, FX_VECTORBALLS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_vectorballs_set_medium, FX_VECTORBALLS_SLOT
SCRIPT_SEGMENT_START    3.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear     
    SCRIPT_CALLSLOT fx_vectorballs_update, FX_VECTORBALLS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT fx_vectorballs_set_large, FX_VECTORBALLS_SLOT
SCRIPT_SEGMENT_START    3.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_vectorballs_update, FX_VECTORBALLS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END
ENDIF

;-----------------------------------------------------------
; 3D Shapes
;-----------------------------------------------------------
; SM: need to cycle through the various shapes & animate the sequence better

IF 1
; dot scroll an intro message
;DOTSCOLLER_SEGMENT      5.0, fx_dotscroller_set_text_3d
TEXTTYPE_SEGMENT        3.0, 3, fx_textscreen_type_3dshapes

SCRIPT_CALLSLOT fx_3dshape_init, FX_3DSHAPE_SLOT
SCRIPT_CALLSLOT fx_3dshape_toggle_culling, FX_3DSHAPE_SLOT      ; start with backfaces visible
SCRIPT_SEGMENT_START    4.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_3dshape_update, FX_3DSHAPE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT load_next_model, FX_3DCODE_SLOT
SCRIPT_CALLSLOT fx_3dshape_toggle_culling, FX_3DSHAPE_SLOT      ; remove backfaces

SCRIPT_SEGMENT_START    4.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_3dshape_update, FX_3DSHAPE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT load_next_model, FX_3DCODE_SLOT

SCRIPT_SEGMENT_START    4.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_3dshape_update, FX_3DSHAPE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT load_next_model, FX_3DCODE_SLOT

SCRIPT_SEGMENT_START    4.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
;    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT        ; this is too garish
;    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_3dshape_update, FX_3DSHAPE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

SCRIPT_CALLSLOT load_next_model, FX_3DCODE_SLOT


;-----------------------------------------------------------
; Crescendo - cut between everything really fast!
;-----------------------------------------------------------

;  Noise
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_noise_update, FX_NOISE_SLOT
SCRIPT_SEGMENT_END

; Testcard
SCRIPT_CALL fx_clear
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_testcard, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_END

; Heisenberg
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear        
    SCRIPT_CALLSLOTV fx_teletext_drawpage, PAGE_HEISENBURG, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

; Colour noise
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_colournoise_update, FX_NOISE_SLOT
;    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

; Animated logo
SCRIPT_CALLSLOT fx_logoanim_init, FX_LOGOANIM_SLOT                ; initialises a single screen with the logo
SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALLSLOT fx_logoanim_init, FX_LOGOANIM_SLOT                ; initialises a single screen with the logo
SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_logoanim_update, FX_LOGOANIM_SLOT            ; just updates top & bottom chars of logo
SCRIPT_SEGMENT_END

GIF_SEGMENT 0.2, PLAYGIFS_WEATHER

; Logo anim
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_logowibble_update, FX_LOGOWIBBLE_SLOT
    SCRIPT_CALLSLOT fx_starfield_update, FX_STARFIELD_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END

; Teletextr
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear        
    SCRIPT_CALLSLOTV fx_teletext_drawpage, PAGE_TELETEXTR, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

; Nova
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear        
    SCRIPT_CALLSLOTV fx_teletext_drawpage, PAGE_NOVA, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

; Plasma
SCRIPT_CALL fx_clear
SCRIPT_CALLSLOT fx_plasma_init, FX_PLASMA_SLOT
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_plasma, FX_PLASMA_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

GIF_SEGMENT 0.2, PLAYGIFS_BLUEBLOB

; Interference
SCRIPT_CALL fx_clear
SCRIPT_CALLSLOTV fx_greenscreen_set_fg, 144+6, FX_GREENSCREEN_SLOT
SCRIPT_CALLSLOTV fx_greenscreen_set_bg, 144+2, FX_GREENSCREEN_SLOT
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_interference_update, FX_INTERFERENCE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

GIF_SEGMENT 0.2, PLAYGIFS_DANCER

; Rotozoom
SCRIPT_CALL fx_clear
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_rotozoom3_animate, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_rotozoom3, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END

GIF_SEGMENT 0.2, PLAYGIFS_BIRD

; Particles
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_particles_update, FX_PARTICLES_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

; Vector text
SCRIPT_CALLSLOT fx_vectortext_init, FX_VECTORTEXT_SLOT
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_vectortext_update, FX_VECTORTEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END

; point cube effect
SCRIPT_CALLSLOT fx_vectorballs_init, FX_VECTORBALLS_SLOT
SCRIPT_CALLSLOT fx_vectorballs_set_small, FX_VECTORBALLS_SLOT
SCRIPT_SEGMENT_START    0.2
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_vectorballs_update, FX_VECTORBALLS_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END

; 3D shape
SCRIPT_CALLSLOT fx_3dshape_init, FX_3DSHAPE_SLOT
SCRIPT_CALLSLOT load_next_model, FX_3DCODE_SLOT
SCRIPT_CALLSLOT load_next_model, FX_3DCODE_SLOT
SCRIPT_CALLSLOT load_next_model, FX_3DCODE_SLOT
SCRIPT_CALLSLOT load_next_model, FX_3DCODE_SLOT
SCRIPT_CALLSLOT load_next_model, FX_3DCODE_SLOT
SCRIPT_CALLSLOTV fx_greenscreen_set_fg, 144+3, FX_GREENSCREEN_SLOT
SCRIPT_CALLSLOTV fx_greenscreen_set_bg, 144+4, FX_GREENSCREEN_SLOT

SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_3dshape_update, FX_3DSHAPE_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT    
SCRIPT_SEGMENT_END
ENDIF


; SM: we should somehow maybe start winding the demo down now toward the credits?
; its a bit of a jolt when they come in.

; Perhaps a vertical scrolling art gallery would be cool - some horsenburger masterpieces?
; A reminder of how cool teletext is.
; KC: Or save this for the Horsenburger picture disc?



;------------------------------------------------------------------------
; PART 4: THE END
;  a) Credits + Greets
;  b) Testcard + turn off TV
;------------------------------------------------------------------------

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

; The music is 34.5 seconds long


; credits intro
SCRIPT_CALLSLOTV fx_textscreen_reset_type_delay, 2, FX_CREDITSCROLL_SLOT
SCRIPT_CALLSLOTV fx_greenscreen_set_fg, 144+3, FX_GREENSCREEN_SLOT
SCRIPT_SEGMENT_START    2.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_textscreen_type_credits, FX_CREDITSCROLL_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END

;-----------------------------------------------------------
; image credits
;-----------------------------------------------------------
SCRIPT_SEGMENT_START    1.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear        
    SCRIPT_CALLSLOTV fx_teletext_drawpage, PAGE_HORSENBURGER, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    1.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear        
    SCRIPT_CALLSLOTV fx_teletext_drawpage, PAGE_KIERAN, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

SCRIPT_SEGMENT_START    1.5
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear        
    SCRIPT_CALLSLOTV fx_teletext_drawpage, PAGE_SIMON, FX_TELETEXT_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT       
SCRIPT_SEGMENT_END

; clear the screen on finish
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALL fx_buffer_clear
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALL fx_buffer_clear


SCRIPT_CALL shadow_set_single_buffer

SCRIPT_SEGMENT_START    34.5-7.0
;    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_creditscroll_update, FX_CREDITSCROLL_SLOT 
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
;    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
SCRIPT_SEGMENT_END

SCRIPT_CALL shadow_set_double_buffer

SCRIPT_CALL fx_music_stop

;----------------------------------------------------------- 
; Finish - show testcard
;-----------------------------------------------------------

SCRIPT_CALL fx_clear
SCRIPT_CALLSLOT fx_testcard_init, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap  
    SCRIPT_CALLSLOT fx_testcard, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_END

; Turn off TV - Screen needs to clear to a single dot in the centre!!
SCRIPT_CALL fx_music_stop
SCRIPT_CALL fx_clear
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap  
SCRIPT_CALLSLOT fx_testcard_dot, FX_TESTCARD_SLOT
SCRIPT_SEGMENT_END

; clear the screen on finish
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALL fx_buffer_clear
SCRIPT_CALL fx_buffer_swap
SCRIPT_CALL fx_buffer_clear

.segment_end

SCRIPT_END

.demo_script_end








;------------------------------------------------------------------------
; UNUSED FX
;------------------------------------------------------------------------

;----------------------------------------------------------
; line box effect
;-----------------------------------------------------------
; SM: gonna make the linebox demo do something more - like animated boxes/fractals etc.
; KC: I get the line box starting in the middle of the screen when I run through?  Uninitialised start pos?
; KC: removing for now as want to get the sequence tighter

; test segment - linebox
IF 0
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_greenscreen_update, FX_GREENSCREEN_SLOT
    SCRIPT_CALLSLOT fx_linebox_update, FX_LINEBOX_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT
SCRIPT_SEGMENT_END
ENDIF

; test segment - just rasters
IF 0
SCRIPT_SEGMENT_START    5.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_rasterbars_update, FX_RASTERBARS_SLOT
    SCRIPT_CALLSLOT fx_rasterbars_write_shadow, FX_RASTERBARS_SLOT
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
; Dot scroller
;-----------------------------------------------------------
IF 0            ; skip this - use as an intro to each section
SCRIPT_SEGMENT_START    20.0
    SCRIPT_CALL fx_buffer_swap  
    SCRIPT_CALL fx_buffer_clear    
    SCRIPT_CALLSLOT fx_dotscroller_update, FX_DOTSCROLLER_SLOT
    SCRIPT_CALLSLOT fx_mirrorfloor_update, FX_MIRRORFLOOR_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader, FX_TELETEXT_SLOT      
SCRIPT_SEGMENT_END
ENDIF

;-----------------------------------------------------------
; Earlier Rotozoomers
;-----------------------------------------------------------
IF 0
; Might kill this one - technically interesting, but way too slow
; KC: yes, too slow!  Next time!
SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_rotozoom1, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT     
SCRIPT_SEGMENT_END
ENDIF

IF 0
; was just a technical concept really - dump it
SCRIPT_SEGMENT_START    10.0
    SCRIPT_CALL fx_buffer_swap
    SCRIPT_CALLSLOT fx_rotozoom2, FX_ROTOZOOM_SLOT
    SCRIPT_CALLSLOT fx_teletext_drawheader2, FX_TELETEXT_SLOT         
SCRIPT_SEGMENT_END
ENDIF








;------------------------------------------------------------------------
; IDEAS
;------------------------------------------------------------------------
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



;------------------------------------------------------------------------
; KIERAN NOTES - 5/6/17
;------------------------------------------------------------------------
; Concept: Bitshifters hijacked Ceefax with our favourite old-school demo fx
; Target time: 3:30s
; Key beats + timings:

; 0. Loading: ~20s

; 1. Setup: ~40s
;    a. Tuning in the TV
;    b. Pages from Ceefax
;    c. Bitshifters hijacked your TV

; 2. Main 2D feature fx: ~60s
;    a. Plasma
;    b. Interference
;    c. Particles

; 3. Main 3D feature fx: ~60s
;    a. 3D points?
;    b. Vector balls
;    c. 3D wireframe
;    d. Vector text?

; 4. End: ~40s
;    a. Credits + greets
;    b. Testcard + turn off

; 5. General Linking fx:
;    a. Animated GIFs
;    b. Dotscroller
;    c. Starfield
;    d. Rasterbars
;    e. Mirror

; Need to get to the action within 60s and keep the overall length tight - less is more!
; Strength is that we can switch rapidly between fx so keep it snappy - we're not hiding any loading!
; Go from least to most impressive - probably start 2D and end 3D ("bringing Teletext to a new dimension")

; 6. FX polish:
;    a. Nice colour setups for Interference
;    b. More colour for particles + make rotation snappier
;    c. Different angles / configurations for dot scroller
;    c. Better anim for Bitshifters logo (could be a beat bar!)

; 7. Extra FX if time:
;    a. Port sinewave scroller
;    b. Linebox
;    c. Bouncing 2D sprites
;    d. Animated dot scroller
