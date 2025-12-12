format ELF64
public _start
include "func.asm"

; --- СИСТЕМНЫЕ ВЫЗОВЫ ---
SYS_WRITE   = 1
SYS_EXIT    = 60
SYS_FORK    = 57
SYS_MMAP    = 9
SYS_MUNMAP  = 11
SYS_WAIT4   = 61

; --- КОНСТАНТЫ MMAP ---
PROT_READ   = 0x1
PROT_WRITE  = 0x2
MAP_SHARED  = 0x01
MAP_ANONY   = 0x20
STDOUT      = 1

section '.bss' writable
    N           dq 0
    array_ptr   dq 0
    array_size  dq 0
    buffer      rb 20
    pid1        dq 0
    pid2        dq 0
    temp_buffer rb 20

section '.data' writable
    usage_msg   db 'Использование: program <N> (N > 0)', 0xA
    usage_len   = $ - usage_msg
    error_msg   db 'Ошибка: Не удалось выделить память или создать процесс.', 0xA
    error_len   = $ - error_msg

    msg_init    db 'Исходный массив: ', 0
    msg_final   db 0xA, 'Финальный массив: ', 0
    comma_space db ', ', 0
    exit_msg    db 0xA, "Программа завершена.", 0xA, 0

section '.text' executable

_start:
    ; Обработка аргументов (N)
    pop rax
    cmp rax, 2
    jl print_usage

    ; Парсинг N (argv[1])
    mov rsi, [rsp+8]
    call str_number
    mov [N], rax

    ; Проверка N > 0
    cmp rax, 0
    jle print_usage

    ; Выделение общей памяти (mmap)
    call allocate_shared_memory

    ; Инициализация массива (1, 2, 3, ..., N)
    call initialize_array

    ; Вывод исходного массива
    mov rsi, msg_init
    call print_str
    call print_array
    call new_line

    ; Создание двух процессов
    mov rax, SYS_FORK
    syscall

    cmp rax, 0
    jl exit_error
    jz child_even
    mov [pid1], rax

    mov rax, SYS_FORK
    syscall

    cmp rax, 0
    jl exit_error
    jz child_odd
    mov [pid2], rax

    jmp parent_process

; Логика детей
child_even:
    mov rsi, [array_ptr]
    add rsi, 4              ; RSI = &array[1] (Начинаем со смещения 4 байта, 1-й индекс)
    mov rcx, [N]
    shr rcx, 1              ; RCX = N / 2

    .loop:
        cmp rcx, 0
        je child_exit

        xor rax, rax
        mov eax, [rsi]

        test eax, 1
        jnz .next

        inc dword [rsi]

    .next:
        add rsi, 8
        dec rcx
        jmp .loop

child_odd:
    mov rsi, [array_ptr]    ; RSI = &array[0] (Начало массива, 0-й индекс)
    mov rcx, [N]
    shr rcx, 1              ; RCX = N / 2 (Количество итераций)

    .loop:
        cmp rcx, 0
        je child_exit

        xor rax, rax
        mov eax, [rsi]

        test eax, 1
        jz .next

        dec dword [rsi]

    .next:
        add rsi, 8
        dec rcx
        jmp .loop

child_exit:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Родитель
parent_process:
    mov rax, SYS_WAIT4
    mov rdi, [pid1]
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall

    mov rax, SYS_WAIT4
    mov rdi, [pid2]
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall

    mov rsi, msg_final
    call print_str
    call print_array

    mov rax, SYS_MUNMAP
    mov rdi, [array_ptr]
    mov rsi, [array_size]
    syscall

    mov rsi, exit_msg
    call print_str
    call exit


allocate_shared_memory:
    mov rax, [N]
    shl rax, 2
    mov [array_size], rax

    mov rax, SYS_MMAP
    xor rdi, rdi
    mov rsi, [array_size]
    mov rdx, PROT_READ or PROT_WRITE
    mov r10, MAP_SHARED or MAP_ANONY
    mov r8, -1
    xor r9, r9
    syscall

    cmp rax, 0
    jl exit_error
    mov [array_ptr], rax
    ret

initialize_array:
    mov rdi, [array_ptr]
    mov rbx, 1
    mov rcx, [N]

    .loop:
        cmp rcx, 0
        je .done

        mov [rdi], ebx
        inc rbx
        add rdi, 4
        dec rcx
        jmp .loop

    .done:
    ret

print_array:
    push rbx
    push r12
    push r13

    mov r12, [array_ptr]   ; Сохраняем указатель на массив
    mov r13, [N]           ; Сохраняем размер массива
    xor rbx, rbx           ; Индекс элемента (0 для первого)

    .print_loop:
        cmp rbx, r13
        jge .done

        ; Если не первый элемент, печатаем запятую
        cmp rbx, 0
        je .skip_comma
        push rsi
        mov rsi, comma_space
        call print_str
        pop rsi

    .skip_comma:
        ; Получаем текущий элемент
        xor rax, rax
        mov eax, [r12]     ; Загружаем 32-битное число

        ; Сохраняем регистры
        push rsi
        push rbx
        push r12

        ; Преобразуем число в строку
        lea rsi, [temp_buffer]
        call number_str

        ; Печатаем число
        call print_str

        ; Восстанавливаем регистры
        pop r12
        pop rbx
        pop rsi

        ; Переходим к следующему элементу
        add r12, 4
        inc rbx
        jmp .print_loop

    .done:
    call new_line

    pop r13
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------
; ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
; ---------------------------------------------------------

exit_error:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [error_msg]
    mov rdx, error_len
    syscall

    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

print_usage:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [usage_msg]
    mov rdx, usage_len
    syscall

    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
