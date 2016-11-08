; Does not need to be page aligned
; Access using:
;  sin(x) = lda slsb,x | lda smsb,x
;  cos(x) = lda clsb,x | lda cmsb,x


;----------------------------------------------------------------------------------------------------------
; sin/cos lookup table
;----------------------------------------------------------------------------------------------------------
; provides 256 degrees of range for angles

; data format:
;  16-bit (approximately 1 bit sign, 3 bits integer, 12 bits fraction [1:3:12]) entries
;
; cos table is offset from sin table by 64 bytes (90 degrees)
;
; stored as:
;  256+64 bytes lsb
; followed by:
;  256+64 bytes msb
; 
; could potentially be optimized using page alignment, 
;  but since it is really only used to create rotation matrix once per frame, and would need more memory,
;  probably not worth it.

.trigtable_start
.slsb 
smsb=slsb+&140
; cos table offsets
clsb=slsb+&40
cmsb=clsb+&140


; sin table values are stored as 16-bit values
; they are multiplied by &1fa0 = 8096 or (&fd << 5) or (253 << 5) or (% 0001 1111 1010 0000)
;  which gives fixed point precision as well as overall scale
; 
; Original author (Nick) notes:
;  The &1FA0 is a bit arbitrary.
;  Note that the way the program uses the sine table to build the rotation matrix 
;  (no multiplications there, it's all done with compound angle formulae) 
;  it doesn't matter what this number is - it just results in a scaling of the whole object. 
;  I knew it had to be a bit less than &2000 but obviously couldn't be bothered to work out
;  exactly how big it could be. Changing it to &1FE0 seems to be fine but &1FF0 is too big.

SINCOS_SCALE = 1 << 12 ;253 << 5 ; = &1fa0, but can be 255 << 5 (&1fe0) as a maximum, given current range of input coordinates
; SM: could be calculated as the largest number that can support full range of 8-bit vertex coordinates without overflow 

    FOR A%, 0, &13F
        S% = SINCOS_SCALE * SIN( A%*2*PI /256 )+.5
        EQUB LO(S%)
    NEXT
    FOR A%, 0, &13F
        S% = SINCOS_SCALE * SIN( A%*2*PI /256 )+.5
        EQUB HI(S%)
    NEXT
.trigtable_end

