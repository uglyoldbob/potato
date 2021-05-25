_push = $(eval _save$1 := $(MAKEFILE_LIST))

_pop = $(eval MAKEFILE_LIST := $(_save$1))

_INCLUDE = $(call _push,$1)$(eval include $(_ROOT)/$1/Makefile)$(call _pop,$1)

DEPENDS_ON = $(call _INCLUDE,$1)

DEPENDS_ON_NO_BUILD = $(eval _NO_RULES := T)$(call _INCLUDE,$1)$(eval _NO_RULES :=)
