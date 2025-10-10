;I do the one thing that you can't.
;You hit them and they get back up,
;I hit them and they stay down.

format elf64

public _start
include "funcnew.asm"

section '.bss' writable
   place rb 15
   msg rb 255
   n rq 0
   num rq 0
section '.text' executable

_start:
    mov r9, 0
    mov rax, 0
    mov rdi, 0
    mov rsi, msg
    mov rdx, 255

    syscall
    xor rdx, rdx
    xor rax, rax
    call str_number
    itera:
        mov rsi, msg
        push rax
        call func
        cmp rdi, 0
        je minus
        mov rdi, 0
        ;call number_str
        ;call print_str
        inc r9
        ;call new_line
        minus:
        pop rax
        cmp rax, 0
        je co

            dec rax
        jmp itera
    co:
        mov rax, r9
        xor rdx, rdx
        call number_str
        call print_str
        call new_line
        call exit


func:
    push rax
    push rbx
    push rcx
    push rsi
    push r8
    mov r8, rax
    xor rdx, rdx
    mov rcx, 5
    div rcx
    cmp rdx, 0
    je pizdarulyu
    mov rax, r8
    xor rdx, rdx
    mov rcx, 11
    div rcx
    cmp rdx, 0
    je pizdarulyu
    mov rdi, 1
    tutu:
        pop r8
        pop rsi
        pop rcx
        pop rbx
        pop rax
    ret

pizdarulyu:
    mov rdi, 0
    jmp tutu
