section .data
;the number of bytes currently allocated for dynamic memory allocation
total_space dd 0

;the start of dynamic memory allocation
;it is assumed that the region for dynamic allocation is increased with sbrk
;andis a single contiguous regionof memory
start_dynamic_allocation dd 0

;previous block address (0 if none)
;next block address (0 if none)
;flags
;size of the data block
;(the block of data)

;block flags
;1 = block is free data


section .bss


MINIMUM_REQUEST_SIZE EQU 4096

section .text
global setup_memory_alloc
setup_memory_alloc:
	;find end of data for start of heap
	mov eax, 45
	mov ebx, 0
	int 80h
	mov [start_dynamic_allocation], eax
	;request a small bit of memory to start
	mov ebx, eax
	add ebx, MINIMUM_REQUEST_SIZE
	mov eax, 45
	int 80h
	;make sure it worked
	cmp eax, ebx
	jne .fail
	add dword [total_space], MINIMUM_REQUEST_SIZE

	;setup the initial structure with the newly requested memory
	mov eax, start_dynamic_allocation
	mov dword [eax], 0
	mov dword [eax+4], 0
	mov dword [eax+8], 1
	mov dword [eax+12], MINIMUM_REQUEST_SIZE-12
	
	jmp .notfail
.fail:
	mov eax, -1
	ret
.notfail:
	mov eax, 0
	ret
