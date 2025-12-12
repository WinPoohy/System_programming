format ELF64
public _start

; Подключаем функции ncurses
extrn initscr
extrn start_color
extrn init_pair
extrn getmaxx
extrn getmaxy
extrn raw
extrn noecho
extrn keypad
extrn stdscr
extrn move
extrn getch
extrn refresh
extrn endwin
extrn timeout
extrn usleep
extrn mvaddch
extrn curs_set
extrn addstr
extrn attron
extrn attroff

; Константы клавиш
KEY_FAST  = 'w'
KEY_SLOW  = 's'
KEY_QUIT  = 'q'

section '.bss' writable
    ; Текущие координаты
    x           dq 0
    y           dq 0

    ; Границы экрана
    scr_w       dq 0
    scr_h       dq 0

    ; Границы текущего витка спирали
    min_x       dq 0
    max_x       dq 0
    min_y       dq 0
    max_y       dq 0

    ; Состояние движения
    dir         dq 0        ; 0:Влево, 1:Вниз, 2:Вправо, 3:Вверх

    delay       dq 60000
    speed_level dq 3
    color_idx   dq 1        ; Текущий индекс цвета (1-6)

section '.data' writable
    cursor_char db '*'      ; Символ следа
    usage_msg   db 'Spiral Control: W - Faster, S - Slower, Q - Quit', 0

section '.text' executable

_start:
    call initscr

    xor rdi, rdi
    call curs_set

    call start_color

    mov rdi, 1
    mov rsi, 1
    mov rdx, 0
    call init_pair

    mov rdi, 2
    mov rsi, 2
    mov rdx, 0
    call init_pair

    mov rdi, 3
    mov rsi, 3
    mov rdx, 0
    call init_pair

    mov rdi, 4
    mov rsi, 4
    mov rdx, 0
    call init_pair

    mov rdi, 5
    mov rsi, 5
    mov rdx, 0
    call init_pair

    mov rdi, 6
    mov rsi, 6
    mov rdx, 0
    call init_pair

    ; Настройка режима терминала
    call refresh
    call noecho
    call raw

    ; Таймаут для getch
    mov rdi, 1
    call timeout

    mov rdi, [stdscr]
    call getmaxx
    mov [scr_w], rax

    call getmaxy
    mov [scr_h], rax

    mov rdi, 0
    mov rsi, 0
    call move
    lea rdi, [usage_msg]
    call addstr

    call reset_spiral_state

.main_loop:
    ; Макрос COLOR_PAIR(n) обычно сдвигает n на 8 бит
    mov rax, [color_idx]
    shl rax, 8
    mov rdi, rax
    call attron

    ; Рисуем символ
    mov rdi, [y]
    mov rsi, [x]
    movzx rdx, byte [cursor_char]
    call mvaddch

    ; Выключаем цвет (attroff)
    mov rax, [color_idx]
    shl rax, 8
    mov rdi, rax
    call attroff

    call refresh

    mov rdi, [delay]
    call usleep

    call getch

    cmp rax, KEY_QUIT
    je .end_program

    cmp rax, KEY_FAST
    je .increase_speed

    cmp rax, KEY_SLOW
    je .decrease_speed

    jmp .update_position

.increase_speed:
    cmp qword [speed_level], 10
    jge .update_position
    inc qword [speed_level]
    jmp .recalc_delay

.decrease_speed:
    cmp qword [speed_level], 1
    jle .update_position
    dec qword [speed_level]

.recalc_delay:
    ; Простая формула задержки: (11 - speed) * 10000
    mov rax, 11
    sub rax, [speed_level]
    imul rax, 10000
    mov [delay], rax

.update_position:
    mov rax, [dir]

    cmp rax, 0
    je .move_left
    cmp rax, 1
    je .move_down
    cmp rax, 2
    je .move_right
    cmp rax, 3
    je .move_up

    jmp .check_completion

.move_left:
    dec qword [x]

    ; Проверка достижения левой границы
    mov rax, [x]
    cmp rax, [min_x]
    jl .turn_down
    jmp .check_completion

.turn_down:
    ; (так как ушли на -1)
    mov rax, [min_x]
    mov [x], rax

    mov qword [dir], 1
    inc qword [min_y]

    inc qword [y]
    jmp .check_completion

.move_down:
    inc qword [y]

    mov rax, [y]
    cmp rax, [max_y]
    jg .turn_right
    jmp .check_completion

.turn_right:
    mov rax, [max_y]
    mov [y], rax

    mov qword [dir], 2     ; Вправо
    inc qword [min_x]      ; Левая граница сдвигается вправо

    inc qword [x]
    jmp .check_completion

.move_right:
    inc qword [x]

    mov rax, [x]
    cmp rax, [max_x]
    jg .turn_up
    jmp .check_completion

.turn_up:
    mov rax, [max_x]
    mov [x], rax

    mov qword [dir], 3     ; Вверх
    dec qword [max_y]      ; Нижняя граница поднимается

    dec qword [y]
    jmp .check_completion

.move_up:
    dec qword [y]

    mov rax, [y]
    cmp rax, [min_y]
    jl .turn_left
    jmp .check_completion

.turn_left:
    mov rax, [min_y]
    mov [y], rax

    mov qword [dir], 0     ; Влево
    dec qword [max_x]      ; Правая граница сдвигается влево

    dec qword [x]
    jmp .check_completion

.check_completion:
    ; Условие: min_x > max_x & min_y > max_y
    mov rax, [min_x]
    cmp rax, [max_x]
    jg .restart_spiral

    mov rax, [min_y]
    cmp rax, [max_y]
    jg .restart_spiral

    jmp .main_loop

.restart_spiral:
    ; Меняем цвет
    inc qword [color_idx]
    cmp qword [color_idx], 6
    jle .do_reset
    mov qword [color_idx], 1 ; Сброс на первый цвет

.do_reset:
    call reset_spiral_state
    jmp .main_loop

.end_program:
    mov rdi, 1
    call curs_set
    call endwin

    mov rax, 60
    xor rdi, rdi
    syscall

reset_spiral_state:
    ; Сброс границ на полный экран
    mov qword [min_x], 0
    mov qword [min_y], 0        ; 0 или 1, если хотим пропустить заголовок

    mov rax, [scr_w]
    dec rax
    mov [max_x], rax

    mov rax, [scr_h]
    dec rax
    mov [max_y], rax

    mov rax, [max_x]
    mov [x], rax

    mov rax, [min_y]
    mov [y], rax

    mov qword [dir], 0
    ret
