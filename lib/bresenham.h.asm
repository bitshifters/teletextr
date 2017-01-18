\\ 8-bit Fast Bresenham Line plot routine
\\ Inspired by http://codebase64.org/doku.php?id=base:bresenham_s_line_algorithm_2
\\ Uses self modifying code for speed
\\ gradient setup (once per line draw call) 104 cycles
\\ 21-5 cycles per iteration
\\ +cost of plot pixel routine

_USE_RTW=TRUE

IF _USE_RTW

.rtw_startx				SKIP 1
.rtw_starty				SKIP 1
.rtw_endx				SKIP 1
.rtw_endy				SKIP 1
.rtw_dx					SKIP 1
.rtw_dy					SKIP 1
.rtw_accum				SKIP 1
.rtw_count				SKIP 1

ELSE

.my_pos_y SKIP 1


\\ Requires MACRO PLOT_PIXEL to be pre-defined that calls a function taking X and Y coords for a point to be rendered



\\ drawline, X=new x coord, Y=new y coord
\\ draws line from lastX,lastY to X,Y
\\ move






;coords
.x_1 	SKIP 1
.y_1	SKIP 1

.x_2	SKIP 1
.y_2	SKIP 1

ENDIF


