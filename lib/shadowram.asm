; Accessing & controlling the Shadow RAM is achieved using the Access control register (ACCCON) at &FE34 
; See page 162 of the New Advanced User Guide (http://www.msknight.com/bbc/manuals/new-advanced-user-guide.pdf)
; Bit 7 - IRR - IRQ control
; Bit 6 - TST - always 0
; Bit 5 - IFJ - 1MHz bus/ROM cartridge select 
; Bit 4 - ITU - TUBE select
; Bit 3 - Y - 8Kb RAM function select
; Bit 2 - X - Main memory RAM source select
; Bit 1 - E - VDU Driver RAM Source select
; Bit 0 - D - CRTC RAM Source select


; D=0 Use main memory for screen, D=1 Use Shadow RAM for screen (contrary to what is specified in AUG)
; E=0 VDU Driver uses Shadow RAM, E=1 VDU Driver uses main memory
; X=0 Normal RAM in main memory, X=1 Shadow RAM in main memory
; Y=0 8K RAM at &C000 to &DFFF, Y=1 VDU Driver code at &C000
; ITU=0 enable external TUBE, ITU=1 enable internal TUBE
; IFJ=0 1Mhz bus at &FC00 to &FDFF, IFJ=1 cartridge at &FC00
; TST=0 normal state (do not change), TST=1 hardware test
; IRR=0 after IRQ processed, IRR=1 IRQ to CPU

; so double buffer rendering works as follows:
;   D=0,X=1 - Display from main memory, Draw to shadow memory (&3000-&7FFF)
;   D=1,X=0 - Display from shadow memory, Draw to main memory (&3000-&7FFF)


; check if host machine is a Master 128
; we do this by testing if memory address &C000 is writable
; returns z=0 if master 128
;         z=1 if not 
.shadow_check_master
{
    lda &c000
    tay
    eor #&ff
    tax
    sta &c000
    cpx &c000
    sty &c000
    rts
}

; clear bit 4 of ACCCON, so that the 8Kb Buffer at &C000 can be used as spare RAM instead of MOS VDU buffer
.shadow_enable_hiram
{
    lda &fe34
    and #255-8  ; set Y to 0
    sta &fe34
	rts	
}


; we set bits 0 and 2 of ACCCON, so that display=Main RAM, and shadow ram is selected as main memory
.shadow_init_buffers
{
    lda &fe34
    ora #4    	; set X to 1
    and #255-1  ; set D to 0
    and #255-8  ; set Y to 0, so that the 8Kb Buffer can be used as RAM
    sta &fe34
    rts
}

; set a single buffer display configuration such that the selected memory is the same as the current display memory
; ie. let X=D
.shadow_set_single_buffer
{
    lda &fe34    
    and #1
    asl a
    asl a
    sta &8f
    lda &fe34
    and #255-4
    ora &8f
    sta &fe34
    rts
}

; set a double buffer display configuration such that the selected memory is the opposite of the current display memory
; ie. let X=!D
.shadow_set_double_buffer
{
    lda &fe34    
    and #1
    eor #1
    asl a
    asl a
    sta &8f
    lda &fe34
    and #255-4
    ora &8f
    sta &fe34
    rts
}


; we swap the buffers by inverting bits 0 and 2
;  the previously selected main memory becomes display memory
;  and previously selected display memory becomes main memory

; in single buffer mode, both display & main memory swap, but point to the same memory
; in double buffer mode, both display & main memory swap, but point to the opposite memory 
.shadow_swap_buffers
{
    lda &fe34
    eor #1+4	; invert bits 0 & 2
    sta &fe34
    rts
}

