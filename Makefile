
all: build/stage0 build/stage1 build/stage0/potato_stage0 build/stage1/potato_stage1

clean:
	rm -rf build

build/stage0:
	mkdir -p build/stage0

build/stage1:
	mkdir -p build/stage1

stage0_SRCS = \
	array.asm \
	main.asm \
	memory.asm \
	file.asm \
	object_elf.asm \
	string_funcs.asm \
	source_file.asm \
	toml.asm

build/stage0/%.o: stage0/%.asm
	nasm -w+all -i stage0 -f elf32 $< -o $@

build/stage0/%.d: stage0/%.asm
	nasm -MT "$(basename $<).o $<" -M $< > $@

stage0_OBJS := $(addsuffix .o,$(addprefix build/stage0/,$(basename $(stage0_SRCS))))

build/stage0/potato_stage0: $(stage0_OBJS)
	ld -m elf_i386 $^ -o'$@'

stage1_SRCS = \
	main.p0

build/stage1/%.o: stage1/%.p0
	build/stage0/potato_stage0 $< $@

stage1_OBJS = $(addsuffix .o,$(addprefix build/stage1/,$(basename $(stage1_SRCS))))

$(stage1_OBJS): build/stage0/potato_stage0

build/stage1/potato_stage1: $(stage1_OBJS)
	ld -m elf_i386 $^ -o'$@'
