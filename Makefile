SUBDIRS = stage0

include $(addsuffix /Makefile,$(SUBDIRS))
