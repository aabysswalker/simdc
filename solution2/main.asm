%macro MALLOC 3
    mov	eax, 45
    xor	ebx, ebx
    int	0x80

    mov edx, %1
    mov %2, edx
    mov edx, edx
    mov ebx, 4
    imul ebx, edx

    add eax, 16
    mov	ebx, eax
    mov	eax, 45
    int	0x80

    cmp	eax, 0
    jl	exit

    mov	edi, eax

    mov %3, edi

    mov	ecx, 1
    xor	eax, eax
    std
    rep	stosd
    cld
%endmacro

%macro PRINTM 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

section .data
    nl db '', 0x0A
    l_str db 'Loop result: ', 0
    l_str_l equ $ - l_str
    s_str db 'SIMD result: ', 0
    s_str_l equ $ - s_str
    result_s dd 0
    result_l dd 0

section .bss
    align 16
    array1 resd 1
    array1_length resd 1
    buffer_write resb 16
    buffer_read resb 16

section .text
    global _start

_start:
    MALLOC 250, [array1_length], [array1]
    deb:

    mov ecx, [array1_length]
    inc ecx
    mov esi, [array1]
    ; fill
    .loop:
        mov [edi], eax
        add eax, 1
        add edi, 4
        loop .loop

    PRINTM s_str, s_str_l
    call _add_simd        
    mov eax, [result_s]
    call printf

    PRINTM nl, 1
    PRINTM l_str, l_str_l
    call _add_loop
    mov eax, [result_l]
    call printf
    PRINTM nl, 1

    exit:
    mov eax, 1
    mov ebx, 0
    int 0x80  

_add_loop:
    mov ecx, [array1_length]
    mov edi, [array1]
    xor eax, eax
    _al:
        add eax, [edi]
        add edi, 4
        dec ecx
        jnz _al
    mov [result_l], eax
    ret

_add_simd:
    mov ecx, [array1_length]
    mov edi, [array1]
    _asl:
        cmp ecx, 4
        jl _asl_tail
        movaps xmm1, [edi]
        addps xmm0, xmm1
        add edi, 16
        sub ecx, 1
        jnz _asl

    _asl_exit:
        haddps xmm0, xmm0 
        haddps xmm0, xmm0
        movd eax, xmm0
        add [result_s], eax
        ret

    _asl_tail:
        cmp ecx, 0
        je _asl_exit
        mov eax, [edi]
        add [result_s], eax
        add edi, 4
        sub ecx, 1
        jmp _asl_tail

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