format elf64
public _start

section '.bss' writeable
    buffer rb 1024
    path_buffer rb 256

section '.text' executable
_start:
    pop rax
    pop rax
    pop rax
    mov [dir_path], rax

    mov rax, 5
    mov rbx, [dir_path]
    mov rcx, 0
    mov rdx, 0
    int 0x80

    mov [dir_fd], eax

    mov rax, 89
    mov ebx, [dir_fd]
    mov rcx, buffer
    mov rdx, 1024
    int 0x80

    mov [bytes_read], eax

    mov rax, 6
    mov ebx, [dir_fd]
    int 0x80

    mov rsi, buffer
    mov rcx, 2

.file_loop:
    push rcx

    mov al, [rsi + 18]
    cmp al, '.'
    je .next_file

    mov rdi, path_buffer

    mov rax, [dir_path]
.copy_dir:
    mov dl, [rax]
    mov [rdi], dl
    inc rax
    inc rdi
    test dl, dl
    jnz .copy_dir

    dec rdi
    mov byte [rdi], '/'
    inc rdi

    lea rax, [rsi + 18]
.copy_name:
    mov dl, [rax]
    mov [rdi], dl
    inc rax
    inc rdi
    test dl, dl
    jnz .copy_name

    mov rax, 13
    mov rbx, 0
    int 0x80
    and eax, 0777o

    mov rbx, path_buffer
    mov rcx, rax
    mov rax, 15
    int 0x80

    pop rcx
    dec rcx
    jz exit

.next_file:
    movzx rax, word [rsi + 16]
    add rsi, rax

    mov rax, rsi
    sub rax, buffer
    cmp eax, [bytes_read]
    jl .file_loop

exit:
    mov rax, 1
    xor rbx, rbx
    int 0x80

section '.bss' writeable
    dir_path dq 0
    dir_fd dd 0
    bytes_read dd 0
