format elf64
public _start

include "func.asm"

section '.data' writeable
    prompt db 'Enter N: '
    prompt_len = $ - prompt
    result_msg db 'Numbers divisible by their last two digits:', 0xA
    result_len = $ - result_msg
    newline db 0xA
    space db ' '

section '.bss' writeable
    input_buf rb 16
    num_buf rb 16
    N rq 1
    current_num rq 1
    divisor rq 1

section '.text' executable

_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    mov rax, 0
    mov rdi, 0
    mov rsi, input_buf
    mov rdx, 16
    syscall

    mov rsi, input_buf
    call str_to_int
    mov [N], rax

    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_len
    syscall

    mov qword [current_num], 100

.find_loop:
    mov rax, [current_num]
    cmp rax, [N]
    jg .done

    call check_divisibility
    cmp rdi, 1
    jne .next_number

    mov rax, [current_num]
    call int_to_str
    call print_number
    call print_space

.next_number:
    inc qword [current_num]
    jmp .find_loop

.done:
    call new_line
    call exit

check_divisibility:
    push rax
    push rbx
    push rdx

    mov rbx, rax

    mov rdx, 0
    mov rcx, 100
    div rcx
    cmp rdx, 0
    je .not_divisible


    mov rax, rbx
    mov [divisor], rdx

    xor rdx, rdx
    div qword [divisor]

    cmp rdx, 0
    jne .not_divisible

    mov rdi, 1
    jmp .end

.not_divisible:
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
