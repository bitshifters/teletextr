\\ 6502 Graphics routines

; Considered some double buffer options where we render to a byte or bit buffer
; and unpack during the copy blit, it's certainly faster to plot pixels this way, but
; the overhead of unpack/copying is severe - nearly 4x the cycle count.
; So faster to do the extra work in plot pixel since that is not called anywhere near as often as 1:1 per pixel.




\\---------------------------------------------------------------------
\\ clearfuction A=clearvalue
\\ X = base address
\\ should compile within a page for speed
\\---------------------------------------------------------------------


.clear_screen_buffer
{
	\\ SELF MODIFYING CODE
	stx clear0+2
	inx
	stx clear1+2
	inx
	stx clear2+2
	inx
	stx clear3+2
	
	
	ldx #0
	.clearloop
	.clear0 sta &7c00,x		; 5
	.clear1 sta &7d00,x		; 5
	.clear2 sta &7e00,x		; 5
	.clear3 sta &7f00,x		; 5
	inx						; 2
	bne clearloop			; 3
	rts
	\\ clear cycles = 4*5+2+3 = 25 * 256 = 6400 = 3.2ms
	\\ faster than using zero page
	\\ 8*5+2+3 = 45 * 128 = 5760 = 2.88ms
}

\\---------------------------------------------------------------------
\\ clearfuction A=clearvalue
\\ should compile within a page for speed
\\---------------------------------------------------------------------

\\ Mode 7 screen = 40 * 25 = 1000 bytes

.clear_screen
{
	ldx #0
	.clearloop
	sta &7c00,x		; 5
	sta &7d00,x		; 5
	sta &7e00,x		; 5
	sta &7f00,x		; 5
	inx				; 2
	bne clearloop	; 2
	rts
	\\ clear cycles = (4*5+2+3)*256 = 6400 = 3.2 ms
}



BLIT_INTERVAL = 64
BLIT_ITERATIONS = 1024 / BLIT_INTERVAL



.mode7_clear_screen_fast
{
	lda #0
	ldx #BLIT_INTERVAL-1
	.blit_loop
FOR n, 0, BLIT_ITERATIONS-1		
	sta MODE7_VRAM_START + n * BLIT_INTERVAL, x
NEXT
	dex				; 2
	bpl blit_loop	; 2
	rts
}

;PRINT "Clear screen cycles = ", (BLIT_ITERATIONS*5+2+3)*BLIT_INTERVAL
OUTPUT_CYCLES (BLIT_ITERATIONS*5+2+3)*BLIT_INTERVAL
OUTPUT_SIZE mode7_clear_screen_fast

; A contains clear char
.mode7_clear_shadow_fast
{

	ldx #BLIT_INTERVAL-1
	.blit_loop
FOR n, 0, BLIT_ITERATIONS-1		
	sta MODE7_VRAM_SHADOW + n * BLIT_INTERVAL, x
NEXT
	dex				; 2
	bpl blit_loop	; 2
	rts
}

;PRINT "Clear screen cycles = ", (BLIT_ITERATIONS*5+2+3)*BLIT_INTERVAL
OUTPUT_CYCLES (BLIT_ITERATIONS*5+2+3)*BLIT_INTERVAL
OUTPUT_SIZE mode7_clear_shadow_fast

.mode7_copy_screen_fast
{
	ldx #BLIT_INTERVAL-1
	.blit_loop
FOR n, 0, BLIT_ITERATIONS-1
	lda MODE7_VRAM_SHADOW + n * BLIT_INTERVAL, x
	sta MODE7_VRAM_START + n * BLIT_INTERVAL, x
NEXT
	dex				; 2
	bpl blit_loop	; 2
	rts
	\\ copy cycles = (63*5*2+2+3)*16 = 10160 cycles = 5.08 ms
}
OUTPUT_CYCLES (BLIT_ITERATIONS*5*2+2+3)*BLIT_INTERVAL
OUTPUT_SIZE mode7_copy_screen_fast

\\ stupid (but fast) clear/copy blit routines
\\ use up loads of memory but give the best speed
IF FALSE

; 3000 bytes code, 2ms
.mode7_clear_screen_fast_stupid
{
	lda #0
FOR n, 0, 40*25
	sta MODE7_VRAM_START + n
NEXT
	rts
}

OUTPUT_CYCLES (4*40*25)
OUTPUT_SIZE mode7_clear_screen_fast_stupid

.mode7_clear_shadow_fast_stupid
{
	lda #0
FOR n, 0, 40*25
	sta MODE7_VRAM_SHADOW + n
NEXT
	rts
}

OUTPUT_CYCLES (4*40*25)
OUTPUT_SIZE mode7_clear_screen_fast_stupid

; 6007 bytes code, 4ms
.mode7_copy_screen_fast_stupid
{
FOR n, 0, 40*25
	lda MODE7_VRAM_SHADOW + n
	sta MODE7_VRAM_START + n
NEXT
	rts
}

OUTPUT_CYCLES (8*40*25)
OUTPUT_SIZE mode7_copy_screen_fast_stupid

ENDIF ; TRUE/FALSE


\\---------------------------------------------------------------------
\\ init first column with a graphics code 
\\ A=teletext graphics colour code
\\ X=base screen address
\\---------------------------------------------------------------------
.set_graphics_mode7
{
	STX &71
	TAX
	LDA #25
	STA &72
	LDA #0
	STA &70
	LDY #0
	.sgl 
	TXA
	STA (&70),Y
	CLC
	LDA &70
	ADC #40
	STA &70
	LDA &71
	ADC #0
	STA &71
	DEC &72
	BNE sgl
	RTS
}

; A contains graphics code to be stored
.mode7_set_graphics_fast
{
FOR n, 0, 24
	sta MODE7_VRAM_START + n*40
NEXT
	rts

\\ cycles = 25*4 = 100 cycles = 0.05ms
}

; A contains graphics code to be stored
.mode7_set_graphics_shadow_fast
{
FOR n, 0, 24
	sta MODE7_VRAM_SHADOW + n*40
NEXT
	rts

\\ cycles = 25*4 = 100 cycles = 0.05ms
}

; A contains graphics code to be stored
; X contains column offset
.mode7_set_column_shadow_fast
{
FOR n, 0, 24
	sta MODE7_VRAM_SHADOW + n*40,x
NEXT
	rts

\\ cycles = 25*4 = 100 cycles = 0.05ms
}


; Hacky timing bar - will write a BG command code to the RHS column of the screen
; depending on where the raster is when this is done will indicate how much frame time is used
.mode7_timer_bar
{
	lda #157
FOR n, 0, 24
	sta MODE7_VRAM_START + n*40 + 39
NEXT
	rts
}


