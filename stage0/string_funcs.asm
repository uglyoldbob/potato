%ifndef STRING_FUNCS_I
%define STRING_FUNCS_I

section .text

global slen
slen:
	push ebx
	mov ebx, eax
.next:
	cmp byte [eax], 0
	jz .done
	inc eax
	jmp .next
.done:
	sub eax, ebx
	pop ebx
	ret	

global sprint
sprint:
	push edx
	push ecx
	push ebx
	push eax
	call slen

	mov edx, eax
	pop eax

	mov ecx, eax
	mov ebx, 1
	mov eax, 4
	int 80h

	pop ebx
	pop ecx
	pop edx
	ret

global sprintLF
sprintLF:
	call sprint
	push eax
	mov eax, 0ah
	push eax
	mov eax, esp
	call sprint
	pop eax
	pop eax
	ret

%endif
