


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
.bank_file4a   EQUS "SBank0 $"
.bank_file5a   EQUS "SBank1 $"

.intro_text0 EQUS "Teletextr OS V1.0", 13, 10, 0
.intro_text1 EQUS "Initializing Teletext system...", 13, 10, 0
.master_text EQUS "This demo is compatible with BBC Master 128 Only. :(", 13, 10, 0

.boot
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

    ; SWR 0
    lda #0
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file0a)
    ldy #HI(bank_file0a)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    ; SWR 1
    lda #1
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file1a)
    ldy #HI(bank_file1a)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    ; SWR 2
    lda #2
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file2a)
    ldy #HI(bank_file2a)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    ; SWR 3
    lda #3
    jsr swr_select_slot

    lda #&80
    ldx #LO(bank_file3a)
    ldy #HI(bank_file3a)
    jsr disksys_load_file
    MPRINT loading_bank_text2
    
    ; shadow bank 0
    lda #SELECT_RAM_MAIN
    jsr shadow_select_ram

    lda #&30
    ldx #LO(bank_file4a)
    ldy #HI(bank_file4a)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    ; shadow bank 1
    lda #SELECT_RAM_SHADOW
    jsr shadow_select_ram

    lda #&30
    ldx #LO(bank_file5a)
    ldy #HI(bank_file5a)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    ; runtime
    jmp main
}