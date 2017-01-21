.start_fx_teletext

.teletext_data  
.teletext_page1
INCBIN "data/pages/edittf.txt.bin"
.teletext_page2
INCBIN "data/pages/ceefax.txt.bin"
.teletext_page3
INCBIN "data/pages/heman.txt.bin"
.teletext_page4
INCBIN "data/pages/heisenburg.txt.bin"


.teletext_header
;"0123456789012345678901234567890123456789"
EQUS "P100   ",130,"CEEFAX "
.page
EQUS "100  Fri 19 Jan ",131,"20:49/1"
.second EQUS "0"
.counter EQUB 0

.page_table
    EQUW teletext_page1
    EQUW teletext_page2
    EQUW teletext_page3
    EQUW teletext_page4

.page_num EQUB 0
.page_count EQUB 0

.teletext_update_page
{
    inc page_num
    lda page_num
    and #3
    sta page_num    
    rts
}

.teletext_update_header
{

    inc page_count
    lda page_count
    and #3
    sta page_count    
    and #3
    bne ok1

    inc page+2
    lda page+2
    cmp #48+10
    bne ok1
    lda #48
    sta page+2
    inc page+1
    lda page+1
    cmp #48+10
    bne ok1
    lda #48
    sta page+1
    inc page+0
    lda page+0
    cmp #48+10
    bne ok1
    lda #49
    sta page+0

.ok1        
    rts
}



.fx_teletext_header
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

   ldx delta_time
.delta_loop

    inc counter
    lda counter
    cmp #50
    bne skip


    lda #0
    sta counter


    ; seconds units
    inc second
    lda second
    cmp #48+10
    bne nosecond
    lda #48
    sta second

    ; seconds tens
    jsr teletext_update_page

    inc second-1
    lda second-1
    cmp #48+6
    bne nosecond
    lda #48
    sta second-1

    ; minutes units
    inc second-3
    lda second-3
    cmp #48+10
    bne nosecond
    lda #48
    sta second-3

    ; minutes tens
    inc second-4
    lda second-4
    cmp #48+6
    bne nosecond
    lda #48
    sta second-4

    ; hours units
    inc second-6
    lda second-6
    cmp #48+10
    bne nosecond
    lda #48
    sta second-6

   ; hours tens
    inc second-7
    lda second-7
    cmp #48+10
    bne nosecond
    lda #48
    sta second-7    



.nosecond
    


.skip
    jsr teletext_update_header


    dex
    BNE delta_loop    

    rts
}


.fx_teletext_drawpage
{
    lda page_num
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


.fx_teletext
{
    jsr fx_teletext_drawpage

    jsr fx_teletext_header

    rts

}

.end_fx_teletext