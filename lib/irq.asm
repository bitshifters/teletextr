



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
