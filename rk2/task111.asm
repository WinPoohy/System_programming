format ELF64

public _start

extrn initscr
extrn endwin
extrn clear
extrn refresh
extrn move
extrn addch
extrn getch
extrn timeout
extrn noecho
extrn curs_set
extrn getmaxx
extrn getmaxy

STDIN_FILENO  = 0
STDOUT_FILENO = 1
STDERR_FILENO = 2

SYS_WRITE    = 1
SYS_NANOSLEEP = 35

section '.bss' writable
    x          dq 0
    y          dq 0
    max_x      dq 0
    max_y      dq 0
    direction  dq 0      ; 0 = вправо-вниз, 1 = вправо-вверх
    speed      dq 100000 ; начальная скорость (100 мс)
    timespec:
        tv_sec  dq 0
        tv_nsec dq 0

section '.data' writable
    cursor_char db '*'

section '.text' executable

_start:
    ; Инициализация ncurses
    call initscr
    call noecho
    call curs_set   ; Скрываем стандартный курсор

    ; Получаем размеры терминала
    call getmaxy
    dec rax         ; Переводим в индексы (0-based)
    mov [max_y], rax

    call getmaxx
    dec rax
    mov [max_x], rax

    ; Начальная позиция
    mov qword [x], 0
    mov qword [y], 0
    mov qword [direction], 0

    ; Устанавливаем неблокирующий ввод
    mov rdi, 0
    call timeout

main_loop:
    ; Очищаем экран
    call clear

    ; Рисуем курсор в текущей позиции
    mov rdi, [y]
    mov rsi, [x]
    call move

    movzx rdi, byte [cursor_char]
    call addch

    ; Обновляем экран
    call refresh

    ; Обработка ввода
    call getch
    cmp rax, 'q'          ; Выход по 'q'
    je exit_program
    cmp rax, '+'          ; Увеличить скорость
    je increase_speed
    cmp rax, '-'          ; Уменьшить скорость
    je decrease_speed

    ; Двигаем курсор в зависимости от направления
    cmp qword [direction], 0
    je move_down_right

move_up_right:
    ; Движение вправо-вверх
    inc qword [x]
    dec qword [y]

    ; Проверяем достижение границ
    mov rax, [x]
    cmp rax, [max_x]
    jg .change_dir
    mov rax, [y]
    cmp rax, 0
    jl .change_dir
    jmp after_move

.change_dir:
    ; Достигли правой границы - меняем направление
    mov qword [direction], 0
    mov qword [x], 0
    mov qword [y], [max_y]
    jmp after_move

move_down_right:
    ; Движение вправо-вниз
    inc qword [x]
    inc qword [y]

    ; Проверяем достижение границ
    mov rax, [x]
    cmp rax, [max_x]
    jg .change_dir
    mov rax, [y]
    cmp rax, [max_y]
    jg .change_dir
    jmp after_move

.change_dir:
    ; Достигли нижней границы - меняем направление
    mov qword [direction], 1
    mov qword [x], 0
    mov qword [y], 0

after_move:
    ; Задержка
    call delay
    jmp main_loop

increase_speed:
    ; Увеличиваем скорость (уменьшаем задержку)
    mov rax, [speed]
    cmp rax, 10000       ; Минимальная задержка 10 мс
    jle after_move
    sub rax, 10000
    mov [speed], rax
    jmp after_move

decrease_speed:
    ; Уменьшаем скорость (увеличиваем задержку)
    mov rax, [speed]
    add rax, 10000
    cmp rax, 500000      ; Максимальная задержка 500 мс
    jg after_move
    mov [speed], rax
    jmp after_move

delay:
    ; Преобразуем микросекунды в наносекунды
    mov rax, [speed]
    mov rbx, 1000000     ; 1 мс = 1,000,000 нс
    mul rbx              ; RAX = speed * 1000000

    mov rbx, 1000000000  ; 1 секунда = 1,000,000,000 нс
    xor rdx, rdx
    div rbx              ; RDX = остаток наносекунд

    mov [tv_sec], rax    ; Секунды
    mov [tv_nsec], rdx   ; Наносекунды

    ; Системный вызов nanosleep
    mov rax, SYS_NANOSLEEP
    mov rdi, timespec
    xor rsi, rsi
    syscall
    ret

exit_program:
    call endwin

    ; Выход
    mov rax, 60          ; sys_exit
    xor rdi, rdi
    syscall
