sp :=

sp +=

_walk = $(if $1,$(wildcard /$(subst $(sp),/,$1)/$2) $(call _walk,$(wordlist 2,$(words $1),x $1),$2))

_find = $(firstword $(call _walk,$(strip $(subst /, ,$1)),$2))

_ROOT := $(patsubst %/root.mak,%,$(call _find,$(CURDIR),root.mak))

include $(_ROOT)/root.mak

#add dependencies here

include $(_ROOT)/top.mak

SRCS = \
	main.asm \
	memory.asm \
	file.asm \
	string_funcs.asm \
	source_file.asm \
	toml.asm

BINARY := potato-stage0

BINARY_EXT := $(_EXEEXT)

potato-stage0: ${SRCS:.asm=.o}
	ld -m elf_i386 $^ -o potato-stage0

include $(_ROOT)/bottom.mak