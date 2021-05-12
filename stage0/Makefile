all: potato-stage0

clean: ${OBJS}
	rm -f ${OBJS}
	rm -f *.d
	rm -f potato-stage0

%.d: %.asm
	nasm -MT "$(basename $<).o $(basename $<).d" -M $< > $@

sources = \
	main.asm \
	memory.asm
include $(sources:.asm=.d)

%.o: %.asm
	nasm -f elf32 $<

potato-stage0: ${sources:.asm=.o}
	ld -m elf_i386 $^ -o potato-stage0

