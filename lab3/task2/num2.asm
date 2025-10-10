; format ELF64

; section '.text' executable
; public _start

; section '.data' writeable
; place db "23453", 0
; a dq 0
; b dq 0
; c dq 0
; chis dq 0

; include 'func.asm'


; _start:
;     add rsp, 23
;     xor rsi, rsi
;     xor rax, rax
;     pop rsi
;     call str_to_int
;     mov [a], rax
;     xor rsi, rsi
;     pop rsi
;     call str_to_int
;     mov [b], rax
;     xor rsi, rsi
;     pop rsi
;     call str_to_int
;     mov [c], rax
;     xor rsi, rsi
;     ;( ( ( ( (b*c) -b) + c) -a )-b)
;     ;((((b*a)/c)+b)-a)
;     mov rax, [b]
;     imul rax, [c] ; rdx = b*c
;     sub rax, [b] ;rdx = b*c - b
;     ;mov rax, rbx
;     add rax, [c]; rdx = b*c - b + c
;     sub rax, [a]; rdx = b*c - b + c - a
;     ;mov rax, rbx
;     sub rax, [b] ; b = b*c - b + c - a -b
;     ;mov rax, rbx
;     call print_int
;     xor rsi, rsi
;     call new_line
;     call exit


; ; str_to_int:
; ;     push rsi
; ;     push rbx
; ;     push rcx
; ;     push rdx
; ;     xor rax, rax
; ;     xor rdx, rdx
; ;     mov rcx, 10
; ;     itera:
; ;         mov byte bl, [rsi + rdx]

; ;         cmp bl, '0'
; ;         jl next
; ;         cmp bl, '9'
; ;         jg next
; ;         sub bl, '0'
; ;         add rax, rbx
; ;         cmp byte [rsi+rdx+1], 0
; ;         je next
; ;         push rdx
; ;         mov rcx, 10
; ;         mul rcx
; ;         pop rdx
; ;         inc rdx
; ;     jmp itera
; ;     next:
; ;     pop rdx
; ;     pop rcx
; ;     pop rbx
; ;     pop rsi
; ;   ret

; ; print_int:

; ;     mov rcx, 10
; ;     xor rbx, rbx
; ;     .iter1:
; ;       xor rdx, rdx
; ;       div rcx
; ;       add rdx, '0'
; ;       push rdx
; ;       inc rbx
; ;       cmp rax,0
; ;     jne .iter1
; ;     .iter2:
; ;       pop rax
; ;       call print_symbl
; ;       dec rbx
; ;       cmp rbx, 0
; ;     jne .iter2

; ;  ret

format ELF64

; Простой вывод символа (для отладки)
print_char:
    push rdi
    push rsi
    push rdx
    push rax

    mov [char_buf], al
    mov rax, 1
    mov rdi, 1
    mov rsi, char_buf
    mov rdx, 1
    syscall

    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

; Новая строка
new_line:
    mov al, 0xA
    call print_char
    ret

; Выход
exit:
    mov rax, 60
    xor rdi, rdi
    syscall

section '.data'
char_buf db 0
