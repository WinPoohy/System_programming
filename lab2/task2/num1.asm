format elf64
public _start
public exit

section '.bss' writeable
num_seven db "7"
newline db 0xA
K db 7
M db 10

section '.text' executable
_start:
    mov cl, [M]

    .iter1:
        push rcx
        mov dl, [K]

        .iter2:
            push rdx
            mov rcx, num_seven
            mov rax, 4
            mov rbx, 1
            mov rdx, 1
            int 0x80
            pop rdx
            dec rdx
            cmp rdx, 0
            jne .iter2

        mov rax, 4
        mov rbx, 1
        mov rdx, 1
        mov rcx, newline
        int 0x80

        pop rcx
        dec rcx
        cmp rcx, 0
        jne .iter1
    call exit
exit:
    mov rax, 1
    xor rbx, rdx
    int 0x80
