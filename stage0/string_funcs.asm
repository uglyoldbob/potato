%ifndef STRING_FUNCS_I
%define STRING_FUNCS_I

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
