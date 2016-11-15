
.swr_ram_banks          SKIP 4   ; 4 slots, each containing the rom bank ID of each available SW RAM bank or FF if none 
.swr_ram_banks_count    SKIP 1
.swr_rom_banks          SKIP 16  ; contains 0 if RAM or non-zero if ROM
.swr_slot_selected      SKIP 1  ; the currently selected slot ID


; scan for SWR banks
; mark swr_rom_banks as 0 if SWR or non-zero if ROM
; on exit A contains number of SWR banks, Z=1 if no SWR, or Z=0 if SWR
.swr_init
{
    sei
    lda &f4:pha

    ; scan for roms
    ldx #15
.rom_loop
    stx &fe30   ; select rom bank
    lda &8000   ; read byte
    tay         ; save
    eor #&FF    ; invert, so that we are know we are writing a different value 
    sta &8000   ; write byte
    tya
    sec
    sbc &8000   ; check that byte was written by comparing what we wrote with what we read back
    sta swr_rom_banks,x ; 0 if ram, non-zero if rom
    dex
    bpl rom_loop

    ; reset swr_ram_banks array
    lda #255
    sta swr_ram_banks+0
    sta swr_ram_banks+1
    sta swr_ram_banks+2
    sta swr_ram_banks+3

    ; put available ram bank id's into swr_ram_banks
    ldx #0
    ldy #0
.ram_loop
    lda swr_rom_banks,x
    beq next
    txa
    sta swr_ram_banks,y
    iny
    cpy #4
    beq finished
.next
    inx
    cpx #16
    bne ram_loop

.finished
    sty swr_ram_banks_count

    ; restore previous bank
    pla
    sta &fe30
    cli
    lda swr_ram_banks_count
    rts
}

; select the rom bank associated with the slot id given in A (0-3) 
; swr_init must have been called previously
;
; A BBC Master will have four 16Kb SWR banks
;
; on entry A contains slot id to be selected
; on exit A contains bank ID, N=0 if success, N=1 if failed
;   &F4 is updated with the selected ROM bank
;   swr_slot_selected contains the selected slot ID
;   does not preserve previously selected bank
; clobbers A,X
.swr_select_slot
{
    tax
    lda swr_ram_banks,X
    bmi bad_socket
    sta &f4
    sta &fe30
    sta swr_slot_selected
.bad_socket
    rts
}

; A contains ROM bank to be selected
.swr_select_bank
{
    sta &f4
    sta &fe30
    rts
}
