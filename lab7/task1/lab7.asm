format ELF64
public _start

section '.data' writeable
    prompt db "Введите команду (например, /bin/ls или ./lab5): ", 0
    prompt_len = $ - prompt

    error_msg db "Ошибка: не удалось найти или запустить программу", 10, 0
    error_len = $ - error_msg

    input_buffer rb 256

    ; Массив аргументов: argv[0] - указатель на строку, argv[1] - NULL
    align 8
    argv dq 0, 0

    envp_addr dq 0
    status dd 0

section '.text' executable
_start:
    ; 1. Извлечение envp из стека
    pop rcx                 ; rcx = argc
    lea rsi, [rsp + rcx*8 + 8]
    mov [envp_addr], rsi    ; Сохраняем адрес начала массива envp

main_loop:
    ; 2. Вывод приглашения
    mov rax, 1              ; sys_write
    mov rdi, 1
    lea rsi, [prompt]
    mov rdx, prompt_len
    syscall

    ; 3. Чтение ввода
    mov rax, 0              ; sys_read
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 255
    syscall

    ; Если ошибка чтения или пустой ввод
    cmp rax, 1
    jle main_loop

    ; 4. Корректная замена символа новой строки на 0
    ; Проходим по строке и заменяем \n или \r на 0
    mov rcx, rax
    lea rdi, [input_buffer]
    mov al, 10              ; '\n'
    repne scasb
    jne .no_newline
    mov byte [rdi-1], 0
.no_newline:

    ; 5. Создание процесса (fork)
    mov rax, 57             ; sys_fork
    syscall

    test rax, rax
    js main_loop            ; Ошибка fork - возвращаемся
    jz child_process        ; Потомок

parent_process:
    ; 6. Ожидание завершения потомка
    mov rdi, rax            ; PID потомка
    mov rax, 61             ; sys_wait4
    lea rsi, [status]
    xor rdx, rdx
    xor r10, r10
    syscall
    jmp main_loop

child_process:
    ; --- ПАРСИНГ АРГУМЕНТОВ ---
    lea rsi, [input_buffer] ; Начало строки
    lea rdi, [argv]         ; Куда пишем указатели на аргументы
    xor rcx, rcx            ; Счетчик аргументов

.parse_loop:
    ; Пропускаем ведущие пробелы
.skip_spaces:
    cmp byte [rsi], ' '
    jne .found_arg
    inc rsi
    jmp .skip_spaces

.found_arg:
    cmp byte [rsi], 0       ; Конец строки?
    je .done_parsing

    mov [rdi + rcx*8], rsi  ; Сохраняем указатель на начало аргумента в argv
    inc rcx

    ; Ищем конец текущего аргумента (пробел или ноль)
.find_end:
    cmp byte [rsi], ' '
    je .terminate_arg
    cmp byte [rsi], 0
    je .done_parsing
    inc rsi
    jmp .find_end

.terminate_arg:
    mov byte [rsi], 0       ; Ставим нуль-терминатор в конце аргумента
    inc rsi
    jmp .parse_loop

.done_parsing:
    mov qword [rdi + rcx*8], 0 ; Последний элемент argv должен быть NULL

    ; --- ЗАПУСК ---
    mov rax, 59             ; sys_execve
    mov rdi, [argv]         ; Путь к файлу (первый аргумент)
    lea rsi, [argv]         ; Весь массив аргументов
    mov rdx, [envp_addr]    ; Окружение
    syscall

    ; Если мы здесь, значит execve не сработал
    mov rax, 1
    mov rdi, 1
    lea rsi, [error_msg]
    mov rdx, error_len
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall
