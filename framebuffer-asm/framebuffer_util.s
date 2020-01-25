	
/*******************************************************************************
 *            
 * Graphic tools:
 *
 * init_graphics: initializes graphics
 * close_graphics: closes resources
 * put_pixel: puts a pixel on a coordinate with a color
 * fill_box: draws a rectangle filled with solid color
 *          
 *******************************************************************************/

	.global init_graphics
	.global close_graphics
	.global put_pixel
	.global fill_box

/*********************************************************************************
 *                                                                               *
 * Open fb file. Allocate virtual memory. Get fix and var screen info		 *
 *                                                                               *
 *********************************************************************************/

init_graphics:
	STMFD SP!, {R1,LR}
	SUB SP, SP, #16			@ create 16 bytes storage


	LDR R0, =fb_dev_lab		@ /dev/fb0
	MOV R1, #o_rdwr			@ open for read write
	BL open				@ open framebuffer device

	BCS error			@ branch if open failed

	LDR R9, =fbfd
	STRB R0, [R9]			@ store file descriptor

					@ file descriptor in R0 for ioctl
	LDR R9, =fbioget_fscreeninfo	@
	LDRH R1, [R9]			@ fix screeninfo for ioctl
	LDR R2, =finfo			@ address of finfo for ioctl
	BL ioctl			@ get fix screeninfo

	BCS error			@ branch if ioctl failed

	LDR R9, =fbfd			@ load file descriptor
	LDRB R0, [R9]			@
	LDR R9, =fbioget_vscreeninfo	@
	LDRH R1, [R9]			@ var screeninfo for ioctl
	LDR R2, =vinfo			@ address of finfo for ioctl
	BL ioctl			@ get var screeninfo

	BCS error			@ branch if ioctl failed

	MOV R0, #0
	LDR R9, =smem_len
	LDR R1, [R9]			@ framebuffer length
	MOV R2, #prot_rdwr		@ data can be read and written
	MOV R3, #map_shared		@ shared map
	LDR R9, =fbfd			@ load file desriptor address
	LDRB R4, [R9]			@ load file descriptor
	STR R4, [SP]			@ store file descriptor in stack
	MOV R4, #0			@ offset is 0
	STR R4, [SP, #4]		@ store it on stack, 2nd position after top
	BL mmap				@ get virtual address

	LDR R1, =smem_start_virtual
	STR R0, [R1]			@ store virtual address of fb

	MOV R0, #0			

	BAL exit
error:
	MOV R0, #1			@ error on exit

exit:
	ADD SP, SP, #16			@ release 16 bytes on stack
	LDMFD SP!, {R1,PC}

/*********************************************************************************
 *                                                                               *
 * Close file. Free up virtual memory                                            *
 *                                                                               *
 *********************************************************************************/

close_graphics:
	STMFD SP!, {R1,LR}

	LDR R9, =smem_start_virtual
	LDR R0, [R9]			@ get virtual address
	LDR R9, =smem_len
	LDR R1, [R9]			@ get virtual memory length

	BL munmap			@ free memory

	LDR R9, =fbfd
	LDR R0, [R9]

	BL close			@ close file

	LDMFD SP!, {R1,PC}

/*********************************************************************************
 *                                                                               *
 * Draws a pixel                                                                 *
 *                                                                               *
 * R0: x coordinate                                                              *
 * R1: y coordinate                                                              *
 * R2: color                                                                     *
 *                                                                               *
 *********************************************************************************/
 

put_pixel:
	STMFD SP!, {R3-R7}
	
	LDR R3, =xres
	LDR R4, [R3]			@ load x resolution into R4

	LDR R6, =smem_start_virtual	@ load start address into R6
	LDR R6, [R6]

	MLA R5, R1, R4, R0		@ R5: offset= y*xres + x

	LDR R3, =bits_per_pixel		@ calculate how	many bits assemble a pixel 
	LDR R7, [R3]
	MOV R7, R7, LSR #3		@ convert bits to bytes
	MUL R5, R5, R7
	ADD R5, R5, R6			@ R5: smem_start + offset
	
	STR R2, [R5]			@ store R2 color into R5

	LDMFD SP!, {R3-R7}
	MOV PC, LR


/*********************************************************************************
 *                                                                               *
 * Draws a filled box                                                            *
 *                                                                               *
 * R0: x coordinate of upper left corner                                         *
 * R1: y coordinate of upper left corner                                         *
 * R3: x coordinate of lower right corner                                        *
 * R4: y coordinate of lower right corner                                        *
 * R2: color                                                                     *
 *                                                                               *
 *********************************************************************************/

fill_box:
	STMFD SP!, {R0-R6, LR}
	ADD R5, R3, #1			@ R5 is a temporary x border  
	ADD R6, R4, #1			@ R6 is a temporary y border  

	STMFD SP!, {R0}			@ because x is being used as a counter
					@ it must be stored in stack
y_loop:
	LDMFD SP!, {R0}			@ practicing stack...
	STMFD SP!, {R0}
x_loop:
	BL put_pixel
	ADD R0, R0, #1
	CMP R0, R5
	BNE x_loop 			@ draw a full row

	ADD R1, R1, #1
	CMP R1, R6
	BNE y_loop			@ draw to bottom

	LDMFD SP!, {R0}			@ practicing stack...
	LDMFD SP!, {R0-R6, LR}
	MOV PC, LR

	.equ o_rdwr, 2
	.equ prot_rdwr, 3
	.equ map_shared, 1
.data

fb_dev_lab:
	.asciz "/dev/fb0"
line_length_lab:
	.asciz "Length of a line:    %08x \n"
smem_start_lab:
	.asciz "Framebuffer address: %08x \n"
smem_len_lab:
	.asciz "Framebuffer length:  %08x \n"
.align 3

/*********************************************************************************
 *                                                                               *
 * Fix screeninfo memory map                                                     *
 *                                                                               *
 *********************************************************************************/

finfo:
id:
	.ascii "                "	@ Identification string
smem_start:
	.word 0x0			@ smem_start
smem_len:
	.word 0x0			@ smem_len
type:
	.word 0x0			@ type
type_aux:
	.word 0x0			@ type_aux
visual:
	.word 0x0		 	@ visual
xpanstep:
	.hword 0x0			@ xpanstep
ypanstep:
	.hword 0x0			@ ypanstep
ywrapstep:
	.hword 0x0			@ ywrapstep
line_length:
	.word 0x0			@ line length
memory_mapped_io:
	.word 0x0			@ memory mapped I/O
accel_type:
	.word 0x0			@ type of acceleration available
reserved:
	.hword 0x0			@ reserved for future compatibility
	.word 0x0
	.word 0x0
	.word 0x0

/*********************************************************************************
 *                                                                               *
 * Var screeninfo memory map                                                     *
 *                                                                               *
 *********************************************************************************/

vinfo:
xres:
	.word 0x0			@ x visible resolution
yres:
	.word 0x0			@ y visible resolution
xres_virtual:
	.word 0x0			@ x virtual resolution
yres_virtual:
	.word 0x0			@ y virtual resolution
xoffset:
	.word 0x0			@ x offset from virtual to visble
yoffset:
	.word 0x0			@ y offset from virtual to visible
bits_per_pixel:
	.word 0x0			@ bits per pixel
grayscale:
	.word 0x1			@ grayscale 0=color, 1=visible
red:
	.word 0x1,0x1,0x1		@ bitfields in
green:					@ fb mem if
	.word 0x1,0x1,0x1		@ true color
blue:					@ else only length
	.word 0x1,0x1,0x1		@ is significant
transp:
	.word 0x1,0x1,0x1		@ transparency
nonstd:
	.word 0x1			@ !=0 non standard pixel format
activate:
	.word 0x1			@ see FB_ACTIVATE
height:
	.word 0x1			@ height of picture in mm
width:
	.word 0x1			@ width of picture in mm
accel_flags:
	.word 0x1			@ obsolete
pixclock:
	.word 0x1			@ pixel clock in ps
left_margin:
	.word 0x1			@ time from sync to  picture
right_margin:
	.word 0x1			@ time from picture to sync
upper_margin:
	.word 0x1			@ time from sync to picture
lower_margin:
	.word 0x1			@
hsync_len:
	.word 0x1			@ legth of horizontal sync
vsync_len:
	.word 0x1			@ length of vertical sync
sync:
	.word 0x1			@
vmode:
	.word 0x1			@
rotate:
	.word 0x1			@ angle we rotate counter clockwise
colorspace:
	.word 0x1			@
		.word 0x1,0x1,0x1,0x1		@ reserved for future compatibility

/*********************************************************************************
 *                                                                               *
 * Local variables                                                               *
 *                                                                               *
 *********************************************************************************/

fbioget_fscreeninfo:
	.hword 0x4602
fbioget_vscreeninfo:
	.hword 0x4600
.align 1
fbfd:
	.byte 80
smem_start_virtual:
	.word 0x0
