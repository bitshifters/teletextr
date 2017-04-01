; General file loading / streaming routines	


FILESYS_DEBUG=FALSE
FILESYS_BUFFER_ADDR = SCRATCH_RAM_ADDR ; must be page aligned
FILESYS_BUFFER_SIZE = 1 ; PAGES TO READ, MUST BE ONE (for now)


;-------------------------------------------------------------------------
; Load a file
;-------------------------------------------------------------------------
.osfile_params			SKIP 18

; X=filename LSB
; Y=filename MSB
; A=load address MSB

.file_load
{
    \\ Set osfile param block
    stx osfile_params + 0
    sty osfile_params + 1
    sta osfile_params + 3
    lda #0
    sta osfile_params + 2

    ; fall into file_osfile
}


;-------------------------------------------------------------------------
; osfile call 
; loads a file into memory
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------


.file_osfile
{
    \\ Set osfile param block
    lda #0
    sta osfile_params + 6

    \\ Issue osfile call
    ldx #LO(osfile_params)
    ldy #HI(osfile_params)
    lda #&FF    ; loadfile
    jsr osfile

    rts
}


; File streaming utilities
; Note that only one file can be open at once.

;-------------------------------------------------------------------------
; Open a file for reading
;-------------------------------------------------------------------------
; entry
;  X=filename LSB
;  Y=filename MSB
; exit
;  no outputs
.osgbpb_params SKIP 13

IF FILESYS_DEBUG
.file_text EQUS "Opened file %b", LO(osgbpb_params), HI(osgbpb_params), 13,10,0
.file_text2 EQUS "Could not open file", 13,10, 0
.file_text3 EQUS "Could not read file", 13,10, 0
.file_text4 EQUS "Reading file", 13,10, 0
.file_text5 EQUS "Bad handle for read file", 13,10, 0
ENDIF

.file_open
{
    lda #&40    ; open for read
    jsr osfind
    ; stash the opened file handle
    sta osgbpb_params+0

    bne open_ok
IF FILESYS_DEBUG    
    MPRINT file_text2
ENDIF
    rts

.open_ok

    ; set memory ptr to 0
    lda #0
    sta osgbpb_params+1
    sta osgbpb_params+2        
    sta osgbpb_params+3
    sta osgbpb_params+4

    ; set read length to 0
    sta osgbpb_params+5
    sta osgbpb_params+6
    sta osgbpb_params+7
    sta osgbpb_params+8 

    ; set file offset to 0
    sta osgbpb_params+9
    sta osgbpb_params+10 
    sta osgbpb_params+11
    sta osgbpb_params+12

IF FILESYS_DEBUG
    MPRINT file_text
ENDIF
    rts
}

;-------------------------------------------------------------------------
; Read data from the currently open file
;-------------------------------------------------------------------------
; entry
;  X=buffer address LSB
;  Y=buffer address MSB
;  A=number of 256 byte pages to read
;  so max bytes that can be read in one call is 65280
; exit
;  returns C=1 on error
;  if eof is reached before 256 bytes are read, dword at osgbpb_params+5 contains number of bytes that could not be read
.file_read
{
    ; set read length msb (eg. bytes*256)
    sta osgbpb_params+6 

    lda osgbpb_params+0
    bne file_ok
    ; invalid file handle
IF FILESYS_DEBUG
    MPRINT file_text5
ENDIF
    sec
    rts

.file_ok
IF FILESYS_DEBUG
;    MPRINT file_text
    MPRINT file_text4
ENDIF
    ; store the read memory ptr address
    stx osgbpb_params+1
    sty osgbpb_params+2

    ; everything else initialised in file_open

    lda #3      ; read data from file to memory, updating read offset ptr sequentially
    ldx #LO(osgbpb_params)
    ldy #HI(osgbpb_params)    
    jsr osgbpb
    ; carry flag will be clear if requested number of bytes were successfully read

IF FILESYS_DEBUG    
    php
    bcc read_ok
    MPRINT file_text3
 .read_ok
    plp
ENDIF
    rts
}

;-------------------------------------------------------------------------
; close the currently open file
;-------------------------------------------------------------------------
; no parameters
.file_close
{
    lda #0          ; close file
    ldy osgbpb_params+0
    jsr osfind    
    lda #0
    sta osgbpb_params+0
    rts
}

;-------------------------------------------------------------------------
; Get the size in bytes of the currently opened file
;-------------------------------------------------------------------------
; no parameters
; returns
;  osargs_params = filesize in bytes (LSB first)

osargs_params=&9C ; 4-byte zero page address for OSARGS output

.file_size
{
    lda #2
    ldy osgbpb_params+0
    ldx #osargs_params        
    jsr osargs
    rts
}

;-------------------------------------------------------------------------
; Stream a file into memory, 256 bytes at a time
;-------------------------------------------------------------------------
; X=filename LSB
; Y=filename MSB
; A=load address MSB (256 byte buffer)



.file_stream
{
    ; save the MSB write address
    sta store+2

    ; get the currently selected ROM/RAM bank
    ; BEFORE we do any DFS related work since that will page the DFS ROM in
    lda &f4
    sta swr_select+1

    ; open the file
    jsr file_open
;    jsr file_size
.fetch_loop
    ; fetch 256 bytes to buffer
    ldx #LO(FILESYS_BUFFER_ADDR)
    ldy #HI(FILESYS_BUFFER_ADDR)
    lda #FILESYS_BUFFER_SIZE          ; read a number of 256 byte pages to the buffer
    jsr file_read 

    ; if EOF then carry will be set, so push status and check again later
    php

.success

.swr_select
    ; select the destination ROM/RAM bank that was selected on entry to the routine 
    lda #&FF            ; MODIFIED
    jsr swr_select_bank

    ; copy the data to destination
    ldx #0
.transfer
    lda FILESYS_BUFFER_ADDR,x
.store
    sta &ff00,x         ; MODIFIED
    inx
    bne transfer
    inc store+2

    ; restore status of read, if last read was successful continue loop
    plp
    bcc fetch_loop
    rts
}