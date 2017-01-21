\\ MODE 7 Animated GIF routines
\\ 6502 source file
\\ Relies on tables in mode7_plot_pixel.asm

\ ******************************************************************
\ *	"Animated GIF" playback based on mode7-video codec
\ *
\ * Called this animated GIF as doesn't do all the fancy streaming
\ * of tracks from disc or decompression in irq/event callback.
\ *
\ * Instead just takes uncompressed (for now) mode7-video codec data
\ * and decode the next frame to anywhere on the screen on update,
\ * with support for looping.
\ * 
\ * Crappy toolchain exists to generate data from animated GIFs
\ * which are usually shorter than videos + loop.
\ ******************************************************************


VID_default_mode7_ypos = 3
VID_default_frame_height = 19
VID_default_frame_size = (MODE7_char_width * VID_default_frame_height)
VID_default_frame_addr = mode7_gif_anim_base_addr_HI + (VID_default_mode7_ypos * MODE7_char_width)


\\ X & Y = LO & HI byte of data source address
.mode7_gif_anim_set_data
{
    \\ Set initial address of data source
    SEC
    TXA
    SBC #1
    STA mode7_gif_anim_load_addr + 1
    TYA
    SBC #0
    STA mode7_gif_anim_load_addr + 2

    .return
    RTS
}

.VID_playback_delay
EQUB 0

.VID_playback_counter
EQUB 0

.VID_frame_start
EQUW VID_default_frame_addr

.VID_frame_end
EQUW VID_default_frame_addr + VID_default_frame_size

.VID_first_frame_addr
EQUW &8000

.mode7_gif_anim_frame_no
EQUW 0

\\ A = playback speed
\\ X & Y = LO & HI byte of screen write address
.mode7_gif_anim_init
{
    STA VID_playback_delay

    \\ Store screen address to write to
    STX VID_frame_start
    STY VID_frame_start+1

	\\ Zero our variables
	LDA #0
	STA mode7_gif_anim_frame_no
	STA mode7_gif_anim_frame_no+1

	\\ Decode stream header
	JSR mode7_gif_anim_get_next_byte		; frame_size_LO

	\\ Calculate frame_end address
    CLC
	ADC VID_frame_start
	STA VID_frame_end

	; preserves flags internally
	JSR mode7_gif_anim_get_next_byte		; frame_size_HI

	ADC VID_frame_start+1
	STA VID_frame_end+1

    \\ Need to capture our loop point after first frame
    LDA #0
    STA VID_first_frame_addr
    STA VID_first_frame_addr+1

    .return
    RTS
}


.mode7_gif_anim_update
{
    \\ Increment our delay
    CLC
    LDA VID_playback_counter
    ADC delta_time
    STA VID_playback_counter

    \\ Are we ready to play next frame?
    CMP VID_playback_delay
    BCC return

    \\ Decrement our counter to keep rate
    SBC VID_playback_delay
    STA VID_playback_counter

	\\ Increment frame counter
	{
		INC mode7_gif_anim_frame_no
		BNE no_carry
		INC mode7_gif_anim_frame_no+1
		.no_carry
	}

    .do_frame

	\\ Decode frame header
	JSR mode7_gif_anim_decode_frame_header

	\\ Decode the video frame
	JSR mode7_gif_anim_decode_frame_data						; <-- this is the slowest bit!

    \\ Is this end of stream data?
    BCC done_frame

    \\ If so then loop!
    \\ This is the address of (second) frame - loop point!
    LDA VID_first_frame_addr
    STA mode7_gif_anim_load_addr + 1

    LDA VID_first_frame_addr+1
    STA mode7_gif_anim_load_addr + 2

    BNE do_frame
  
    .done_frame
    \\ Have we set the loop address yet?
    LDA VID_first_frame_addr+1
    BNE return

    \\ This is the address of (second) frame - loop point!
    LDA mode7_gif_anim_load_addr + 1
    STA VID_first_frame_addr

    LDA mode7_gif_anim_load_addr + 2
    STA VID_first_frame_addr+1

    .return
    RTS
}


\ ******************************************************************
\ *	Video stream decode routines
\ ******************************************************************

.mode7_gif_anim_decode_frame_header
{
	\\ Get number of deltas in frame (16-bits)
	JSR mode7_gif_anim_get_next_byte
	STA mode7_gif_anim_num_deltas

	JSR mode7_gif_anim_get_next_byte
	STA mode7_gif_anim_num_deltas+1

	\\ Reset our write ptr
	LDA VID_frame_start			; #LO(VID_frame_addr)
	STA writeptr
	LDA VID_frame_start+1		; #HI(VID_frame_addr)
	STA writeptr+1

	.return
	RTS
}

.mode7_gif_anim_decode_entire_frame
{
	\\ Write entire frame (<=1000 bytes)
	.loop
	JSR mode7_gif_anim_get_next_byte

	LDY #0					; this was missing?!
	STA (writeptr),Y

	INC writeptr
	BNE no_carry
	INC writeptr+1
	.no_carry

	LDA writeptr
	CMP VID_frame_end		; #LO(VID_frame_addr + VID_frame_size)
	BNE loop
	LDA writeptr+1
	CMP VID_frame_end+1		; #HI(VID_frame_addr + VID_frame_size)
	BNE loop

	CLC						; no read error

	.return
	RTS
}

.mode7_gif_anim_decode_frame_data
{
	\\ Check if this is a special frame before we start
	LDA mode7_gif_anim_num_deltas+1
	CMP #&FF
	BEQ special_frame

	\\ Regular frame (deltas)

	.loop
	\\ Check if we're done
	LDA mode7_gif_anim_num_deltas
	BNE not_zero
	LDA mode7_gif_anim_num_deltas+1
	BNE not_zero

	\\  Zero deltas left
	CLC
	RTS

	.not_zero
	\\ Get packed 16-bit delta
	JSR mode7_gif_anim_get_next_byte
	STA mode7_gif_anim_packed_delta

	JSR mode7_gif_anim_get_next_byte
	STA mode7_gif_anim_packed_delta+1

	\\ Decode offset (10 bits)
	CLC
	LDA mode7_gif_anim_packed_delta
	ADC writeptr
	STA writeptr

	LDA mode7_gif_anim_packed_delta+1
	AND #&1						; only need bottom 1 bit (9-bit offset in colour scheme)
	ADC writeptr+1
	STA writeptr+1

	\\ Decode pixels into MODE 7 byte (6 bits)
	\\ 00X1 1111
	\\ 0X01 1111
	\\ 0X11 1111

	LDA mode7_gif_anim_packed_delta+1
	AND #&2						; control code flag
	BEQ decode_gfx_char

	LDA mode7_gif_anim_packed_delta+1
	AND #&E0					; top 3 bits are data
	LSR A: LSR A: LSR A: LSR A: LSR A
	STA mode7_gif_anim_shifted_bit				; temp storage

	\\ This is a control code not a graphics char
	LDA mode7_gif_anim_packed_delta+1
	AND #&1C					; control code

	\\ Zero just means continue
	BEQ skip_screen_write		; 0 = skip write (to enable 10-bit offset)

	CMP #&04					; (1 << 2) = colour
	BNE not_colour_code

	\\ Colour code
	CLC
	LDA mode7_gif_anim_shifted_bit
	ADC #144					; turn control code data into colour character
	BNE write_to_screen			; always taken

	.not_colour_code
	CMP #&08					; (2 << 2) = control char
	BNE skip_screen_write		; we don't know what this is!

	\\ Control code
	CLC
	LDA mode7_gif_anim_shifted_bit
	ADC #152					; turn control code data into background character
	BNE write_to_screen			; always taken

	.decode_gfx_char
	LDA mode7_gif_anim_packed_delta+1
	AND #128					; top bit 7
	LSR A						; shift down to bit 6
	STA mode7_gif_anim_shifted_bit

	LDA mode7_gif_anim_packed_delta+1	
	LSR A
	LSR A						; shift down twice
	ORA #32						; always need 32 for MODE 7
	ORA mode7_gif_anim_shifted_bit				; mask in bit 6

	\\ Write to screen! (do this without indirect write?)
	.write_to_screen
	LDY #0
	STA (writeptr),Y

	.skip_screen_write
	\\ Decrement delta count
	SEC
	LDA mode7_gif_anim_num_deltas
	SBC #1
	STA mode7_gif_anim_num_deltas
	LDA mode7_gif_anim_num_deltas+1
	SBC #0
	STA mode7_gif_anim_num_deltas+1

	\\ Next delta
	JMP loop

	.special_frame
	LDA mode7_gif_anim_num_deltas
	BEQ full_frame					; &FFFF indicates end of stream

	\\ End of stream
	SEC
	BNE return

	\\ Write entire frame (<=1000 bytes)
	.full_frame
	JSR mode7_gif_anim_decode_entire_frame

	.return
	RTS
}

\ ******************************************************************
\ *	Video stream data routines
\ ******************************************************************

.mode7_gif_anim_get_next_byte
\\{
    PHP

	INC mode7_gif_anim_load_addr + 1
	bne mode7_gif_anim_get_next_byte_no_carry
	INC mode7_gif_anim_load_addr + 2
    .mode7_gif_anim_get_next_byte_no_carry

 .mode7_gif_anim_load_addr
	lda &8000-1	                    ; **SELF-MODIFIED CODE**
    
    .mode7_gif_anim_get_next_byte_return
    PLP
    RTS
\\}
