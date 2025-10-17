section .bss
    ascii_str resb 4

section .text
    global _start

_start:
    pop rax
    cmp rax, 2

    pop rax
    pop rax

    mov cl, [rax]
    cmp byte [rax+1], 0

    movzx rax, cl

    mov rdi, ascii_str
    call int_to_string

    mov rax, 1
    mov rdi, 1
    mov rsi, ascii_msg
    mov rdx, 12
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, ascii_str
    mov rdx, 4
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    jmp .exit

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

int_to_string:
    push rbx
    push rcx
    push rdx

    mov rbx, 10
    mov rcx, 0

    cmp rax, 0
    jne .convert
    mov byte [rdi], '0'
    mov byte [rdi+1], 0
    jmp .done

.convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    cmp rax, 0
    jne .convert

    mov rbx, 0
.store:
    pop rax
    mov [rdi+rbx], al
    inc rbx
    loop .store

    mov byte [rdi+rbx], 0

.done:
    pop rdx
    pop rcx
    pop rbx
    ret
