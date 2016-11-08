
IF WIREFRAME
    linedraw = linedraw4
ELSE
    linedraw = linedraw5f
ENDIF




;----------------------------------------------------------------------------------------------------------
; clear the draw buffer
;----------------------------------------------------------------------------------------------------------


IF WIREFRAME
.wipe
{
    LDX#&2F:CMP#&30:BNE wipe0:JMP wipe1
    .wipe0 LDA#0
    .loop
    FOR Y%, &5D40, &7A00, &140
        FOR X%, Y%, Y%+144, 48
            STA X%,X
        NEXT
    NEXT
    DEX:BMI wiped:JMP loop
    .wiped RTS
    .wipe1 LDA#0
    .loop2
    FOR Y%, &3540, &5200, &140
        FOR X%, Y%, Y%+144, 48
            STA X%,X
        NEXT
    NEXT
    DEX:BMI wiped1:JMP loop2
    .wiped1 
    RTS
}

ELSE


.wipe 
{
    LDA#0:LDX#&2F
    .loop5
    FOR Y%, &3A40, &5700, &140
        FOR X%, Y%, Y%+144, 48
           STA X%,X
        NEXT
    NEXT
    DEX:BMI wiped:JMP loop5
    .wiped 
    RTS
}


; xor fill the back buffer to the front buffer
.fill
{ 
    SEC:LDX#&B8
    .loop6
    LDA &3A40,X
    EOR &3A41,X:STA&5D41,X
    EOR &3A42,X:STA&5D42,X
    EOR &3A43,X:STA&5D43,X
    EOR &3A44,X:STA&5D44,X
    EOR &3A45,X:STA&5D45,X
    EOR &3A46,X:STA&5D46,X
    EOR &3A47,X:STA&5D47,X

    FOR A%,&5E80, &7A00, &140

        EOR A%-&2300,X:STAA%,X
        EOR A%-&22FF,X:STAA%+1,X
        EOR A%-&22FE,X:STAA%+2,X
        EOR A%-&22FD,X:STAA%+3,X
        EOR A%-&22FC,X:STAA%+4,X
        EOR A%-&22FB,X:STAA%+5,X
        EOR A%-&22FA,X:STAA%+6,X
        EOR A%-&22F9,X:STAA%+7,X

    NEXT 
    TXA:SBC#8:BCC filled:TAX:JMP loop6
    .filled 
    RTS
}

; copy the back buffer to the front buffer
.fill_copy
{
    LDA#0:LDX#&2F
    .loop5
    FOR Y%, &3A40, &5700, &140
        FOR X%, Y%, Y%+144, 48
           LDA X%,X:STA X%+(&5D40-&3A40),X
        NEXT
    NEXT
    DEX:BMI wiped:JMP loop5
    .wiped 
    RTS
}

ENDIF

