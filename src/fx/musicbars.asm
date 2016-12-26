
; extremely dodgy music bars :)

FX_MUSICBARS_BEAT_HEIGHT = 2    ; num lines to set
FX_MUSICBARS_BEAT_FADE = 3      ; fade speed, down from 9

FX_MUSICBARS_FREQ_FADE = 3      ; fade speed, down from 15

FX_MUSICBARS_SOLID = FALSE      ; **BROKEN (doesn't reset fg col yet)

.fx_musicbars_horiz_freq
{
	JSR fx_rasterbars_reset_bg

    {
        LDX #0
        LDY #VGM_FX_num_freqs-1
        .loop
        LDA vgm_freq_array, Y
        BEQ next

        SEC
        SBC #FX_MUSICBARS_FREQ_FADE
        BPL set_freq

;        LDA teletext_bg_col, X
;        AND #&FE
;        STA teletext_bg_col, X

        LDA #0
        STA vgm_freq_array, Y
        JMP next

        .set_freq
        STA vgm_freq_array, Y

        LDA #1
        ORA teletext_bg_col, X
        STA teletext_bg_col, X

        .next
        INX
        DEY
        BPL loop
    }

    {
        LDX #0
        LDY #VGM_FX_num_freqs-1
        .loop
        LDA vgm_freq_array+VGM_FX_num_freqs, Y
        BEQ next

        SEC
        SBC #FX_MUSICBARS_FREQ_FADE
        BPL set_freq

;        LDA teletext_bg_col, X
;        AND #&FD
;        STA teletext_bg_col, X

        LDA #0
        STA vgm_freq_array+VGM_FX_num_freqs, Y
        JMP next

        .set_freq
        STA vgm_freq_array+VGM_FX_num_freqs, Y

        LDA #2
        ORA teletext_bg_col, X
        STA teletext_bg_col, X

        .next
        INX
        DEY
        BPL loop
    }

    {
        LDX #0
        LDY #VGM_FX_num_freqs-1
        .loop
        LDA vgm_freq_array+(VGM_FX_num_freqs*2), Y
        BEQ next

        SEC
        SBC #FX_MUSICBARS_FREQ_FADE
        BPL set_freq

 ;       LDA teletext_bg_col, X
 ;       AND #&FB
 ;       STA teletext_bg_col, X

        LDA #0
        STA vgm_freq_array+(VGM_FX_num_freqs*2), Y
        JMP next

        .set_freq
        STA vgm_freq_array+(VGM_FX_num_freqs*2), Y

        LDA #4
        ORA teletext_bg_col, X
        STA teletext_bg_col, X

        .next
        INX
        DEY
        BPL loop
    }

    .return
    RTS
}

.fx_musicbars_beat_table
EQUB 0,0,0,4,4,4,5,5,5,7

.fx_musicbars_horiz_beat
{
;	JSR fx_rasterbars_reset_bg

    LDY #VGM_FX_num_channels-1
    LDX #0

    .loop
    LDA vgm_chan_array, Y
    BEQ is_zero
    SEC
    SBC #FX_MUSICBARS_BEAT_FADE
    BPL set_chan
    LDA #0
    .set_chan
    STA vgm_chan_array, Y

    .is_zero
    STX set_zero+1
    TAX
    LDA fx_musicbars_beat_table, X

    .set_zero
    LDX #0

    FOR n,1,FX_MUSICBARS_BEAT_HEIGHT,1
    STA teletext_bg_col, X
    IF FX_MUSICBARS_SOLID
    STA teletext_fg_col, X
    ENDIF
    INX
    NEXT

    .next
    DEY
    BPL loop

    .return
    RTS
}

.fx_musicbars_sep_on_noise_beat
{
    LDY #VGM_FX_num_channels-1  ; noise
    LDA vgm_chan_array, Y
    BEQ return

    LDX #MODE7_separated

    SEC
    SBC #FX_MUSICBARS_BEAT_FADE
    BPL set_chan
    LDA #0
    LDX #MODE7_contiguous
    .set_chan
    STA vgm_chan_array, Y

    TXA
    LDY #MODE7_char_height - 1
    .loop
    STA teletext_fx, Y
    DEY
    BPL loop

    .return
    RTS
}
