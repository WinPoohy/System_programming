format ELF64

public _start
public exit
public print

section '.bss' writable
    num_seven db ('7')
    newline db  (0xA)
    place db 1
    num dq 0

section '.data'
    amount dq 50


section '.text' executable
    _start:
    xor rsi, rsi
    .iter1:
        xor rdi, rdi

        mov rbx, [num]
        inc rbx
        mov [num], rbx

        .iter2:
        mov al, [num_seven]
        call print
        inc rdi
        cmp rdi, [num]
        jne .iter2

        mov al, [newline]
        call print

        inc rsi
        cmp rsi, [amount]
        jne .iter1
    call exit

print:
    push rax
    mov [place], al
    mov eax, 4
    mov ebx, 1
    mov ecx, place
    mov edx, 1
    int 0x80
    pop rax
    ret

exit:
    mov eax, 1
    mov ebx, 0
    int 0x80
