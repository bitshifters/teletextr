


.bank_file_music    EQUS "Bank0", 13

MUSIC_SLOT_NO = 0

.main
{
\\ ***** System initialise ***** \\

	\\ *FX 200,3 - clear memory on break as we use OS memory areas and can cause nasty effects
	LDA #200
	LDX #3
	JSR osbyte			


    jsr swr_init
    bne swr_ok

    MPRINT swr_fail_text
    rts

.swr_fail_text EQUS "No SWR banks found.", 13, 10, 0
.swr_bank_text EQUS "Found % SWR banks.", 13, 10, 0
.swr_bank_text2 EQUS " Bank %", 13, 10, 0
.loading_bank_text EQUS "Loading bank", 13, 10, 0
.loading_bank_text2 EQUS "Bank loaded", 13, 10, 0
.test_print_number EQUS "%", 13,10,0
    .swr_ok

    MPRINTAP    swr_bank_text,swr_ram_banks_count
    ldx #0
.swr_print_loop
    lda swr_ram_banks,x
    MPRINTA    swr_bank_text2
    inx
    cpx swr_ram_banks_count
    bne swr_print_loop
    
    MPRINT loading_bank_text

	\\ Initialise music player - pass in VGM_stream_data address
	\\ parses header from stream

    lda #MUSIC_SLOT_NO
    jsr swr_select_slot
    lda #&80
    ldx #LO(bank_file_music)
    ldy #HI(bank_file_music)
    jsr file_load

    MPRINT loading_bank_text2
    

    ; runtime
    
	\\ Set MODE 7
	LDA #22: JSR oswrch
	LDA #7: JSR oswrch

	\\ Turn off cursor by directly poking crtc
	SEI
	LDA #10: STA &FE00
	LDA #32: STA &FE01
	CLI	


	LDX #&00
	LDY #&80
	JSR	vgm_init_stream

    \\ Start our event driven fx
    ldx #LO(event_handler)
    ldy #HI(event_handler)
    JSR start_eventv

;-------------------------------------------------------------
; Main loop
;-------------------------------------------------------------

\\ Initialise effect layers
 	jsr effect_copybuffer_init
	jsr effect_3dshape_init

    .loop
    lda #19:jsr osbyte

	; get delta time since last update
	ldx	vsync_count
	lda #0
	sta vsync_count
	stx delta_time

\\ render effect layers
 	jsr effect_copybuffer_update

	jsr effect_greenscreen_update
	jsr effect_linebox_update

	jsr effect_copperbars_update
	jsr effect_3dshape_update


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

	inc vsync_time+0	; 5
	bne no_timehi		; 2/3
	inc vsync_time+1	; 5
.no_timehi 
	inc vsync_count


    lda &f4
    tay

    ; page in the music bank
    lda #MUSIC_SLOT_NO
    jsr swr_select_slot

	\\ Poll the music player
	jsr poll_player
    
    ; restore previously paged ROM bank
    tya
    jsr swr_select_bank

  ;  lda#65:jsr oswrch

	\\ Restore registers
	pla:tay:pla:tax:pla

	\\ Return
    .not_vsync
	plp
	rts
}


\ ******************************************************************
\ *	Event Vector Routines
\ ******************************************************************

\\ System vars
.old_eventv				SKIP 2

.start_eventv				; new event handler in X,Y
{
	\\ Remove interrupt instructions
	lda #NOP_OP
	sta PSG_STROBE_SEI_INSN
	sta PSG_STROBE_CLI_INSN
	
	\\ Set new Event handler
	sei
	LDA EVENTV
	STA old_eventv
	LDA EVENTV+1
	STA old_eventv+1

	stx EVENTV
	sty EVENTV+1
	cli
	
	lda #0
	sta vsync_time+0
	sta vsync_time+1
	sta vsync_count

	\\ Enable VSYNC event.
	lda #14
	ldx #4
	jsr osbyte
	rts
}
	
.stop_eventv
{
	\\ Disable VSYNC event.
	lda #13
	ldx #4
	jsr osbyte

	\\ Reset old Event handler
	SEI
	LDA old_eventv
	STA EVENTV
	LDA old_eventv+1
	STA EVENTV+1
	CLI 

	\\ Insert interrupt instructions back
	lda #SEI_OP
	sta PSG_STROBE_SEI_INSN
	lda #CLI_OP
	sta PSG_STROBE_CLI_INSN
	rts
}
