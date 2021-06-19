%include 'array_inc.asm'
%include 'file_inc.asm'
%include 'memory_inc.asm'

;to examine the sections directly
;hd build/stage1/main.o -s 4 -e '5/4 " %08.8X" "\n"'
;section headers start at offset 0x40

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
.sym_strings: resb ARRAY_SIZE
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
;ebx is the address of the elf_sh32_printer object
global elf_write_strings
elf_write_strings:
	push eax
	push ebx
	push ecx
	push eax
	mov ebx, [ebx+elf_sh32_printer.dat]
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

;eax is fd
;ebx is the elf32_object address
global elf_write_the_rest
elf_write_the_rest:
	push eax
	push ebx
	push ecx
	sub esp, 16
	mov [esp], ebx
	mov [esp+16], eax
	lea eax, [ebx+elf32_object.shtable]
	mov [esp+4], eax ;the section header table array
	call array_get_count
	mov [esp+8], eax

	mov ecx, 1
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
.examine:
	call array_get_element
	mov ebx, [eax] ;ebx is the entry for this sections functions (elf_sh32_printer)
	cmp dword [ebx+elf_sh32_printer.write], 0
	jz .no_write_func
	mov eax, [esp+16]
	call [ebx+elf_sh32_printer.write]
.no_write_func:
	inc ecx
	dec dword [esp+8]
	jmp .check_sh
.done:
	add esp, 16
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
	sub esp, 20
;esp = the elf32_object
;esp+4 = elf32_object.shtable
;esp+8 = number of sections
;esp+12 = length of all strings?
;esp+16 = current calculated file offset
;esp+20 = counter

	mov [esp], eax ;store the elf32_object
	mov ebx, eax
	lea eax, [eax+elf32_object.shtable]
	call array_get_count
	mov [ebx+elf32_object.header+elfheader32.shnum], ax
	mov [esp+8], eax
	mov ebx, elf_sh32_size
	imul eax, ebx
	mov dword [esp+16], eax
	add dword [esp+16], 64

;start checking sections
;section 0 is special
	mov dword [esp+20], 1
.check_sh:
	mov eax, [esp+8]
	cmp eax, [esp+20]
	je .done
.more_sections:
;todo: check to see if this is a string section, update main header if it is
;todo: check to see if this is a symbol table, update main header if it is
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable]
	mov ebx, [esp+20]
	call array_get_element
	mov eax, [eax]
	mov edx, eax ;edx is the current section header

;check for string table
	cmp dword [edx+elf_sh32.type], 3
	jne .not_strings
	mov eax, [esp]
	cmp word [eax+elf32_object.header+elfheader32.shstrindx], 0
	jnz .not_strings
	;the first string table is assumed to be for section names
	mov ebx, [esp+20]
	mov [eax+elf32_object.header+elfheader32.shstrindx], bx
.not_strings:

	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable_funcs]
	mov ebx, [esp+20]
.examine:
	call array_get_element
	mov ebx, [eax] ;ebx is the entry for this sections functions (elf_sh32_printer)
	cmp dword [ebx+elf_sh32_printer.size], 0
	jz .no_size_func
	call [ebx+elf_sh32_printer.size]
	mov [edx+elf_sh32.size], eax
	jmp .after_size
.no_size_func:
	mov eax, [edx+elf_sh32.size]	;assume size is prepopulated
.after_size:
	mov ecx, [esp+16]
	mov [edx+elf_sh32.offset], ecx
	add [esp+16], eax	;add section size to current offset
	inc dword [esp+20]
	jmp .check_sh
.done:
	add esp, 20
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

elf_individual_symbol_write:
	xchg eax, ebx
	call file_put_data
	ret

;eax is fd
;ebx is the address of the elf_sh32_printer object
elf_symbols_write:
	push ebx
	push ecx
	mov ebx, [ebx+elf_sh32_printer.dat]
	xchg eax, ebx
	mov ecx, elf_sym_size
	push elf_individual_symbol_write
	call array_iterate
	add esp, 4
	pop ecx
	pop ebx
	ret

elf_symbols_size:
	push ebx
	mov eax, [eax]
	mov eax, [eax+elf_sh32_printer.dat]
	call byte_array_get_count
	mov ebx, elf_sym_size
	imul eax, ebx
	pop ebx
	ret

elf_string_size:
	mov eax, [eax]
	mov eax, [eax+elf_sh32_printer.dat]
	call byte_array_get_count
	ret

global elf_setup_elf_sh32_list
elf_setup_elf_sh32_list:
	push ecx
	push ebx
	push eax
	sub esp, 12
	mov [esp], eax
	;setup string table
	lea eax, [eax+elf32_object.strings]
	call byte_array_setup
	mov ebx, null_string
	mov ecx, 1
	call byte_array_append_null_terminated
	mov ebx, test_string
	call byte_array_append_null_terminated
	
	;setup symbol string table
	mov eax, [esp]
	lea eax, [eax+elf32_object.sym_strings]
	call byte_array_setup
	mov ebx, null_string
	mov ecx, 1
	call byte_array_append_null_terminated

	mov eax, [esp]
	mov ebx, eax
	lea eax, [ebx+elf32_object.shtable_funcs]
	call array_setup

	mov eax, ebx
	mov word [eax+elf32_object.header+elfheader32.shstrindx], 0
	lea eax, [eax+elf32_object.shtable]
	mov [esp+4], eax
	call array_setup
	mov [esp+8], eax

	;section 0 is special
	call elf_create_funcs_element
	mov ecx, eax
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable_funcs]
	mov ebx, ecx
	call array_append_item

	mov eax, [esp+4]
	call elf_create_elf_sh32
	mov ebx, eax
	mov eax, [esp+4]
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

	;section 1 is the string table
	call elf_create_funcs_element
	mov ecx, eax
	mov ebx, [esp]
	lea ebx, [ebx+elf32_object.strings]
	mov [ecx+elf_sh32_printer.dat], ebx
	mov dword [ecx+elf_sh32_printer.size], elf_string_size
	mov dword [ecx+elf_sh32_printer.write], elf_write_strings
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable_funcs]
	mov ebx, ecx
	call array_append_item

	mov eax, [esp+4]
	call elf_create_elf_sh32
	mov ebx, eax
	mov eax, [esp+4]
	call array_append_item
	mov dword [ebx+elf_sh32.name], 0
	mov dword [ebx+elf_sh32.type], 3
	mov dword [ebx+elf_sh32.flags], 0
	mov dword [ebx+elf_sh32.addr], 0
	mov dword [ebx+elf_sh32.offset], 0
	mov dword [ebx+elf_sh32.size], 0
	mov dword [ebx+elf_sh32.link], 0
	mov dword [ebx+elf_sh32.info], 0
	mov dword [ebx+elf_sh32.addralign], 0
	mov dword [ebx+elf_sh32.entsize], 0

	;section 2 is the symbol table
	call elf_create_funcs_element
	mov ecx, eax
	call array_create
	mov dword [ecx+elf_sh32_printer.dat], eax ;todo put in a real address here
	mov dword [ecx+elf_sh32_printer.write], elf_symbols_write
	mov dword [ecx+elf_sh32_printer.size], elf_symbols_size
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable_funcs]
	mov ebx, ecx
	call array_append_item

	mov eax, [esp+4]
	call elf_create_elf_sh32
	mov ebx, eax
	mov eax, [esp+4]
	call array_append_item
	mov dword [ebx+elf_sh32.name], 1
	mov dword [ebx+elf_sh32.type], 2
	mov dword [ebx+elf_sh32.flags], 0
	mov dword [ebx+elf_sh32.addr], 0
	mov dword [ebx+elf_sh32.offset], 0
	mov dword [ebx+elf_sh32.size], 0
	mov dword [ebx+elf_sh32.link], 1
	mov dword [ebx+elf_sh32.info], 2
	mov dword [ebx+elf_sh32.addralign], 4
	mov dword [ebx+elf_sh32.entsize], elf_sym_size

	add esp, 12
	pop eax
	pop ebx
	pop ecx
	ret

global elf_configure_code_section
elf_configure_code_section:
	push ebx
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
	mov ebx, 16
	mov [eax+elf_sh32.addralign], ebx
	pop ebx
	ret

;eax is the elf32_object
;ebx is the section name string, null terminated
;eax is returned as the new section header (elf_sh32 object)
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

	call elf_create_funcs_element
	mov ecx, eax
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable_funcs]
	mov ebx, ecx
	call array_append_item

	mov ebx, [esp+8]
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable]
	call array_append_item
	mov eax, [esp+8]
	add esp, 16
	add esp, 4
	pop ebx
	pop ecx
	ret

;eax is the elf32_object
;ebx is the symbol name, null terminated, null for no name
;return is the address of the elf_sym
global elf_register_symbol
elf_register_symbol:
	push ecx
	push ebx
	sub esp, 12
	mov [esp], eax
	mov [esp+8], ebx
;create the symbol object
	mov eax, elf_sym_size
	call memory_alloc
	mov [esp+4], eax
;append it to the symbol table list
	mov eax, [esp]
	lea eax, [eax+elf32_object.shtable_funcs]
	mov ebx, SYMBOL_TABLE_SECTION
	call array_get_element
	mov eax, [eax]
	mov eax, [eax+elf_sh32_printer.dat]
	mov ebx, [esp+4]
	call array_append_item
;check for a string name
	cmp dword [esp+8], 0
	je .no_string
	mov eax, [esp]

	mov eax, [esp]
	lea eax, [eax+elf32_object.strings]
	call byte_array_get_count
	mov ebx, eax
	mov eax, [esp+4]
	mov [eax+elf_sym.name], ebx

	mov eax, [esp]
	lea eax, [eax+elf32_object.strings]
	mov ebx, [esp+8]
	mov ecx, 1
	call byte_array_append_null_terminated

	jmp .done_string
.no_string:
	mov ebx, 0
	mov eax, [esp+4]
	mov [eax+elf_sym.name], ebx
.done_string:
	mov ebx, 0
	mov eax, [esp+4]
	mov [eax+elf_sym.value], ebx
	mov [eax+elf_sym.size], ebx
	mov [eax+elf_sym.info], bl
	mov [eax+elf_sym.other], bl
	mov [eax+elf_sym.index], bx
	add esp, 12
	pop ebx
	pop ecx
	ret

global elf_symbol_set_value
elf_symbol_set_value:
	mov [eax+elf_sym.value], ebx
	ret

global elf_symbol_set_size
elf_symbol_set_size:
	mov [eax+elf_sym.size], ebx
	ret

global elf_symbol_set_info
elf_symbol_set_info:
	mov [eax+elf_sym.info], bl
	ret

global elf_symbol_set_index
elf_symbol_set_index:
	mov [eax+elf_sym.index], bx
	ret



elf_create_funcs_element:
	mov eax, elf_sh32_printer_size
	call memory_alloc
	mov dword [eax+elf_sh32_printer.dat], 0
	mov dword [eax+elf_sh32_printer.size], 0
	mov dword [eax+elf_sh32_printer.write], 0
	ret
