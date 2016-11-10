
\\ reset all memory from &3000 to &8000 to zero
\\ hides unsightly mode switches
.clear_vram
{
	sei
	lda #&30
	sta loop2+2
	lda #0
	ldy #&50
.loop
	ldx #0
.loop2
	sta &FF00,x
	inx
	bne loop2
	inc loop2+2
	dey
	bne loop
	cli
	rts
}

