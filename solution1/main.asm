%macro PRINTM 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

section .data
    array1 dd 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34
    array1_length equ ($ - array1) / 4
    array2 dd 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34
    array2_length equ ($ - array2) / 4
    nl db '', 0x0A
    l_str db 'Loop result: ', 0
    l_str_l equ $ - l_str
    s_str db 'SIMD result: ', 0
    s_str_l equ $ - s_str

section .bss
    result_array resd array1_length
    result_array_s resd array1_length
    buffer_write resb 16
    buffer_read resb 16

section .text
    global _start

_start:

    call add_array
    PRINTM l_str, l_str_l
    mov esi, result_array
    mov ecx, array1_length
    call print_array
    PRINTM nl, 1

    call add_array_s
    PRINTM s_str, s_str_l
    mov esi, result_array_s
    mov ecx, array1_length
    call print_array
    PRINTM nl, 1

    mov eax, 1
    mov ebx, 0
    int 0x80  

add_array:
    mov ecx, array1_length
    mov esi, array1
    mov edi, array2
    mov edx, result_array
    _add_loop:
        mov eax, [esi]
        add eax, [edi]
        mov [edx], eax
        add esi, 4
        add edi, 4
        add edx, 4
        dec ecx
        jnz _add_loop
        ret

add_array_s:
    mov ecx, array1_length
    mov esi, array1
    mov edi, array2
    mov edx, result_array_s
    _add_loop_s:
        cmp ecx, 4
        jl _als_tail
        movups xmm0, [esi]
        movups xmm1, [edi]
        addps xmm0, xmm1
        movups [edx], xmm0
        add esi, 16
        add edi, 16
        add edx, 16
        sub ecx, 4
        jnz _add_loop_s
    _als_exit:
        ret

    _als_tail:
        mov eax, [esi]
        add eax, [edi]
        mov [edx], eax
        add esi, 4
        add edi, 4
        add edx, 4
        dec ecx
        jnz _als_tail


print_array:    
    _print_loop:
        test ecx, ecx
        jz _leave
        
        mov eax, [esi]

        push ecx
        push esi
        call printf
        pop esi
        pop ecx

        add esi, 4
        dec ecx
        jmp _print_loop

        _leave:
            ret

printf:
    test eax, eax
    jge _store_number
    mov byte [buffer_read], '-'
    neg eax
    mov esi, buffer_read
    inc esi
    jmp _convert_number

    _store_number:
        mov esi, buffer_read

    _convert_number:
        xor ecx, ecx
        mov ebx, 10

    _convert_loop:
        xor edx, edx
        div ebx
        add dl, '0'
        push dx
        inc ecx
        test eax, eax
        jnz _convert_loop

    _print_digits:
        test ecx, ecx
        jz _done_printing
        pop dx
        mov [esi], dl
        inc esi
        dec ecx
        jmp _print_digits

    _done_printing:
        mov byte [esi], ' '
        inc esi

        mov eax, 4
        mov ebx, 1
        mov ecx, buffer_read
        mov edx, esi
        sub edx, buffer_read
        int 0x80
        ret