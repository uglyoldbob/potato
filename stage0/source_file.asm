%include 'string_funcs_inc.asm'
%include 'file_inc.asm'

struc source_file
.mode: resw 1
endstruc

section .data
process_source_msg db 'Loading potato source file:',0
process_source_problem db 'There was a problem loading the potato source file.',0

source_file_var: times source_file_size db 0

section .text

;al is the byte, ebx
process_source_file_byte:
	sub esp, 20
	cmp word [ebx+source_file.mode], 0
	jne .not_mode0
.mode0:
	
	jmp .done_mode
.not_mode0:

.done_mode:
	
	add esp,20
	ret

global process_source_file
process_source_file:
	push edx
	push ecx
	push ebx
	push eax
	sub esp, 20
	mov [esp+4], eax
	mov [esp+8], ebx
	mov eax, process_source_msg
	call sprintLF

	mov eax, [esp+4]
	call sprintLF

	mov eax, [esp+4]
	call file_open
	cmp eax, 0
	jl .file_problem
	jmp .file_processing
.file_problem:
	mov eax, process_source_problem
	call sprintLF
	jmp .done
.file_processing:
	mov [esp+12], eax
	call file_map
	mov [esp+16], eax
	
	mov eax, [esp+12]
	call file_getsize
	mov ecx, eax
	xor edx, edx
	mov ebx, source_file_var
.file_data_loop:
	mov eax, [esp+16]
	mov al, [eax+edx]
	call process_source_file_byte
	inc edx
	loop .file_data_loop
	mov eax, [esp+12]
	call file_getsize
	mov ebx, eax
	mov eax, [esp+16]
	call file_unmap
	call file_close
.done:
	add esp, 20
	pop eax
	pop ebx
	pop ecx
	pop edx
	ret
