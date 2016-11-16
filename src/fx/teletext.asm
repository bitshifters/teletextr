
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
EQUS "100  Tue 15 Nov ",131,"20:49/1"
.second EQUS "0"
.counter EQUB 0

.page_table
    EQUW teletext_page1
    EQUW teletext_page2
    EQUW teletext_page3
    EQUW teletext_page4

.page_num EQUB 0


.fx_teletext
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




    ldy #0
.loop
    lda (&90),y
    sta &7c00,y
    lda (&92),y
    sta &7d00,y
    lda (&94),y
    sta &7e00,y
    lda (&96),y
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

    ldx #0
.loop2
    lda teletext_header,x
    sta &7c00,x
    inx
    cpx #40
    bne loop2

    inc counter
    lda counter
    cmp #50
    bne skip
    inc page_num
    lda page_num
    and #3
    sta page_num
    inc second
    lda #0
    sta counter
.skip

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