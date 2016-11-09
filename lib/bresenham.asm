

\\ SELF MODIFYING CODE
.draw_line
{
	\\ init
			ldx #&c8        ; c8 = iny opcode
			lda y_2
			sta to_y+1
			sec
			sbc y_1
			bcs skip1
			eor #&ff
			adc #1
			ldx #&88        ; 88 = dey opcode - change direction
	.skip1
			sta d_y+1		; dy = abs(y2-y1)
			sta t_y_1+1
			sta t_y_2+1
			stx incy1		; y increment or decrement
			stx incy2
	 
			ldx #&e8        ; e8 = inx opcode
			lda x_2
			sta to_x+1
			sec
			sbc x_1
			bcs skip2
			eor #&ff
			adc #1
			ldx #&ca        ; ca = dex opcode - change direction
	.skip2
			stx incx1		; a = dx = abs(x2-x1)
			stx incx2		; x increment or decrement
	 
			ldx x_1			; start at x1,y1
			ldy y_1
	 
	\\ loop
	 
	;start x in x-register
	;start y in y-register
	;delta x in a-register
	 
	.d_y	cmp #0			; MODIFIED
			bcc steep
	 
			sta t_x_1+1
			lsr a
			sta errx+1
	.loopx
;			clc                 ;needed, as previous cmp could set carry. could be saved if we always count up and branch with bcc;
			
			PLOT_PIXEL_CLIPPED

	.errx	lda #0			; MODIFIED
			sec
	.t_y_1	sbc #0			; MODIFIED
			bcs skip3
	 
			;one might also swap cases (bcc here) and duplicate the loopend. saves more or less cycles as the subtract-case occurs more often than the add-case. Copying the whole loop to zeropage also save cycles as sta errx+1 is only 3 cycles then. (Bitbreaker)
	 
	.t_x_1	adc #0			; MODIFIED
	.incy1	iny				; MODIFIED
	.skip3	sta errx+1
	 
	.incx1	inx				; MODIFIED
	.to_x	cpx #0			; MODIFIED
			bne loopx
			rts
	 
	.steep
			sta t_x_2+1
			lsr a
			sta erry+1
	.loopy
;			clc                 ;needed, as previous cmp could set carry. could be saved if we always count up and branch with bcc;

			PLOT_PIXEL_CLIPPED

	.erry 	lda #0				; MODIFIED
			sec
	.t_x_2	sbc #0				; MODIFIED
			bcs skip4
	 
	.t_y_2	adc #0				; MODIFIED
	.incx2	inx					; MODIFIED
	.skip4	sta erry+1
	 
	.incy2	iny					; MODIFIED
	.to_y	cpy #0				; MODIFIED
			bne loopy
			rts
}

\-------------------------------------------------------------------

\\ Plot line from lastX,lastY to X,Y
.draw_to	
{
	lda x_1
	sta x_2
	lda y_1
	sta y_2
	stx x_1
	sty y_1
	jsr draw_line
	rts
}

\\ Move plot cursor from lastX,lastY to X,Y
.move_to
{
	lda x_1
	sta x_2
	lda y_1
	sta y_2
	stx x_1
	sty y_1
	rts
}




\.plot_point
\{
\	txa:pha
\	tya:pha
	
	;tax:pla:tay:pha	; swap x/y
	
\	PLOTPIXEL
\	pla:tay
\	pla:tax
\	rts
\}\


; read byte, 8-bits = 4 chars




