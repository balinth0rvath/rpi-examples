
CC=gcc

ifndef TARGET
frame: framebuffer_main.s framebuffer_util.s
		${CC} -g -c framebuffer_main.s 
		${CC} -g -c framebuffer_util.s
		${CC} -g -o frame framebuffer_main.o framebuffer_util.o 
endif


ifeq ($(TARGET), fractal)
fractal: fractal.s framebuffer_util.s
		${CC} -g -c fractal.s 
		${CC} -g -c framebuffer_util.s
		${CC} -g -o fractal fractal.o framebuffer_util.o 
endif

clean:
	rm *.o

