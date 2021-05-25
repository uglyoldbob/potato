%include 'string_funcs_inc.asm'
%include 'file_inc.asm'

section .data
process_source_msg db 'Loading potato source file:',0
process_source_problem db 'There was a problem loading the potato source file.',0

section .bss
source_file_buffer: resd 1

section .text

process_source_file_byte:
	ret

global process_source_file
process_source_file:
	push eax
	mov eax, process_source_msg
	call sprintLF

	mov eax, [esp]
	call sprintLF

	mov eax, [esp]
	call open_file
	cmp eax, 0
	jl .file_problem
	jmp .file_processing
.file_problem:
	mov eax, process_source_problem
	call sprintLF
	jmp .done
.file_processing:
	push eax
	mov eax, [esp]
	call map_file
	mov [source_file_buffer], eax
	
	mov eax, [esp]
	call get_filesize
	mov ecx, eax
.file_data_loop:
	push ecx

	;todo: get byte from the buffer
	call process_source_file_byte
	pop ecx
	loop .file_data_loop
	mov eax, [esp]
	call get_filesize
	mov ebx, eax
	mov eax, [source_file_buffer]
	call unmap_file
	call close_file
	pop eax
.done:
	pop eax
	ret
