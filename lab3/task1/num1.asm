format elf64
public _start

include 'func.asm'

section '.data' writeable
    newline db 0xA

section '.bss' writeable
    code_buffer rb 4

section '.text' executable
_start:
    pop rax
    cmp rax, 2
    jne exit

    pop rax
    pop rax
    movzx rax, byte [rax]

    mov rdi, code_buffer
    call int_to_string

    mov rdx, 0

.get_length:
    cmp byte [rdi+rdx], 0
    je .print
    inc rdx
    jmp .get_length

.print:
    mov rax, 4
    mov rbx, 1
    mov rcx, code_buffer
    int 0x80

    mov rax, 4
    mov rbx, 1
    mov rcx, newline
    mov rdx, 1
    int 0x80

; int_to_string:
;     push rbx
;     push rcx
;     push rdx

;     mov rbx, 10
;     mov rcx, 0

;     cmp rax, 0
;     jne .convert
;     mov byte [rdi], '0'
;     mov byte [rdi+1], 0
;     jmp .done

; .convert:
;     xor rdx, rdx
;     div rbx
;     add dl, '0'
;     push rdx
;     inc rcx
;     cmp rax, 0
;     jne .convert

;     mov rbx, 0
; .store:
;     pop rax
;     mov [rdi+rbx], al
;     inc rbx
;     loop .store

;     mov byte [rdi+rbx], 0

; .done:
;     pop rdx
;     pop rcx
;     pop rbx
;     ret


exit:
    mov rax, 1
    xor rbx, rbx
    int 0x80
