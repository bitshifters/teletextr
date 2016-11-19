; DFS/ADFS Disk op routines
; http://chrisacorns.computinghistory.org.uk/docs/Acorn/Manuals/Acorn_DiscSystemUGI2.pdf

DISKSYS_DEBUG = FALSE

.osword_params
.osword_params_drive
EQUB 0				; drive
.osword_params_address
EQUD 0				; address
EQUB &03			; number params
EQUB &53			; command = read data multi-sector
.osword_params_track
EQUB 0				; logical track
.osword_params_sector
EQUB 0				; logical sector
.osword_params_size_sectors
EQUB &2A			; sector size / number sectors = 256 / 10
.osword_params_return
EQUB 0				; returned error value

; Returns last diskop error code in A
.disksys_get_error
{
    lda osword_params_return
    rts
}


; on entry
; X = track number (0-79)
; Y = sector number (0-9)
; max 80 tracks x 10 sectors = 800 sectors
.disksys_seek
{
    stx osword_params_track
    sty osword_params_sector
    rts
}




; on entry
; A = number of sectors to read (0-31)
; X = destination memory address LSB
; Y = destination memory address MSB
; if previous seek was to the first sector on a track, and A=10 then a complete track will be read.
.disksys_read_sectors
{
	\\ Store sector count in params block
    and #&1f
    ora #&20
	sta osword_params_size_sectors

	\\ Update load address in params block
    stx osword_params_address+0
	sty osword_params_address+1

	\\ Make DFS read multi-sector call
	ldx #LO(osword_params)
	ldy #HI(osword_params)
	lda #&7F
	jsr osword

	\\ Error value returned in osword_params_return
    rts
}

.disksys_catalogue_addr     EQUW 0

; set the memory address where the disk catalogue will be stored
; on entry
; X = catalogue memory address LSB
; Y = catalogue memory address MSB
.disksys_set_catalogue_addr
{
    stx disksys_catalogue_addr+0
    sty disksys_catalogue_addr+1
    rts
}

; on entry
; X = destination memory address LSB
; Y = destination memory address MSB
; on exit
; 512 bytes written to buffer in X/Y
.disksys_read_catalogue
{
    jsr disksys_set_catalogue_addr

    ldx #0
    ldy #0
    jsr disksys_seek
    lda #2
    ldx disksys_catalogue_addr+0
    ldy disksys_catalogue_addr+1
    jsr disksys_read_sectors    
    rts
}



; on entry
; X is ID of the file
; Assumes disksys_read_catalogue has been called prior
; X, Y is preserved
; TEST FUNCTION
.disksys_get_filename
{
    txa
    pha

    lda disksys_catalogue_addr+0
    sta addr+1
    lda disksys_catalogue_addr+1
    sta addr+2

    txa
    asl a
    asl a
    asl a
    clc
    adc #8
    tax    

    ldy #8
.addr
    lda &ffff,x
    jsr &ffee
    inx
    dey
    bne addr

    pla
    tax
    rts
}

; Returns number of files on the disk
; X/Y preserved
.disksys_get_numfiles
{
    lda disksys_catalogue_addr+0
    clc
    adc #5
    sta addr+1
    lda disksys_catalogue_addr+1
    adc #1
    sta addr+2
.addr
    lda &ffff ; get numfiles (is *8)
    ; divide numfiles by 8
    lsr a
    lsr a
    lsr a
    rts
}


; Returns id of a file on the disk (0-31)
; returns 255 if not found
; X = filename address LSB
; Y = filename address MSB
; filename must be an 8 byte format where D is directory "NNNNNNND"
; filename IS case sensitive.
; clobbers &9c-&9f ZP
.disksys_find_file
{
    stx comp_addr2+1
    sty comp_addr2+2
 ;   stx comp_addr3+1
 ;   sty comp_addr3+2

    lda disksys_catalogue_addr+0
    clc
    adc #8
    sta comp_addr+1
    lda disksys_catalogue_addr+1
    adc #0
    sta comp_addr+2

    ; get numfiles
    jsr disksys_get_numfiles    
    sta counter+1    

;loop through files looking for exact match
    ldx #0
.check_loop
    ldy #7
.comp_loop

;.comp_addr3
;    lda &ffff,y
;    MPRINT   ftxt3  

.comp_addr
    lda &ffff,y     ; modified

  
.comp_addr2
    cmp &ffff,y     ; modified

    bne failed
    dey
    bpl comp_loop
    ; found it, return id
    txa
;    MPRINT   ftxt  
    rts
;.ftxt EQUS "Found it %a",13,10,0
;.ftxt2 EQUS "Checking %a",13,10,0
;.ftxt3 EQUS "With %a",13,10,0
;.ftxt4 EQUS "NO MATCH", 13,10,0

.failed
;    MPRINT   ftxt4  

    lda comp_addr+1
    clc
    adc #8
    sta comp_addr+1
    lda comp_addr+2
    adc #0
    sta comp_addr+2
    inx
.counter
    cpx #123        ; modified
    beq end
    jmp check_loop
.end
    ; not found
    lda #255
    rts
}



; returns file attributes for given file id
; on entry
; A=file id (0-31)
; on exit
; X=attributes LSB
; Y=attributes MSB
.disksys_file_info
{
    asl a
    asl a
    asl a
    clc
    adc #8
    adc disksys_catalogue_addr+0
    tax
    lda disksys_catalogue_addr+1
    adc #1
    tay
    rts
}


; A=memory address MSB (page aligned)
; X=filename address LSB
; Y=filename address MSB
; clobbers memory &0e00 to &10ff
.disksys_load_file
{
    sta transfer_addr+2

    ; get the currently selected ROM/RAM bank
    ; BEFORE we do any DFS related work since that will page the DFS ROM in
    lda &f4
    sta swr_select+1    

    txa:pha:tya:pha

    ; load disk catalogue
    ldx #&00
    ldy #&0e
    jsr disksys_read_catalogue

    pla:tay:pla:tax

    jsr disksys_find_file
    bpl continue
    ; file not found
    rts
.file_length    EQUB 0,0,0
.file_sector    EQUB 0,0
.file_sectors   EQUW 0
;.file_addr      EQUB 0
.txt_sector EQUS "sector %w", LO(file_sector), HI(file_sector), 13,10,0
.txt_length EQUS "length %w", LO(file_length), HI(file_length), 13,10,0
.txt_sectors EQUS "sectors %w", LO(file_sectors), HI(file_sectors), 13,10,0
.txt_t1 EQUS "Track %a", 13,10,0
.txt_s1 EQUS "Sector %a", 13,10,0
.txt_l1 EQUS "Loading to %a", 13,10,0

.continue
    ; get attributes
    jsr disksys_file_info
    ; we ignore load & exec address
    ; just need length & start sector 
    stx &9e
    sty &9f

    ldy #4
    lda (&9e),y
    sta file_length+0
    iny
    lda (&9e),y
    sta file_length+1
    iny
    lda (&9e),y
    lsr a
    lsr a
    lsr a
    lsr a
    and #3
    sta file_length+2

    lda (&9e),y
    and #3
    sta file_sector+1
    iny
    lda (&9e),y
    sta file_sector+0    

    lda file_length+1
    sta file_sectors+0
    lda file_length+2
    sta file_sectors+1
    lda file_length+0
    beq pagea
    inc file_sectors+0
    bcc pagea
    inc file_sectors+1
.pagea

    MPRINT txt_sector
    MPRINT txt_length
    MPRINT txt_sectors

    ; seek to start of file

;   div sector offset by 10 to get track/sector
    lda file_sector+1
    ldx #8
    asl file_sector+0
.l1 
    rol a
    bcs l2
    cmp #10
    bcc l3
.l2 
    sbc #10
    sec
.l3 
    rol file_sector+0
    dex
    bne l1    

    MPRINT txt_s1
    sta file_sector+1   ; now contains sector
    
    lda file_sector+0   ; now contains track
    MPRINT txt_t1
    


.load_loop

    ; seek to sector
    ldx file_sector+0   ; track
    ldy file_sector+1   ; sector
    jsr disksys_seek

    ; move to next sector
    inc file_sector+1
    lda file_sector+1
    cmp #10
    bne same_track
    ; move to next track
    lda #0
    sta file_sector+1
    inc file_sector+0
.same_track

    lda file_sectors+0
    bne fetch
    lda file_sectors+1
    bne fetch

    MPRINT txt_sectors    
    ; finished
    rts
.fetch

    lda transfer_addr+2
    MPRINT txt_l1


    ; load the sector
    lda #1
    ldx #0
    ldy #&10
    jsr disksys_read_sectors

    sei
.swr_select
    ; select the destination ROM/RAM bank that was selected on entry to the routine 
    lda #&FF            ; MODIFIED
    jsr swr_select_bank


    ldx #0
.transfer
    lda &1000,x
.transfer_addr
    sta &ff00,x         ; modified
    inx
    bne transfer
    cli


    inc transfer_addr+2


    lda file_sectors+0
    sec
    sbc #1
    sta file_sectors+0
    lda file_sectors+1
    sbc #0
    sta file_sectors+1
    jmp load_loop

    rts


.addr
    sta &ff00,x     ; modified

}

; Sector 00
; &00 to &07 First eight bytes of the 13-byte disc title
; &08 to &0E First file name
; &0F Directory of first file name
; &10 to &1E Second file name
; &1F Directory of second file name . . . .
;  . . and so on
; Repeated up to 31 files

; Sector 01
; &00 to &03 Last four bytes of the disc title
; &04 Sequence number
; &05 The number of catalogue entries multiplied by 8
; &06 (bits 0,1) Number of sectors on disc (two high order bits of 10 bit
; number)
; (bits 4,5) !BOOT start-up option
; &07 Number of sectors on disc (eight low order bits of 10 bit
; number)
; &08 First file's load address, low order bits
; &09 First file's load address, middle order bits
; &OA First file's exec address, low order bits
; &0B First file's exec address, middle order bits
; &0C First file's length in bytes, low order bits
; &0D First file's length in bytes, middle order bits
; &0E (bits 0,1) First file's start sector, two high order bits of 10 bit
; number
; (bits 2,3) First file's load address, high order bits
; (bits 4,5) First file's length in bytes, high order bits
; (bits 6,7) First file's exec address, high order bits
; &0F First file's start sector, eight low order bits of 10 bit
; number
; . . . and so on
; Repeated for up to 31 files


