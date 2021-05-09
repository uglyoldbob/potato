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

close_file:
	mov ebx, eax
	mov eax, 6
	int 80h
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

	pop eax
	call close_file
.done:
	pop eax
	ret
