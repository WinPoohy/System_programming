# Makefile
CC = gcc
ASM = fasm
CFLAGS = -Wall -Wextra -std=c99

TARGET = program
SOURCES_C = main.c
SOURCES_ASM = array.asm
OBJECTS = main.o array.o

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $^ -o $@

main.o: main.c
	$(CC) $(CFLAGS) -c $< -o $@

array.o: array.asm
	$(ASM) $<

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: all clean
