
; play some animated gifs

PLAYGIFS_shadow_addr = &7800
PLAYGIFS_num = 4
PLAYGIFS_time = 25 * 8


.fx_playgifs_data
{
    EQUW animated_gif_bird
    EQUW animated_gif_weather
    EQUW animated_gif_dancer
    EQUW animated_gif_blueblob
}

.fx_playgifs_speed
{
	EQUB 1
	EQUB 2
	EQUB 3
	EQUB 4
}

.fx_playgifs_length
{
	EQUB 25 * 4
	EQUB 255
	EQUB 25 * 6
	EQUB 25 * 3
}

\ ******************************************************************
\ *	Play GIFs FX
\ ******************************************************************

.fx_playgifs_num
EQUB 0

.fx_playgifs_timer
EQUB 0

.fx_playgifs_init
{
IF _SAVESWR
	LDA &F4
	PHA
ENDIF

	\\ Switch to swram bank
	LDA #FX_PLAYGIFS_SLOT
	JSR swr_select_slot

	\\ Get GIF data
	LDA fx_playgifs_num
	ASL A
	TAX
	LDA fx_playgifs_data, X
	LDY fx_playgifs_data+1, X
	TAX
	JSR mode7_gif_anim_set_data

	\\ Initialise GIF player
	LDX fx_playgifs_num
	LDA fx_playgifs_speed, X
	LDX #LO(PLAYGIFS_shadow_addr)
	LDY #HI(PLAYGIFS_shadow_addr)
	JSR mode7_gif_anim_init

	\\ Reset our timer
	LDX fx_playgifs_num
	LDA fx_playgifs_length, X
	STA fx_playgifs_timer

IF _SAVESWR
	\\ Restore current bank
	PLA
	JSR swr_select_bank
ENDIF

	RTS
}

.fx_playgifs_update
{
	\\ Decrement our timer
	DEC fx_playgifs_timer
	BEQ play_next_gif

IF _SAVESWR
	\\ Switch to swram bank
	LDA &F4
	PHA
ENDIF

	LDA #FX_PLAYGIFS_SLOT
	JSR swr_select_slot



	\\ Update GIF player
	JSR mode7_gif_anim_update

IF _SAVESWR
	\\ Restore current bank
	PLA
	JMP swr_select_bank			; will RTS for us
ELSE
	RTS
ENDIF

	\\ Next GIF
	.play_next_gif
	LDA fx_playgifs_num
	CLC
	ADC #1
	CMP #PLAYGIFS_num
	BCC init_next_gif

	JSR fx_buffer_clear
	LDA #0

	.init_next_gif
	STA fx_playgifs_num
	JSR fx_playgifs_init

	.return
	RTS
}
