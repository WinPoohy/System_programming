format elf64
public _start

section '.data' writeable
    prompt db 'Enter n: '
    prompt_len = $ - prompt
    result db 'Sum: '
    result_len = $ - result
    newline db 0xA

section '.bss' writeable
    buf rb 16
    num_buf rb 16
    n rq 1
    sum rq 1

section '.text' executable

_start:
    ; Вывод приглашения
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; Чтение числа n
    mov rax, 0
    mov rdi, 0
    mov rsi, buf
    mov rdx, 16
    syscall

    ; Преобразование строки в число
    mov rsi, buf
    call str_to_int
    mov [n], rax

    ; Вычисление суммы ряда
    call calculate_sum

    ; Вывод результата
    mov rax, 1
    mov rdi, 1
    mov rsi, result
    mov rdx, result_len
    syscall

    mov rax, [sum]
    call int_to_str
    call print_number

    call new_line
    call exit

; Вычисление суммы ряда: 1 - 2 + 3 - 4 + ... + (-1)^(n+1) * n
calculate_sum:
    push rax
    push rbx
    push rcx
    push rdx

    mov rax, 0          ; сумма = 0
    mov rbx, 1          ; текущее число = 1
    mov rcx, [n]        ; количество итераций = n
    mov rdx, 1          ; знак = +1 (начинаем с плюса)

.calc_loop:
    ; Добавляем текущее число с правильным знаком
    mov r8, rbx         ; копируем число
    imul r8, rdx        ; умножаем на знак
    add rax, r8         ; добавляем к сумме

    ; Меняем знак для следующей итерации
    neg rdx

    ; Переходим к следующему числу
    inc rbx
    loop .calc_loop

    mov [sum], rax      ; сохраняем результат

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Преобразование строки в число
str_to_int:
    xor rax, rax
    xor rcx, rcx

.convert_loop:
    mov cl, [rsi]
    cmp cl, 0xA         ; новая строка
    je .done
    cmp cl, 0           ; конец строки
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

; Преобразование числа в строку
int_to_str:
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdi, num_buf
    mov rbx, 10
    xor rcx, rcx

    ; Проверка на отрицательное число
    test rax, rax
    jns .positive
    neg rax
    mov byte [rdi], '-'
    inc rdi

.positive:
    ; Проверка на 0
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

    ; Извлекаем цифры из стека
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

; Вывод числа
print_number:
    push rax
    push rdi
    push rsi
    push rdx

    ; Находим длину строки
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

; Новая строка
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

; Выход
exit:
    mov rax, 60
    xor rdi, rdi
    syscall
