
; specify true to force multiplication tables to be contiguous in memory
; if false they are separated into different memory locations to free up 768 bytes
; which allows just enough more RAM to have more models in the wireframe demo 
CONTIGUOUS_TABLES = TRUE


;----------------------------------------------------------------------------------------------------------
; Zero Page Vars
;----------------------------------------------------------------------------------------------------------


; 3x3 rotation matrix
; 16-bit unit vectors
.m00lsb SKIP 1
.m01lsb SKIP 1
.m02lsb SKIP 1
.m10lsb SKIP 1
.m11lsb SKIP 1
.m12lsb SKIP 1
.m20lsb SKIP 1
.m21lsb SKIP 1
.m22lsb SKIP 1

.m00msb SKIP 1
.m01msb SKIP 1
.m02msb SKIP 1
.m10msb SKIP 1
.m11msb SKIP 1
.m12msb SKIP 1
.m20msb SKIP 1
.m21msb SKIP 1
.m22msb SKIP 1

.adr SKIP 8

.xr SKIP 2
.yr SKIP 2
.zr SKIP 2

.product SKIP 2

; 8-bit rotation angles
.rx SKIP 1
.ry SKIP 1
.rz SKIP 1

; model data
.npts SKIP 1
.nlines SKIP 1
.nsurfs SKIP 1
.maxvis SKIP 1

.lhs SKIP 2
.rhs SKIP 2

.lmul0 SKIP 2
.lmul1 SKIP 2
.rmul0 SKIP 2
.rmul1 SKIP 2

.surfs SKIP 2
.oldsurfs SKIP 2
.surfsdone SKIP 2
.visible SKIP 2

; ptr to the lines array for the current model
.lines SKIP 2

; 64-bit line flag array (8 bytes)
; set by 'hiddenlineremoval'
.line SKIP 8

; temp address
.odr SKIP 2



; line rendering coordinates, start and end
.x0 SKIP 1
.y0 SKIP 1
.x1 SKIP 1
.y1 SKIP 1

; logic vars
.scr SKIP 2
.err SKIP 1
.errs SKIP 1
.cnt SKIP 1
.ls SKIP 1
.dx SKIP 1
.dy SKIP 1
.scrstrt SKIP 1

.transx SKIP 1
.transy SKIP 1
.transz SKIP 1



;.c SKIP 1

