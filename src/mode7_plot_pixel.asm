\\ Plot Pixel functions
\\ 6502 include file
\\ DISPLAY_MODE variable must be set prior to inclusion

FASTER_PLOT = TRUE



; reserve space for line tables, for Mode7 both tables fit into 1 page
; allows conversion of 78x75 coordinates to memory address & glyph mask

ALIGN 256
.mode7_tables_start
; 3x75 byte tables = 225 bytes
.plot_pixel_ytable_lo
	FOR i, 0, PLOT_PIXEL_RANGE_Y-1
	  y = (i DIV 3) * 40 + 1		; +1 due to graphics chr
IF FASTER_PLOT
	  EQUB LO(y-i)	; adjust for (zp),y style addressing, where Y will be the y coordinate
ELSE
	  EQUB LO(y)
ENDIF
	NEXT
.plot_pixel_ytable_hi
	FOR i, 0, PLOT_PIXEL_RANGE_Y-1
	  y = (i DIV 3) * 40 + 1		; +1 due to graphics chr
IF FASTER_PLOT
	  EQUB HI(y-i)	; adjust for (zp),y style addressing, where Y will be the y coordinate
ELSE
	  EQUB HI(y)
ENDIF

	NEXT
.plot_pixel_ytable_chr
	FOR n, 0, PLOT_PIXEL_RANGE_Y-1
		IF (n MOD 3) == 0
			EQUB 160+1+2
		ELIF (n MOD 3) == 1
			EQUB 160+4+8
		ELSE
			EQUB 160+16+64			
		ENDIF	
	NEXT
OUTPUT_SIZE mode7_tables_start

; x offset lookup tables	
ALIGN 256
; 3x78 bytes = 234 bytes
.plot_pixel_xtable
	FOR i, 0, PLOT_PIXEL_RANGE_X-1
	  y = i>>1
	  EQUB LO(y)
	NEXT	
.plot_pixel_xtable_chr
	FOR n, 0, PLOT_PIXEL_RANGE_X-1
		IF (n AND 1) == 0
			EQUB 160+1+4+16			; left hand column mask (even pixels)
		ELSE
			EQUB 160+2+8+64			; right hand column mask (odd pixels)
		ENDIF	
	NEXT
.mode7_tables_end

; [ 1][ 2] + 160
; [ 4][ 8]
; [16][64]

OUTPUT_SIZE mode7_tables_start

\\ Plotting routines - as macros	



MACRO ADD_PIXEL_COUNT
	sed
	clc
	lda plot_cnt + 0
	adc #1
	sta plot_cnt + 0
	lda plot_cnt + 1
	adc #0
	sta plot_cnt + 1
	cld
ENDMACRO

.hexascii EQUS "0123456789ABCDEF"



; PLOT_PIXEL
; Draws unclipped pixel where X is Y coord and Y is X coord (for line drawing routine)
; define MODE7 plot pixel function for line drawing
; X contains X coord (0-77)
; Y contains Y coord (0-74)
; X and Y are preserved



MACRO PLOT_PIXEL
{	

	clc							;[2]
	lda plot_pixel_xtable,x		;[4]	get chr offset on row (Xcoord / 2)
	adc plot_pixel_ytable_lo,y	;[4]	C may be set after this addition.

IF FASTER_PLOT
	sta plot_lo 					;[3]
ELSE
	sta plot0+1					;[4]
	sta plot1+1					;[4]
ENDIF

	lda plot_pixel_ytable_hi,y	;[4]	C will be clear after this addition
	adc draw_buffer_addr 		;[3]	for double buffering - add the base drawbuffer address, uses 1 more cycle than fixed addressing
;	adc draw_buffer_addr ;#&7c;			;[3]	for double buffering - add the base drawbuffer address, uses 1 more cycle than fixed addressing

IF FASTER_PLOT
	sta plot_hi						;[3]
ELSE
	sta plot0+2					;[4]
	sta plot1+2					;[4]
ENDIF
	lda plot_pixel_ytable_chr,y	;[4]	get 2-pixel wide teletext glyph for Y coord
	and plot_pixel_xtable_chr,x	;[4]	apply odd/even X coord mask  

IF FASTER_PLOT
	ora (plot_lo),y					;[5]		
	sta (plot_lo),y					;[5]
ELSE
	.plot0 ora &ffff			;[4]	; MODIFIED
	.plot1 sta &ffff			;[4]	; MODIFIED
ENDIF
								;49 cycles. Not great, but teletext is a fiddly layout.
								;41 cycles if faster plot

IF DEBUG_PIXEL_COUNT
	ADD_PIXEL_COUNT
ENDIF
}
ENDMACRO

OUTPUT_CYCLES 49
; 0.0245 ms
; fillrate = 2040 per 50hz
; 

; 78*2+75*2

MACRO PLOT_PIXEL_CLIPPED
{
	cpx #PLOT_PIXEL_RANGE_X
	bcs clipped
	cpy #PLOT_PIXEL_RANGE_Y
	bcs clipped
	; clipping eats 8 cycles
	PLOT_PIXEL
	.clipped
}
ENDMACRO
	


.mode7_plot_pixel
{
	PLOT_PIXEL
	rts
}

.mode7_plot_pixel_clipped
{
	PLOT_PIXEL_CLIPPED
	rts
}


IF FALSE

\\ misc other code

\ plot pixel X=xcoord Y=ycoord
\ xrange=0 to 79, yrange=0 to 59 

.cullpixel
{
	RTS
}


.plotpixel
{
	; test bounds - remember 2 less pixel due to graphics
	CPX #PLOT_PIXEL_RANGE_X
	BCS cullpixel
	CPY #PLOT_PIXEL_RANGE_Y
	BCS cullpixel
	;8 cycles for bounds test

	; calc address tables
	TXA:ASLA:STA &72 \ store X*2 (5)
	TXA:LSRA:STA &73 \ store X/2 (5)
	TYA:ASLA:STA &74 \ store blockmask for later
	TYA:ASLA:TAY \ y=y*2 for word lookup  (6)

	\ get row mem address using Y 
	LDA ytable+0,Y
	STA &70 \ (7)
	LDA ytable+1,Y
	CLC
	ADC draw_buffer_addr ;#&7c ; draw_buffer_addr
	STA &71 \ (7)

	\ calc pixel
	\ take x coord AND 1
	\ take y coord AND 3 * 2
	\ x+y = lookup

	TXA:AND#1:ORA &74:TAX \ (8)

	LDA blocktable,X \ (4)

	\\ plot pixel
	LDY &73:ORA(&70),Y
	STA(&70),Y \(13)

	RTS \ (6)
	; 78 cycles plot pixel
}



\ 58 cycles ( +20 per pixl in the fill function)

.fillscreen
{
	LDY#0	;Y coord
	.xloop
	LDX#0
	.yloop

	PLOT_PIXEL
	
;	TXA:PHA:TYA:PHA:JSR &FFE0:PLA:TAY:PLA:TAX
	
	INX
	CPX #PLOT_PIXEL_RANGE_X
	BNE yloop
	INY
	CPY #PLOT_PIXEL_RANGE_Y
	BNE xloop \ (3)
	
	JSR &FFE0
	RTS
}





; reserve space for y coords
; we move row offsets in by one byte to preserve the colour code
; so pixel range is x from 0-77 and y from 0-74

ALIGN 256
.ytable ; SKIP 2*3*25

FOR i, 0, 74
  y = 1 + (i DIV 3) * 40
  EQUW y
NEXT

; to save any div by 3, the table has 75 entries which is the max height
ALIGN 256
.blocktable ; SKIP 75*2

FOR i, 0, 24
  EQUB 1+32+128
  EQUB 2+32+128
  EQUB 4+32+128
  EQUB 8+32+128
  EQUB 16+32+128
  EQUB 64+32+128
NEXT

ENDIF

; a faster plot pixel scheme
; x input = 0 to 77
; y input = 0 to 74
; 5850 combinations

; have to compute screen address
; then compute glyph to store


