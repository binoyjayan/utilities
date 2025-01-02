# The compiler
CC = gcc
CFLAGS = -Wall -Wextra -O2

TARGET = main
LIBRARY = libatomic_stack.a

all: $(TARGET)

$(TARGET): main.o $(LIBRARY)
	$(CC) $(CFLAGS) -o $(TARGET) main.o -L. -latomic_stack

main.o: main.c atomic_stack.h
	$(CC) $(CFLAGS) -c main.c

$(LIBRARY): atomic_stack.o
	ar rcs $(LIBRARY) atomic_stack.o

atomic_stack.o: atomic_stack.c atomic_stack.h
	$(CC) $(CFLAGS) -c atomic_stack.c

clean:
	$(RM) $(TARGET) *.o *.a