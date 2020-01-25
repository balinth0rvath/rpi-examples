/*******************************************************************************
 *    
 * Draws a mandelbrot set,
 *
 * i - real axis 	
 * j - imaginary axis
 *
 * Input: 
 *	i1,j1: float coordinates of upper left corner
 *      i2,j2: float coordinates of lower right corner
 *
 * Variables:                                          
 * 	x, y: variables are containing the current pixel
 *	x moves from 0 to max_x (800)		
 * 	y moves from 0 to max_y (400)	
 * 	step sizes are di, dj	
 *                             
 *******************************************************************************/

	.global main
	.func main
main:
	STMFD SP!, {LR}

	BL init_graphics	@ Init graphics

	CMP R0, #1
	BEQ exit

	LDR R0, =max_iter
	LDR R5, [R0]		@ R5 is max iteration

	LDR R0, =i1
	VLDR S0, [R0]		@ S0 is i1

	LDR R0, =j1
	VLDR S1, [R0]		@ S1 is j1

	LDR R0, =i2
	VLDR S2, [R0]		@ S2 is i2

	LDR R0, =j2 
	VLDR S3, [R0]		@ S3 is j2

	LDR R0, =max_x
	LDR R3, [R0]		
	VMOV S4, R3
	VCVT.F32.U32 S4, S4	@ S4 and R3 are max_x

	LDR R0, =max_y		
	LDR R4, [R0]
	VMOV S5, R4
	VCVT.F32.U32 S5, S5	@ S5 and R4 are max_y
	
	VSUB.F32 S6, S2, S0	@ S6 is di 
	VDIV.F32 S6, S6, S4	@ di = (i2 - i1) / max_x

	VSUB.F32 S7, S3, S1	@ S7 is dj
	VDIV.F32 S7, S7, S5	@ dj = (j2 - j1) / max_y

	VMOV S9, S1		@ S9 is j = j1
	MOV R1, #0		@ R1 is y = 0
loop_y:
	VMOV S8, S0		@ S8 is i = i1
	MOV R0, #0		@ R0 is x = 0
loop_x:
	BL iterate		@ calculate color

	BL put_pixel		@ put a pixel to x,y

	VADD.F32 S8, S8, S6	@ i = i + di
	ADD R0, R0, #1		@ increment x too
	CMP R3, R0
	BNE loop_x

	VADD.F32 S9, S9, S7	@ j = j + dj
	ADD R1, R1, #1		@ inrement y 
	CMP R4, R1
	BNE loop_y

	BL close_graphics	@ close graphics
exit:
	LDMFD SP!, {PC}		

/*********************************************************************************
 *                                    
 * Calculates a point of mandelbrot set
 *                                   
 * Input:
 * 	S8: real part (i)
 * 	S9: imaginary part (j)
 *	R5: max iteration
 * Output:
 * 	R2: color                      
 * Variables:
 *	R0: iteration counter
 *	S0: iterating real part (ii)
 *	S1: iterating imaginary part (ij)
 * 	S2: temporary real part (ti)
 *	S3: escape threshold (et)
 *	S4: auxilary (aux_j)
 *	S5: auxilary (aux_t)
 *                                     
 *********************************************************************************/
iterate:
	STMFD SP!, {R0-R1,LR}
	VSTMDB SP!, {S0-S5}	@ store S0 - S5

	MOV R0, R5		@ iterate from max iter

	MOV R2, #0		@ color starts at rgb 000

	VMOV S0, S8		@ set iterating real part
	VMOV S1, S9		@ set iterating imaginary part
	LDR R1, =aux_j
	VLDR S4, [R1]		@ aux_j = 2	
	VADD.F32 S5, S4, S4	@ aut_t = 4

loop_iter:
	ADD R2, R2, #10		@ add one to color on each iter step

	VMUL.F32 S2, S0, S0
	VMLS.F32 S2, S1, S1	 
	VADD.F32 S2, S2, S8	@ ti = ii * ii - ij * ij + i

	VMUL.F32 S1, S0, S1
	VMUL.F32 S1, S1, S4	
	VADD.F32 S1, S1, S9	@ ij = 2 * ii * ij + j

	VMOV S0, S2		@ ii = ti

	VMUL.F32 S3, S0, S0
	VMLA.F32 S3, S1, S1	@ et = ii * ii + ij * ij
	VCMP.F32 S3, S5
	VMRS APSR_nzcv, FPSCR
	BGE exit_iter		@ exit if i * i + j * j < 4

	SUBS R0, R0, #1		@ countdown iter to 0
	BNE loop_iter
	MOV R2, #0		@ infinit is black
exit_iter:
	VLDM SP!, {S0-S5}	@ release S0 - S5
	
	LDMFD SP!, {R0-R1,PC}


@ data area
.data

i1:
	.float -2
j1:
	.float -1
i2:
	.float  1.3
j2:
	.float  1
aux_j:
	.float 2
max_x:
	.word 800
max_y:
	.word 480
max_iter:
	.word 100
