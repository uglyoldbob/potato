%include 'memory_inc.asm'
%include 'string_funcs_inc.asm'
%include 'options_file.asm'
%include 'source_file_inc.asm'
%include 'object_elf_inc.asm'

section .data
msg1 db 'Potato compiler stage0', 0ah, 0
msg_usage db 'Usage: <stage0> <filename> <output>', 0ah
	  db '<filename> - The filename to compile.', 0ah
	  db '<output> - The filename to write output to.', 0ah
	  db 0
arg_index db 0 ;the index number of the argument being parsed
number_arguments dd 0

section .bss
source_struct: resb OPTIONS_SIZE
filename: resd 1
objectname: resd 1
objecthandle: resd 1

elf_object: resd 1



section .text
global _start
_start:

	mov eax, msg1
	call sprintLF

;print all the arguments
	pop ecx
	mov [number_arguments], ecx
.nextArg:
	cmp ecx, 0
	jz .doneWithArgs
	pop eax
	cmp byte [arg_index], 1
	jne .not_filename
	mov [filename], eax
	call sprintLF
.not_filename:

	cmp byte [arg_index], 2
	jne .not_objectname
	mov [objectname], eax
	call sprintLF
.not_objectname:

	dec ecx
	inc byte [arg_index]
	jmp .nextArg
.doneWithArgs:

	call setup_memory_alloc
	mov eax, 123
	call memory_alloc
	cmp dword [number_arguments], 3
	je .have_some_arguments
	mov eax, msg_usage
	call sprintLF
	jmp .done
.have_some_arguments:
	
	mov eax, [filename]
	mov ebx, source_struct
	call process_source_file

.write_output:
	mov eax, [objectname]
	call file_open_write
	mov [objecthandle], eax

	call elf_header_size
	call memory_alloc
	mov [elf_object], eax
	call elf_setup_header

	call elf_write_header

	mov eax, [objecthandle]
	call file_sync

	mov eax, [objecthandle]
	call file_close


.done:
	; return with status of eax
	mov ebx, 0
	mov eax, 1
	int 80h
