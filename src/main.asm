


.bank_file0    EQUS "Bank0", 13
.bank_file1    EQUS "Bank1", 13
.bank_file2    EQUS "Bank2", 13
.bank_file3    EQUS "Bank3", 13



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
.swr_bank_text EQUS "Found %b", LO(swr_ram_banks_count), HI(swr_ram_banks_count), " SWR banks.", 13, 10, 0
.swr_bank_text2 EQUS " Bank %a", 13, 10, 0
.loading_bank_text EQUS "Loading bank", 13, 10, 0
.loading_bank_text2 EQUS "Bank loaded", 13, 10, 0
.test_print_number EQUS "%a", 13,10,0
    .swr_ok

    MPRINT    swr_bank_text
    ldx #0
.swr_print_loop
    lda swr_ram_banks,x
    MPRINT    swr_bank_text2
    inx
    cpx swr_ram_banks_count
    bne swr_print_loop
    
    MPRINT loading_bank_text


	\\ load all banks
    lda #0
	sei
    jsr swr_select_slot
	cli
    lda #&80
    ldx #LO(bank_file0)
    ldy #HI(bank_file0)
    jsr file_load
    MPRINT loading_bank_text2

    lda #1
	sei
    jsr swr_select_slot
	cli
    lda #&80
    ldx #LO(bank_file1)
    ldy #HI(bank_file1)
    jsr file_load
    MPRINT loading_bank_text2

    lda #2
	sei
    jsr swr_select_slot
	cli
    lda #&80
    ldx #LO(bank_file2)
    ldy #HI(bank_file2)
    jsr file_load
    MPRINT loading_bank_text2

    lda #3
	sei
    jsr swr_select_slot
	cli
    lda #&80
    ldx #LO(bank_file3)
    ldy #HI(bank_file3)
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

	inc vsync_time+0	; 5
	bne no_timehi		; 2/3
	inc vsync_time+1	; 5
.no_timehi 
	inc vsync_count


	; prevent re-entry
	lda re_entrant
	bne skip_update

	inc re_entrant



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