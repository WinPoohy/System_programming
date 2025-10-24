format ELF64
public _start

include 'func.asm'

section '.data' writeable
    newline db 0xA
    minus db '-'

section '.bss' writeable
    a dq 0
    b dq 0
    c dq 0


section '.text' executable
_start:
    pop rcx
    cmp rcx, 4
    jl exit
    pop rsi

    pop rsi
    call str_to_int
    mov [a], rax

    pop rsi
    call str_to_int
    mov [b], rax

    pop rsi
    call str_to_int
    mov [c], rax

    ; Вычисляем выражение: ((((a-c)*b)/c)*a)

    mov rax, [a]
    sub rax, [c] ; rax = a - c

    imul qword [b] ; rax = (a-c) * b

    xor rdx, rdx ; обнуляем rdx для деления
    idiv qword [c] ; rax = ((a-c)*b) / c

    imul qword [a]  ;rax = (((a-c)*b)/c) * a

    call print_int
    call new_line


; str_to_int:
;     xor rax, rax
;     xor rcx, rcx
; .convert_loop:
;     mov cl, byte [rsi]
;     test cl, cl
;     jz .done
;     cmp cl, '0'
;     jl .done
;     cmp cl, '9'
;     jg .done
;     sub cl, '0'
;     imul rax, 10
;     add rax, rcx
;     inc rsi
;     jmp .convert_loop
; .done:
;     ret

; print_int:
;     push rax
;     push rbx
;     push rcx
;     push rdx
;     push rdi
;     push rsi

;     test rax, rax
;     jns .positive
;     neg rax
;     push rax
;     mov rax, 1
;     mov rdi, 1
;     mov rsi, minus
;     mov rdx, 1
;     syscall
;     pop rax

; .positive:
;     mov rcx, 10
;     xor rbx, rbx

;     test rax, rax
;     jnz .convert
;     push '0'
;     inc rbx
;     jmp .print

; .convert:
;     xor rdx, rdx
;     div rcx
;     add dl, '0'
;     push rdx
;     inc rbx
;     test rax, rax
;     jnz .convert

; .print:
;     mov rax, 1
;     mov rdi, 1
;     mov rdx, 1

; .digit_loop:
;     mov rsi, rsp
;     syscall
;     pop rsi
;     dec rbx
;     jnz .digit_loop

;     pop rsi
;     pop rdi
;     pop rdx
;     pop rcx
;     pop rbx
;     pop rax
;     ret

; new_line:
;     push rax
;     push rdi
;     push rsi
;     push rdx

;     mov rax, 1
;     mov rdi, 1
;     mov rsi, newline
;     mov rdx, 1
;     syscall

;     pop rdx
;     pop rsi
;     pop rdi
;     pop rax
;     ret


exit:
    mov rax, 60
    xor rdi, rdi
    syscall
