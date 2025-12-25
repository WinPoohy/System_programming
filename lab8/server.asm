format ELF64
public _start

SYS_WRITE       = 1
SYS_CLOSE       = 3
SYS_SOCKET      = 41
SYS_ACCEPT      = 43
SYS_BIND        = 49
SYS_LISTEN      = 50
SYS_EXIT        = 60

AF_INET         = 2
SOCK_STREAM     = 1
INADDR_ANY      = 0
PORT            = 7777

section '.data' writeable
    msg_start       db '[Server] TIC-TAC-TOE ready on 7777...', 10, 0
    msg_client      db '[Client connected]', 10, 0

    ; Буферы
    recv_buf        rb 256
    send_buf        rb 2048

    serv_addr:
        dw AF_INET
        db 0x1E, 0x61       ; Port 7777
        dd INADDR_ANY
        dq 0

    sockfd          dq 0
    clientfd        dq 0

    ; Игровое состояние
    ; Доска 9 байт. Изначально '1'..'9'.
    ; Игрок = 'O', Сервер = 'X'
    board           db '1','2','3','4','5','6','7','8','9'
    moves_count     dq 0
    seed            dq 987654321

section '.text' executable
_start:
    ; Сетевая инициализация (как в Blackjack)
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, 0
    syscall
    mov [sockfd], rax

    mov rax, SYS_BIND
    mov rdi, [sockfd]
    mov rsi, serv_addr
    mov rdx, 16
    syscall

    mov rax, SYS_LISTEN
    mov rdi, [sockfd]
    mov rsi, 1
    syscall

    mov rsi, msg_start
    call print_string

accept_loop:
    mov rax, SYS_ACCEPT
    mov rdi, [sockfd]
    mov rsi, 0
    mov rdx, 0
    syscall
    mov [clientfd], rax

    mov rsi, msg_client
    call print_string

new_game:
    call reset_board
    call send_board

game_loop:
    ; Ждем ход игрока
    mov rax, 0
    mov rdi, [clientfd]
    mov rsi, recv_buf
    mov rdx, 255
    syscall

    cmp rax, 0
    jle close_client

    mov al, byte [recv_buf]

    ; Если ввели 'q' или 'r'
    cmp al, 'q'
    je close_client
    cmp al, 'r'
    je new_game

    ; Проверяем ввод (от '1' до '9')
    sub al, '1'     ; конвертируем ASCII '1'..'9' в число 0..8
    cmp al, 0
    jl game_loop    ; если меньше 0 - игнор
    cmp al, 8
    jg game_loop    ; если больше 8 - игнор

    ; Проверяем, свободна ли клетка
    movzx rbx, al
    lea rcx, [board + rbx]
    cmp byte [rcx], 'X'
    je game_loop
    cmp byte [rcx], 'O'
    je game_loop

    ; --- ХОД ИГРОКА ---
    mov byte [rcx], 'O' ; Ставим нолик
    inc qword [moves_count]

    ; Проверка победы игрока
    call check_win
    cmp rax, 1
    je player_wins

    ; Проверка ничьей
    cmp qword [moves_count], 9
    jge draw_game

    ; --- ХОД СЕРВЕРА (AI) ---
    call make_server_move

    ; Проверка победы сервера
    call check_win
    cmp rax, 1
    je server_wins

    ; Проверка ничьей после хода сервера
    cmp qword [moves_count], 9
    jge draw_game

    ; Продолжаем игру
    call send_board
    jmp game_loop

; --- ЗАВЕРШЕНИЕ РАУНДА ---
player_wins:
    mov rdi, send_buf
    call draw_board_to_buf
    mov rax, msg_you_win
    call strcat
    call send_final_buffer
    jmp wait_restart

server_wins:
    mov rdi, send_buf
    call draw_board_to_buf
    mov rax, msg_server_wins
    call strcat
    call send_final_buffer
    jmp wait_restart

draw_game:
    mov rdi, send_buf
    call draw_board_to_buf
    mov rax, msg_draw
    call strcat
    call send_final_buffer
    jmp wait_restart

wait_restart:
    ; Просто ждем любой ввод чтобы начать заново
    mov rax, 0
    mov rdi, [clientfd]
    mov rsi, recv_buf
    mov rdx, 255
    syscall
    cmp rax, 0
    jle close_client
    jmp new_game

close_client:
    mov rax, SYS_CLOSE
    mov rdi, [clientfd]
    syscall
    jmp accept_loop

; =========================================
; ЛОГИКА ИГРЫ
; =========================================

reset_board:
    mov rcx, 9
    mov rbx, 0
.loop:
    mov al, bl
    add al, '1'
    mov [board + rbx], al
    inc rbx
    loop .loop
    mov qword [moves_count], 0
    ret

; Случайный (но корректный) ход сервера
make_server_move:
    ; Простой алгоритм: пробуем случайные клетки пока не найдем пустую
    ; Если доска почти полная, это может занять пару циклов, но для 3x3 это мгновенно.
.try_again:
    call rand
    xor rdx, rdx
    mov rbx, 9
    div rbx         ; rdx = 0..8

    lea rbx, [board + rdx]
    cmp byte [rbx], 'X'
    je .try_again
    cmp byte [rbx], 'O'
    je .try_again

    mov byte [rbx], 'X'
    inc qword [moves_count]
    ret

; Проверка победы
; Возвращает RAX=1 если кто-то выиграл, RAX=0 если нет
check_win:
    ; Варианты победы:
    ; 0,1,2 | 3,4,5 | 6,7,8 (строки)
    ; 0,3,6 | 1,4,7 | 2,5,8 (столбцы)
    ; 0,4,8 | 2,4,6 (диагонали)

    ; Строки
    mov rsi, 0
    mov rdi, 1
    mov rdx, 2
    call check_line
    cmp rax, 1
    je .win

    mov rsi, 3
    mov rdi, 4
    mov rdx, 5
    call check_line
    cmp rax, 1
    je .win

    mov rsi, 6
    mov rdi, 7
    mov rdx, 8
    call check_line
    cmp rax, 1
    je .win

    ; Столбцы
    mov rsi, 0
    mov rdi, 3
    mov rdx, 6
    call check_line
    cmp rax, 1
    je .win

    mov rsi, 1
    mov rdi, 4
    mov rdx, 7
    call check_line
    cmp rax, 1
    je .win

    mov rsi, 2
    mov rdi, 5
    mov rdx, 8
    call check_line
    cmp rax, 1
    je .win

    ; Диагонали
    mov rsi, 0
    mov rdi, 4
    mov rdx, 8
    call check_line
    cmp rax, 1
    je .win

    mov rsi, 2
    mov rdi, 4
    mov rdx, 6
    call check_line
    cmp rax, 1
    je .win

    mov rax, 0
    ret
.win:
    mov rax, 1
    ret

; Вспомогательная: проверяет равны ли 3 ячейки (RSI, RDI, RDX)
check_line:
    mov al, [board + rsi]
    mov bl, [board + rdi]
    cmp al, bl
    jne .no
    mov bl, [board + rdx]
    cmp al, bl
    jne .no
    mov rax, 1 ; Equal
    ret
.no:
    xor rax, rax
    ret

; =========================================
; ГРАФИКА (ASCII)
; =========================================

send_board:
    mov rdi, send_buf
    call draw_board_to_buf
    mov rax, msg_prompt
    call strcat
    call send_final_buffer
    ret

send_final_buffer:
    mov rsi, send_buf
    call send_string
    ret

draw_board_to_buf:
    ; Очистка экрана (ANSI escape codes)
    mov dword [rdi], 0x635B1B ; ESC[c (reset) - упрощенно просто newline
    mov byte [rdi], 10
    inc rdi

    ; Рисуем сетку
    ; Line 1
    mov byte [rdi], ' '
    inc rdi
    mov al, [board+0]
    mov [rdi], al
    inc rdi
    mov dword [rdi], ' | '
    add rdi, 3
    mov al, [board+1]
    mov [rdi], al
    inc rdi
    mov dword [rdi], ' | '
    add rdi, 3
    mov al, [board+2]
    mov [rdi], al
    inc rdi
    mov byte [rdi], 10
    inc rdi

    ; Sep 1
    mov dword [rdi], '---+'
    add rdi, 4
    mov dword [rdi], '---+'
    add rdi, 4
    mov dword [rdi], '---'
    mov byte [rdi+3], 10
    add rdi, 4

    ; Line 2
    mov byte [rdi], ' '
    inc rdi
    mov al, [board+3]
    mov [rdi], al
    inc rdi
    mov dword [rdi], ' | '
    add rdi, 3
    mov al, [board+4]
    mov [rdi], al
    inc rdi
    mov dword [rdi], ' | '
    add rdi, 3
    mov al, [board+5]
    mov [rdi], al
    inc rdi
    mov byte [rdi], 10
    inc rdi

    ; Sep 2
    mov dword [rdi], '---+'
    add rdi, 4
    mov dword [rdi], '---+'
    add rdi, 4
    mov dword [rdi], '---'
    mov byte [rdi+3], 10
    add rdi, 4

    ; Line 3
    mov byte [rdi], ' '
    inc rdi
    mov al, [board+6]
    mov [rdi], al
    inc rdi
    mov dword [rdi], ' | '
    add rdi, 3
    mov al, [board+7]
    mov [rdi], al
    inc rdi
    mov dword [rdi], ' | '
    add rdi, 3
    mov al, [board+8]
    mov [rdi], al
    inc rdi
    mov byte [rdi], 10
    inc rdi

    mov byte [rdi], 0
    ret

strcat:
    ; Присоединяет строку из RAX к буферу в RDI
    push rsi
    mov rsi, rax
.copy:
    lodsb
    test al, al
    jz .done
    stosb
    jmp .copy
.done:
    mov byte [rdi], 0
    pop rsi
    ret

; =========================================
; УТИЛИТЫ
; =========================================
rand:
    push rbx
    push rcx
    push rdx
    mov rax, [seed]
    mov rbx, 6364136223846793005
    mul rbx
    mov rcx, 1442695040888963407
    add rax, rcx
    mov [seed], rax
    pop rdx
    pop rcx
    pop rbx
    ret

send_string:
    push rdi
    push rax
    push rdx
    push rcx
    mov rdi, rsi
    call strlen
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, [clientfd]
    syscall
    pop rcx
    pop rdx
    pop rax
    pop rdi
    ret

print_string:
    push rdi
    push rax
    push rdx
    push rcx
    mov rdi, rsi
    call strlen
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    pop rcx
    pop rdx
    pop rax
    pop rdi
    ret

strlen:
    xor rax, rax
.L: cmp byte [rdi + rax], 0
    je .D
    inc rax
    jmp .L
.D: ret

section '.data'
    msg_prompt      db 10, 'Your turn (O). Enter 1-9: ', 0
    msg_you_win     db 10, '*** YOU WIN! ***', 10, 'Press any key to restart...', 0
    msg_server_wins db 10, '--- SERVER WINS ---', 10, 'Press any key to restart...', 0
    msg_draw        db 10, '=== DRAW ===', 10, 'Press any key to restart...', 0
