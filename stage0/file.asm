section .text

global file_open
file_open:
	push ecx
	push ebx
	mov ecx, 0	;read
	mov ebx, eax
	mov eax, 5
	int 80h
	pop ebx
	pop ecx
	ret

global file_open_write
file_open_write:
	push edx
	push ecx
	push ebx
	mov ecx, 0q644
	mov ebx, eax
	mov eax, 8
	int 80h
	pop ebx
	pop ecx
	pop edx
	ret

global file_sync:
file_sync:
	push ebx
	mov ebx, eax
	mov eax, 118
	int 80h
	pop ebx
	ret

global file_put_data
;eax = fd
;ebx = buffer address
;ecx = length
file_put_data:
	push edx
	push ecx
	push ebx
	mov edx, ecx
	mov ecx, ebx
	mov ebx, eax
	mov eax, 4
	int 80h
	pop ebx
	pop ecx
	pop edx
	ret

global file_map
file_map:
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
	mov ebx, eax
	call file_getsize
	mov ecx, eax
	mov edi, ebx
	mov ebp, 0
	mov eax, 192
	mov ebx, 0
	mov edx, 1
	mov esi, 1
	;addr, length, prot, flags, fd, offset
	;
	int 80h
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	ret

global file_unmap
file_unmap:
	push ecx
	push ebx
	mov ecx, ebx
	mov ebx, eax
	mov eax, 91
	int 80h
	pop ebx
	pop ecx
	ret

global file_getsize
file_getsize:
	push ebx
	push ecx
	mov ebx, eax
	mov eax, 6Ch
	mov ecx, esp
	sub ecx, 88
	int 80h
	mov eax, [esp-68]
.fs_check:
	pop ecx
	pop ebx
	ret

global file_close
file_close:
	push ebx
	mov ebx, eax
	mov eax, 6
	int 80h
	pop ebx
	ret
