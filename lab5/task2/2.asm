format ELF64
public _start

section '.bss' writable
    input_fd    dq 0
    output_fd   dq 0
    buffer      rb 1
    k           dq 0
    counter     dq 0

section '.data' writable
    usage_msg db 'Usage: program <input_file> <output_file> <k>', 0xA
    usage_len = $ - usage_msg
    error_msg db 'Error: ', 0xA
    error_len = $ - error_msg

section '.text' executable

_start:
    mov rax, [rsp]
    cmp rax, 4
    jge .open_files

    mov rax, 1
    mov rdi, 1
    mov rsi, usage_msg
    mov rdx, usage_len
    syscall
    jmp .exit

.open_files:
    mov rax, [rsp + 32]
    call str_to_int
    mov [k], rax

    cmp qword [k], 1
    jge .open_input
    mov qword [k], 1

.open_input:
    mov rax, 2
    mov rdi, [rsp + 16]
    mov rsi, 0
    mov rdx, 0
    syscall

    cmp rax, 0
    jl .error
    mov [input_fd], rax

.open_output:
    mov rax, 2
    mov rdi, [rsp + 24]
    mov rsi, 101o
    mov rdx, 644o
    syscall

    cmp rax, 0
    jl .close_input
    mov [output_fd], rax

.process_file:
    mov qword [counter], 0

.read_loop:
    mov rax, 0
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, 1
    syscall

    cmp rax, 0
    jle .close_files

    mov rax, [counter]
    inc qword [counter]

    xor rdx, rdx
    div qword [k]
    cmp rdx, 0
    jne .read_loop

    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, buffer
    mov rdx, 1
    syscall

    jmp .read_loop

.close_files:
    mov rax, 3
    mov rdi, [output_fd]
    syscall

.close_input:
    mov rax, 3
    mov rdi, [input_fd]
    syscall
    jmp .exit

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
