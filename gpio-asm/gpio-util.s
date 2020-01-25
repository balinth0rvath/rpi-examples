	.global gpio_open
	.global gpio_close
	.global gpio_set

gpio_open:
	
	STMFD SP!, {R1-R5,LR}
	LDR R0, =dev_mem
	MOV R1, #o_rdwr
	
	BL open

	BCS error

	LDR R3, =fd
	STR R0, [R3]		@ store file desctiptor into mem referenced by fd

	MOV R0, #0         	@ memory starts at 0             
	MOV R1, #4096		@ map one page R1
	MOV R2, #prot_rdwr	@ data can be read and written R2
	MOV R3, #map_shared	@ shared map into R3    

	LDR R9, =fd		@ get fd address
	LDR R4, [R9]		@ load fd into R4
	STR R4, [SP]		@ store fd into stack
	LDR R4, =gpiobase 	@ offset is 0x3F200000
	LDR R5, [R4]		@ set it to R5
	STR R5, [SP,#4]		@ store it after fd
	BL mmap

	LDR R1,=gpiobase_virtual
	STR R0, [R1]		@ store gpio virt address into gpio_base_virtual

	MOV R0, #0		@ zero in R0 means succesfull mapping
	B exit
error:
	MOV R0, #1		@ mapping failed
exit:
	LDMFD SP!, {R1-R5, PC}

gpio_close:
	STMFD SP!, {R0, LR}
	
	LDR R0, =dev_mem
	BL close

	LDMFD SP!, {R0, PC}

/*********************************************************************************
 *                                                                               *
 * Sets a gpio pin to output and sets or clears it                               *
 *                                                                               *
 * R9:  The pin number     	         	                                 *
 * R10: 1 - set 0 - clear                                                        *
 *                                                                               *
 *********************************************************************************/

gpio_set:
	STMFD SP!, {R0-R8,LR}

	STMFD SP!, {R9}

	LDR R0, =gpiobase_virtual
	LDR R1, [R0]		@ load virtual address into R1

	MOV R4, #10
	MOV R5, #0
loop:				@ this loop determines the gpio sel register attached to
				@ pin number set in R9
	CMP R9, R4		@ exit if gpio number(R9) is lesser than loop variable(R4)
	BLT loop_exit
	ADD R4, #10		@ 0..9 10..19 20..29 30..39 40..49 50..53 
	ADD R5, #4		@    0      4      8     12     16     20
	B loop
loop_exit:

	SUB R6, R4, #10		@ R6 corresponds to the base. For example if pin is 16
				@ then R4 is 20 when the loop ends. so R4-10 is the base
				@ If you substract this base from the pin, you got
				@ the pins number in the sel register, In the prev
				@ example it is 6. This vaule * 3 is the shift to be 
	MOV R8, #3     		@ applied.
	SUB R9, R6		@ e.g. R9=16 R6=10 R9=R9 - R6 = 6. R7 = 18
	MUL R7, R9, R8		@ i will not remember what the fuck happens here
	MOV R3, #1
	LSL R3, R7 
	
	ADD R1, R5		@ virtual+R5 has to be modified
	LDR R2, [R1]		@ load gpiosel1 into R2             
	ORR R2, R2, R3 		@ set 001 to pin 16
	STR R2, [R1]		@ store R2 at address R1 makes gpio#0x10 output

	LDR R0, =gpiobase_virtual
	LDR R1, [R0]                                    
	ADD R1, #28		@ base+28 is the set register for pins under 31
				@ beyond that is tbd
	CMP R10, #0
	BNE positive
	ADD R1, #12		@ if R10 is set to clear then base+40 is the reg
positive:
	LDR R2, [R1]		@ load gpiopinset0 into r2
	MOV R10, #1		@ R10 is not set/clear reg anymore. it is used
				@ to calculate the offset now 
	LDMFD SP!, {R9}
	LSL R10, R9  
	ORR R2, R2, R10     	@ set led state     
	STR R2, [R1]

	LDMFD SP!, {R0-R8,PC} 

.data

gpiobase:	
	.word 0x3F200000
gpiobase_virtual:
	.word 0x0
dev_mem:
	.asciz "/dev/mem"
.align	3

fd:
	.word 0x0  
virt_mem:
	.word 0x0

.equ   	o_rdwr, 2
.equ	prot_rdwr, 3
.equ	map_shared, 1
