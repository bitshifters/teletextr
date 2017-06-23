.start_fx_teletext

.teletext_data  
.teletext_page0
INCBIN "data/pages/testpage.txt.bin"
.teletext_page1
INCBIN "data/pages/edittf.txt.bin"
.teletext_page2
INCBIN "data/pages/ceefax.txt.bin"
.teletext_page3
INCBIN "data/pages/heman.txt.bin"
.teletext_page4
INCBIN "data/pages/heisenburg.txt.bin"
.teletext_page5
INCBIN "data/pages/teletextr2.txt.bin"




.page_table
    EQUW teletext_page0
    EQUW teletext_page1
    EQUW teletext_page2
    EQUW teletext_page3
    EQUW teletext_page4
    EQUW teletext_page5





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