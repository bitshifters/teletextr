
; ray caster

RAYCASTER_shadow_addr = &7803
RAYCASTER_sin_scale = 127
RAYCASTER_block_size = 40

RAYCASTER_default_heading = &20
RAYCASTER_default_player_x = 8
RAYCASTER_default_player_y = 8

RAYCASTER_num_rays = 37

_RAYCASTER_FISHEYE = FALSE
_RAYCASTER_DEBUG = FALSE

INKEY_w = 33
INKEY_s = 81
INKEY_a = 65
INKEY_d = 50

\ ******************************************************************
\ *	Ray caster FX
\ ******************************************************************

.fx_raycaster_init
{
	LDA #RAYCASTER_default_heading
	STA raycaster_heading

	LDA #RAYCASTER_default_player_x
	STA raycaster_playerxh

	LDA #RAYCASTER_default_player_y
	STA raycaster_playeryh

	LDA #0
	STA raycaster_playerx
	STA raycaster_playery

\\ Set colours (sky, wall, floor)

	LDA #144+4
	STA raycaster_colours+0
	LDA #144+3
	STA raycaster_colours+1
	LDA #144+6
	STA raycaster_colours+2

    jsr fx_buffer_clear

\\ Initialise teletext setup

    lda #158    ; hold graphics
    ldx #0
	jsr mode7_set_column_shadow_fast

	lda #144+7  ; white graphics
    ldx #1
	jsr mode7_set_column_shadow_fast

    lda #255    ; full block (used as control character for rest of line)
    ldx #2
	jsr mode7_set_column_shadow_fast    

	.return
	RTS
}

.copyply2ray
{
	LDA raycaster_playerx
	STA raycaster_rayposx
	LDA raycaster_playerxh
	STA raycaster_rayposxh
	
	LDA raycaster_playery
	STA raycaster_rayposy
	LDA raycaster_playeryh
	STA raycaster_rayposyh

	.return
	RTS
}

.copyray2ply
{
	LDA raycaster_rayposx
	STA raycaster_playerx
	LDA raycaster_rayposxh
	STA raycaster_playerxh
	
	LDA raycaster_rayposy
	STA raycaster_playery
	LDA raycaster_rayposyh
	STA raycaster_playeryh

	.return
	RTS
}

.getsincos_copyplr2ray
{
\\ Get step in x & y from sin & cos table

	LDA raycaster_sin_table, X
	STA raycaster_stepx

	LDA	raycaster_cos_table, X
	STA raycaster_stepy

\\ Reset ray start position to player position

	JSR copyply2ray

	.return
	RTS
}

.addsteptopos
{
	LDX #2

	.loop_stepadd
	LDA raycaster_stepx, X
	ORA #&7F
	BMI sign_ext
	LDA #0
	.sign_ext
	PHA

	CLC
	LDA raycaster_stepx, X
	ADC raycaster_rayposx, X
	STA raycaster_rayposx, X
	PLA
	ADC raycaster_rayposxh, X
	STA raycaster_rayposxh, X

	DEX
	DEX
	BPL loop_stepadd

	\\ Look up map
	ASL A: ASL A: ASL A: ASL A
	ADC raycaster_rayposyh
	TAX
	LDA fx_raycaster_map, X

	.return
	RTS
}

.raycaster_colours
EQUB 0, 0, 0

.raycaster_heights
EQUB 0, 0, 0

.fx_raycaster_update
{
	.loop_main

	LDY #0				; start on lefthand side of screen

	.loop_ray

	TYA
	CLC
	ADC raycaster_heading
	SEC
	SBC #(RAYCASTER_num_rays/2)			; half of the fov
	TAX

	JSR getsincos_copyplr2ray

	LDA #0
	STA raycaster_distance

	.loop_dist
	INC raycaster_distance

	\\ Can limit distance here
	BMI skip_dist

	JSR addsteptopos
	\\ Returns a cell or empty

	BEQ loop_dist

	.skip_dist

	\\ Use this for colour
	CLC
	ADC #144
	STA raycaster_colours+1		; wall colour

	\\ Debug
IF _RAYCASTER_DEBUG
	LDA raycaster_distance
	STA raycaster_debug_distance, Y

	LDA raycaster_rayposxh
	STA raycaster_debug_rayx, Y

	LDA raycaster_rayposyh
	STA raycaster_debug_rayy, Y
ENDIF

	\\ Scale distasnce to avoid fisheye

IF _RAYCASTER_FISHEYE
	LDX raycaster_distance

	LDA #0
	STA raycaster_distancel

	LDA #1
	STA raycaster_distance

	.fisheye_loop
	CLC
	LDA raycaster_distancel
	ADC raycaster_cos_table - (RAYCASTER_num_rays/2), Y
	STA raycaster_distancel
	LDA raycaster_distance
	ADC #0
	STA raycaster_distance

	DEX
	BNE fisheye_loop

	ASL raycaster_distancel
	ROL raycaster_distance
	ASL raycaster_distancel
	ROL raycaster_distance
	ASL raycaster_distancel
	ROL raycaster_distance

	IF _RAYCASTER_DEBUG
	LDA raycaster_distance
	STA raycaster_debug_fisheye, Y
	ENDIF
ENDIF

	LDX #&FF
	LDA #RAYCASTER_block_size
	.loop_div
	INX
	SBC raycaster_distance
	BCS loop_div

	TXA
	CMP #14
	BCC vline_validheight
	LDA #13
	.vline_validheight
	ASL A
	SEC
	SBC #1						; make odd number as mode 7 has odd number of rows
	STA raycaster_heights+1
	EOR #&FF
	ADC #MODE7_char_height+1
	LSR A
	STA raycaster_heights+0
	STA raycaster_heights+2
	
	.screen_addr_hack
	LDA #LO(RAYCASTER_shadow_addr)
	STA writeptr
	LDA #HI(RAYCASTER_shadow_addr)
	STA writeptr+1

	LDX #2
	.vline_loop
	DEC raycaster_heights,X
	BMI vline_sectioncomplete

	LDA raycaster_colours, X
	STA (writeptr), Y

	CLC
	LDA writeptr
	ADC #40
	STA writeptr
	LDA writeptr+1
	ADC #0
	STA writeptr+1

	JMP vline_loop

	.vline_sectioncomplete
	DEX
	BPL vline_loop

	INY
	CPY #RAYCASTER_num_rays
	BCS finished_rays

	JMP loop_ray

	.finished_rays

	\\ Do user input

	\\ Reset ray pos
	LDX raycaster_heading
	JSR getsincos_copyplr2ray

	\\ Check keys
	{
		LDA #121
		LDX #0
		JSR osbyte

		CPX #INKEY_w
		BNE not_w
		JSR addsteptopos
		JSR copyray2ply
		JMP done_keys

		.not_w
		CPX #INKEY_s
		BNE not_s

		LDA raycaster_stepx
		EOR #&FF
		STA raycaster_stepx
		LDA raycaster_stepy
		EOR #&FF
		STA raycaster_stepy
		JSR addsteptopos
		JSR copyray2ply
		JMP done_keys

		.not_s
		CPX #INKEY_a
		BNE not_a
		DEC raycaster_heading
		DEC raycaster_heading
;		DEC raycaster_heading
;		DEC raycaster_heading

		.not_a
		CPX #INKEY_d
		BNE not_d
		INC raycaster_heading
		INC raycaster_heading
;		INC raycaster_heading
;		INC raycaster_heading

		.not_d

		.done_keys
	}

	.return
	RTS
}

ALIGN &100
.fx_raycaster_map
EQUB 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5		; could pre-add 144
EQUB 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 7, 7, 7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 7, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 7, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 7, 7, 7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 7, 7, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 7, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 7, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 7, 7, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5		; could pre-add 144
EQUB 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5		; could pre-add 144
EQUB 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3		; could pre-add 144

.raycaster_sin_table
FOR n,0,&13F,1
EQUB RAYCASTER_sin_scale * SIN(2 * PI * n / 256)
NEXT

raycaster_cos_table = raycaster_sin_table + &40			; this can be overlapped with sin table +64

IF _RAYCASTER_DEBUG
.raycaster_debug_distance
SKIP 40

.raycaster_debug_fisheye
SKIP 40

.raycaster_debug_rayx
SKIP 40

.raycaster_debug_rayy
SKIP 40
ENDIF
