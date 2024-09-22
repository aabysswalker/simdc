%macro PRINTM 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro
section .data
    align 16
    string db "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf", 0x0A
    string_len equ $ - string - 1
    align 16
    sub_string db "asdfa", 0x0A
    sub_string_len equ $ - sub_string - 1
    result dd 0
    result_l dd 0
    lr db "Loop result: ", 0
    lr_size equ $ - lr
    sr db "SIMD result: ", 0
    sr_size equ $ - sr
    nl db 0x0A

section .bss
    align 16
    buffer_write resb 16
    buffer_read resb 16 

section .text
    global _start

_start:
    PRINTM lr, lr_size
    call find_substring
    mov eax, [result_l]
    call printf
    PRINTM nl, 1
    PRINTM sr, sr_size
    call find_substring_s
    mov eax, [result]
    call printf
    PRINTM nl, 1
    mov eax, 1
    mov ebx, 0
    int 0x80

find_substring:
    xor ebx, ebx
    outer_loop:
        mov ecx, sub_string_len
        mov esi, string
        add esi, ebx
        mov edi, sub_string

    inner_loop:
        mov al, [esi]
        mov dl, [edi]
        cmp al, dl
        jne not_found
        inc esi
        inc edi
        dec ecx
        jnz inner_loop

        inc dword [result_l]

    not_found:
        inc ebx
        mov eax, string_len
        sub eax, sub_string_len
        cmp ebx, eax
        jle outer_loop

        ret

find_substring_s:
    xor ebx, ebx
    outer_loop_s:
        mov ecx, sub_string_len
        mov esi, string
        add esi, ebx
        mov edi, sub_string
        mov eax, sub_string_len
        movdqu xmm0, [edi]

    inner_loop_s:
        movdqu xmm1, [esi]
        pcmpeqb xmm1, xmm0
        pmovmskb edx, xmm1
        cmp edx, 0
        jne check_length

        jmp not_found_s

    check_length:
        mov ecx, sub_string_len
        mov edi, sub_string
        mov esi, string
        add esi, ebx
        xor edi, edi

    length_check_loop:
        mov al, [esi + edi]
        mov dl, [sub_string + edi]
        cmp al, dl
        jne not_found_s
        inc edi
        dec ecx
        jnz length_check_loop

        inc dword [result]

    not_found_s:
        inc ebx
        mov eax, string_len
        sub eax, sub_string_len
        cmp ebx, eax
        jle outer_loop_s

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