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

;this structure contains two function pointers and a regular pointer
;size takes a pointer (eax) to whatever and returns the number of bytes of data in ebx
;.write takes fd(eax), data (ebx) and writes all of the contents to the file descriptor
struc elf_sh32_printer
.dat: resd 1
.size: resd 1
.write: resd 1
endstruc

struc elf_sym
.name: resd 1
.value: resd 1
.size: resd 1
.info: resb 1
.other: resb 1
.index: resw 1
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
.shtable_funcs: resb ARRAY_SIZE ;an array of elf_sh32_printer objects
.strings: resb ARRAY_SIZE
endstruc

STRING_TABLE_SECTION EQU 1
SYMBOL_TABLE_SECTION EQU 2

section .data
padding1: times 64-elfheader32_size db 0
null_string: db 0
test_string: db 'test string.', 0

section .text

;create an elf32_object
global elf32_object_create
elf32_object_create:
	mov eax, elf32_object_size
	call memory_alloc
	call elf_setup_header
	call elf_setup_elf_sh32_list
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
	push eax
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
	pop eax
	ret

;eax is fd
;ebx is the elf32_object address
global elf_write_strings
elf_write_strings:
	push eax
	push ebx
	push ecx
	lea ebx, [ebx+elf32_object.strings]
	push eax
	mov eax, ebx
	call byte_array_get_data_ptr_and_count
	mov ecx, ebx
	mov ebx, eax
	pop eax
	call file_put_data
	pop ecx
	pop ebx
	pop eax
	ret

;eax is the elf32_object
;this function updates the entries in the header with the data from the elf_sh32_list
;updates the string section
global elf_update_sh
elf_update_sh:
	push edx
	push ecx
	push ebx
	push eax
	sub esp, 12
	;todo, fix stack things
	mov [esp], eax ;store the elf32_object
	mov ebx, eax
	lea eax, [eax+elf32_object.shtable]
	call array_get_count
	mov [ebx+elf32_object.header+elfheader32.shnum], ax
	mov ecx, eax ;store the number of section header entries
	mov eax, [esp]
	lea eax, [eax+elf32_object.strings]
	;eax is the strings array
	call byte_array_get_count
	mov ebx, eax
	;ebx is strings length
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable]
	mov ebx, 1
	call array_get_element
	mov eax, [eax]
	;eax is the elf_sh32 object
	xchg eax, ecx
	mov edx, elf_sh32_size
	mul edx
	xchg eax, ecx
	;ecx is the size
	mov [eax+elf_sh32.size], ebx
	mov [eax+elf_sh32.offset], ecx
	add dword [eax+elf_sh32.offset], 64
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable]
	mov [esp+4], eax ;the section header table array
	call array_get_count
	mov [esp+8], eax
	mov eax, [esp]
	lea eax, [eax+elf32_object.strings]
	call byte_array_get_count
	mov [esp+12], eax ;length of all strings
	
	mov eax, [esp+4]
	mov ebx, 1
	call array_get_element
	mov eax, [eax]
	mov ebx, [esp+12]
	mov [eax+elf_sh32.size], ebx
	
	mov eax, [esp+8]
	mov edx, elf_sh32_size
	
	mul edx
	add eax, 64
	add [esp+12], eax

	mov ecx, 2
	sub dword [esp+8], 2
.check_sh:
	mov eax, [esp+8]
	cmp eax, 0
	je .done
.more_sections:
	mov eax, [esp+4]
	mov ebx, ecx
	call array_get_element
	mov eax, [eax]
	mov edx, eax ;edx is the current section header
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable_funcs]
	call array_get_element
	mov ebx, eax ;ebx is the entry for this sections functions (elf_sh32_printer)
;	call [ebx+elf_sh32_printer.size]
	mov eax, 140
	;mov [edx+elf_sh32.size], eax
	mov eax, [esp+12]
	;mov [edx+elf_sh32.offset], eax
	inc ecx
	dec dword [esp+8]
.done_modding:
	jmp .check_sh
.done:
	add esp, 12
	pop eax
	pop ebx
	pop ecx
	pop edx
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
	push ebx
	push eax
	lea eax, [eax+elf32_object.strings]
	call byte_array_setup
	push ebx
	push ecx
	mov ebx, null_string
	mov ecx, 1
	call byte_array_append_null_terminated
	mov ebx, test_string
	call byte_array_append_null_terminated
	pop ecx
	pop ebx

	pop eax
	push eax
	mov ebx, eax
	lea eax, [ebx+elf32_object.shtable_funcs]
	call array_setup

	mov eax, ebx
	mov word [eax+elf32_object.header+elfheader32.shstrindx], 1
	lea eax, [eax+elf32_object.shtable]
	push eax
	call array_setup

	;section 0 is special
	mov ebx, eax
	call elf_create_elf_sh32
	xchg eax, ebx
	call array_append_item
	mov dword [ebx+elf_sh32.name], 0
	mov dword [ebx+elf_sh32.type], 0
	mov dword [ebx+elf_sh32.flags], 0
	mov dword [ebx+elf_sh32.addr], 0
	mov dword [ebx+elf_sh32.offset], 0
	mov dword [ebx+elf_sh32.size], 0
	mov dword [ebx+elf_sh32.link], 0
	mov dword [ebx+elf_sh32.info], 0
	mov dword [ebx+elf_sh32.addralign], 0
	mov dword [ebx+elf_sh32.entsize], 0
	pop eax

	;section 1 is the string table
	push eax
	mov ebx, eax
	call elf_create_elf_sh32
	xchg eax, ebx
	call array_append_item
	mov dword [ebx+elf_sh32.name], 0
	mov dword [ebx+elf_sh32.type], 3
	mov dword [ebx+elf_sh32.flags], 0
	mov dword [ebx+elf_sh32.addr], 0
	mov dword [ebx+elf_sh32.offset], 144
	mov dword [ebx+elf_sh32.size], 6
	mov dword [ebx+elf_sh32.link], 0
	mov dword [ebx+elf_sh32.info], 0
	mov dword [ebx+elf_sh32.addralign], 0
	mov dword [ebx+elf_sh32.entsize], 0
	pop eax

	;section 2 is the symbol table
	push eax
	mov ebx, eax
	call elf_create_elf_sh32
	xchg eax, ebx
	call array_append_item
	mov dword [ebx+elf_sh32.name], 1
	mov dword [ebx+elf_sh32.type], 2
	mov dword [ebx+elf_sh32.flags], 0
	mov dword [ebx+elf_sh32.addr], 0
	mov dword [ebx+elf_sh32.offset], 6 ;will be filled out later
	mov dword [ebx+elf_sh32.size], 48
	mov dword [ebx+elf_sh32.link], 2
	mov dword [ebx+elf_sh32.info], 0
	mov dword [ebx+elf_sh32.addralign], 4
	mov dword [ebx+elf_sh32.entsize], elf_sym_size
	pop eax


	pop eax
	pop ebx
	ret

;eax is the elf32_object
;ebx is the section name string, null terminated
global elf_create_section
elf_create_section:
	push ecx
	push ebx
	push eax
	sub esp, 16
	mov [esp], eax
	mov [esp+4], ebx
	call elf_create_elf_sh32
	mov [esp+8], eax
	mov eax, [esp]
	lea eax, [eax+elf32_object.strings]
	call byte_array_get_count
	mov [esp+12], eax
	mov eax, [esp]
	lea eax, [eax+elf32_object.strings]
	mov ebx, [esp+4]
	mov ecx, 1
	call byte_array_append_null_terminated
	mov ecx, [esp+12]
	mov eax, [esp+8]
	mov [eax+elf_sh32.name], ecx
	;setup section as code section. 
	;TODO move to a function
	mov ebx, 1
	mov [eax+elf_sh32.type], ebx
	mov ebx, 1
	mov [eax+elf_sh32.link], ebx
	mov ebx, 19
	mov [eax+elf_sh32.info], ebx
	mov ebx, 6
	mov [eax+elf_sh32.flags], ebx
	mov ebx, 0
	mov [eax+elf_sh32.addr], ebx
	mov ebx, 0
	mov [eax+elf_sh32.addralign], ebx

	mov ebx, [esp+8]
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable]
	call array_append_item
	call array_get_count
	add esp, 16
	pop eax
	pop ebx
	pop ecx
	ret
