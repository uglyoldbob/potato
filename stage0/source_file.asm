%include 'string_funcs_inc.asm'
%include 'file_inc.asm'

struc source_file
.mode: resw 1
.column: resw 1
.row: resd 1
endstruc

struc source_mode
.plain: resb 1
.commenting: resb 1
endstruc

section .data
process_source_msg db 'Loading potato source file:',0
process_source_problem db 'There was a problem loading the potato source file.',0
just_newline db 10, 0
print_w db 'w', 0
print_e db 'e', 0
print_c db 'c', 0
print_x db 'x', 0

source_file_var: times source_file_size db 0

section .text

global setup_source_file
setup_source_file:
	mov word [ebx+source_file.column], 1
	mov dword [ebx+source_file.row], 1
	mov word [ebx+source_file.mode], 0
	ret

;this function is called by the is_* functions when the character meets one of the
;characters in that character class
character_check_yes:
	or ah, 1
	test ah, 1
	ret

;this function is called by the is_* functions when the character fails to meet all of the
;characters in the character class
character_check_no:
	test ah, 1
	ret

;al is the byte to check
;low bit of ah is set if true (al is an ascii whitespace)
;low bit of ah is unmodified if false
is_whitespace:
	cmp al, ' '
	je character_check_yes
	cmp al, 13
	je character_check_yes
	cmp al, 10
	je character_check_yes
	cmp al, 9
	je character_check_yes
	jmp character_check_no

is_comment_start:
	cmp al, ';'
	je character_check_yes
	jmp character_check_no

is_newline:
	cmp al, 10
	je character_check_yes
	jmp character_check_no

handle_mode_plain:
	and ah, 0feh
	call is_whitespace
	jnz .modeplain_1
	and ah, 0feh
	call is_comment_start
	jnz .modeplain_comment
	jmp .modeplain_unhandled
.modeplain_1:	;whitespace
	push eax
	mov eax, print_w
	call sprint
	pop eax
	and ah, 0feh
	call is_newline
	jz .done_mode
	mov eax, just_newline
	call sprint
	jmp .done_mode
.modeplain_comment:
	mov word [ebx+source_file.mode], source_mode.commenting
	mov eax, print_c
	call sprint
	jmp .done_mode
.modeplain_unhandled:
	mov eax, print_e
	call sprint
.done_mode:
	ret

handle_mode_comment1:
	and ah, 0feh
	call is_newline
	jnz .end_comment
	mov eax, print_c
	call sprint
	jmp .done_mode
.end_comment:
	mov eax, just_newline
	call sprint
	mov word [ebx+source_file.mode], source_mode.plain
	jmp .done_mode
.done_mode:
	ret

operate_row_column:
	and ah, 0feh
	call is_newline
	jnz .newline
	inc word [ebx+source_file.column]
	ret
.newline:
	mov word [ebx+source_file.column], 1
	inc dword [ebx+source_file.row]
	ret

;al is the byte, ebx is the source_file struct
process_source_file_byte:
	push eax
	sub esp, 20
	call operate_row_column
	cmp word [ebx+source_file.mode], source_mode.plain
	je .mode_plain
	cmp word [ebx+source_file.mode], source_mode.commenting
	je .mode_commenting
	
	jmp .unknown_mode
.mode_plain:
	call handle_mode_plain
	jmp .done_mode
.mode_commenting:
	call handle_mode_comment1
	jmp .done_mode
.unknown_mode:
	mov eax, print_x
	call sprint
.done_mode:
	
	add esp,20
	pop eax
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
