%include 'memory_inc.asm'

struc array
.count: resd 1	;the number of elements currently stored
.capacity: resd 1 ;the max number of elements the array can currently store
.elements: resd 1 ;the location of the elements
endstruc

global array_size_get
array_size_get:
	mov eax, array_size
	ret

;setup an array that exists somewhere
global array_setup
array_setup:
	push ebx
	mov ebx, eax
	mov dword [ebx+array.count], 0
	mov dword [ebx+array.capacity],10
	mov eax, array_size
	add eax, 4*10
	call memory_alloc
	mov [ebx+array.elements],eax
	mov eax, ebx
	pop ebx
	ret

;allocate and initialize an array
global array_create
array_create:
	mov eax, array_size
	call memory_alloc
	call array_setup
	ret

;eax is the array, it is assumed that the elements stored have already been destroyed
global array_destroy
array_destroy:
	push ebx
	mov ebx, eax
	lea eax, [ebx+array.elements]
	call memory_unalloc
	mov eax, ebx
	call memory_unalloc
	pop ebx
	ret

global array_increase
array_increase:
	push ecx
	push ebx
	mov ebx, [eax+array.capacity]
	shl ebx, 1
	xchg eax, ebx
	call memory_alloc
	xchg eax, ebx
	mov ecx, 0
.copy_element:
	push eax
	mov eax, [eax+array.elements]
	mov edx, [eax+ecx*4]
	pop eax
	mov [ebx+array.elements+ecx*4], edx
	inc ecx
	cmp ecx, [eax+array.capacity]
	jb .copy_element
	call memory_unalloc
	mov eax, ebx	
	pop ebx
	pop ecx
	ret

;todo
global array_decrease
array_decrease:
	ret

;eax is the array
;ebx is the value to append
global array_append_item
array_append_item:
	push eax
	push ecx
	mov ecx, [eax+array.count]
	cmp ecx, [eax+array.capacity]
	jb .not_resize
.resize:
	call array_increase
.not_resize:
	inc dword [eax+array.count]
	mov eax, [eax+array.elements]
	mov [eax+ecx*4], ebx
	pop ecx
	pop eax
	ret

;eax is the array
;ebx is the value to append
global array_item_exists
array_item_exists:
	push ecx
	mov ecx, 0
.process_item:
	;todo fix this
	push eax
	mov eax, [eax+array.elements]
	cmp ebx, [eax+ecx*4]
	pop eax
	je .match
	inc ecx
	cmp ecx, [eax+array.count]
	jb .process_item
.nomatch:
	mov eax, 0
	pop ecx
	ret
.match:
	mov eax, 1
	pop ecx
	ret

;eax is the array
;first argument on stack is the function to call
;all other registers remain the same for the function call
;the function to call is called for every element of the array, with eax being the element
global array_iterate
array_iterate:
	;esp+4 contains the function address
	push ecx
	mov ecx, 0
.more_elements:
	push eax
	mov eax, [eax+array.elements]
	mov eax, [eax+ecx*4]
	push ecx
	mov ecx, [esp+8]
	pushad
	call [esp+48]
	popad
	pop ecx
	pop eax
	inc ecx
	cmp ecx, [eax+array.count]
	jb .more_elements
	pop ecx
	ret
