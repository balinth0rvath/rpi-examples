
/*******************************************************************************
 *                                                                             *
 * Framebuffer practice. main function opens   				       * 
 * /dev/fb0 for read and write, then stores framebuffer fixinfo and varinfo    *
 * in local memory. Creates virtual memory mapping.                            * 
 *                                                                             *
 *******************************************************************************/

	.global	main
	.func main
main:
	STMFD SP!, {LR}

	BL init_graphics

	CMP R0, #1
	BEQ exit

	MOV R0, #0


	LDR R3, =red
	LDR R2, [R3]

	MOV R0, #50			@ 
	MOV R1, #30			@
	MOV R3, #500			@
	MOV R4, #280 			@
	
	BL fill_box
	
	BL close_graphics
exit:
	LDMFD SP!, {PC}


red:   
	.word 0x0000FF00
green:
	.word 0x00FF00F0
blue:
	.word 0x0000FFFF
zero:
	.word 0x0
