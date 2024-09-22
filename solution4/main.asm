%macro PRINTM 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

section .data
    align 16
    matrix1 dd 1,2,3,4,5, 1,2,3,4,5, 1,2,3,4,5, 1,2,3,4,5,1,2,3,4,5 
    m1c equ 5
    m1r equ 5
    align 16
    matrix2 dd 5,6,7,8,9, 5,6,7,8,9, 5,6,7,8,9, 5,6,7,8,9, 5,6,7,8,9
    m2c equ 5
    m2r equ 5

    r1c equ m2c
    r1r equ m1r 

    nl db 0x0A
    m1_str db "Matrix 1 ", 0x0A
    m1_str_l equ $ - m1_str
    m2_str db "Matrix 2 ", 0x0A
    m2_str_l equ $ - m2_str
    r_str db "Result matrix loop", 0x0A
    r_str_l equ $ - r_str
    rs_str db "Result SIMD", 0x0A
    rs_str_l equ $ - rs_str

section .bss
    align 16
    ; Save here
    result resd r1c * r1r
    result_s resd r1c * r1r

    buffer_write resb 16
    buffer_read resb 16

section .text
    global _start

_start:
    PRINTM m1_str, m1_str_l
    mov ebx, m1c
    mov esi, matrix1
    mov ecx, m1r  * m1c
    call print_array
    PRINTM nl, 1

    PRINTM m2_str, m2_str_l
    mov ebx, m2c
    mov esi, matrix2
    mov ecx, m2r  * m2c
    call print_array
    PRINTM nl, 1

    call multiply_s
    call multiply
    
    PRINTM r_str, r_str_l
    mov ebx, r1c
    mov esi, result_s
    mov ecx, r1r  * r1c
    call print_array
    PRINTM nl, 1
    PRINTM rs_str, rs_str_l
    mov ebx, r1c
    mov esi, result
    mov ecx, r1r  * r1c
    call print_array
    PRINTM nl, 1

    mov eax, 1
    mov ebx, 0
    int 0x80  

multiply:
    mov esi, matrix1
    mov edi, matrix2
    mov cl, r1c
    mov ch, r1r
    mov ebx, result
    xor eax, eax
    xor edx, edx

    _mloop_o:
        mov cl, r1r

        _mloop_i:
            xor eax, eax
            xor edx, edx

            push ecx
            push esi
            push edi

            mov cl, m1c
            _mloop_dot:
                mov eax, [esi]
                imul eax, [edi]

                add edx, eax

                add esi, 4
                add edi, m2c * 4
                dec cl
                cmp cl, 0
                jg _mloop_dot
            
            mov dword [ebx], edx
            
            pop edi
            pop esi
            pop ecx

            add edi, 4
            add ebx, 4
            
            xor eax, eax
            dec cl
            cmp cl, 0
            jg _mloop_i
            
        add esi, m1c * 4
        mov edi, matrix2
        dec ch 
        cmp ch, 0
        jg _mloop_o
    _mexit:
        ret

multiply_s:
    mov esi, matrix1
    mov edi, matrix2
    mov cl, r1c
    mov ch, r1r
    mov ebx, result_s
    xor eax, eax
    xor edx, edx

    _sloop_o:
        mov cl, r1r

        _sloop_i:
            xor eax, eax
            xor edx, edx

            push ecx
            push esi
            push edi

            xorps xmm0, xmm0

            mov cl, m1c
            _sloop_dot:
                movd xmm1, [esi]
                movd xmm2, [edi]
                pmulld xmm1, xmm2
                paddd xmm0, xmm1
                add esi, 4
                add edi, m2c * 4
                dec cl
                cmp cl, 0
                jg _sloop_dot
            
            movd [ebx], xmm0
            
            pop edi
            pop esi
            pop ecx

            add edi, 4
            add ebx, 4
            
            xor eax, eax
            dec cl
            cmp cl, 0
            jg _sloop_i
            
        add esi, m1c * 4
        mov edi, matrix2
        dec ch 
        cmp ch, 0
        jg _sloop_o
    _exit_s:
        ret



print_array:
    mov edx, 0
    _print_loop:
        test ecx, ecx
        jz _leave

        cmp edx, ebx
        jl _print_loop_c

        push ecx
        push esi
        push ebx
        push edx
        PRINTM nl, 1
        pop edx
        pop ebx
        pop esi
        pop ecx
        mov edx, 0

    _print_loop_c:
        inc edx
        mov eax, [esi]

        push ecx
        push esi
        push ebx
        push edx
        call printf
        pop edx
        pop ebx
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
