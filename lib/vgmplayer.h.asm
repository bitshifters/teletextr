
\\ VGM Player module
\\ Include file
\\ Define ZP and constant vars only in here
\\ Uses memory &0380-&03DF & ZP


\ ******************************************************************
\ *	Define global constants
\ ******************************************************************

VGM_FX_num_freqs = 16				; number of VU bars - can be 16 or 32
VGM_FX_num_channels = 4				; number of beat bars (one per channel)


\\ Player
VGM_PLAYER_string_max = 42			; size of our meta data strings (title and author)
VGM_PLAYER_sample_rate = 50			; locked to 50Hz

\ ******************************************************************
\ *	Declare ZP variables
\ ******************************************************************

\\ Copied out of the RAW VGM header
.vgm_player_packet_count	SKIP 2		; number of packets
.vgm_player_duration_mins	SKIP 1		; song duration (mins)
.vgm_player_duration_secs	SKIP 1		; song duration (secs)

.vgm_player_packet_offset	SKIP 1		; offset from start of file to beginning of packet data


\\ Player vars
.vgm_player_ended			SKIP 1		; non-zero when player has reached end of tune
.vgm_player_data			SKIP 1		; temporary variable when decoding sound data - must be separate as player running on events
.vgm_player_last_reg		SKIP 1		; last channel (register) refered to by the VGM sound data
.vgm_player_reg_bits		SKIP 1		; bits 0 - 7 set if SN register 0 - 7 updated this frame, cleared at start of player poll
.vgm_player_counter			SKIP 2		; increments by 1 every poll (20ms) - used as our tracker line no. & to sync fx with audio update

;.vgm_player_counter_tmp     SKIP 1