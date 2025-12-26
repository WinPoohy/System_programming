format ELF64
public main
extrn printf
extrn scanf
extrn exit

section '.data' writeable
    ; Строки форматов
    input_fmt       db "%lf", 0
    header_fmt      db 10, "%-10s | %-12s | %-6s | %-12s | %-12s", 10, 0
    line_fmt        db "-----------|--------------|--------|--------------|--------------", 10, 0
    row_fmt         db "%-10.4f | %-12.8f | %-6d | %-12.8f | %-12.8f", 10, 0

    ; Заголовки столбцов
    s_x             db "x", 0
    s_eps           db "epsilon", 0
    s_n             db "terms", 0
    s_sum           db "series sum", 0
    s_formula       db "formula", 0

    msg_x           db "Enter x (PI/5 <= x <= PI): ", 0
    msg_eps         db "Enter epsilon: ", 0

    ; Переменные
    x               rq 1
    epsilon         rq 1
    series_res      rq 1
    formula_res     rq 1
    term_count      rq 1

    ; Константы
    val_3           dq 3.0
    val_4           dq 4.0
    temp_n          rq 1

section '.text' executable

main:
    ; 1. Ввод данных
    mov rdi, msg_x
    xor rax, rax
    call printf

    mov rdi, input_fmt
    mov rsi, x
    xor rax, rax
    call scanf

    mov rdi, msg_eps
    xor rax, rax
    call printf

    mov rdi, input_fmt
    mov rsi, epsilon
    xor rax, rax
    call scanf

    ; 2. Расчет по формуле: 1/4 * (x^2 - pi^2/3)
    finit
    fldpi               ; st0 = pi
    fmul st0, st0       ; st0 = pi^2
    fdiv qword [val_3]  ; st0 = pi^2 / 3

    fld qword [x]       ; st0 = x, st1 = pi^2/3
    fmul st0, st0       ; st0 = x^2, st1 = pi^2/3

    fsubrp st1, st0     ; st0 = x^2 - pi^2/3
    fdiv qword [val_4]  ; st0 = (x^2 - pi^2/3) / 4
    fstp qword [formula_res]

    ; 3. Вычисление суммы ряда
    call calc_series

    ; 4. Вывод таблицы
    mov rdi, header_fmt
    mov rsi, s_x
    mov rdx, s_eps
    mov rcx, s_n
    mov r8, s_sum
    mov r9, s_formula
    xor rax, rax
    call printf

    mov rdi, line_fmt
    xor rax, rax
    call printf

    mov rdi, row_fmt
    movq xmm0, [x]
    movq xmm1, [epsilon]
    mov rsi, [term_count]
    movq xmm2, [series_res]
    movq xmm3, [formula_res]
    mov rax, 4          ; 4 float аргумента (xmm0-xmm3)
    call printf

    ; Выход
    xor rdi, rdi
    call exit

; Процедура вычисления ряда
calc_series:
    finit
    fldz                ; st0 = 0.0 (сумма)
    mov qword [term_count], 0

    .loop:
        inc qword [term_count]

        ; Считаем cos(nx)
        fld qword [x]
        mov rax, [term_count]
        mov [temp_n], rax
        fild qword [temp_n] ; st0 = n, st1 = x, st2 = sum
        fmul st0, st1       ; st0 = n*x
        fcos                ; st0 = cos(nx)

        ; Убираем x из стека
        fxch st1
        fstp st0            ; st0 = cos(nx), st1 = sum

        ; Делим на n^2
        fild qword [temp_n]
        fmul st0, st0       ; st0 = n^2
        fdivp st1, st0      ; st0 = cos(nx)/n^2, st1 = sum

        ; Учет знака (-1)^n
        mov rax, [term_count]
        test rax, 1
        jz .apply_sum       ; Если четное (n=2, 4...), знак "+" (уже есть)
        fchs                ; Если нечетное, меняем знак на "-"

    .apply_sum:
        ; Проверка точности ПЕРЕД прибавлением (или сохранение для проверки)
        fst qword [temp_n]  ; используем temp_n как буфер для текущего члена
        faddp st1, st0      ; st0 = новая сумма

        ; Проверяем |слагаемое| < epsilon
        fld qword [temp_n]
        fabs
        fld qword [epsilon]
        fcomip st1          ; сравниваем eps и |term|
        fstp st0            ; очищаем стек от |term|

        jbe .loop           ; если eps <= |term|, продолжаем

    fstp qword [series_res]
    ret
