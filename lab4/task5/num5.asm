format elf64
public _start

include "func.asm"

section '.data' writeable
    newline db 0xA

section '.bss' writeable
    place rb 15
    msg rb 255
    n rq 1
    num rq 1

section '.text' executable

_start:
    mov r9, 0

    mov rax, 0
    mov rdi, 0
    mov rsi, msg
    mov rdx, 255
    syscall

    mov rsi, msg
    call str_number
    mov [n], rax

itera:
    push rax
    call func
    cmp rdi, 0
    je .skip_count
    inc r9

.skip_count:
    pop rax
    cmp rax, 0
    je .done
    dec rax
    jmp itera
.done:
    mov rax, r9
    call number_str
    call print_str
    call new_line
    call exit

func:
    push rax
    push rbx
    push rdx

    mov rbx, rax

    xor rdx, rdx
    mov rcx, 5
    div rcx
    cmp rdx, 0
    je .success

    mov rax, rbx
    xor rdx, rdx
    mov rcx, 11
    div rcx
    cmp rdx, 0
    je .success

    mov rdi, 1
    jmp .end

.success:
    mov rdi, 0

.end:
    pop rdx
    pop rbx
    pop rax
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
