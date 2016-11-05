\\ ******************************************************************
\\ EXOMISER (compression library)
\\ ******************************************************************

\\ Uses memory:
\\ &0400-0800	- 1024 byte decompression buffer
\\ &0D02-0D9F	-  156 byte decompression table
\\ Plus ZP vars
\\ Exomiser decruncher routine installs empty NMI handler at &0d00

\\ Compress data using:
\\ exomizer.exe raw -c -m 1024 <file.raw> -o <file.exo>

\ ******************************************************************
\ *	Space reserved for runtime buffers not preinitialised
\ ******************************************************************

EXO_buffer_len = 1024			; this is now packed in to language workspace at &0400
\\ If you want to make this bigger than 1024 then need to find somewhere else to put it!!

\\ Exomiser unpack buffer (must be page aligned)
\\ Now moved this to the language workspace at &0400 - &0800
EXO_buffer_start = &400
EXO_buffer_end = EXO_buffer_start + EXO_buffer_len

; -------------------------------------------------------------------
; this 156 byte table area may be relocated. It may also be clobbered
; by other data between decrunches.
; Located at spare OS memory page &0d02 - 0x0d9f reserved for Econet/Trackball/NMI
; RTI (&40) is written to &0d00 for clean NMI handler
; -------------------------------------------------------------------

EXO_TABL_SIZE = 156
exo_tabl_bi  = &0d9f - EXO_TABL_SIZE
exo_tabl_lo = exo_tabl_bi + 52
exo_tabl_hi = exo_tabl_bi + 104


\\ Declare ZP vars
.EXO_zp_src_hi	SKIP 1
.EXO_zp_src_lo	SKIP 1
.EXO_zp_src_bi	SKIP 1
.EXO_zp_bitbuf	SKIP 1

.EXO_zp_len_lo	SKIP 1
.EXO_zp_len_hi	SKIP 1

.EXO_zp_bits_lo	SKIP 1
.EXO_zp_bits_hi	SKIP 1

.EXO_zp_dest_hi	SKIP 1
.EXO_zp_dest_lo	SKIP 1	; dest addr lo
.EXO_zp_dest_bi	SKIP 1	; dest addr hi


