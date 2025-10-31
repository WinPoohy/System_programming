format ELF64
public _start

section '.bss' writable
    input_fd    dq 0     ; файловый дескриптор входного файла
    output_fd   dq 0     ; файловый дескриптор выходного файла
    file_size   dq 0     ; размер файла
    file_data   rq 1     ; указатель на данные файла в памяти
    k_value     dq 0     ; начальная позиция k
    m_value     dq 0     ; значение m (радиус "раскачивания")

section '.data' writable
    usage_msg db 'Usage: program <input_file> <output_file> <k> <m>', 0xA
    usage_len = $ - usage_msg
    error_msg db 'Error processing files', 0xA
    error_len = $ - error_msg

section '.text' executable

_start:
    ; Проверяем количество аргументов командной строки
    mov rax, [rsp]        ; argc
    cmp rax, 5            ; должно быть 5 аргументов
    jge .process_args     ; если достаточно - продолжаем

    ; Выводим сообщение об использовании
    mov rax, 1
    mov rdi, 1
    mov rsi, usage_msg
    mov rdx, usage_len
    syscall
    jmp .exit

.process_args:
    ; Преобразуем k из строки в число
    mov rax, [rsp + 32]   ; argv[3] - значение k
    call str_to_int
    mov [k_value], rax

    ; Преобразуем m из строки в число
    mov rax, [rsp + 40]   ; argv[4] - значение m
    call str_to_int
    mov [m_value], rax

    ; Открываем входной файл
    mov rax, 2            ; sys_open
    mov rdi, [rsp + 16]   ; argv[1] - входной файл
    mov rsi, 0            ; O_RDONLY
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .error
    mov [input_fd], rax

    ; Определяем размер файла
    mov rax, 8            ; sys_lseek
    mov rdi, [input_fd]
    mov rsi, 0            ; смещение 0
    mov rdx, 2            ; SEEK_END (от конца файла)
    syscall
    mov [file_size], rax

    ; Возвращаемся в начало файла
    mov rax, 8            ; sys_lseek
    mov rdi, [input_fd]
    mov rsi, 0            ; смещение 0
    mov rdx, 0            ; SEEK_SET (от начала)
    syscall

    ; Выделяем память для файла
    mov rax, 9            ; sys_mmap
    mov rdi, 0            ; автоматический выбор адреса
    mov rsi, [file_size]  ; размер
    mov rdx, 1            ; PROT_READ (только чтение)
    mov r10, 2            ; MAP_PRIVATE
    mov r8, [input_fd]    ; файловый дескриптор
    mov r9, 0             ; смещение
    syscall
    cmp rax, 0
    jl .close_input
    mov [file_data], rax

    ; Закрываем входной файл (данные уже в памяти)
    mov rax, 3            ; sys_close
    mov rdi, [input_fd]
    syscall

    ; Открываем выходной файл
    mov rax, 2            ; sys_open
    mov rdi, [rsp + 24]   ; argv[2] - выходной файл
    mov rsi, 101o         ; O_WRONLY|O_CREAT|O_TRUNC
    mov rdx, 644o         ; права доступа
    syscall
    cmp rax, 0
    jl .unmap_memory
    mov [output_fd], rax

    ; Обрабатываем файл в "раскачивающемся" порядке
    call process_swing_order

    ; Закрываем выходной файл
    mov rax, 3
    mov rdi, [output_fd]
    syscall

.unmap_memory:
    ; Освобождаем память
    mov rax, 11           ; sys_munmap
    mov rdi, [file_data]
    mov rsi, [file_size]
    syscall
    jmp .exit

.close_input:
    mov rax, 3
    mov rdi, [input_fd]
    syscall

.error:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, error_len
    syscall

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

; Обработка в "раскачивающемся" порядке
process_swing_order:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, [file_data]  ; указатель на данные
    mov r13, [file_size]  ; размер файла
    mov r14, [k_value]    ; начальная позиция k
    mov r15, [m_value]    ; значение m

    ; Проверяем корректность k (должно быть в пределах файла)
    cmp r14, r13
    jge .done             ; если k >= размера файла - выходим

    ; Начинаем с позиции k
    mov rbx, 0            ; счётчик смещения

    ; Записываем начальный символ (позиция k)
    mov rax, 1            ; sys_write
    mov rdi, [output_fd]
    mov rsi, r12          ; база данных файла
    add rsi, r14          ; + позиция k
    mov rdx, 1
    syscall

    mov rbx, 1            ; начинаем с первого смещения

.swing_loop:
    ; Проверяем достигли ли границ и не превысили ли m
    cmp rbx, r15
    jg .done              ; если смещение > m - заканчиваем

    ; === ПРАВАЯ ПОЗИЦИЯ (k + смещение) ===
    mov rax, r14          ; начальная позиция
    add rax, rbx          ; + смещение
    cmp rax, r13          ; проверяем правую границу
    jge .check_left       ; если вышли за правую границу

    ; Записываем символ справа
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, r12          ; база
    add rsi, r14          ; + k
    add rsi, rbx          ; + смещение
    mov rdx, 1
    syscall

    ; === ЛЕВАЯ ПОЗИЦИЯ (k - смещение) ===
    mov rax, r14          ; начальная позиция
    sub rax, rbx          ; - смещение
    cmp rax, 0            ; проверяем левую границу
    jl .next_offset       ; если вышли за левую границу

    ; Записываем символ слева
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, r12          ; база
    add rsi, r14          ; + k
    sub rsi, rbx          ; - смещение
    mov rdx, 1
    syscall

.next_offset:
    ; Увеличиваем смещение
    inc rbx
    jmp .swing_loop

.check_left:
    ; Проверяем есть ли символы слева
    mov rax, r14
    sub rax, rbx
    cmp rax, 0
    jl .done              ; если и слева нет символов - заканчиваем

    ; Записываем только левый символ
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, r12          ; база
    add rsi, r14          ; + k
    sub rsi, rbx          ; - смещение
    mov rdx, 1
    syscall
    inc rbx
    jmp .check_left

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Функция преобразования строки в число
str_to_int:
    push rbx
    push rcx
    push rdx
    push rsi

    mov rsi, rax          ; указатель на строку
    xor rax, rax          ; результат
    xor rcx, rcx          ; счётчик

.convert_loop:
    mov cl, [rsi]         ; текущий символ
    cmp cl, 0             ; конец строки?
    je .done
    cmp cl, '0'
    jl .done
    cmp cl, '9'
    jg .done

    sub cl, '0'           ; символ -> цифра
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .convert_loop

.done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
