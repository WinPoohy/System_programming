format elf64
public _start

section '.bss' writeable
    buffer rb 64

section '.text' executable
_start:
    pop rax
    cmp rax, 2

    pop rax
    pop rdi
    xor rax, rax
    xor rcx, rcx
    .convert:
        mov cl, byte [rdi]
        test cl, cl
        jz .converted
        sub cl, '0'
        imul rax, 10
        add rax, rcx
        inc rdi
        jmp .convert

    .converted:
    mov r8, rax
    xor r9, r9
    mov r10, 1

    .loop:
        cmp r10, r8
        jg .print

        mov rax, r10
        mov r11, 10
        .find_first_digit:
            xor rdx, rdx
            div r11
            test rax, rax
            jz .found_first_digit
            mov r12, rax
            jmp .find_first_digit

        .found_first_digit:
        test rdx, rdx
        jnz .use_remainder
        mov rdx, r12

        .use_remainder:
        mov rax, r10
        imul rax, rdx
        add r9, rax

        inc r10
        jmp .loop

    .print:
        mov rax, r9
        mov rdi, buffer + 63
        mov rcx, 10
        mov byte [rdi], 0xA

        .convert_loop:
            dec rdi
            xor rdx, rdx
            div rcx
            add dl, '0'
            mov [rdi], dl
            test rax, rax
            jnz .convert_loop

        mov rax, 4
        mov rbx, 1
        mov rcx, rdi
        mov rdx, buffer + 64
        sub rdx, rcx
        int 0x80

        jmp exit

exit:
    mov rax, 1
    xor rbx, rbx
    int 0x80
