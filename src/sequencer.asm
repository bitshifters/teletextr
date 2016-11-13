
; update_routine - 0 if none, A contains number of frames to update, X/Y contain parameters
; init_routine - 0 if none, no parameters passed
; databank - the SWR databank containing the datafiles for this effect


MACRO EFFECT_HEADER    update_routine, init_routine, databank
    EQUW    init_routine
    EQUW    update_routine
    EQUB    databank
ENDMACRO



SCRIPTID_SEGMENT_START=1
SCRIPTID_SEGMENT_END=2

SCRIPTID_CALL=3
SCRIPTID_PLAY=4
SCRIPTID_PLAYV=5

SCRIPTID_END=255


; Call a routine
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

; Indicate the end of a segment
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



.sequence_time              EQUW 0
.sequence_ptr               EQUW 0
.sequence_segment_ptr       EQUW 0
.sequence_segment_time      EQUW 0
.sequence_segment_duration  EQUW 0
.sequence_segment_id        EQUB 0




; X/Y contain ptr to sequence data
.sequencer_init
{
    stx sequence_ptr+0
    sty sequence_ptr+1

    lda #0
    
    sta sequence_segment_ptr+0
    sta sequence_segment_ptr+1

    sta sequence_time+0
    sta sequence_time+1

    sta sequence_segment_time+0
    sta sequence_segment_time+1

    sta sequence_segment_duration+0
    sta sequence_segment_duration+1

    rts
}



; Get byte from sequence stream and return in A
; Does not advance the pointer.
.sequence_peek_byte
{
    lda sequence_ptr+0
    sta addr+1
    lda sequence_ptr+1
    sta addr+2
.addr
    lda &ffff
    rts
}

; Get byte from sequence stream and return in A
; sequence_ptr += 1
.sequence_fetch_byte
{
    lda sequence_ptr+0
    sta addr+1
    lda sequence_ptr+1
    sta addr+2
.addr    
    lda &ffff

    inc sequence_ptr+0
    bne done
    inc sequence_ptr+1
.done    
    rts    
}

; Get byte from sequence stream and return LSB in A,MSB in X
; sequence_ptr += 2
.sequence_fetch_word
{
    jsr sequence_fetch_byte
    sta temp
    jsr sequence_fetch_byte
    tax
    lda temp
    rts    
.temp EQUB 0
}

; call the routine at the current sequence ptr (word)
; consumes two bytes from the command stream
.sequence_call
{
    jsr sequence_fetch_byte
    sta call+1
    jsr sequence_fetch_byte
    sta call+2
.call
    jmp &ffff   ; use subroutine rts
}



; Update the sequencer script
.sequencer_text 
    EQUS "DT:%w"
    EQUW delta_time
    EQUS " T:%w"
    EQUW sequence_time
    EQUS " Ptr:%w"
    EQUW sequence_ptr
    EQUS " SegP:%w"
    EQUW sequence_segment_ptr    
    EQUS " SegT:%w"
    EQUW sequence_segment_time  
    EQUS " SegD:%w"
    EQUW sequence_segment_duration    
    EQUS " SegN:%b"
    EQUW sequence_segment_id

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

.sequencer_update
{
    jsr sequencer_process

    MPRINTMEM sequencer_text,&7800

    rts
}

.sequencer_process
{
    ; sequence_time += delta_time
    lda sequence_time+0
    clc
    adc delta_time
    sta sequence_time+0
    lda sequence_time+1
    adc #0
    sta sequence_time+1

    ; if not currently in a segment, skip to the command processor
    lda sequence_segment_ptr+1
    beq command_loop

    ; we are in a segment

    

    ; sequence_segment_time += delta_time
    lda sequence_segment_time+0
    clc
    adc delta_time
    sta sequence_segment_time+0
    lda sequence_segment_time+1
    adc #0
    sta sequence_segment_time+1

    ; if sequence_segment_time >= duration
    ;   segment finished, leave sequence ptr    
    ; else
    ;   reset sequence ptr to segment start
    lda sequence_segment_time+1
    cmp sequence_segment_duration+1
    bcc segment_not_finished
    lda sequence_segment_time+0
    cmp sequence_segment_duration+0
    bcc segment_not_finished

    ; segment finished

    lda #0
    sta sequence_segment_time+0
    sta sequence_segment_time+1
    sta sequence_segment_duration+0
    sta sequence_segment_duration+1
    sta sequence_segment_ptr+0
    sta sequence_segment_ptr+1    
    jmp command_loop    

.segment_not_finished
    ; so reset the sequence_ptr to the segment pointer
    lda sequence_segment_ptr+0
    sta sequence_ptr+0
    lda sequence_segment_ptr+1
    sta sequence_ptr+1

.command_loop

    ; take a look at the next command byte
    ; see if we've reached the end first.
    jsr sequence_peek_byte
    cmp #SCRIPTID_END
    bne command_start

    ; player will halt on this command
    ; since we havent consumed the last byte.
    rts

.command_start

    ; get the next command in the sequence
    jsr sequence_fetch_byte

.command_init
    cmp #SCRIPTID_CALL
    bne command_play

    jsr sequence_call
    jmp command_loop

.command_play
    cmp #SCRIPTID_PLAY
    bne command_playv

    jsr sequence_call
    jmp command_loop

.command_playv
    cmp #SCRIPTID_PLAYV
    bne command_segment_start

    ;TODO

    jsr sequence_fetch_word   ; offset
    jsr sequence_fetch_word   ; duration
    
    ; if (time>= (time+offset)) && (time < time+offset+duration)
    ;   jsr sequence_call
    jsr sequence_fetch_word  ; effect routine
    jmp command_loop

.command_segment_start
    cmp #SCRIPTID_SEGMENT_START
    bne command_segment_end

    inc sequence_segment_id
    jsr sequence_fetch_word   ; duration of segment
    sta sequence_segment_duration+0
    stx sequence_segment_duration+1

    ; stash the ptr to the first command in this segment
    ; so that it can be repeated for the duration of the segment
    lda sequence_ptr+0
    sta sequence_segment_ptr+0
    lda sequence_ptr+1
    sta sequence_segment_ptr+1

    lda #0
    sta sequence_segment_time+0
    sta sequence_segment_time+1
    
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
