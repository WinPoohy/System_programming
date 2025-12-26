# Makefile
CC = gcc
ASM = fasm
CFLAGS = -no-pie -g
TARGET = program

all: $(TARGET)

$(TARGET): main.c array.o
	$(CC) $(CFLAGS) main.c array.o -o $(TARGET)

array.o: array.asm
	$(ASM) array.asm

clean:
	rm -f *.o $(TARGET)
