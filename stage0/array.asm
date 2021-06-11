%include 'memory_inc.asm'
%include 'string_funcs_inc.asm'

;an array struc holds a number of dword sized objects
;it will typically hold dynamically allocated elements
struc array
.count: resd 1	;the number of elements currently stored
.capacity: resd 1 ;the max number of elements the array can currently store
.elements: resd 1 ;the location of the elements
endstruc

;code below is for the dword array structure (element size is 4 bytes)

global array_size_get
array_size_get:
	mov eax, array_size
	ret

global array_get_count
array_get_count:
	mov eax, [eax+array.count]
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

;TODO fix this like byte array increase was fixed
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

;code below is for the byte array structure (element size is 1 byte)

global byte_array_size_get
byte_array_size_get:
	jmp array_size_get

global byte_array_get_count
byte_array_get_count:
	jmp array_get_count

;setup an array that exists somewhere
global byte_array_setup
byte_array_setup:
	push ebx
	mov ebx, eax
	mov dword [ebx+array.count], 0
	mov dword [ebx+array.capacity],10
	mov eax, array_size
	add eax, 10
	call memory_alloc
	mov [ebx+array.elements],eax
	mov eax, ebx
	pop ebx
	ret

;eax is the array object
global byte_array_takedown
byte_array_takedown:
	push ebx
	mov ebx, eax
	lea eax, [ebx+array.elements]
	call memory_unalloc
	pop ebx
	ret

;appends a chunk of data that is null terminated
;eax is the array
;ebx is the pointer to the data
;ecx specifies if the null terminator should be included
global byte_array_append_null_terminated
byte_array_append_null_terminated:
	push edx
	push eax
	push ebx
	push ecx
	xchg eax, ebx
	call slen
	mov edx, eax
.check_size:
	mov ecx, [ebx+array.capacity]
	sub ecx, [ebx+array.count]
	cmp ecx, edx
	jae .large_enough
	mov eax, ebx
	push eax
	call byte_array_increase
	pop eax
	jmp .check_size
.large_enough:
	mov ecx, eax ;ecx is number of bytes to copy
	mov eax, [esp+8] ;eax is the array object
	mov ebx, [eax+array.elements]
	add ebx, [eax+array.count]
	mov eax, ebx
	mov ebx, [esp+4]
	push edx
.copy_byte:
	cmp byte [ebx], 0
	jz .check_null
	mov cl, [ebx]
	mov [eax], cl
	inc ebx
	inc eax
	jmp .copy_byte
.check_null:
	pop edx
	mov eax, [esp+8]
	add [eax+array.count], edx
	pop ecx
	cmp ecx, 1
	jne .no_null
	mov ebx, [eax+array.elements]
	add ebx, [eax+array.count]
	mov byte [ebx], 0
	inc dword [eax+array.count]
.no_null:
	pop ebx
	pop eax
	pop edx
	ret

byte_array_increase:
	push ecx
	push ebx
	push edx
	mov ebx, [eax+array.capacity]
	shl ebx, 1
	xchg eax, ebx
	call memory_alloc
	xchg eax, ebx
	;eax is the array object again
	;ebx is the new element
	push ebx
	mov ebx, [eax+array.capacity]
	shl ebx, 1
	mov [eax+array.capacity], ebx
	pop ebx
	mov ecx, 0
.copy_element:
	mov dl, [eax+array.elements+ecx]
	mov [ebx+ecx], dl
	inc ecx
	cmp ecx, [eax+array.count]
	jb .copy_element
	push eax
	mov eax, [eax+array.elements]
	call memory_unalloc
	pop eax
	mov [eax+array.elements], ebx
	pop edx
	pop ebx
	pop ecx
	ret

global byte_array_get_data_ptr_and_count
byte_array_get_data_ptr_and_count:
	mov ebx, [eax+array.count]
	mov eax, [eax+array.elements]
	ret
