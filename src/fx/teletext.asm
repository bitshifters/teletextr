.start_fx_teletext


.teletext_data  
.teletext_page0
INCBIN "data/pages/testpage.txt.bin"
PAGE_TEST = 0
.teletext_page1
INCBIN "data/pages/edittf.txt.bin"
PAGE_EDITTF = 1
.teletext_page2
INCBIN "data/pages/ceefax.txt.bin"
PAGE_CEEFAX = 2
.teletext_page3
INCBIN "data/pages/heman.txt.bin"
PAGE_HEMAN = 3
.teletext_page4
INCBIN "data/pages/heisenburg.txt.bin"
PAGE_HEISENBURG = 4



.teletext_page5
INCBIN "data/pages/teletextr2.txt.bin"
PAGE_TELETEXTR = 5
.teletext_page6
INCBIN "data/pages/nova.txt.bin"
PAGE_NOVA = 6
.teletext_page7
INCBIN "data/pages/horsenburger.txt.bin"
PAGE_HORSENBURGER = 7
.teletext_page8
INCBIN "data/pages/kieran.txt.bin"
PAGE_KIERAN = 8
.teletext_page9
INCBIN "data/pages/simon.txt.bin"
PAGE_SIMON = 9
.teletext_page10
INCBIN "data/pages/yorks.bin"
PAGE_YORKS = 10




.page_table
    EQUW teletext_page0
    EQUW teletext_page1
    EQUW teletext_page2
    EQUW teletext_page3
    EQUW teletext_page4
    EQUW teletext_page5
    EQUW teletext_page6
    EQUW teletext_page7
    EQUW teletext_page8
    EQUW teletext_page9
    EQUW teletext_page10





; render the ceefax header at top of current draw buffer
.fx_teletext_drawheader
{
    lda draw_buffer_addr
    sta write_adr+2

    ldx #0
.loop2
    lda teletext_header,x
.write_adr
    sta &7c00,x
    inx
    cpx #40
    bne loop2

    rts
}

.fx_teletext_drawheader2
{
    ldx #0
.loop2
    lda teletext_header,x
    sta &7c00,x
    inx
    cpx #40
    bne loop2
    rts
}


; on entry, A=page num
.fx_teletext_drawpage
{
    asl a
    tax
    lda page_table+0,x
    sta &90
    sta &92
    sta &94
    sta &96

    lda page_table+1,x
    tay
    sty &91
    iny
    sty &93
    iny
    sty &95
    iny
    sty &97



    lda draw_buffer_addr
    tax:stx write0+2
    inx:stx write1+2
    inx:stx write2+2
    inx:stx write3+2

    ldy #0
.loop
    lda (&90),y
.write0
    sta &7c00,y
    lda (&92),y
.write1
    sta &7d00,y
    lda (&94),y
.write2
    sta &7e00,y
    lda (&96),y
.write3
    sta &7f00,y
    

;    lda teletext_data+0,x
;    sta &7c00,x
;    lda teletext_data+256,x
;    sta &7d00,x
;    lda teletext_data+512,x
;    sta &7e00,x
;    lda teletext_data+768,x
;    sta &7f00,x
    iny
    bne loop

    rts
}


.fx_teletext_showtestcard
{
    lda #0
    jsr fx_teletext_drawpage
    rts
}

.fx_teletext_showpages
{
    lda page+1
    and #3
    clc
    adc #1
    jsr fx_teletext_drawpage

    rts
}

.end_fx_teletext