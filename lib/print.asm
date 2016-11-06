

; print given string with one argument value supplied in A
; preserves all registers
MACRO MPRINTA    stringaddr
    sta &9f:txa:pha:tya:pha
    ldx #LO(stringaddr)
    ldy #HI(stringaddr)
    lda &9f
    jsr print_arg
    pla:tay:pla:tax:lda &9f
ENDMACRO

; print given string with one argument value as parameter address
; preserves all registers
MACRO MPRINTAP    stringaddr,valueadr
    pha:txa:pha:tya:pha
    ldx #LO(stringaddr)
    ldy #HI(stringaddr)
    lda valueadr
    jsr print_arg
    pla:tay:pla:tax:pla
ENDMACRO





; print given string, no arguments
; preserves all registers
MACRO MPRINT        stringaddr  
    pha:txa:pha:tya:pha
    ldx #LO(stringaddr)
    ldy #HI(stringaddr)
    jsr print
    pha:txa:pha:tya:pha    
ENDMACRO

; X/Y address of ZT string to print
; does not process any arguments
.print
{
    stx output_chr+1
    sty output_chr+2
    ldx #0    
.output_chr 
    lda &FFFF,X
    beq done
    jsr oswrch
    inx
    jmp output_chr
.done
    rts
}


; X/Y address of ZT string to print containing one 8-bit arg, where embedded % is replaced by arg value
; A is value of argument
; EQUS "text %"
.print_arg
{
    stx output_chr+1
    sty output_chr+2
    tay
    ldx #0
.output_chr 
    lda &FFFF,X
    beq done
    cmp #'%'
    bne no_arg

    ; convert binary number to decimal
  

    tya
    jsr bin2bcd8
    ; 16 bit bcd_out result
    ; but 8 bit only needs 3 decimal chars

    lda bcd_out+1
    and #&0f
    bne no_lz
    lda bcd_out+0
    and #&f0
    beq skip_lz2    
    bne skip_lz
.no_lz
    clc
    adc #48
    jsr oswrch
.skip_lz
    lda bcd_out+0
    and #&f0
    lsr a
    lsr a
    lsr a
    lsr a
    clc
    adc #48
    jsr oswrch

.skip_lz2
    lda bcd_out+0
    and #&0f
    clc
    adc #48

.no_arg    
    jsr oswrch
    inx
    jmp output_chr
.done
    rts
}

     
.binary_in       EQUW 0 ; value to convert (LSB first) 65536
.bcd_out        SKIP 3 ; bcd_out output, input of 0xffff will become $36, $55, $06

; A contains 8-bit value to convert
.bin2bcd8
{
    sta binary_in+0
    lda #0
    sta binary_in+1
}
.bin2bcd16
{
    TXA
    PHA

    SED         ; Switch to decimal mode
    LDA #0      ; Ensure the result is clear
    STA bcd_out+0
    STA bcd_out+1
    STA bcd_out+2
    LDX #16     ; The number of source bits
        
.CNVBIT     
    ASL binary_in+0   ; Shift out one bit
    ROL binary_in+1
    LDA bcd_out+0   ; And add into result
    ADC bcd_out+0
    STA bcd_out+0
    LDA bcd_out+1   ; propagating any carry
    ADC bcd_out+1
    STA bcd_out+1
    LDA bcd_out+2   ; ... thru whole result
    ADC bcd_out+2
    STA bcd_out+2
    DEX         ; And repeat for next bit
    BNE CNVBIT
    CLD         ; Back to binary
    PLA
    TAX
    rts
}