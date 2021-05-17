%include 'string_funcs.asm'

OPTIONS_SIZE equ 64

section .data
process_options_msg db 'Loading options file:',0
process_options_problem db 'There was a problem loading the options file.',0

section .bss
options_file_buffer: resd 1

section .text

open_file:
	mov ecx, 0
	mov ebx, eax
	mov eax, 5
	int 80h
	ret

map_file:
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
	mov ebx, eax
	call get_filesize
	mov ecx, eax
	mov edi, ebx
	mov ebp, 0
	mov eax, 192
	mov ebx, 0
	mov edx, 1
	mov esi, 1
	;addr, length, prot, flags, fd, offset
	;
	int 80h
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	ret

unmap_file:
	mov ecx, ebx
	mov ebx, eax
	mov eax, 91
	int 80h
	ret

get_filesize:
	push ebx
	push ecx
	mov ebx, eax
	mov eax, 6Ch
	mov ecx, esp
	sub ecx, 88
	int 80h
	mov eax, [esp-68]
.fs_check:
	pop ecx
	pop ebx
	ret

close_file:
	mov ebx, eax
	mov eax, 6
	int 80h
	ret

process_options_file_byte:
	ret

process_options_file:
	push eax
	mov eax, process_options_msg
	call sprintLF

	mov eax, [esp]
	call sprintLF

	mov eax, [esp]
	call open_file
	cmp eax, 0
	jl .file_problem
	jmp .file_processing
.file_problem:
	mov eax, process_options_problem
	call sprintLF
	jmp .done
.file_processing:
	push eax
	mov eax, [esp]
	call map_file
	mov [options_file_buffer], eax
	
	mov eax, [esp]
	call get_filesize
	mov ecx, eax
.file_data_loop:
	push ecx

	;todo: get byte from the buffer
	call process_options_file_byte	
	pop ecx
	loop .file_data_loop
	mov eax, [esp]
	call get_filesize
	mov ebx, eax
	mov eax, [options_file_buffer]
	call unmap_file
	call close_file
	pop eax
.done:
	pop eax
	ret
