
; check if host machine is a Master 128
; we do this by testing if memory address &C000 is writable
; returns z=0 if master 128
;         z=1 if not 
.shadow_check_master
{
    sei
    lda &c000
    tay
    eor #&ff
    tax
    sta &c000
    cpx &c000
    sty &c000
    cli
    rts
}




; we set bits 0 and 2, so that display=Main RAM, and shadow ram is selected as main memory
.shadow_init_buffers
{
    lda &fe34
    ora #1+4    ; set D and X to 1
    and #255-8  ; set Y to 0, so that the 8Kb Buffer can be used as RAM
    sta &fe34
    rts
}

; we swap the buffers by inverting bits 0 and 2
;  the previously selected main memory becomes display memory
;  and previously selected display memory becomes main memory
.shadow_swap_buffers
{
    lda &fe34
    eor #1+4
    sta &fe34
    rts
}

