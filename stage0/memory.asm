section .data
;the number of bytes currently allocated for dynamic memory allocation
total_space dd 0

;the start of dynamic memory allocation
;it is assumed that the region for dynamic allocation is increased with sbrk
;andis a single contiguous regionof memory
start_dynamic_allocation dd 0

;definition of the data structure used in memory allocation
struc memblock
.prev: resd 1	;0 if none
.next: resd 1	;0 if none
.addr: resd 1	;only valid when used flag set
.flags: resd 1	;bits:(0)used,(others)reserved
.size: resd 1	;the size of the block in bytes
endstruc

;block flags
;1 = block is free data

section .bss


;make sure these match (2^12 = 4096, 2^13=8192, etc)
NUMBER_BITS_MIN_REQUEST EQU 12
MINIMUM_REQUEST_SIZE EQU 4096

NUMBER_BITS_ALLOC EQU 3
ALLOC_SIZE_ALIGN EQU 8

section .text

;increase eax until it is divisible by 8
size_up_to_8:
	dec eax
	shr eax, NUMBER_BITS_ALLOC
	inc eax
	shl eax, NUMBER_BITS_ALLOC
	ret

size_up_additional_request:
	dec eax
	shr eax, NUMBER_BITS_MIN_REQUEST
	inc eax
	shl eax, NUMBER_BITS_MIN_REQUEST
	ret

;eax is the address to release
;todo: do this
global memory_unalloc
memory_unalloc:
	push ebx
	;get the address of the block
	sub eax, memblock_size
	mov ebx, eax
.verify_block_exists:
	mov eax, [start_dynamic_allocation]
.check_block:
	cmp eax, ebx
	je .block_found
	cmp eax, 0
	je .block_not_found
	mov eax, [eax+memblock.next]
	jmp .check_block	
.block_found:
	and dword [eax+memblock.flags], 0fffffffeh
	;check for a previous block
	cmp dword [eax+memblock.prev], 0
	je .check_for_next
	mov ebx, [eax+memblock.prev]
	test dword [ebx+memblock.flags], 1
	jnz .check_for_next
	cmp dword [eax+memblock.next], 0
	je .two_block_combine
.three_block_combine:
	push ecx
	mov ecx, [eax+memblock.next]
	mov [ebx+memblock.next], ecx
	mov [ecx+memblock.prev], ebx
	mov [ebx+memblock.size], ecx
	sub [ebx+memblock.size], ebx
	sub dword [ebx+memblock.size], memblock_size
	pop ecx
	jmp .check_for_next
.two_block_combine:
	mov dword [ebx+memblock.next], 0
	mov eax, [eax+memblock.size]
	add [ebx+memblock.size], eax
	add dword [ebx+memblock.size], memblock_size
.check_for_next:
	;todo more stuff
	mov ebx, [eax+memblock.next]
	test dword [ebx+memblock.flags], 1
	jnz .done
	cmp dword [ebx+memblock.next], 0
	je .two_block_merge
.three_block_merge:
	xchg eax, ebx
	push ecx
	mov ecx, [eax+memblock.next]
	mov [ebx+memblock.next], ecx
	mov [ecx+memblock.prev], ebx
	mov [ebx+memblock.size], ecx
	sub [ebx+memblock.size], ebx
	sub dword [ebx+memblock.size], memblock_size
	pop ecx
	jmp .done
.two_block_merge:
	xchg eax, ebx
	mov dword [ebx+memblock.next], 0
	mov eax, [eax+memblock.size]
	add [ebx+memblock.size], eax
	add dword [ebx+memblock.size], memblock_size
.done:
	mov eax, 0
	pop ebx
	ret
.block_not_found:
	mov eax, 1
	pop ebx
	ret

global memory_alloc
;eax = amount of memory requested
memory_alloc:
	push ebx
	call size_up_to_8
	sub esp, 12
	mov dword [esp], eax	;size requested
	mov dword [esp+4], 0FFFFFFFFh ;smallest size found so far
	mov dword [esp+8], 0 ;record associated with smallest size
	;start the search
	mov eax, [start_dynamic_allocation]
.check_this_block:
	mov ebx, [eax+memblock.flags]
	test ebx, 1
	jnz .next_block
.unused_block:
	mov ebx, [eax+memblock.size] ;block size
	cmp ebx, [esp]
	jb .next_block
.block_is_large_enough:
	cmp ebx, [esp+4]
	jae .next_block
.the_smallest_suitable_block:
	mov [esp+4], ebx
	mov [esp+8], eax
.next_block: ;advance to the next block, if it is present
	mov ebx, [eax+memblock.next]
	cmp ebx, 0
	je .no_more_blocks
	mov eax, ebx
	jmp .check_this_block
.no_more_blocks:
	cmp dword [esp+4], 0FFFFFFFFH
	je .not_enough_space
.there_is_space:
	mov eax, [esp+8]
	mov ebx, [esp]
	call mem_use_block
	add esp, 12
	mov ebx, [esp+4]
	mov [eax+memblock.addr], ebx
	add eax, memblock_size
	pop ebx
	ret
.not_enough_space:
	mov eax, [eax+memblock.size] ;the size of the block
	call request_more_memory
	cmp eax, 0
	jne .fail_alloc_more
	call mem_use_block
	add esp, 12
	mov ebx, [esp+4]
	mov [eax+memblock.addr], ebx
	add eax, memblock_size
	pop ebx
	ret
.fail_alloc_more:
	add esp, 12
	mov eax, 0
	pop ebx
	ret

;uses the specified block
;eax is the block
;ebx is the amount of memory to use
mem_use_block:
	push ecx
	mov ecx, [eax+memblock.size]
	cmp ecx, ebx
	jne .use_partial_block
.use_entire_block:
	or dword [eax+memblock.flags], 1
	pop ecx
	ret
.use_partial_block:
	sub ecx, ALLOC_SIZE_ALIGN+memblock_size
	cmp ecx, ebx
	jb .use_entire_block
	push edx
	mov edx, eax
	add edx, ebx
	add edx, memblock_size
	mov [edx+memblock.prev], eax
	mov ecx, [eax+memblock.next]
	mov [edx+memblock.next], ecx
	mov ecx, [eax+memblock.size]
	mov [edx+memblock.size], ecx
	sub [edx+memblock.size], ebx
	sub dword [edx+memblock.size], memblock_size
	mov [eax+memblock.size], edx
	or dword [eax+memblock.flags],1
	sub dword [eax+memblock.size], eax
	sub dword [eax+memblock.size],memblock_size
	mov [eax+memblock.next], edx
	mov dword [edx+memblock.flags], 0
	pop edx
	pop ecx
	ret

request_more_memory:
	push ebx
	sub esp, 4
	mov [esp], eax
	mov ebx, [start_dynamic_allocation]
	add ebx, [total_space]
	add ebx, eax
	mov eax, 45
	int 80h
	cmp eax, ebx
	jne .fail
	mov eax, [esp]
	add [total_space], eax
	mov eax, 0
	add esp, 4
	pop ebx
	ret
.fail:
	mov eax, 1
	add esp, 4
	pop ebx
	ret

global setup_memory_alloc
setup_memory_alloc:
	;find end of data for start of heap
	mov eax, 45
	mov ebx, 0
	int 80h
	mov [start_dynamic_allocation], eax
	mov dword [total_space], 0
	;request a small bit of memory to start
	mov eax, MINIMUM_REQUEST_SIZE
	call request_more_memory
	cmp eax, 0
	jne .fail

	;setup the initial structure with the newly requested memory
	mov eax, [start_dynamic_allocation]
	mov dword [eax+memblock.prev], 0
	mov dword [eax+memblock.next], 0
	mov dword [eax+memblock.addr], 0
	mov dword [eax+memblock.flags], 0
	mov dword [eax+memblock.size], MINIMUM_REQUEST_SIZE-memblock_size
	
	jmp .notfail
.fail:
	mov eax, -1
	ret
.notfail:
	mov eax, 0
	ret
