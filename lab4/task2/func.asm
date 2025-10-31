str_to_int:
    xor rax, rax
    xor rcx, rcx

.convert_loop:
    mov cl, [rsi]
    cmp cl, 0xA
    je .done
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
    ret

int_to_str:
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdi, num_buf
    mov rbx, 10
    xor rcx, rcx

    test rax, rax
    jns .positive
    neg rax
    mov byte [rdi], '-'
    inc rdi

.positive:
    test rax, rax
    jnz .convert
    mov byte [rdi], '0'
    mov byte [rdi+1], 0
    jmp .done

.convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .convert

.store:
    pop rdx
    mov [rdi], dl
    inc rdi
    loop .store

    mov byte [rdi], 0

.done:
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret

print_number:
    push rax
    push rdi
    push rsi
    push rdx

    mov rsi, num_buf
    xor rdx, rdx
.length_loop:
    cmp byte [rsi], 0
    je .print
    inc rsi
    inc rdx
    jmp .length_loop

.print:
    mov rax, 1
    mov rdi, 1
    mov rsi, num_buf
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

new_line:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
