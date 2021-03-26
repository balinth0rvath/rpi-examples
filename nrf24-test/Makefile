CFLAGS=-I.
DEPS = nrf24-test.h
OBJ = nrf24-test.o 

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

nrf24-test: $(OBJ)
	$(CC) -o $@ $^ $(CFLAGS)

clean:
	rm nrf24-test
	rm *.o
