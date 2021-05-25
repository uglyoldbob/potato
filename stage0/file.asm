section .text

global open_file
open_file:
	mov ecx, 0
	mov ebx, eax
	mov eax, 5
	int 80h
	ret

global map_file
map_file:
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
	mov ebx, eax
	call get_filesize
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

global unmap_file
unmap_file:
	mov ecx, ebx
	mov ebx, eax
	mov eax, 91
	int 80h
	ret

global get_filesize
get_filesize:
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

global close_file
close_file:
	mov ebx, eax
	mov eax, 6
	int 80h
	ret
