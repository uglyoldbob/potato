%include 'string_funcs_inc.asm'
%include 'file_inc.asm'

OPTIONS_SIZE equ 64

section .data
process_options_msg db 'Loading options file:',0
process_options_problem db 'There was a problem loading the options file.',0

section .bss
options_file_buffer: resd 1

section .text

process_options_file_byte:
	ret

process_options_file:
	push eax
	mov eax, process_options_msg
	call sprintLF

	mov eax, [esp]
	call sprintLF

	mov eax, [esp]
	call file_open
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
	call file_map
	mov [options_file_buffer], eax
	
	mov eax, [esp]
	call file_getsize
	mov ecx, eax
.file_data_loop:
	push ecx

	;todo: get byte from the buffer
	call process_options_file_byte	
	pop ecx
	loop .file_data_loop
	mov eax, [esp]
	call file_getsize
	mov ebx, eax
	mov eax, [options_file_buffer]
	call file_unmap
	call file_close
	pop eax
.done:
	pop eax
	ret
