all: potato-stage0

clean: ${OBJS}
	rm ${OBJS}

%.o: %.asm
	nasm -f elf32 $<

OBJS = main.o

potato-stage0: ${OBJS}
	ld -m elf_i386 ${OBJS} -o potato-stage0
