$(_MODULE_NAME)_OBJS := $(addsuffix $(_OBJEXT),$(addprefix $($(_MODULE_NAME)_OUTPUT)/,$(basename $(SRCS)))) $(DEPS)

$(_MODULE_NAME)_BINARY := $($(_MODULE_NAME)_OUTPUT)/$(BINARY)$(BINARY_EXT)

ifneq ($(_NO_RULES),T)

ifneq ($($(_MODULE_NAME)_DEFINED),T)

all: $($(_MODULE_NAME)_BINARY)

.PHONY: $(_MODULE_NAME)

$(_MODULE_NAME): $($(_MODULE_NAME)_BINARY)

_IGNORE := $(shell mkdir -p $($(_MODULE_NAME)_OUTPUT))

_CLEAN := clean-$(_MODULE_NAME)

.PHONY: clean $(_CLEAN)

clean: $(_CLEAN)

$(_CLEAN):
	rm -rf $($(patsubst clean-%,%,$@)_OUTPUT)

include $(wildcard $($(_MODULE_NAME)_OUTPUT)/%.d)

$($(_MODULE_NAME)_OUTPUT)/%.o: $(_MODULE_PATH)/%.asm
	nasm -i $(_MODULE_PATH) -f elf32 $< -o $@

$($(_MODULE_NAME)_OUTPUT)/%.d: $(_MODULE_PATH)/%.asm
	nasm -MT "$(basename $<).o $<" -M $< > $@

$($(_MODULE_NAME)_OUTPUT)/$(BINARY)$(_EXEEXT): $($(_MODULE_NAME)_OBJS)
	ld -m elf_i386 $^ -o'$@'

$(_MODULE_NAME)_DEFINED := T

endif

endif
