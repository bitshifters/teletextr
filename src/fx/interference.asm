
; classic circle interference pattern
; uses large sprite of concentric circles drawn in two layers
; requires 6x versions of sprite in all offsets i.e. lots of memory

.start_fx_interference

INTERFERENCE_shadow_addr = MODE7_VRAM_SHADOW + MODE7_char_width + 3	; currently writing 36x22 character screen


INTERFERENCE_sprite_width = 54
INTERFERENCE_sprite_height = 33

INTERFERENCE_screen_width = 37
INTERFERENCE_screen_height = 24

INTERFERENCE_max_x = (INTERFERENCE_sprite_width - INTERFERENCE_screen_width) * 2	; in pixels
INTERFERENCE_max_y = (INTERFERENCE_sprite_height - INTERFERENCE_screen_height) * 3	; in pixels

INTERFERENCE_table_size = 64			; sin table for X


\ ******************************************************************
\ *	Interference FX
\ ******************************************************************

\\ Local variables - could probably get rid of most of these
\\ or use a temp ZP variable for speed

.fx_interference_plot_x
EQUB 0

.fx_interference_plot_y
EQUB 0

.fx_interference_char_x
EQUB 0

.fx_interference_char_y
EQUB 0

.fx_interference_set_ptrs
{
	\\ X coordinate to char
	STX fx_interference_plot_x			; 4c
	TXA									; 2c
	AND #&1
	CLC
	ADC fx_interference_plot_x			; char x = (x + (x&1)) DIV 2 as effectively negative
	LSR A								; 2c

	\\ Y coordinate to char
	STY fx_interference_plot_y

	\\ X,Y are effectively negative so:
	\\ 0->0,0  1->1,2  2->1,1  3->1,0  4->2,2  5->2,1  6->3,0

	INY:INY
	LDX mode7_sprites_div3_table, Y		; 4c

	\\ A still contains fx_interference_char_x

	\\ Calculate internal sprite address
	CLC									; 2c
	ADC fx_interference_mult_LO, X		; 4c
	STA readptr
	LDA fx_interference_mult_HI, X		; 4c
	ADC #0
	STA readptr+1

	\\ Where are we reading data from?

	\\ Calculate offset 0 - 5
	.mode7_sprites_plot_x
	LDY fx_interference_plot_y
	SEC
	LDA #3
	SBC mode7_sprites_mod3_table, Y		; 4c
	CMP #3
	BCC y_offset_ok
	LDA #0								; y_offset actually (3 - (y MOD 3))
	.y_offset_ok
	TAY

	LDA fx_interference_plot_x			; 2c
	AND #&1								; 2c x_offset
	ORA mode7_sprites_mod3_table, Y		; 4c y_offset

	\\ Multiply by our offset to locate sprite data
	TAX									; 2c
	CLC
	LDA readptr
	ADC fx_interference_table_LO, X						; 4c
	STA readptr
	LDA readptr+1
	ADC fx_interference_table_HI, X						; 4c
	STA readptr+1

	\\ Set our write pointer
	LDA #LO(INTERFERENCE_shadow_addr)
	STA writeptr
	LDA #HI(INTERFERENCE_shadow_addr)
	STA writeptr+1

	.return
	RTS
}


\\ Draw our sprite with offset X,Y in pixels to entire screen

.fx_interference_draw_screen
{
	\\ Calculate our read pointer based on X,Y
	\\ Write pointer is always start of screen
	JSR fx_interference_set_ptrs

	LDX #0
	.y_loop

	\\ Copy a row of characters

	LDY #0
	.x_loop
	LDA (readptr), Y
	STA (writeptr), Y
	INY
	CPY #INTERFERENCE_screen_width
	BNE x_loop

	\\ Next row of sprite data

	CLC
	LDA readptr
	ADC #INTERFERENCE_sprite_width
	STA readptr
	LDA readptr+1
	ADC #0
	STA readptr+1

	\\ Next row of screen

	CLC
	LDA writeptr
	ADC #MODE7_char_width
	STA writeptr
	LDA writeptr+1
	ADC #0
	STA writeptr+1

	\\ Until done

	INX
	CPX #INTERFERENCE_screen_height
	BNE y_loop

	.return
	RTS
}


\\ Draw our sprite with offset X,Y in pixels to entire screen

.fx_interference_blend_screen
\\{
	\\ Calculate our read pointer based on X,Y
	\\ Write pointer is always start of screen
	JSR fx_interference_set_ptrs

	LDX #0
	.fx_interference_blend_screen_y_loop

	\\ Copy a row of characters

	LDY #0
	.fx_interference_blend_screen_x_loop
	LDA (readptr), Y
	
	\\ Can poke in different blend instruction here - e.g. ORA
	.fx_interference_blend_screen_blend_instruction
	EOR (writeptr), Y

	ORA #32					; always need 32!

	STA (writeptr), Y
	INY
	CPY #INTERFERENCE_screen_width
	BNE fx_interference_blend_screen_x_loop

	\\ Next row of sprite data

	CLC
	LDA readptr
	ADC #INTERFERENCE_sprite_width
	STA readptr
	LDA readptr+1
	ADC #0
	STA readptr+1

	\\ Next row of screen

	CLC
	LDA writeptr
	ADC #MODE7_char_width
	STA writeptr
	LDA writeptr+1
	ADC #0
	STA writeptr+1

	\\ Until done

	INX
	CPX #INTERFERENCE_screen_height
	BNE fx_interference_blend_screen_y_loop

	.fx_interference_blend_screen_return
	RTS
\\}

\\ Set our blend mode
.fx_interference_set_blend_ora
{
	LDA #OPCODE_ora_indirect_Y
	STA fx_interference_blend_screen_blend_instruction

	.return
	RTS
}

.fx_interference_set_blend_eor
{
	LDA #OPCODE_eor_indirect_Y
	STA fx_interference_blend_screen_blend_instruction

	.return
	RTS
}

\\ Local variables for motion

.fx_interference_x
EQUB 0

.fx_interference_dx
EQUB 1

.fx_interference_y
EQUB 0

.fx_interference_dy
EQUB 1

.fx_interference_x_idx
EQUB 0


\\ Main update function

.fx_interference_update
{
;	lda #144+7
;   ldx #0
;	jsr mode7_set_column_shadow_fast



	\\ Draw base layer to screen

	LDX fx_interference_x
	LDY fx_interference_y
	JSR fx_interference_draw_screen

	\\ Draw top layer to screen with EOR

	LDY fx_interference_x_idx
	LDX fx_interference_sin_table_x, Y
	LDY #16
	JSR fx_interference_blend_screen



	\\ Update motion for both layers

	\\ Currently base layer just bounces x,y linearly around available area

	CLC
	lda fx_interference_x
	ADC fx_interference_dx
	BMI x_hit_left

	CMP #INTERFERENCE_max_x
	BCC x_ok
	
	\\ X hit right
	LDA #&FF					; -1
	STA fx_interference_dx
	LDA #INTERFERENCE_max_x
	JMP x_ok

	.x_hit_left
	LDA #1
	STA fx_interference_dx
	LDA #0

	.x_ok
	STA fx_interference_x

	CLC
	lda fx_interference_y
	ADC fx_interference_dy
	BMI y_hit_top

	CMP #INTERFERENCE_max_y
	BCC y_ok
	
	\\ Y hit bottom
	LDA #&FF					; -1
	STA fx_interference_dy
	LDA #INTERFERENCE_max_y
	JMP y_ok

	.y_hit_top
	LDA #1
	STA fx_interference_dy
	LDA #0

	.y_ok
	STA fx_interference_y

	\\ Top layer is lookup into sine table

	CLC
	LDA fx_interference_x_idx
	ADC #&1
	AND #INTERFERENCE_table_size-1
	STA fx_interference_x_idx

	.return
	RTS
}


\ ******************************************************************
\ *	Lookup tables
\ ******************************************************************

\\ This assumes data is compiled by BeebAsm at correct address for SWRAM
\\ i.e. &8000 onwards

.fx_interference_table_LO
{
	EQUB LO(circles_data_00)
	EQUB LO(circles_data_10)
	EQUB LO(circles_data_01)
	EQUB LO(circles_data_11)
	EQUB LO(circles_data_02)
	EQUB LO(circles_data_12)
}

.fx_interference_table_HI
{
	EQUB HI(circles_data_00)
	EQUB HI(circles_data_10)
	EQUB HI(circles_data_01)
	EQUB HI(circles_data_11)
	EQUB HI(circles_data_02)
	EQUB HI(circles_data_11)
}

.fx_interference_sin_table_x
FOR n, 0, INTERFERENCE_table_size-1, 1
EQUB 18 + 17 * SIN(2 * PI * n / INTERFERENCE_table_size)
NEXT

.fx_interference_mult_LO
FOR n, 0, MODE7_char_height-1, 1
EQUB LO(INTERFERENCE_sprite_width * n)				; sprite pitch
NEXT

.fx_interference_mult_HI
FOR n, 0, MODE7_char_height-1, 1
EQUB HI(INTERFERENCE_sprite_width * n)				; sprite pitch
NEXT


INCLUDE "src\sprites\circles.asm"

.end_fx_interference