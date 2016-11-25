

; define z order table resolution - more bits, more sorting precision
; for mode 7 with coarse meshes, 3 bits is fine
DEPTH_BITS = 3  ; max 7
MAX_DEPTH = 2^DEPTH_BITS

.zorder SKIP MAX_VERTS


;---------------------------------------------------------------------------------------------------------
; Coordinate Zsort routine
;---------------------------------------------------------------------------------------------------------
; Sorts all screen Z coords for the currently selected model in near-to-far order
; On entry:
;  no parameters
; On exit:
;  All registers clobbered
;  All points in the model will be transformed
;  zorder array contains the sorted vertex IDs. To render back to front iterate from zorder[npts...0]
;---------------------------------------------------------------------------------------------------------
; The sort is stable and constant time for n vertices.
; The sort uses a linked list order table technique:
;  Each point is allocated to a depth bucket order table based on the 8-bit vertex z coord.
;  If the order table already contains an entry, the new entry is added to the table, with a link to the previous entry.
;  Once all vertex entries have been allocated, the order table is traversed serialising each vertex id into the zorder output array
;  DEPTH_BITS controls the resolution of the order table, where lower values result in better performance at the cost of sort precision

; It requires the following number of operations:
;  MAX_DEPTH memory clears
;  npts x memory fetches & transforms
;  3 x npts memory writes
;  MAX_DEPTH memory fetches
;  npts x memory writes
;  npts x 2 memory reads

.zsort
{
    ; clear order table
    ldx #0
    stx zcount

    lda #255            ; [2]
.resetz
    sta ztable,X        ; [5]
    inx                 ; [2]
    cpx #MAX_DEPTH      ; [2]
    bne resetz          ; [3]
                        ; 12 x MAX_DEPTH = 96 cycles


    ; sort the coordinates of the current model into z depth order from far plane to near plane (z = 0 to 255)
    ldx npts
.zpoints_loop
    txa                 ; [2]
    pha                 ; [3]
    
    ; get zcoord of vertex ID (X is preserved)
    jsr getscreenz      ; [6]+routine cost
    ; returns Z coord in A
    ; reduce to DEPTH_BITS bit range, non-linear conversion would be more ideal, but y'know.. 6502 and all
    FOR n, 1, 8-DEPTH_BITS
        lsr a           ; [2] x n
    NEXT
    tay                 ; [2]

    ; zstack[zcount] = n
    txa                 ; [2]
    ldx zcount          ; [4]
    sta zstack,x        ; [5]

    ; if ztable[z] >= 0, goto relink 
    lda ztable,y        ; [5]
    bpl relink          ; [2/3]

    ; else:
    ; zlinks[zcount] = -1
    lda #255            ; [2]

.relink

    ; zlinks[zcount] = ztable[z]
    sta zlinks,x        ; [5]

.continue

    ; ztable[z] = zcount
    txa                 ; [2]
    sta ztable,y        ; [5]
    inc zcount          ; [6]

    ; for each vertex z
    pla                 ; [4]
    tax                 ; [2]
    dex                 ; [2]
    bpl zpoints_loop    ; [3]

                        ; approx 69 cycles per point

    ; we now have a sparse linked list order table
    ; so traverse it and compile the final ordered list
    ; guaranteed to visit all MAX_DEPTH entries in ztable
    ldx #0
    ldy #0
.ploop
    tya                 ; [2]
    pha                 ; [3]

    ; get order table entry, and check if empty (-1)
    lda ztable,y        ; [5]
    bmi empty           ; [3]

    ; not empty, parse the entry:
    ;  y = ztable[y]
    ;  while y >= 0:
    ;   zorder[x++] = zstack[y]
    ;   y = zlinks[y]
    ; guaranteed to execute 'npts' times
.traverse
    tay                 ; [2]
    lda zstack,y        ; [5]
    sta zorder,x        ; [5]
    inx                 ; [2]
    lda zlinks,y        ; [5]
    bpl traverse        ; [2/3]
                        ; 23-24 cycles
.empty
    pla                 ; [4], zp stash would be 1 cycle faster, plus could ldy
    tay                 ; [2]

    iny                 ; [2]
    cpy #MAX_DEPTH      ; [2]
    bne ploop           ; [3]
                        ; 26 cycle loop overhead

    ; setup = MAX_DEPTH x 12 cycles
    ; allocate = npts x 69 cycles
    ; traverse = npts x 23 cycles + MAX_DEPTH x 26 cycles

    ; so MAX_DEPTH=8, npts=26, cycles=96+1794+598+208 
    ; total 2696 cycles, 1.34ms

    rts

; workspace for sorting
.ztable SKIP MAX_DEPTH
.zstack SKIP MAX_VERTS
.zlinks SKIP MAX_VERTS
.zcount EQUB 0

}


; alternative schemes:
; create one way linked list of sorted points
; for each point find insertion point based on where point.z >= linkedlist.z
;  point.next = linkedlist.next
;  linkedlist.next = point




; worst case, points present in 100% reverse order
; best case, points present in 100% correct order
; each point therefore requires a full list traversal before insertion at the end
; npts*(1+npts)/2 
; npts = 26, worst case traversals = 351 
; best case traversal = npts
;
; would use slightly less memory, 2x MAX_VERTS
; would not be a time constant sort. 
; worst case would be approx 3x slower than order table sort.
; best case would be approx 10x fast than order table sort

; insertion sort too complex for 6502
; bubble sort N^2 worst case = 676 traversals

; order table sort is constant
; 8 traversals of order table, npts(26) insertions cost
; 8 more traversals of order table, npts(26) traversal costs
; total 68 operations