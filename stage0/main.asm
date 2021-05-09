
section .data
msg1 db 'Potato compiler stage0', 0ah, 0
	global _start

section .text
_start:

	mov ebx, msg1
	mov eax, ebx
nextchar:
	cmp byte [eax], 0
	jz endstring
	inc eax
	jmp nextchar
endstring:
	sub eax, ebx
	mov edx, eax

	mov ecx, msg1
	mov ebx, 1
	mov eax, 4
	int 80h

	; return with status of eax
	mov ebx, 0
	mov eax, 1
	int 80h
