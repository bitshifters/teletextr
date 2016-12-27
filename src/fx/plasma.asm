
; cheezy plasma demo
; achieves single-colour-character "pixels" by abusing hold graphics
; doesn't seem to work in jsbeeb for some reason

; plasma animation vars
.pnt_tab EQUD 0
.t1 EQUB 0
.t2 EQUB 0
.t3 EQUB 0
.t4 EQUB 0

; hacky cos table
.fx_plasma_cos
    FOR i, 0, 256
        EQUB 60*(COS(i*PI/32))
    NEXT

; rainbow-ish palette
; could easily be optimized to used less memory but slower to render
.fx_plasma_colour
    FOR i, 0, 32:EQUB 144+1:NEXT
    FOR i, 0, 32:EQUB 144+1:NEXT
    FOR i, 0, 32:EQUB 144+3:NEXT
    FOR i, 0, 32:EQUB 144+2:NEXT
    FOR i, 0, 32:EQUB 144+6:NEXT
    FOR i, 0, 32:EQUB 144+4:NEXT
    FOR i, 0, 32:EQUB 144+5:NEXT
    FOR i, 0, 32:EQUB 144+5:NEXT
    

; call once before the animation routine
.old_irqv
EQUW 0

.fx_plasma_init
{
    jsr fx_buffer_clear



    lda #158    ; hold graphics
    ldx #0
	jsr mode7_set_column_shadow_fast

	lda #144+7  ; white graphics
    ldx #1
	jsr mode7_set_column_shadow_fast


    lda #255    ; full block (used as control character for rest of line)
    ldx #2
	jsr mode7_set_column_shadow_fast    

    lda #144+7  ; white block 
    ldx #39
	jsr mode7_set_column_shadow_fast

    SEI
	LDX #&FF					; X=11111111
	STX &FE44					; R4=T1 Low-Order Latches (write)
	STX &FE45					; R5=T1 High-Order Counter
	STX &FE46
	STX &FE47
	
	LDA #64						; A=00000000
	STA &FE4B					; R11=Auxillary Control Register (timer 1 latched mode)

	LDA #&7F					; A=01111111
	STA &FE4E					; R14=Interrupt Enable (disable all interrupts)

	LDA #&C2					; A=11000010
	STA &FE4E					; R14=Interrupt Enable (enable main_vsync and timer interrupt)

    lda #9
    sta &fe00
    lda #8                      ; R9 = X - 2
    sta &fe01

	LDA &204:STA old_irqv
	LDA &205:STA old_irqv+1
	
	LDA #LO(main_irq):STA &204
	LDA #HI(main_irq):STA &205		; set interrupt handler
    CLI

    rts
}

TIMER_initial = (40 * 64) - 2			; 
TIMER_latch = (6 * 25 * 64) - 2				; 

.main_irq_flag
EQUB 0

.main_irq
{
	LDA &FC
	PHA

	LDA &FE4D
    AND #&40
    BNE irqtimer

    .irqvsync
    ; don't acknowledge vsync otherwise *fx19 doesn't work

	LDA #LO(TIMER_initial)
	STA &FE44					; R4=T1 Low-Order Latches (write)
	LDA #HI(TIMER_initial)
	STA &FE45					; R5=T1 High-Order Counter
	
	LDA #LO(TIMER_latch)
	STA &FE46
	LDA #HI(TIMER_latch)
	STA &FE47

    LDA #0
    STA main_irq_flag

    .exit_vsync
    PLA
    STA &FC
    JMP (old_irqv)

    .irqtimer
    STA &FE4D       ; ack timer 1

    LDA main_irq_flag
    BNE second_part

    ; default MODE 7
    ; R4 = vertical total rows = 30 = 31 - 1 = 25 + 6 - 1
    ; R6 = vertical displayed rows = 25
    ; R7 = vertical sync position = 27 = 25 + 2
    ; R9 = scanlines per character = 18 = 20 - 2 (interlaced)
IF 1
    ; first part
 	\\ CRTC cycle 25 - 1 rows
	LDA #4: STA &FE00
	LDA #24: STA &FE01				; 
	
	\\ Never generate vsync
	LDA #7: STA &FE00
	LDA #&ff: STA &FE01				; never generate vsync
	
	\\ Visible rows = 25
	LDA #6: STA &FE00
	LDA #25: STA &FE01				; 

    \\ Vertical total adjust
    LDA #5: STA &FE00
    LDA #0: STA &FE01
ENDIF

    JMP exit_timer

    .second_part
IF 1
    ; should restart data from &7c00
 	\\ CRTC cycle 25 - 1 rows
	LDA #4: STA &FE00
	LDA #30: STA &FE01				; 
	
	\\ Never generate vsync
	LDA #7: STA &FE00
	LDA #27: STA &FE01			;
	
	\\ Visible rows = 16
	LDA #6: STA &FE00
	LDA #25: STA &FE01				; 

    \\ Vertical total adjust
    LDA #5: STA &FE00
    LDA #2: STA &FE01
ENDIF

    .exit_timer
    INC main_irq_flag

    PLA
    STA &FC
    RTI
}


.fx_plasma
{
;    jsr fx_plasma_rand
;   rts



    lda pnt_tab+0
    sta t1
    lda pnt_tab+1
    sta t2

    lda #LO(MODE7_VRAM_SHADOW)
    sta addr+1
    lda #HI(MODE7_VRAM_SHADOW)
    sta addr+2

    ldy #0
.yloop
    lda pnt_tab+2
    sta t3
    lda pnt_tab+3
    sta t4

    ldx #3
    tya
    pha
.xloop
    ldy t1
    lda fx_plasma_cos,y
    ldy t2
    clc
    adc fx_plasma_cos,y
    ldy t3
    adc fx_plasma_cos,y
    ldy t4
    adc fx_plasma_cos,y

    tay
    lda fx_plasma_colour,y
.addr
    sta &ffff,x

    inc t3
    inc t3
    inc t3
    inc t4
    inc t4

    inx
;    inx        ; extra inx if you want square 'pixels' since teletext chars are rectangular
    cpx #39
    bne xloop


    inc t1
    inc t1
    inc t2


    lda addr+1
    clc
    adc #40
    sta addr+1
    lda addr+2
    adc #0
    sta addr+2

    pla
    tay
    iny
    cpy #25
    bne yloop


    inc pnt_tab+0
    inc pnt_tab+1
    inc pnt_tab+1
    inc pnt_tab+2
    inc pnt_tab+2
    inc pnt_tab+2
    inc pnt_tab+3
    inc pnt_tab+3
    inc pnt_tab+3
    inc pnt_tab+3



    rts
}


; some test junk functions
.random
{
    lda random_seed
    beq doEor
    asl a
    beq noEor ;if the input was $80, skip the EOR
    bcc noEor
.doEor
    eor #&1d
.noEor  
    sta random_seed
    rts
}
.random_seed EQUB 59    
.random_seed2 EQUB 59

.fx_plasma_rand
{
    lda random_seed2
    sta random_seed
;    inc random_seed2

	lda #144+7
    ldx #1
	jsr mode7_set_column_shadow_fast

    lda #158
    ldx #0
	jsr mode7_set_column_shadow_fast

    lda #255
    ldx #2
	jsr mode7_set_column_shadow_fast    

    lda #144+7
    ldx #39
	jsr mode7_set_column_shadow_fast  

    lda #LO(MODE7_VRAM_SHADOW)
    sta store+1
    lda #HI(MODE7_VRAM_SHADOW)
    sta store+2

    ldy #25
.yloop
    ldx #3
    tya:pha
.xloop



    jsr random
    and #7
    tay
    lda colour_table,y
.store
    sta &ffff,x
    inx
    cpx #39
    bne xloop

    pla:tay

    lda store+1
    clc
    adc #40
    sta store+1
    lda store+2
    adc #0
    sta store+2

    dey
    bne yloop

    rts
.colour_table EQUB 158,145,146,147,148,149,150,151
}