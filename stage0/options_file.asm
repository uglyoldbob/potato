%include 'string_funcs.asm'

OPTIONS_SIZE equ 64

section .data
process_options_msg db 'Loading options file:',0
process_options_problem db 'There was a problem loading the options file.',0
section .text

open_file:
	mov ecx, 0
	mov ebx, eax
	mov eax, 5
	int 80h
	ret

get_filesize:
	mov ebx, eax
	mov eax, 6Ch
	mov ecx, esp
	sub ecx, 88
	int 80h
	mov eax, [esp-68]
.fs_check:
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
	call get_filesize
	mov ecx, eax
.file_data_loop:
	push ecx

	;read a byte from the file
	;TODO: read more than one byte at a time, still parse one byte at a time.
	mov edx, 1
	mov ebx, [esp+4]
	mov ecx, esp
	sub ecx, 1
	mov eax, 3
	int 80h
	mov eax, 0
	mov bl, [esp-1]
	call process_options_file_byte	
	pop ecx
	loop .file_data_loop

	pop eax
	call close_file
.done:
	pop eax
	ret
