
IF _USE_RTW


\\ Plot line from lastX,lastY to X,Y
.draw_to	
{
	lda rtw_startx
	sta rtw_endx
	lda rtw_starty
	sta rtw_endy
	stx rtw_startx
	sty rtw_starty
	jsr draw_line
	rts
}

\\ Move plot cursor from lastX,lastY to X,Y
.move_to
{
	lda rtw_startx
	sta rtw_endx
	lda rtw_starty
	sta rtw_endy
	stx rtw_startx
	sty rtw_starty
	rts
}

.draw_line
{
	; calc dx = ABS(startx - endx)
	SEC
	LDA rtw_startx
	TAX
	SBC rtw_endx
	BCS posdx
	EOR #255
	ADC #1
	.posdx
	STA rtw_dx
	
	; C=0 if dir of startx -> endx is positive, otherwise C=1
	PHP
	
	; calc dy = ABS(starty - endy)
	SEC
	LDA rtw_starty
	TAY
	SBC rtw_endy
	BCS posdy
	EOR #255
	ADC #1
	.posdy
	STA rtw_dy
	
	; C=0 if dir of starty -> endy is positive, otherwise C=1
	PHP
	
	; Coincident start and end points exit early
	ORA rtw_dx
	BNE nonzero

	; safe exit for coincident points
	PLP
	PLP
	RTS

	.nonzero
	
	; determine which type of line it is
	LDA rtw_dy
	CMP rtw_dx
	BCC shallowline
		
.steepline

	; self-modify code so that line progresses according to direction remembered earlier
	PLP					; C=sign of dy
	LDA #&C8			; INY (goingdown)
	BCC P%+4
	LDA #&88			; DEY (goingup)
	STA goingupdown
	
	PLP					; C=sign of dx
	LDA #&E8			; INX (goingright)
	BCC P%+4
	LDA #&CA			; DEX (goingleft)
	STA goingleftright

	; initialise accumulator for 'steep' line
	LDA rtw_dy
	STA rtw_count
	LSR A

.steeplineloop

	STA rtw_accum
	
	; plot pixel
	PLOT_PIXEL_CLIPPED

	; check if done
	DEC rtw_count
	BNE goingupdown

	.exitline
	RTS
	
	; move up to next line
	.goingupdown
	NOP					; self-modified to INY (goingdown) or DEY (goingup)
	
	; check move to next pixel column
	.movetonextcolumn
	SEC
	LDA rtw_accum
	SBC rtw_dx
	BCS steeplineloop
	ADC rtw_dy
	
	; move left or right to next pixel column
	.goingleftright
	NOP					; self-modifed to INX (goingright) or DEX (goingleft)
	JMP steeplineloop
	
.shallowline

	; self-modify code so that line progresses according to direction remembered earlier
	PLP					; C=sign of dy
	LDA #&C8			; INY (goingdown)
	BCC P%+4
	LDA #&88			; DEY (goingup)
	STA goingupdown2
	
	PLP					; C=sign of dx
	LDA #&E8			; INX (goingright)
	BCC P%+4
	LDA #&CA			; DEX (goingleft)
	STA goingleftright2

	; initialise accumulator for 'steep' line
	LDA rtw_dx
	STA rtw_count
	LSR A

.shallowlineloop

	STA rtw_accum
	
	; plot pixel in cached byte
	PLOT_PIXEL_CLIPPED
	
	; check if done
	DEC rtw_count
	BNE goingleftright2

	.exitline2
	RTS
	
	; move left or right to next pixel column
	.goingleftright2
	NOP					; self-modifed to INX (goingright) or DEX (goingleft)
	
	; check whether we move to the next line
	.movetonextline
	SEC
	LDA rtw_accum
	SBC rtw_dy
	BCS shallowlineloop
	ADC rtw_dx

	; move down or up to next line
	.goingupdown2
	NOP					; self-modified to INY (goingdown) or DEY (goingup)
	JMP shallowlineloop
}

ELSE

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

ENDIF


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




