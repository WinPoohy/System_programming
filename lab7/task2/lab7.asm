format ELF64
public _start

; Константы
SYS_READ    = 0
SYS_WRITE   = 1
SYS_MMAP    = 9
SYS_MUNMAP  = 11
SYS_FORK    = 57
SYS_EXIT    = 60
SYS_WAIT4   = 61
SYS_NANOSLEEP = 35

STDOUT      = 1
PROT_READ   = 0x1
PROT_WRITE  = 0x2
MAP_SHARED  = 0x01
MAP_ANONY   = 0x20

; Вариант 669
COUNT       = 5
ARRAY_SIZE  = 4 + (COUNT * 4)

section '.data' writeable
    msg_start       db "Массив из 669 чисел заполнен.", 10, 0
    msg_start_len   = $ - msg_start

    msg_task0:
        db "[Процесс 1] Наиболее частая цифра: ", 0
    len_0 = $ - msg_task0

    msg_task1:
        db "[Процесс 2] Пятое число после минимального: ", 0
    len_1 = $ - msg_task1

    msg_task2:
        db "[Процесс 3] 0.75 квантиль: ", 0
    len_2 = $ - msg_task2

    msg_task3:
        db "[Процесс 4] Количество простых чисел: ", 0
    len_3 = $ - msg_task3

    newline         db 10, 0
    space           db " ", 0 ; Пробел для вывода

    array_ptr       dq 0
    data_ptr        dq 0
    seed            dd 777

    num_buffer      rb 20

    timespec:
        dq 0
        dq 1000000

section '.text' executable
_start:
    ; 1. Выделение памяти
    mov rax, SYS_MMAP   ; Номер сусколла mmap (9)
    mov rdi, 0          ; Адрес выбирает ОС
    mov rsi, ARRAY_SIZE ; Размер памяти
    mov rdx, PROT_READ or PROT_WRITE ; Чтение и запись разрешены
    mov r10, MAP_SHARED or MAP_ANONY ; Память общая и анонимная
    mov r8, -1          ; Дескриптор файла (не нужен для MAP_ANONY)
    mov r9, 0
    syscall

    cmp rax, 0
    jl exit_error

    mov [array_ptr], rax
    mov dword [rax], 0
    lea rbx, [rax + 4]
    mov [data_ptr], rbx

    ; 2. Заполнение
    mov rdi, [data_ptr]
    mov rcx, COUNT
    fill_loop:
        call rand
        mov [rdi], eax
        add rdi, 4
        loop fill_loop

        mov rax, SYS_WRITE
        mov rdi, STDOUT
        lea rsi, [msg_start]
        mov rdx, msg_start_len
        syscall

    ; Вывод массива
        mov rsi, [data_ptr] ; Указатель на данные
        mov rcx, COUNT      ; Счетчик
    print_arr_loop:
        push rcx
        push rsi

        xor rax, rax
        mov eax, [rsi]      ; Берем число
        call print_num      ; Печатаем

        mov rax, SYS_WRITE  ; Печатаем пробел
        mov rdi, STDOUT
        lea rsi, [space]
        mov rdx, 1
        syscall

        pop rsi
        add rsi, 4
        pop rcx
        loop print_arr_loop

        call print_newline

    ; 3. Форки
    mov r15, 0
    fork_loop:
        cmp r15, 4
        je wait_children

        mov rax, SYS_FORK
        syscall

        test rax, rax
        js exit_error
        jz child_process

        inc r15
        jmp fork_loop

    child_process:
        cmp r15, 0
        je task_freq_digit
        cmp r15, 1
        je task_fifth_min
        cmp r15, 2
        je task_quantile
        cmp r15, 3
        je task_primes
        jmp child_exit

    ; Первая задачка
    task_freq_digit:
        sub rsp, 80
        mov rdi, rsp
        call count_digits

        mov rcx, 0
        mov rbx, -1
        mov rdx, -1
    .find_max:
        cmp rcx, 10
        je .print
        mov rax, [rsp + rcx*8]
        cmp rax, rbx
        jle .next
        mov rbx, rax
        mov rdx, rcx
    .next:
        inc rcx
        jmp .find_max
    .print:
        mov r14, rdx
        add rsp, 80

        call wait_my_turn
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        lea rsi, [msg_task0]
        mov rdx, len_0
        syscall
        mov rax, r14
        call print_num
        call print_newline
        call pass_turn
        jmp child_exit

    ; Второй номер
    task_fifth_min:
        sub rsp, 2700
        mov rdi, rsp
        mov rsi, [data_ptr]
        mov rcx, COUNT
        rep movsd

        mov rdi, rsp
        mov rcx, COUNT
        call bubble_sort

        mov eax, [rsp + 4*4]
        mov r14, rax

        add rsp, 2700

        call wait_my_turn
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        lea rsi, [msg_task1]
        mov rdx, len_1
        syscall
        mov rax, r14
        call print_num
        call print_newline
        call pass_turn
        jmp child_exit

    ; Задачка трииииииииии
    task_quantile:
        sub rsp, 2700
        mov rdi, rsp
        mov rsi, [data_ptr]
        mov rcx, COUNT
        rep movsd

        mov rdi, rsp
        mov rcx, COUNT
        call bubble_sort

        mov eax, [rsp + 3*4]
        mov r14, rax
        add rsp, 2700

        call wait_my_turn
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        lea rsi, [msg_task2]
        mov rdx, len_2
        syscall
        mov rax, r14
        call print_num
        call print_newline
        call pass_turn
        jmp child_exit

    ; Четвертая задачка
    task_primes:
        mov rsi, [data_ptr]
        mov rcx, COUNT
        xor rbx, rbx
    .scan:
        lodsd
        call check_prime
        test dl, dl
        jz .next
        inc rbx
    .next:
        loop .scan

        mov r14, rbx

        call wait_my_turn
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        lea rsi, [msg_task3]
        mov rdx, len_3
        syscall
        mov rax, r14
        call print_num
        call print_newline
        call pass_turn
        jmp child_exit


    child_exit:
        mov rax, SYS_EXIT
        xor rdi, rdi
        syscall

    wait_children:
    .wl:
        mov rax, SYS_WAIT4
        mov rdi, -1
        xor rsi, rsi
        xor rdx, rdx
        xor r10, r10
        syscall
        cmp rax, 0
        jg .wl

        mov rax, SYS_MUNMAP
        mov rdi, [array_ptr]
        mov rsi, ARRAY_SIZE
        syscall

        mov rax, SYS_EXIT
        xor rdi, rdi
        syscall

    exit_error:
        mov rax, SYS_EXIT
        mov rdi, 1
        syscall

; Подпрограммы

bubble_sort:
    cmp rcx, 1
    jle .ret
    dec rcx
    .outer:
        push rcx
        mov rsi, rdi
        mov rdx, rcx
    .inner:
        mov eax, [rsi]
        mov ebx, [rsi+4]
        cmp eax, ebx
        jle .noswap
        mov [rsi], ebx
        mov [rsi+4], eax
    .noswap:
        add rsi, 4
        dec rdx
        jnz .inner
        pop rcx
        loop .outer
    .ret:
        ret

check_prime:
    cmp eax, 2
    jl .not
    je .yes
    test eax, 1
    jz .not
    mov r8d, 3
    .loop:
        mov r9d, r8d
        imul r9d, r9d
        cmp r9d, eax
        ja .yes
        xor edx, edx
        push rax
        div r8d
        pop rax
        test edx, edx
        jz .not
        add r8d, 2
        jmp .loop
    .yes:
        mov dl, 1
        ret
    .not:
        xor dl, dl
        ret

wait_my_turn:
    push rbx
    push rax
    push rcx
    push rdx
    push rdi
    push rsi
.check:
    mov rbx, [array_ptr]
    mov eax, [rbx]
    cmp eax, r15d
    je .ok
    mov rax, SYS_NANOSLEEP
    lea rdi, [timespec]
    xor rsi, rsi
    syscall
    jmp .check
.ok:
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rax
    pop rbx
    ret

pass_turn:
    push rbx
    mov rbx, [array_ptr]
    lock inc dword [rbx] ; Атомарно увеличиваем счетчик в общей памяти
    pop rbx
    ret

rand:
    mov eax, [seed]
    mov edx, 1103515245
    mul edx
    add eax, 12345
    mov [seed], eax
    xor edx, edx
    mov ebx, 100000
    div ebx
    mov eax, edx
    ret

count_digits:
    push rdi
    mov rcx, 10
    xor rax, rax
    rep stosq
    pop rbx

    mov rsi, [data_ptr]
    mov rcx, COUNT
.ol:
    xor rax, rax
    mov eax, [rsi]
    mov r8, 10
    test eax, eax
    jnz .il
    inc qword [rbx + 0]
    jmp .ct
.il:
    test eax, eax
    jz .ct
    xor edx, edx
    div r8d
    inc qword [rbx + rdx*8]
    jmp .il
.ct:
    add rsi, 4
    dec rcx
    jnz .ol
    ret

print_num:
    lea rsi, [num_buffer + 19]
    mov byte [rsi], 0
    mov rbx, 10
.cv:
    dec rsi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    test rax, rax
    jnz .cv
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rdx, [num_buffer + 19]
    sub rdx, rsi
    syscall
    ret
print_newline:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [newline]
    mov rdx, 1
    syscall
    ret
