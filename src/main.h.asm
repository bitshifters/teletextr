\\ Common global defines
INCLUDE "lib/bbc.h.asm"
INCLUDE "lib/bbc_utils.h.asm"


\ ******************************************************************
\ *	Define fast (zero page) runtime variables
\ ******************************************************************

\\ Our own app variables
ORG &00
GUARD &9F							; user ZP + econet ZP



\\ Any includes here can declare ZP vars from the pool using SKIP
INCLUDE "lib/exomiser.h.asm"
INCLUDE "lib/vgmplayer.h.asm"
INCLUDE "src/3d.h.asm"

.disp_buffer_addr	SKIP 1	; MSB of display buffer address
.draw_buffer_addr	SKIP 1	; MSB of draw buffer address


INCLUDE "src/mode7_graphics.h.asm"
INCLUDE "src/mode7_plot_pixel.h.asm"
INCLUDE "src/bresenham.h.asm"

ORG &1100


.start


\ ******************************************************************
\ *	Code entry
\ ******************************************************************

INCLUDE "lib/exomiser.asm"
INCLUDE "lib/vgmplayer.asm"
INCLUDE "src/3d.asm"

INCLUDE "src/mode7_graphics.asm"
INCLUDE "src/mode7_plot_pixel.asm"
INCLUDE "src/bresenham.asm"

.main
{
\\ ***** System initialise ***** \\

	\\ *FX 200,3 - clear memory on break as we use OS memory areas and can cause nasty effects
	LDA #200
	LDX #3
	JSR osbyte			

	JSR clear_vram

	
	\\ Set MODE 7
	LDA #22: JSR oswrch
	LDA #7: JSR oswrch

	\\ Turn off cursor by directly poking crtc
	SEI
	LDA #10: STA &FE00
	LDA #32: STA &FE01
	CLI	

	\\ Initialise music player - pass in VGM_stream_data address
	\\ parses header from stream
	LDX #LO(VGM_stream_data)
	LDY #HI(VGM_stream_data)
	JSR	vgm_init_stream

    \\ Start our event driven fx
    ldx #LO(event_handler)
    ldy #HI(event_handler)
    JSR start_eventv


    jsr init_3d

\\ can never return to OS as we use all memory
    .loop
    lda #19:jsr osbyte

    jsr update_3d


    jmp loop
}


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
	sta &3000,x
	inx
	bne loop2
	inc loop2+2
	dey
	bne loop
	cli
	rts
}



.event_handler
{
	php
	cmp #4
	bne not_vsync

	\\ Preserve registers
	pha:TXA:PHA:TYA:PHA

	\\ Poll the music player
	jsr poll_player
    

  ;  lda#65:jsr oswrch

	\\ Restore registers
	PLA:TAY:PLA:TAX:pla

	\\ Return
    .not_vsync
	plp
	rts
}


\ ******************************************************************
\ *	Event Vector Routines
\ ******************************************************************

\\ System vars
.old_eventv				SKIP 2

.start_eventv				; new event handler in X,Y
{
	\\ Remove interrupt instructions
	lda #NOP_OP
	sta PSG_STROBE_SEI_INSN
	sta PSG_STROBE_CLI_INSN
	
	\\ Set new Event handler
	sei
	LDA EVENTV
	STA old_eventv
	LDA EVENTV+1
	STA old_eventv+1

	stx EVENTV
	sty EVENTV+1
	cli
	
	\\ Enable VSYNC event.
	lda #14
	ldx #4
	jsr osbyte
	rts
}
	
.stop_eventv
{
	\\ Disable VSYNC event.
	lda #13
	ldx #4
	jsr osbyte

	\\ Reset old Event handler
	SEI
	LDA old_eventv
	STA EVENTV
	LDA old_eventv+1
	STA EVENTV+1
	CLI 

	\\ Insert interrupt instructions back
	lda #SEI_OP
	sta PSG_STROBE_SEI_INSN
	lda #CLI_OP
	sta PSG_STROBE_CLI_INSN
	rts
}

.VGM_stream_data
INCBIN "data/music.raw.exo"


.end

PRINT "Code from", ~start, "to", ~end, ", size is", (end-start), "bytes"
SAVE "Main", start, end, main
