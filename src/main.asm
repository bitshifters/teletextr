_ENABLE_IRQ_VSYNC = TRUE

TIMER_latch = 20000-2		; 20ms = 1x vsync :)
TIMER_start = (TIMER_latch * 0.9)		; some % down the frame is our vsync point


.main
{
\\ ***** Main demo routine ***** \\


    
	\\ Set MODE 7
	LDA #22: JSR oswrch
	LDA #7: JSR oswrch

	\\ Turn off cursor by directly poking crtc
	SEI
	LDA #10: STA &FE00
	LDA #32: STA &FE01
	CLI	



    ; initialise shadow ram
    ; CAN ONLY DO THIS ONCE CODE IS IN PLACE TO ENSURE MEMORY &3000-&7C00 does not contain executable code
    jsr shadow_enable_hiram
IF USE_SHADOW_RAM
    jsr shadow_init_buffers
ENDIF



	\\ init
	lda #0
	sta vsync_time+0
	sta vsync_time+1
	sta vsync_count

	IF _ENABLE_IRQ_VSYNC
    lda #19:jsr osbyte
	JSR irq_init
	ENDIF

    \\ Start our event driven fx
    ldx #LO(event_handler)
    ldy #HI(event_handler)
    JSR start_eventv

;-------------------------------------------------------------
; Main loop
;-------------------------------------------------------------

	ldx #LO(demo_script_start)
	ldy #HI(demo_script_start)
	jsr script_init

    .loop
	IF _ENABLE_IRQ_VSYNC
	LDA vsync_count
	.wait_for_vsync
	CMP vsync_count
	BEQ wait_for_vsync
	ELSE
    lda #19:jsr osbyte
	ENDIF

	; get delta time since last update
	ldx	vsync_count
	lda #0
	sta vsync_count
	stx delta_time

	jsr script_update

\\ can never return to OS as we use all memory
    jmp loop
}





.event_handler
{
	php
	cmp #4
	bne not_vsync

	\\ Preserve registers
	pha:txa:pha:tya:pha

	; prevent re-entry
	lda re_entrant
	bne skip_update
	inc re_entrant

    ; update vsync counter
	inc vsync_time+0	; 5
	bne no_timehi		; 2/3
	inc vsync_time+1	; 5
.no_timehi

	IF _ENABLE_IRQ_VSYNC = FALSE
	inc vsync_count
	ENDIF

    ; call our music interrupt handler
	jsr fx_music_irq

	dec re_entrant
.skip_update

	\\ Restore registers
	pla:tay:pla:tax:pla

	\\ Return
    .not_vsync
	plp
	rts
.re_entrant EQUB 0
}

.player_init
{
	rts
}

.player_update
{
	rts
}


\ ******************************************************************
\ * IRQ
\ ******************************************************************

IF _ENABLE_IRQ_VSYNC
.irq_init
{
	SEI
	LDA IRQ1V:STA old_irqv
	LDA IRQ1V+1:STA old_irqv+1

	LDA #LO(irq_handler):STA IRQ1V
	LDA #HI(irq_handler):STA IRQ1V+1		; set interrupt handler

	LDA #64						; A=00000000
	STA &FE4B					; R11=Auxillary Control Register (timer 1 latched mode)

	LDA #&C0					; A=11000000
	STA &FE4E					; R14=Interrupt Enable (enable timer 1 interrupt)

	LDA #LO(TIMER_start)
	STA &FE44					; R4=T1 Low-Order Latches (write)
	LDA #HI(TIMER_start)
	STA &FE45					; R5=T1 High-Order Counter
	
	LDA #LO(TIMER_latch)
	STA &FE46
	LDA #HI(TIMER_latch)
	STA &FE47
	CLI

	RTS
}

.old_irqv
EQUW &FFFF

.irq_handler
{
	LDA &FC
	PHA

	LDA &FE4D
	AND #&40			; timer 1
	BEQ return_to_os

	\\ Acknowledge timer1 interrupt
	STA &FE4D

	\\ Increment vsync counter
	INC vsync_count

	\\ Pass on to OS IRQ handler
	.return_to_os
	PLA
	STA &FC
	JMP (old_irqv)		; RTI
}
ENDIF