
; ray caster

RAYCASTER_shadow_addr = &7800
RAYCASTER_sin_scale = 127

\ ******************************************************************
\ *	Ray caster FX
\ ******************************************************************

.fx_raycaster_init
{
	.return
	RTS
}

.fx_raycaster_update
{
	.return
	RTS
}

.raycaster_sin_table
FOR n,0,&13F,1
EQUB RAYCASTER_sin_scale * SIN(2 * PI * n / 256)
NEXT

raycaster_cos_table = raycaster_sin_table + &40			; this can be overlapped with sin table +64
