
; specify true to force multiplication tables to be contiguous in memory
; if false they are separated into different memory locations to free up 768 bytes
; which allows just enough more RAM to have more models in the wireframe demo 
CONTIGUOUS_TABLES = TRUE


;----------------------------------------------------------------------------------------------------------
; Zero Page Vars
;----------------------------------------------------------------------------------------------------------


; 3x3 rotation matrix
; 16-bit unit vectors
m00lsb=0
m00msb=9
m01lsb=1
m01msb=&A
m02lsb=2
m02msb=&B
m10lsb=3
m10msb=&C
m11lsb=4
m11msb=&D
m12lsb=5
m12msb=&E
m20lsb=6
m20msb=&F
m21lsb=7
m21msb=&10
m22lsb=8
m22msb=&11

adr=&12

xr=&1A
yr=&1C
zr=&1E

product=&20

; 8-bit rotation angles
rx=&22
ry=&23
rz=&24

; model data
npts=&30
nlines=&31
nsurfs=&32
maxvis=&33

lhs=&40
rhs=&42

lmul0=&44
lmul1=&46
rmul0=&48
rmul1=&4A

surfs=&50
oldsurfs=&52
surfsdone=&54
visible=&56

; ptr to the lines array for the current model
lines=&57

; 64-bit line flag array (8 bytes)
; set by 'hiddenlineremoval'
line=&59

; temp address
odr=&61

; logic vars
space=&63
p=&64
f=&65
flicker=&66
pause=&67
culling=&68     ; culling = 0=disabled, 255=enabled
cullingdb=&69   ; culling key debounce
opt_filled=&6A
opt_filled_db=&6B

; line rendering coordinates, start and end
x0=&70:y0=&71
x1=&72:y1=&73

; logic vars
scr=&74
err=&76
errs=&77
cnt=&78
ls=&79
dx=&FF
dy=&7A
scrstrt=&7B
c=&7C

