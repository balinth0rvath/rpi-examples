CC=gcc
CCFLAGS= -g -c
LDFLAGS= -g -o

SOURCES = $(wildcard *.s)
OBJECTS = $(SOURCES:.s=.o)
TARGET =gpio

$(TARGET): $(OBJECTS)                 
		$(CC) $(CCFLAGS) $(SOURCES)
		${CC} $(LDFLAGS) $@ $^    

clean:
	rm *.o $(TARGET)


