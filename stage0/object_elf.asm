struc elfheader32
.ident: resb 4
.type: resw 1
.machine: resw 1
.version: resd 1
.entry: resd 1
.phoff: resd 1
.shoff: resd 1
.flags: resd 1
.ehsize: resw 1
.phentsize: resw 1
.phnum: resw 1
.shentsize: resw 1
.shnum: resw 1
.shstrindx: resw 1
endstruc

global elf_write_header
elf_write_header:
	ret
