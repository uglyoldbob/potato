%include 'string_funcs.asm'
%include 'options_file.asm'

section .data
msg1 db 'Potato compiler stage0', 0ah, 0
msg_usage db 'Usage: <stage0> <things>', 0ah
	  db '<things> - Required but currently unused argument.', 0ah
arg_index db 0 ;the index number of the argument being parsed
number_arguments dd 0
options_file_message db 'Using options file: ', 0
options_filename db 'options',0

section .bss
options_struct: resb OPTIONS_SIZE



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
	call sprintLF
	dec ecx
	inc byte [arg_index]
	jmp .nextArg
.doneWithArgs:

	cmp dword [number_arguments], 1
	jne .have_some_arguments
	mov eax, msg_usage
	call sprintLF
	jmp .go
.have_some_arguments:
	jmp .go
.go:

	mov eax, options_file_message
	call sprint
	mov eax, options_filename
	call sprintLF	
	mov eax, options_filename
	mov ebx, options_struct
	call process_options_file 

	; return with status of eax
	mov ebx, 0
	mov eax, 1
	int 80h
