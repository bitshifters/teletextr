\ ******************************************************************
\ *	Bootstrap loader code
\ ******************************************************************


.os_load_system   EQUS "LOAD System", 13
.os_load_main     EQUS "LOAD Main", 13
.os_load_sbank0   EQUS "LOAD SBank0", 13
.os_load_sbank1   EQUS "LOAD SBank1", 13


; disk loader uses hacky filename format (same as catalogue) 
; we use disk loader for SWR banks only
.bank_file0a   EQUS "Bank0  $"
.bank_file1a   EQUS "Bank1  $"
.bank_file2a   EQUS "Bank2  $"
.bank_file3a   EQUS "Bank3  $"



.intro_text0 EQUS "Teletextr OS V1.0", 13, 10, 0
.intro_text1 EQUS "Initializing Teletext system...", 13, 10, 0
.master_text EQUS "This demo is compatible with BBC Master 128 Only. :(", 13, 10, 0


.boot_entry
{
\\ ***** System initialise ***** \\

	\\ *FX 200,3 - clear memory on break as we use OS memory areas and can cause nasty effects
	lda #200
	ldx #3
	jsr osbyte		

    ; install the system utils at &900
    ldx #LO(os_load_system)
    ldy #HI(os_load_system)
    jsr oscli

    ; check system compatibility
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
.loading_bank_text EQUS "Loading bank... ", 0
.loading_bank_text2 EQUS "OK", 13, 10, 0
.test_print_number EQUS "%a", 13,10,0


    .swr_ok

IF 0
    MPRINT    swr_bank_text
    ldx #0
.swr_print_loop
    lda swr_ram_banks,x
    MPRINT    swr_bank_text2
    inx
    cpx swr_ram_banks_count
    bne swr_print_loop
ENDIF

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

    \\ install main code
    MPRINT loading_bank_text
    ldx #LO(os_load_main)
    ldy #HI(os_load_main)
    jsr oscli    
    MPRINT loading_bank_text2

	\\ load all SWR banks

    ; PARTY MODE - LOAD CATALOG ONCE ONLY
    jsr disksys_fetch_catalogue


    ; SWR 0
    MPRINT loading_bank_text  
    lda #0
    jsr swr_select_slot
    lda #&80
    ldx #LO(bank_file0a)
    ldy #HI(bank_file0a)
    jsr disksys_load_file
    MPRINT loading_bank_text2   

    ; SWR 1
    MPRINT loading_bank_text
    lda #1
    jsr swr_select_slot
    lda #&80
    ldx #LO(bank_file1a)
    ldy #HI(bank_file1a)
    jsr disksys_load_file
    MPRINT loading_bank_text2   

    ; SWR 2
    MPRINT loading_bank_text
    lda #2
    jsr swr_select_slot
    lda #&80
    ldx #LO(bank_file2a)
    ldy #HI(bank_file2a)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    ; SWR 3
    MPRINT loading_bank_text
    lda #3
    jsr swr_select_slot
    lda #&80
    ldx #LO(bank_file3a)
    ldy #HI(bank_file3a)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    \\ Install main & shadow ram banks

    ; shadow bank 0
    MPRINT loading_bank_text
    lda #SELECT_RAM_MAIN
    jsr shadow_select_ram
    ldx #LO(os_load_sbank0)
    ldy #HI(os_load_sbank0)
    jsr oscli   
    MPRINT loading_bank_text2

    ; shadow bank 1
    MPRINT loading_bank_text
    lda #SELECT_RAM_SHADOW
    jsr shadow_select_ram
    ldx #LO(os_load_sbank1)
    ldy #HI(os_load_sbank1)
    jsr oscli   
    ; reset ram
    lda #SELECT_RAM_MAIN
    jsr shadow_select_ram
    MPRINT loading_bank_text2

    ; runtime
    jmp main
}