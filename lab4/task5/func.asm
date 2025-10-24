str_number:
    xor rax, rax
    xor rcx, rcx

.loop:
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
    jmp .loop

.done:
    ret

number_str:
    push rax
    push rbx
    push rdx
    push rdi
    push rsi

    mov rdi, place
    mov rbx, 10
    xor rcx, rcx

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

    mov rsi, rdi
.store:
    pop rdx
    mov [rsi], dl
    inc rsi
    loop .store

    mov byte [rsi], 0

.done:
    pop rsi
    pop rdi
    pop rdx
    pop rbx
    pop rax
    ret

print_str:
    push rax
    push rdi
    push rsi
    push rdx

    mov rsi, place
    xor rdx, rdx
.length:
    cmp byte [rsi], 0
    je .print
    inc rsi
    inc rdx
    jmp .length

.print:
    mov rax, 1
    mov rdi, 1
    mov rsi, place
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
