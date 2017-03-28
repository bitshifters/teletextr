\\ 6502 Graphics routines

MODE7_VRAM_START = &7c00

IF USE_SHADOW_RAM
MODE7_VRAM_SHADOW = &7C00
ELSE
MODE7_VRAM_SHADOW = &7800
ENDIF

.disp_buffer_addr	SKIP 1	; MSB of display buffer address
.draw_buffer_addr	SKIP 1	; MSB of draw buffer address


