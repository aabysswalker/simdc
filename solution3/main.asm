%macro PRINTM 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

section .data
    align 16
    array1 dd 2,4,6,8,10,11,12
    array1_length equ ($ - array1) / 4
    array2 dd 2,4,6,8,10,11,12
    array2_length equ ($ - array2) / 4
    nl db '', 0x0A
    l_str db 'Loop result: ', 0
    l_str_l equ $ - l_str
    s_str db 'SIMD result: ', 0
    s_str_l equ $ - s_str

section .bss
    align 16
    l_vec resd array1_length
    l_vec_s resd array1_length
    l_dot resd 1
    l_dot_s resd 1
    buffer_write resb 16
    buffer_read resb 16

section .text
    global _start

_start:
    PRINTM l_str, l_str_l
    call add_vec
    mov esi, l_vec
    mov ecx, array1_length
    call print_array
    PRINTM nl, 1
    call dot_vec
    mov eax, [l_dot]
    call printf
    PRINTM nl, 1


    PRINTM s_str, s_str_l
    call add_vec_s
    mov esi, l_vec_s
    mov ecx, array1_length
    call print_array
    PRINTM nl, 1
    call dot_vec_s
    mov eax, [l_dot_s]
    call printf
    PRINTM nl, 1


    mov eax, 1
    mov ebx, 0
    int 0x80  

dot_vec:
    mov ecx, array1_length
    mov esi, array1
    mov edi, array2
    mov eax, 0
    mov edx, l_dot

    _dot_loop:
        mov ebx, [esi]
        imul ebx, [edi]
        add eax, ebx
        add esi, 4
        add edi, 4
        dec ecx
        jnz _dot_loop

        mov [edx], eax  
        ret

dot_vec_s:
    mov ecx, array1_length
    mov esi, array1
    mov edi, array2
    mov edx, 0
    mov eax, 0

    _dls_loop:
        cmp ecx, 4
        jl _dls_remainder
        movups xmm0, [edi]
        movups xmm1, [esi]
        pmulld xmm0, xmm1
        haddps xmm0, xmm0
        haddps xmm0, xmm0

        movd edx, xmm0
        add eax, edx
        add esi, 16
        add edi, 16
        sub ecx, 4
        jnz _dls_loop

    _dls_remainder:
        cmp ecx, 0
        je _dls_exit
        mov ebx, [esi]
        imul ebx, [edi]
        add eax, ebx
        add esi, 4
        add edi, 4
        sub ecx, 1
        cmp ecx, 0
        jg _dls_remainder 

    _dls_exit:
        mov [l_dot_s], eax
        ret

add_vec:
    mov ecx, array1_length
    mov esi, array1
    mov edi, array2
    mov edx, l_vec
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

add_vec_s:
    mov ecx, array1_length
    mov esi, array1
    mov edi, array2
    mov edx, l_vec_s
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
    _als_tail:
        cmp ecx, 0
        je _als_exit
        mov eax, [esi]
        add eax, [edi]
        mov [edx], eax
        add esi, 4
        add edi, 4
        add edx, 4
        dec ecx
        jnz _als_tail
        ret

    _als_exit:
        ret

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