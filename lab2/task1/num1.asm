format elf64
public _start

section '.text' executable
_start:
    ; Получаем аргумент командной строки
    pop rax                ; argc
    cmp rax, 2
    jl .error              ; если аргументов меньше 2 - ошибка

    pop rax                ; argv[0] - имя программы
    pop rdi                ; argv[1] - параметр n

    ; Конвертируем строку в число
    xor rax, rax
    xor rcx, rcx
    .convert:
        mov cl, byte [rdi]
        test cl, cl
        jz .converted
        sub cl, '0'
        imul rax, 10
        add rax, rcx
        inc rdi
        jmp .convert

    .converted:
    mov r8, rax           ; r8 = n
    xor r9, r9            ; r9 = общая сумма
    mov r10, 1            ; r10 = k (текущее число)

    .loop:
        cmp r10, r8
        jg .print_result

        ; Находим первую цифру числа r10
        mov rax, r10
        mov r11, 10
        .find_first_digit:
            xor rdx, rdx
            div r11
            test rax, rax
            jz .found_first_digit
            mov r12, rax
            jmp .find_first_digit

        .found_first_digit:
        test rdx, rdx
        jnz .use_remainder
        mov rdx, r12      ; если делится нацело, берем частное

        .use_remainder:
        ; Умножаем k на первую цифру и добавляем к сумме
        mov rax, r10
        imul rax, rdx
        add r9, rax

        inc r10
        jmp .loop

    .print_result:
        ; Преобразуем результат в строку для вывода
        mov rax, r9
        mov rdi, buffer + 63
        mov rcx, 10
        mov byte [rdi], 0xA  ; новая строка

        .convert_loop:
            dec rdi
            xor rdx, rdx
            div rcx
            add dl, '0'
            mov [rdi], dl
            test rax, rax
            jnz .convert_loop

        ; Вывод результата
        mov rax, 4
        mov rbx, 1
        mov rcx, rdi
        mov rdx, buffer + 64
        sub rdx, rcx
        int 0x80

        jmp exit

    .error:
        ; Вывод сообщения об ошибке
        mov rax, 4
        mov rbx, 1
        mov rcx, error_msg
        mov rdx, error_len
        int 0x80

        jmp exit

exit:
    mov rax, 1
    xor rbx, rbx
    int 0x80

section '.data' writeable
    error_msg db "Error: missing argument n", 0xA
    error_len = $ - error_msg

section '.bss' writeable
    buffer rb 64
