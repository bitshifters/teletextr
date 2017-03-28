


IF 0
.bank_file0    EQUS "Bank0", 13
.bank_file1    EQUS "Bank1", 13
.bank_file2    EQUS "Bank2", 13
.bank_file3    EQUS "Bank3", 13
.myfile EQUS "Bank0  $"
ENDIF

; disk loader uses hacky filename format (same as catalogue) 
.bank_file0a   EQUS "Bank0  $"
.bank_file1a   EQUS "Bank1  $"
.bank_file2a   EQUS "Bank2  $"
.bank_file3a   EQUS "Bank3  $"


.intro_text0 EQUS "Teletextr OS V1.0", 13, 10, 0
.intro_text1 EQUS "Initializing Teletext system...", 13, 10, 0
.master_text EQUS "This demo is compatible with BBC Master 128 Only. :(", 13, 10, 0

.main
{
\\ ***** System initialise ***** \\

	\\ *FX 200,3 - clear memory on break as we use OS memory areas and can cause nasty effects
	LDA #200
	LDX #3
	JSR osbyte		


    jsr shadow_check_master
    beq is_master
    MPRINT    master_text
    rts
.is_master



    MPRINT    intro_text0
    MPRINT    intro_text1

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

IF 0
    ; cat info
    ldx #&00
    ldy #&0e
    jsr disksys_read_catalogue

    jsr disksys_get_numfiles

    MPRINT test_print_number
    tax
    dex
.cloop
    jsr disksys_get_filename
    dex
    bpl cloop

    ldx #LO(myfile)
    ldy #HI(myfile)
    jsr disksys_find_file
    MPRINT test_print_number

    lda #&80
    ldx #LO(myfile)
    ldy #HI(myfile)
    jsr disksys_load_file
ENDIF



	\\ load all banks
IF 1


    lda #0
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file0a)
    ldy #HI(bank_file0a)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    lda #1
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file1a)
    ldy #HI(bank_file1a)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    lda #2
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file2a)
    ldy #HI(bank_file2a)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    lda #3
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file3a)
    ldy #HI(bank_file3a)
    jsr disksys_load_file
    MPRINT loading_bank_text2
    
ELSE

    lda #0
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file0)
    ldy #HI(bank_file0)
    jsr file_stream
    MPRINT loading_bank_text2

    lda #1
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file1)
    ldy #HI(bank_file1)
    jsr file_stream
    MPRINT loading_bank_text2

    lda #2
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file2)
    ldy #HI(bank_file2)
    jsr file_stream
    MPRINT loading_bank_text2

    lda #3
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file3)
    ldy #HI(bank_file3)
    jsr file_stream
    MPRINT loading_bank_text2


ENDIF


    ; runtime
    
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