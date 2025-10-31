format ELF64
public _start

section '.bss' writable
    input_fd    dq 0
    output_fd   dq 0
    file_size   dq 0
    file_data   rq 1
    k_value     dq 0
    m_value     dq 0

section '.data' writable
    usage_msg db 'Usage: program <input_file> <output_file> <k> <m>', 0xA
    usage_len = $ - usage_msg
    error_msg db 'Error processing files', 0xA
    error_len = $ - error_msg

section '.text' executable

_start:
    mov rax, [rsp]
    cmp rax, 5
    jge .process_args

    mov rax, 1
    mov rdi, 1
    mov rsi, usage_msg
    mov rdx, usage_len
    syscall
    jmp .exit

.process_args:
    mov rax, [rsp + 32]
    call str_to_int
    mov [k_value], rax

    mov rax, [rsp + 40]
    call str_to_int
    mov [m_value], rax

    mov rax, 2
    mov rdi, [rsp + 16]
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .error
    mov [input_fd], rax

    mov rax, 8
    mov rdi, [input_fd]
    mov rsi, 0
    mov rdx, 2
    syscall
    mov [file_size], rax

    mov rax, 8
    mov rdi, [input_fd]
    mov rsi, 0
    mov rdx, 0
    syscall

    mov rax, 9
    mov rdi, 0
    mov rsi, [file_size]
    mov rdx, 1
    mov r10, 2
    mov r8, [input_fd]
    mov r9, 0
    syscall
    cmp rax, 0
    jl .close_input
    mov [file_data], rax

    mov rax, 3
    mov rdi, [input_fd]
    syscall

    mov rax, 2
    mov rdi, [rsp + 24]
    mov rsi, 101o
    mov rdx, 644o
    syscall
    cmp rax, 0
    jl .unmap_memory
    mov [output_fd], rax

    call process_swing_order

    mov rax, 3
    mov rdi, [output_fd]
    syscall

.unmap_memory:
    mov rax, 11
    mov rdi, [file_data]
    mov rsi, [file_size]
    syscall
    jmp .exit

.close_input:
    mov rax, 3
    mov rdi, [input_fd]
    syscall

.error:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, error_len
    syscall

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

process_swing_order:
    push rbx
    push r12
    push r13
    push r14

    mov r12, [file_data]
    mov r13, [file_size]
    mov r14, [k_value]
    mov rbx, [m_value]

    cmp r14, r13
    jge .done

    mov rcx, 0
    mov r8, 0

    mov rax, 1
    mov rdi, [output_fd]
    lea rsi, [r12 + r14]
    mov rdx, 1
    syscall

    mov rcx, 1

.swing_loop:
    mov rax, r14
    add rax, rcx
    cmp rax, r13
    jge .check_left

    mov rax, r14
    sub rax, rcx
    cmp rax, 0
    jl .check_right

    mov rax, 1
    mov rdi, [output_fd]
    lea rsi, [r12 + r14 + rcx]
    mov rdx, 1
    syscall

    mov rax, 1
    mov rdi, [output_fd]
    lea rsi, [r12 + r14 - rcx]
    mov rdx, 1
    syscall

    inc rcx

    cmp rcx, rbx
    jle .swing_loop
    jmp .done

.check_right:
    mov rax, r14
    add rax, rcx
    cmp rax, r13
    jge .done

    mov rax, 1
    mov rdi, [output_fd]
    lea rsi, [r12 + r14 + rcx]
    mov rdx, 1
    syscall
    inc rcx
    jmp .check_right

.check_left:
    mov rax, r14
    sub rax, rcx
    cmp rax, 0
    jl .done

    mov rax, 1
    mov rdi, [output_fd]
    lea rsi, [r12 + r14 - rcx]
    mov rdx, 1
    syscall
    inc rcx
    jmp .check_left

.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

str_to_int:
    push rbx
    push rcx
    push rdx
    push rsi

    mov rsi, rax
    xor rax, rax
    xor rcx, rcx

.convert_loop:
    mov cl, [rsi]
    cmp cl, 0
    je .done
    cmp cl, '0'
    jl .done
    cmp cl, '9'
    jg .done

    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .convert_loop

.done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
