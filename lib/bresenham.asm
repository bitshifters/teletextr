
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
	BEQ exitline
	
	; determine which type of line it is
	LDA rtw_dy
	CMP rtw_dx
	BCC shallowline
		
.steepline

	; self-modify code so that line progresses according to direction remembered earlier
	PLP
	LDA #goingdown-branchupdown-2
	BCC P%+4
	LDA #goingup-branchupdown-2
	STA branchupdown+1
	
	PLP
	LDA #goingright-branchleftright-2
	BCC P%+4
	LDA #goingleft-branchleftright-2
	STA branchleftright+1

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
	.branchupdown
	BNE P%			; self-modified to goingdown or goingup
	.exitline
	RTS
	
	; move up to next line
	.goingup
	DEY
	JMP movetonextcolumn	; always taken
	
	; move down to next line
	.goingdown
	INY
	
	; check move to next pixel column
	.movetonextcolumn
	SEC
	LDA rtw_accum
	SBC rtw_dx
	BCS steeplineloop
	ADC rtw_dy
	
	.branchleftright
	BCS P%					; self-modified to goingright or goingleft
	
	; move left to next pixel column
	.goingleft
	DEX
	JMP steeplineloop
	
	; move right to next pixel column
	.goingright
	INX
	JMP steeplineloop
	
.shallowline

	; self-modify code so that line progresses according to direction remembered earlier
	PLP
	LDA #goingdown2-branchupdown2-2
	BCC P%+4
	LDA #goingup2-branchupdown2-2
	STA branchupdown2+1
	
	PLP
	LDA #goingright2-branchleftright2-2
	BCC P%+4
	LDA #goingleft2-branchleftright2-2
	STA branchleftright2+1

	; initialise accumulator for 'steep' line
	LDA rtw_dx
	STA rtw_count
	LSR A
	STA rtw_accum	

.shallowlineloop

	; cache byte from destination screen address
	
.shallowlineloop2

	; plot pixel in cached byte
	PLOT_PIXEL_CLIPPED
	
	; check if done
	DEC rtw_count
	.branchleftright2
	BNE P%					; self-modified to goingleft2 or goingright2

	.exitline2
	RTS
	
	; move left to next pixel column
	.goingleft2
	DEX
	JMP movetonextline
	
	; move right to next pixel column
	.goingright2
	INX
	JMP movetonextline
	
	; check whether we move to the next line
	.movetonextline
	STA rtw_temp
	SEC
	LDA rtw_accum
	SBC rtw_dy
	.branchupdown2
	BCC P%					; self-modified to goingdown2 or goingup2
	STA rtw_accum
	LDA rtw_temp
	BCS shallowlineloop2	; always taken
	
	; move down to next line
	.goingdown2
	ADC rtw_dx
	STA rtw_accum				; store new accumulator
	INY
	JMP shallowlineloop
	
	; move up to next line
	.goingup2
	ADC rtw_dx
	STA rtw_accum
	DEY
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




