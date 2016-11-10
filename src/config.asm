; update_routine - 0 if none, A contains number of frames to update, X/Y contain parameters
; init_routine - 0 if none, no parameters passed
; databank - the SWR databank containing the datafiles for this effect


MACRO EFFECT_HEADER    update_routine, init_routine, databank
    EQUW    init_routine
    EQUW    update_routine
    EQUB    databank
ENDMACRO



; Fade off the BBC Computer screen
; CEEFAX page
; bzz with TESTCARD "BITSHIFTERS TV" & 1Khz tone
; flicker off
; music starts
;
; bitshifters presents
; 'teletextr demo'