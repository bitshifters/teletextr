
; Script command tokens
SCRIPTID_SEGMENT_START=1
SCRIPTID_SEGMENT_END=2
SCRIPTID_CALL=3
SCRIPTID_PLAY=4
SCRIPTID_PLAYV=5
SCRIPTID_END=255


; Calls a routine directly
MACRO SCRIPT_CALL    effect_addr
    EQUB    SCRIPTID_CALL
    EQUW    effect_addr
ENDMACRO

; Begin a segment of a given duration
; All script commands between this and SEGMENT_END will be looped until this duration has elapsed
MACRO SCRIPT_SEGMENT_START    duration
    EQUB    SCRIPTID_SEGMENT_START
    EQUW    duration*50
ENDMACRO

; Indicate the end of a segment - MUST be paired with a SCRIPT_SEGMENT_START
MACRO SCRIPT_SEGMENT_END
    EQUB    SCRIPTID_SEGMENT_END
ENDMACRO


; Play an effect within a segment, no arguments
MACRO SCRIPT_PLAY   effect_ptr
    EQUB    SCRIPTID_PLAY
    EQUW    effect_ptr
ENDMACRO

; Play an effect within a segment, started at T+offset and for the given duration
; If duration is 0, the effect will play until the end of the segment
; NOT YET IMPLEMENTED!
MACRO SCRIPT_PLAYV   effect_ptr, offset, duration
    EQUB    SCRIPTID_PLAYV
    EQUW    offset*50
    EQUW    duration*50
    EQUW    effect_ptr
ENDMACRO

; End of script marker. All scripts must have exactly one of these commands.
MACRO SCRIPT_END
    EQUB    SCRIPTID_END
ENDMACRO



.script_time              EQUW 0    ; elapsed time in 1/50th secs
.script_ptr               EQUW 0    ; current command ptr in the script
.script_segment_ptr       EQUW 0    ; ptr to the first command in the current segment that is processing
.script_segment_time      EQUW 0    ; elapsed time in the current segment
.script_segment_duration  EQUW 0    ; duration of the current segment
.script_segment_id        EQUB 0    ; id of the current segment (was mainly for debugging)



; Setup new script to run
; On entry, X/Y contain ptr to sequence data (lsb/msb)
.script_init
{
    stx script_ptr+0
    sty script_ptr+1

    lda #0
    
    sta script_segment_ptr+0
    sta script_segment_ptr+1

    sta script_time+0
    sta script_time+1

    sta script_segment_time+0
    sta script_segment_time+1

    sta script_segment_duration+0
    sta script_segment_duration+1

    rts
}



; Get byte from sequence stream and return in A
; Does not advance the pointer.
.script_peek_byte
{
    lda script_ptr+0
    sta addr+1
    lda script_ptr+1
    sta addr+2
.addr
    lda &ffff
    rts
}

; Get byte from sequence stream and return in A
; script_ptr += 1
.script_fetch_byte
{
    lda script_ptr+0
    sta addr+1
    lda script_ptr+1
    sta addr+2
.addr    
    lda &ffff

    inc script_ptr+0
    bne done
    inc script_ptr+1
.done    
    rts    
}

; Get byte from sequence stream and return LSB in A,MSB in X
; script_ptr += 2
.script_fetch_word
{
    jsr script_fetch_byte
    sta temp
    jsr script_fetch_byte
    tax
    lda temp
    rts    
.temp EQUB 0
}

; call the routine at the current sequence ptr (word)
; consumes two bytes from the command stream
.script_call
{
    jsr script_fetch_byte
    sta call+1
    jsr script_fetch_byte
    sta call+2
.call
    jmp &ffff   ; use subroutine rts
}


; Debug text
.script_text 
    EQUS "DT:%w"
    EQUW delta_time
    EQUS " T:%w"
    EQUW script_time
    EQUS " Ptr:%w"
    EQUW script_ptr
    EQUS " SegP:%w"
    EQUW script_segment_ptr    
    EQUS " SegT:%w"
    EQUW script_segment_time  
    EQUS " SegD:%w"
    EQUW script_segment_duration    
    EQUS " SegN:%b"
    EQUW script_segment_id

    EQUS " Seg1:%v"
    EQUW segment1 
IF FALSE   
    EQUS " Seg2:%v"
    EQUW segment2    
    EQUS " Seg3:%v"
    EQUW segment3    
ENDIF
    EQUS " SegE:%v"
    EQUW segment_end    
    

    EQUB 0


; Update the sequencer script
.script_update
{
    ; separated for easier reading
    jsr script_process

 ;   MPRINTMEM script_text,&7800

    ; DEBUG CODE
    ; check for space bar pressed to skip segment
    lda #&81:ldx #LO(-99):ldy #&FF:jsr &FFF4
    tya:beq nopress:lda debounce:bne nopress
    lda #0:sta script_segment_duration+0:sta script_segment_duration+1
    lda #1:.nopress sta debounce


    rts
.debounce EQUB 0
}

.script_process
{
    ; script_time += delta_time
    lda script_time+0
    clc
    adc delta_time
    sta script_time+0
    lda script_time+1
    adc #0
    sta script_time+1

    ; if not currently in a segment, skip to the command processor
    lda script_segment_ptr+1
    beq command_loop

    ; we are in a segment

    

    ; script_segment_time += delta_time
    lda script_segment_time+0
    clc
    adc delta_time
    sta script_segment_time+0
    lda script_segment_time+1
    adc #0
    sta script_segment_time+1

    ; if script_segment_time >= duration
    ;   segment finished, leave sequence ptr    
    ; else
    ;   reset sequence ptr to segment start
    lda script_segment_time+1
    cmp script_segment_duration+1
    bcc segment_not_finished
    lda script_segment_time+0
    cmp script_segment_duration+0
    bcc segment_not_finished

    ; segment finished

    lda #0
    sta script_segment_time+0
    sta script_segment_time+1
    sta script_segment_duration+0
    sta script_segment_duration+1
    sta script_segment_ptr+0
    sta script_segment_ptr+1    
    jmp command_loop    

.segment_not_finished
    ; so reset the script_ptr to the segment pointer
    lda script_segment_ptr+0
    sta script_ptr+0
    lda script_segment_ptr+1
    sta script_ptr+1

.command_loop

    ; take a look at the next command byte
    ; see if we've reached the end first.
    jsr script_peek_byte
    cmp #SCRIPTID_END
    bne command_start

    ; player will halt on this command
    ; since we havent consumed the last byte.
    rts

.command_start

    ; get the next command in the sequence
    jsr script_fetch_byte

.command_init
    cmp #SCRIPTID_CALL
    bne command_play

    jsr script_call
    jmp command_loop

.command_play
    cmp #SCRIPTID_PLAY
    bne command_playv

    jsr script_call
    jmp command_loop

.command_playv
    cmp #SCRIPTID_PLAYV
    bne command_segment_start

    ;TODO!

    jsr script_fetch_word   ; offset
    jsr script_fetch_word   ; duration
    
    ; if (time>= (time+offset)) && (time < time+offset+duration)
    ;   jsr script_call
    jsr script_fetch_word  ; effect routine
    jmp command_loop

.command_segment_start
    cmp #SCRIPTID_SEGMENT_START
    bne command_segment_end

    inc script_segment_id
    jsr script_fetch_word   ; duration of segment
    sta script_segment_duration+0
    stx script_segment_duration+1

    ; stash the ptr to the first command in this segment
    ; so that it can be repeated for the duration of the segment
    lda script_ptr+0
    sta script_segment_ptr+0
    lda script_ptr+1
    sta script_segment_ptr+1

    lda #0
    sta script_segment_time+0
    sta script_segment_time+1
    
    jmp command_loop

.command_segment_end
    cmp #SCRIPTID_SEGMENT_END
    bne command_unknown

    ; end of segment reached
    ; next update we will either repeat the segment or advance to next command
    rts

.command_unknown
    rts
}
