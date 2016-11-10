



.effect_linebox  EFFECT_HEADER  effect_linebox_update,0,0

.effect_linebox_update
{

IF TRUE
    lda #0
    sta x0:sta y0
    lda #64
    sta x1:sta y1
    jsr linedraw	
ENDIF

IF FALSE	
	ldx #0
	ldy #0
	jsr move_to

	ldx #PLOT_PIXEL_RANGE_X-1
	ldy #0
	jsr draw_to

	ldx #PLOT_PIXEL_RANGE_X-1
	ldy #PLOT_PIXEL_RANGE_Y-1
	jsr draw_to	

	ldx #0
	ldy #PLOT_PIXEL_RANGE_Y-1
	jsr draw_to		

	ldx #0
	ldy #0
	jsr draw_to		

    	
ENDIF    



    rts    
}
