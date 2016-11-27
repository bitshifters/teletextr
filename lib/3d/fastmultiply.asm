
; quarter square lookup tables
;  table1 = n*n/4, where n=0..510
;  table2 = (n-255)*(n-255)/4, where n=0..510
;
; table2 + table1 origins must be page aligned

ALIGN 256



IF CONTIGUOUS_TABLES
.table_data SKIP 1536
;table_data = &0E00

; specify contiguous tables
    SQUARETABLE2_LSB = table_data
    SQUARETABLE1_LSB = SQUARETABLE2_LSB+256
    SQUARETABLE2_MSB = SQUARETABLE1_LSB+512
    SQUARETABLE1_MSB = SQUARETABLE2_MSB+256
ELSE



; msb & lsb tables can be in different memory locations
; enables us to move the program org down a bit
; as we can spread the two 768 bytes tables around the memory map 
    SQUARETABLE2_LSB = &0E00
    SQUARETABLE1_LSB = SQUARETABLE2_LSB+256

    SQUARETABLE2_MSB = &0900 ;&1100
    SQUARETABLE1_MSB = SQUARETABLE2_MSB+256
ENDIF





;----------------------------------------------------------------------------------------------------------
; setup quarter square multiplication tables
;----------------------------------------------------------------------------------------------------------
; f(x) = x^2 / 4. Then a*b = f(a+b) - f(a-b) 
;
; This implementation uses two tables of squares:
;  table1 = n*n/4, where n=0..510
;  table2 = (n-255)*(n-255)/4, where n=0..510
;  
; Unsigned multiplication of two 8-bit terms is computed as:
;  r = table1[a+b] - table2[(a EOR 255)+b]
; where r is a 16-bit unsigned result
;----------------------------------------------------------------------------------------------------------
; A clever innovation with this code is that it takes advantage of overlaps in the table
;  which means the tables fit into 1536 bytes instead of the usual 2048. 
;
; &0000-&01FF = table2 lsb
; &0100-&02FF = table1 lsb
; &0300-&04FF = table2 msb
; &0400-&05FF = table1 msb 
;----------------------------------------------------------------------------------------------------------
.initialise_multiply
{

    ; set the msb of lmul0, lmul1, rmul0 and rmul1 just once
    ;  for the entire lifecycle of the application
    ;  - the lsb of these 16-bit addresses will be set as the multiplication terms
    LDA#HI(SQUARETABLE1_LSB):STA lmul0+1:STA rmul0+1
    LDA#HI(SQUARETABLE1_MSB):STA lmul1+1:STA rmul1+1

    ; compute table1
    
    ; x=y=lhs=0
    ; while y<256:
    ;     if y>0:
    ;         lhs += x
    ;         table1[offset+y] = lhs
    ;         x = x + 1
    ;
    ;     lhs += x
    ;     offset = y
    ;     table1[offset+y] = lhs    
    ;     y = y + 1

    ; effectively the same as:
    ; for n in range(0,511):  # 0-510
    ;     table1[n] = n*n/4

    ; initialise counters and indices    
    LDA#0:TAX:TAY
    STX lhs:STY lhs+1

    ; skip increment on first iteration
    CLC
    BCC go

    .loop2
    TXA:ADC lhs:STA lhs:STA(lmul0),Y
    LDA#0:ADC lhs+1:STA lhs+1:STA(lmul1),Y
    INX

    .go 
    STY lmul0:STY lmul1
    TXA:ADC lhs:STA lhs:STA(lmul0),Y
    LDA#0:ADC lhs+1:STA lhs+1:STA(lmul1),Y
    INY
    BNE loop2

    ; compute table2

    ; for x in range(0,256):
    ;     table2[x] = table1[255-x]
    ;     table2[x+256] = table1[x+1]    
    ;
    ; effectively the same as:
    ; for n in range(0,511):  # 0-510
    ;     table2[n] = (n-255)*(n-255)/4


    LDX#0:LDY#&FF
    .loop3
    LDA SQUARETABLE1_LSB+1,Y:STA SQUARETABLE2_LSB,X
    LDA SQUARETABLE1_MSB+1,Y:STA SQUARETABLE2_MSB,X
    DEY:INX:BNE loop3

    rts
}



IF 0
square1_lo = SQUARETABLE1_LSB
square2_lo = SQUARETABLE2_LSB
square1_hi = SQUARETABLE1_MSB
square2_hi = SQUARETABLE2_MSB
ELSE


ALIGN 256

.square1_lo
FOR i, 0, 511
	EQUB LO(i*i/4)
NEXT

.square1_hi
FOR i, 0, 511
	EQUB HI(i*i/4)
NEXT

.square2_lo
FOR i, 0, 511
	EQUB LO((i-255)*(i-255)/4)
NEXT
.square2_hi
FOR i, 0, 511
	EQUB HI((i-255)*(i-255)/4)
NEXT
ENDIF


; Description: Unsigned 16-bit multiplication with unsigned 32-bit result.
;                                                                         
; Input: 16-bit unsigned value in T1                                      
;        16-bit unsigned value in T2                                      
;        Carry=0: Re-use T1 from previous multiplication (faster)         
;        Carry=1: Set T1 (slower)                                         
;                                                                         
; Output: 32-bit unsigned value in PRODUCT                                
;                                                                         
; Clobbered: PRODUCT, X, A, C                                             
;                                                                         
; Allocation setup: T1,T2 and PRODUCT preferably on Zero-page.            
               
.maths_multiply_16bit_unsigned 
{                                            
		; <T1 * <T2 = AAaa                                        
		; <T1 * >T2 = BBbb                                        
		; >T1 * <T2 = CCcc                                        
		; >T1 * >T2 = DDdd                                        
		;                                                         
		;       AAaa                                              
		;     BBbb                                                
		;     CCcc                                                
		; + DDdd                                                  
		; ----------                                              
		;   PRODUCT!                                              

		; Setup T1 if changed
		bcc skipt1               
		lda T1+0         
		sta sm1a+1       
		sta sm3a+1       
		sta sm5a+1       
		sta sm7a+1       
		eor #$ff         
		sta sm2a+1       
		sta sm4a+1       
		sta sm6a+1       
		sta sm8a+1       
		lda T1+1         
		sta sm1b+1       
		sta sm3b+1       
		sta sm5b+1       
		sta sm7b+1       
		eor #$ff         
		sta sm2b+1       
		sta sm4b+1       
		sta sm6b+1       
		sta sm8b+1       
.skipt1                 

		; Perform <T1 * <T2 = AAaa
		ldx T2+0                  
		sec                       
.sm1a	lda square1_lo,x          
.sm2a	sbc square2_lo,x          
		sta PRODUCT+0             
.sm3a	lda square1_hi,x          
.sm4a	sbc square2_hi,x          
		sta _AA+1                 

		; Perform >T1_hi * <T2 = CCcc
		sec                          
.sm1b	lda square1_lo,x             
.sm2b	sbc square2_lo,x             
		sta _cc+1                    
.sm3b	lda square1_hi,x             
.sm4b	sbc square2_hi,x             
		sta _CC+1                    

		; Perform <T1 * >T2 = BBbb
		ldx T2+1                  
		sec                       
.sm5a	lda square1_lo,x          
.sm6a	sbc square2_lo,x          
		sta _bb+1                 
.sm7a	lda square1_hi,x          
.sm8a	sbc square2_hi,x          
		sta _BB+1                 

		; Perform >T1 * >T2 = DDdd
		sec                       
.sm5b	lda square1_lo,x          
.sm6b	sbc square2_lo,x          
		sta _dd+1                 
.sm7b	lda square1_hi,x          
.sm8b	sbc square2_hi,x          
		sta PRODUCT+3             

		; Add the separate multiplications together
		clc                                        
._AA	lda #0                                     
._bb	adc #0                                     
		sta PRODUCT+1                              
._BB	lda #0                                     
._CC	adc #0                                     
		sta PRODUCT+2                              
		bcc skip1                                     
		inc PRODUCT+3                          
		clc                                    
.skip1                                        
._cc	lda #0                                     
		adc PRODUCT+1                              
		sta PRODUCT+1                              
._dd	lda #0                                     
		adc PRODUCT+2                              
		sta PRODUCT+2                              
		bcc skip2                                    
		inc PRODUCT+3                          
.skip2                                        
		rts
}       



; Description: Signed 16-bit multiplication with signed 32-bit result.
;                                                                     
; Input: 16-bit signed value in T1                                    
;        16-bit signed value in T2                                    
;        Carry=0: Re-use T1 from previous multiplication (faster)     
;        Carry=1: Set T1 (slower)                                     
;                                                                     
; Output: 32-bit signed value in PRODUCT                              
;
; Clobbered: PRODUCT, X, A, C
.maths_multiply_16bit_signed
{
		jsr maths_multiply_16bit_unsigned

		; Apply sign (See C=Hacking16 for details).
		lda T1+1
		bpl positive0
		sec
		lda PRODUCT+2
		sbc T2+0
		sta PRODUCT+2
		lda PRODUCT+3
		sbc T2+1
		sta PRODUCT+3
.positive0
		lda T2+1
		bpl positive1
		sec
		lda PRODUCT+2
		sbc T1+0
		sta PRODUCT+2
		lda PRODUCT+3
		sbc T1+1
		sta PRODUCT+3
.positive1
		rts
}
