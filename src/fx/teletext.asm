
.teletext_data
INCBIN "data/edittf.bin"

.teletext_header
;"0123456789012345678901234567890123456789"
EQUS "P100   ",130,"CEEFAX "
.page
EQUS "100  Tue 15 Nov ",131,"20:49/1"
.second EQUS "0"
.counter EQUB 0
.fx_teletext
{
    ldx #0
.loop
    lda teletext_data+0,x
    sta &7c00,x
    lda teletext_data+256,x
    sta &7d00,x
    lda teletext_data+512,x
    sta &7e00,x
    lda teletext_data+768,x
    sta &7f00,x
    inx
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