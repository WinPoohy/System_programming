; .get_length:
;     cmp byte [rdi+rdx], 0
;     je .print
;     inc rdx
;     jmp .get_length


; .print:
;     mov rax, 4
;     mov rbx, 1
;     mov rcx, code_buffer
;     int 0x80

;     mov rax, 4
;     mov rbx, 1
;     mov rcx, newline
;     mov rdx, 1
;     int 0x80

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
