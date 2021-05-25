all: potato-stage0

clean: ${OBJS}
	rm -f ${OBJS}
	rm -f *.d
	rm -f potato-stage0

sources = \
	main.asm \
	memory.asm \
	file.asm \
	string_funcs.asm \
	source_file.asm \
	toml.asm
include $(sources:.asm=.d)

define ASM_D_RULE
$(1) : $(3)
	nasm -MT "$(2) $(1)" -M $(3) > $(basename $1).d
endef

$(foreach s, $(sources), $(eval $(call ASM_D_RULE, $(basename $s).d, $(basename $s).o, $(s))))

%.o: %.asm
	nasm -f elf32 $<

potato-stage0: ${sources:.asm=.o}
	ld -m elf_i386 $^ -o potato-stage0

