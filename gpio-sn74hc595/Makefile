CC=gcc
#CFLAGS= -O0 -g
shift: shift.o
	${CC} ${CFLAGS} -o shift shift.o 
mem: memexp.o
	${CC} -o memexp memexp.o 
clean:
	rm *.o shift 
	rm memexp
