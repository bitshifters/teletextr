


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
    lda #19:jsr osbyte

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
	inc vsync_count

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