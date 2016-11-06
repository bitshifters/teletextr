	


.osfile_params			SKIP 18


;-------------------------------------------------------------------------
; Load a file
;-------------------------------------------------------------------------
; X=filename LSB
; Y=filename MSB
; A=load address MSB

.file_load
{
    \\ Set osfile param block
    stx osfile_params + 0
    sty osfile_params + 1
    sta osfile_params + 3
    lda #0
    sta osfile_params + 2

    ; fall into file_osfile
}


;-------------------------------------------------------------------------
; osfile call 
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------

.file_osfile
{
    \\ Set osfile param block
    lda #0
    sta osfile_params + 6

    \\ Issue osfile call
    ldx #LO(osfile_params)
    ldy #HI(osfile_params)
    lda #&FF
    jsr osfile

    rts
}
