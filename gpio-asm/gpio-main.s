	.global main
	.func main
main:
	STMFD SP!, {LR}
	
	BL gpio_open
	CMP R0, #0
	BNE exit    
	
	MOV R9, #16
	MOV R10, #1

	BL gpio_set 

	MOV R9, #20
	MOV R10, #1
	
	BL gpio_set

	MOV R9, #21
	MOV R10, #1
	
	BL gpio_set

	BL gpio_close
normal:
	MOV R0, #0
exit:
	LDMFD SP!, {PC}

