exit:
    mov rax, 60
    xor rdi, rdi
    syscall
    ret

new_line:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 0xA
    push rax
    mov rsi, rsp
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall
    pop rax

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

print_symbl:
    push rdi
    push rsi
    push rdx
    push rcx

    push rax
    mov rsi, rsp          ; указатель на символ
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    mov rdx, 1            ; длина 1 символ
    syscall
    pop rax               ; восстанавливаем стек

    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

; Function printing of string
; input rsi - place of memory of begin string
print_str:
    push rax
    push rdi
    push rdx
    push rcx

    mov rax, rsi
    call len_str
    mov rdx, rax          ; длина строки
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    mov rsi, rsi          ; указатель на строку (уже в rsi)
    syscall

    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

; input rax - place of memory of begin string
; output rax - length of the string
len_str:
    push rdx
    mov rdx, rax          ; сохраняем начало строки
    .iter:
        cmp byte [rax], 0
        je .next
        inc rax
        jmp .iter
    .next:
    sub rax, rdx          ; вычисляем длину
    pop rdx
    ret

; Convert string to integer
; input: rsi - pointer to string
; output: rax - integer value
str_to_int:
    push rsi
    push rbx
    push rcx
    push rdx
    xor rax, rax          ; обнуляем результат
    xor rdx, rdx          ; обнуляем счётчик
    mov rcx, 10           ; основание системы счисления
    .itera:
        mov bl, [rsi + rdx] ; берём текущий символ
        cmp bl, '0'
        jl .next
        cmp bl, '9'
        jg .next
        sub bl, '0'       ; преобразуем символ в цифру
        add rax, rbx      ; добавляем к результату
        cmp byte [rsi + rdx + 1], 0 ; проверяем следующий символ
        je .next          ; если конец строки - выходим
        push rdx
        mul rcx           ; умножаем результат на 10
        pop rdx
        inc rdx           ; переходим к следующему символу
        jmp .itera
    .next:
    pop rdx
    pop rcx
    pop rbx
    pop rsi
    ret

; Print integer
; input: rax - integer to print
print_int:
    push rbx
    push rcx
    push rdx

    mov rcx, 10           ; основание системы счисления
    xor rbx, rbx          ; счётчик цифр
    .iter1:
        xor rdx, rdx
        div rcx           ; делим rax на 10
        add rdx, '0'      ; преобразуем остаток в символ
        push rdx          ; сохраняем символ в стек
        inc rbx           ; увеличиваем счётчик цифр
        cmp rax, 0
        jne .iter1        ; продолжаем, если число не нуль

    .iter2:
        pop rax           ; достаём символ из стека
        call print_symbl  ; печатаем символ
        dec rbx           ; уменьшаем счётчик
        cmp rbx, 0
        jne .iter2        ; продолжаем, пока есть цифры

    pop rdx
    pop rcx
    pop rbx
    ret

; String to number with error checking (улучшенная версия)
; input: rsi - string pointer
; output: rax - number, CF=1 if error
str_symbol:
    push rcx
    push rbx
    push rdx

    xor rax, rax
    xor rcx, rcx          ; счётчик позиции
    .loop:
        xor rbx, rbx
        mov bl, byte [rsi + rcx]
        cmp bl, 0         ; конец строки?
        je .finished
        cmp bl, '0'
        jl .error
        cmp bl, '9'
        jg .error
        sub bl, '0'       ; символ -> цифра
        imul rax, 10      ; умножаем текущий результат на 10
        add rax, rbx      ; добавляем новую цифру
        inc rcx
        jmp .loop

    .finished:
        clc               ; очищаем флаг ошибки
        jmp .restore

    .error:
        stc               ; устанавливаем флаг ошибки

    .restore:
        pop rdx
        pop rbx
        pop rcx
        ret
