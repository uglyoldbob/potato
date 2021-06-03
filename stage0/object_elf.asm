%include 'array_inc.asm'
%include 'file_inc.asm'
%include 'memory_inc.asm'

struc elfheader32
.ident: resb 4
.ident_class: resb 1
.ident_data: resb 1
.ident_version: resb 1
.ident_osabi: resb 1
.ident_osabiver: resb 1
.ident_reserved: resb 7
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

;section header
;the elf section header table is an array of this struc
struc elf_sh32
.name: resd 1
.type: resd 1
.flags: resd 1
.addr: resd 1
.offset: resd 1
.size: resd 1
.link: resd 1
.info: resd 1
.addralign: resd 1
.entsize: resd 1
endstruc

struc elf_sym
.name: resd 1
.value: resd 1
.size: resd 1
.info: resd 1
.other: resd 1
.index: resd 1
endstruc

struc elf_rel
.offset: resd 1
.info: resd 1
endstruc

struc elf_rela
.offset: resd 1
.info: resd 1
.addend: resd 1
endstruc

struc elf32_object
.header: resb elfheader32_size
.shtable: resb ARRAY_SIZE
endstruc

section .data
padding1: times 64-elfheader32_size db 0

section .text

;create an elf32_object
global elf32_object_create
elf32_object_create:
	mov eax, elf32_object_size
	call memory_alloc
	ret

global elf32_object_destroy
elf32_object_destroy:
	ret

global elf_header_size
elf_header_size:
	mov eax, elfheader32_size
	ret

;eax is the elf32_object address
global elf_setup_header
elf_setup_header:
	lea eax, [eax+elf32_object.header]
	mov dword [eax+elfheader32.ident], 0464c457fh
	mov byte [eax+elfheader32.ident_class], 1
	mov byte [eax+elfheader32.ident_data], 1
	mov byte [eax+elfheader32.ident_version], 1
	mov byte [eax+elfheader32.ident_osabi], 0
	mov byte [eax+elfheader32.ident_osabiver], 0
	push eax
	push edi
	push ecx
	lea edi, [eax+elfheader32.ident_reserved]
	mov eax, 0
	mov ecx, 7
	rep stosb
	pop ecx
	pop edi
	pop eax
	mov word [eax+elfheader32.type], 1
	mov word [eax+elfheader32.machine], 3
	mov dword [eax+elfheader32.version], 1
	mov dword [eax+elfheader32.entry], 0
	mov dword [eax+elfheader32.phoff], 0
	mov dword [eax+elfheader32.shoff], 64
	mov dword [eax+elfheader32.flags], 0
	mov word [eax+elfheader32.ehsize], elfheader32_size
	mov word [eax+elfheader32.phentsize], 0
	mov word [eax+elfheader32.phnum], 0
	mov word [eax+elfheader32.shentsize], elf_sh32_size
	mov word [eax+elfheader32.shnum], 0
	mov word [eax+elfheader32.shstrindx], 0
	ret

;eax is fd
;ebx is the elf32_object address
global elf_write_header
elf_write_header:
	push eax
	push ebx
	push ecx
	lea ebx, [ebx+elf32_object.header]
	mov ecx, elfheader32_size
	call file_put_data
	pop ecx
	pop ebx
	pop eax
	push ecx
	push ebx
	push eax
	mov ebx, padding1
	mov ecx, 64-elfheader32_size
	call file_put_data
	pop eax
	pop ebx
	pop ecx
	ret

elf_test:
	xchg eax, ebx
	call file_put_data
	ret

;eax is fd
;ebx is the elf32_object address
global elf_write_shtable
elf_write_shtable:
	push ecx
	push ebx
	xchg eax, ebx
	lea eax, [eax+elf32_object.shtable]
	mov ecx, elf_sh32_size
	push dword elf_test
	call array_iterate
	pop ebx
	pop ebx
	pop ecx
	ret

global elf_create_elf_sh32
elf_create_elf_sh32:
	mov eax, elf_sh32_size
	call memory_alloc
	push eax
	push edi
	push ecx
	mov edi, eax
	mov eax, 0
	mov ecx, elf_sh32_size
	rep stosb
	pop ecx
	pop edi
	pop eax
	ret

global elf_setup_elf_sh32_list
elf_setup_elf_sh32_list:
	lea eax, [eax+elf32_object.shtable]
	call array_setup
	mov ebx, eax
	call elf_create_elf_sh32
	xchg eax, ebx
	call array_append_item
	ret
