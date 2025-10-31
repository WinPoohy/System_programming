format elf64
public _start

include "func.asm"
section '.data' writeable
    prompt db 'Enter n: '
    prompt_len = $ - prompt
    result db 'Sum: '
    result_len = $ - result
    newline db 0xA

section '.bss' writeable
    buf rb 16
    num_buf rb 16
    n rq 1
    sum rq 1

section '.text' executable

_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    mov rax, 0
    mov rdi, 0
    mov rsi, buf
    mov rdx, 16
    syscall

    mov rsi, buf
    call str_to_int
    mov [n], rax

    call calculate_sum


    mov rax, 1
    mov rdi, 1
    mov rsi, result
    mov rdx, result_len
    syscall

    mov rax, [sum]
    call int_to_str
    call print_number

    call new_line
    call exit

; Вычисление суммы ряда: 1 - 2 + 3 - 4 + ... + (-1)^(n+1) * n
calculate_sum:
    push rax
    push rbx
    push rcx
    push rdx

    mov rax, 0
    mov rbx, 1
    mov rcx, [n]
    mov rdx, 1

.calc_loop:
    mov r8, rbx
    imul r8, rdx
    add rax, r8

    neg rdx

    inc rbx
    loop .calc_loop

    mov [sum], rax

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
