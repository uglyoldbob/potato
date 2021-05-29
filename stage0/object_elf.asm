%include 'file_inc.asm'

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

section .text

global elf_header_size
elf_header_size:
	mov eax, elfheader32_size
	ret

global elf_setup_header
elf_setup_header:
	mov dword [eax+elfheader32.ident], 07f454c46h

	push ebx
	push ecx
	mov ebx, eax
	mov ecx, elfheader32_size
	call file_put_data
	pop ecx
	pop ebx

	ret

global elf_write_header
elf_write_header:
	ret
