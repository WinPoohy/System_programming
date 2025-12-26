; array.asm
format ELF64

public create_array
public free_array
public add_to_end
public remove_from_start
public is_empty
public fill_random
public remove_even_numbers
public count_ends_with_one
public print_array

section '.data' writable
newline db 10, 0
space db " ", 0
empty_msg db "Array is empty", 10, 0
initial_capacity dq 4
random_seed dq 0

section '.bss' writable
temp_buffer rb 32

section '.text' executable

mem_alloc:
    push rdi rsi rdx r10 r8 r9 rcx

    mov rsi, rdi        ; length
    mov rax, 9          ; sys_mmap (syscall #9)
    xor rdi, rdi        ; addr = NULL (система выбирает адрес)
    mov rdx, 3          ; PROT_READ | PROT_WRITE (3)
    mov r10, 34         ; MAP_PRIVATE | MAP_ANONYMOUS (0x22)
    mov r8, -1          ; fd = -1 (для анонимной памяти)
    xor r9, r9          ; offset = 0
    syscall

    pop rcx r9 r8 r10 rdx rsi rdi
    ret

mem_free:
    push rax rdi rsi rcx

    mov rax, 11         ; sys_munmap (syscall #11)
    syscall

    pop rcx rsi rdi rax
    ret

; Array* create_array()
create_array:
    push rdi rsi

    mov rdi, 24
    call mem_alloc
    test rax, rax
    js .error           ; ошибка

    mov rsi, rax        ; rsi = указатель на структуру

    ; Инициализация полей
    mov qword [rsi], 0        ; data = NULL
    mov qword [rsi + 8], 0    ; capacity = 0
    mov qword [rsi + 16], 0   ; size = 0

    mov rdi, [initial_capacity]
    shl rdi, 3

    push rsi
    call mem_alloc
    pop rsi

    test rax, rax
    js .error_struct

    ; Заполняем структуру
    mov [rsi], rax
    mov rdx, [initial_capacity]
    mov [rsi + 8], rdx
    mov qword [rsi + 16], 0

    mov rax, rsi
    jmp .done

.error_struct:
    mov rdi, rsi
    mov rsi, 24
    call mem_free
.error:
    xor rax, rax
.done:
    pop rsi rdi
    ret

; фри array(Array* arr)
free_array:
    push rdi rsi rbx

    test rdi, rdi
    jz .done

    mov rbx, rdi        ; Сохраняем указатель на структуру

    ; Освобождаем массив данных
    mov rdi, [rbx]
    test rdi, rdi
    jz .free_struct

    mov rsi, [rbx + 8]
    shl rsi, 3          ; переводим в байты для munmap
    call mem_free

.free_struct:
    mov rdi, rbx
    mov rsi, 24
    call mem_free

.done:
    pop rbx rsi rdi
    ret

; void add_to_end(Array* arr, unsigned long value)
add_to_end:
    push rdi rsi rbx r12 r13 r14

    mov r12, rdi  ; Array* arr
    mov r13, rsi  ; value

    ; Проверка вместимости
    mov rbx, [r12 + 16]  ; size
    mov rcx, [r12 + 8]   ; capacity

    cmp rbx, rcx
    jl .add_directly

    shl rcx, 1           ; новая емкость = старая * 2
    mov [r12 + 8], rcx   ; обновляем capacity

    ; Выделяем новую память
    mov rdi, rcx
    shl rdi, 3           ; байты
    call mem_alloc

    test rax, rax
    js .done

    mov r14, rax         ; r14 = новый указатель данных

    ; Копирование данных
    mov rcx, [r12 + 16]  ; size
    test rcx, rcx
    jz .copy_done
    mov rsi, [r12]       ; старые данные
    mov rdi, r14         ; новые данные

.copy_loop:
    mov rdx, [rsi]
    mov [rdi], rdx
    add rsi, 8
    add rdi, 8
    dec rcx
    jnz .copy_loop

.copy_done:
    ; Освобождение старой памяти
    mov rdi, [r12]       ; старый указатель
    mov rsi, [r12 + 8]   ; текущая (уже удвоенная) емкость
    shr rsi, 1           ; получаем старую емкость
    shl rsi, 3           ; байты
    call mem_free

    ; Обновляем указатель в структуре
    mov [r12], r14

.add_directly:
    mov rbx, [r12 + 16]     ; size
    mov rcx, [r12]          ; data ptr
    mov [rcx + rbx * 8], r13
    inc rbx
    mov [r12 + 16], rbx

.done:
    pop r14 r13 r12 rbx rsi rdi
    ret

remove_from_start:
    push rdi rbx r12

    mov r12, rdi

    call is_empty
    test rax, rax
    jnz .empty

    mov rbx, [r12]       ; data ptr
    mov rax, [rbx]       ; возвращаемое значение (первый элемент)

    mov rcx, [r12 + 16]  ; size
    dec rcx
    jz .update_size

    ; Сдвиг памяти: memmove(arr, arr+1, (size-1)*8)
    mov rdi, [r12]       ; куда (в начало)
    lea rsi, [rdi + 8]   ; откуда (со второго элемента)
    mov rdx, rcx
    shl rdx, 3           ; байты
    call memmove

.update_size:
    mov rcx, [r12 + 16]
    dec rcx
    mov [r12 + 16], rcx
    jmp .done

.empty:
    xor rax, rax

.done:
    pop r12 rbx rdi
    ret

is_empty:
    mov rax, [rdi + 16]  ; size
    test rax, rax
    setz al
    movzx rax, al
    ret

fill_random:
    push rdi rsi rbx r12 r13 r14

    mov r12, rdi  ; Array* arr
    mov r13, rsi  ; count

    xor r14, r14

.fill_loop:
    cmp r14, r13
    jge .done

    call simple_random
    mov rdi, r12
    mov rsi, rax
    call add_to_end

    inc r14
    jmp .fill_loop

.done:
    pop r14 r13 r12 rbx rsi rdi
    ret

simple_random:
    push rbx rcx rdx

    mov rax, [random_seed]
    test rax, rax
    jnz .has_seed

    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [random_seed], rax

.has_seed:
    mov rbx, rax
    shl rbx, 13
    xor rax, rbx
    mov rbx, rax
    shr rbx, 7
    xor rax, rbx
    mov rbx, rax
    shl rbx, 17
    xor rax, rbx

    mov [random_seed], rax

    xor rdx, rdx
    mov rbx, 100        ; диапазон 0-99
    div rbx
    mov rax, rdx
    inc rax             ; диапазон 1-100

    pop rdx rcx rbx
    ret

; void remove_even_numbers(Array* arr)
remove_even_numbers:
    push rdi rsi rcx r12 r13 r14

    mov r12, rdi

    call is_empty
    test rax, rax
    jnz .done

    mov r13, [r12 + 16]  ; size (предел цикла)
    xor r14, r14         ; индекс для записи (куда сохраняем нечетные)

    mov rbx, [r12]       ; data ptr
    xor rcx, rcx         ; индекс для чтения (текущий элемент)

.process_loop:
    cmp rcx, r13
    jge .update_size

    mov rax, [rbx + rcx * 8]
    test rax, 1          ; проверка на нечетность (младший бит == 1)
    jz .skip_even        ; если 0 (четное), пропускаем (не увеличиваем r14)

    ; Если нечетное:
    mov [rbx + r14 * 8], rax ; перезаписываем в "сжатую" часть
    inc r14

.skip_even:
    inc rcx
    jmp .process_loop

.update_size:
    mov [r12 + 16], r14  ; обновляем размер массива

.done:
    pop r14 r13 r12 rcx rsi rdi
    ret

count_ends_with_one:
    push rdi rbx r12 r13

    mov r12, rdi
    xor r13, r13         ; счетчик

    call is_empty
    test rax, rax
    jnz .done

    mov rbx, [r12]       ; data ptr
    mov rcx, [r12 + 16]  ; loop counter (size)

.count_loop:
    test rcx, rcx
    jz .done

    mov rax, [rbx]       ; загружаем число

    ; Проверка: оканчивается ли на 1 в десятичной системе? (num % 10 == 1)
    push rcx
    push rdx
    xor rdx, rdx
    mov rcx, 10
    div rcx              ; rax = div, rdx = mod
    cmp rdx, 1
    pop rdx
    pop rcx
    jne .not_match

    inc r13

.not_match:
    add rbx, 8
    dec rcx
    jmp .count_loop

.done:
    mov rax, r13
    pop r13 r12 rbx rdi
    ret

print_array:
    push rdi rbx r12 r13

    mov r12, rdi

    call is_empty
    test rax, rax
    jz .print_elements

    mov rdi, empty_msg
    call print_string
    jmp .done

.print_elements:
    mov rbx, [r12]
    mov r13, [r12 + 16]
    xor rcx, rcx

.print_loop:
    cmp rcx, r13
    jge .end_print

    mov rdi, [rbx + rcx * 8]
    call print_number

    mov rdi, space
    call print_string

    inc rcx
    jmp .print_loop

.end_print:
    mov rdi, newline
    call print_string

.done:
    pop r13 r12 rbx rdi
    ret

print_string:
    push rsi rdx rax rdi rcx r11

    mov rsi, rdi
    xor rdx, rdx

.find_length:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .find_length

.print:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall

    pop r11 rcx rdi rax rdx rsi
    ret

print_number:
    push rdi rsi rdx rcx r8 r9 r10 r11

    mov rax, rdi
    lea rdi, [temp_buffer + 31]
    mov byte [rdi], 0
    mov r8, 10

.convert_loop:
    dec rdi
    xor rdx, rdx
    div r8
    add dl, '0'
    mov [rdi], dl
    test rax, rax
    jnz .convert_loop

    call print_string

    pop r11 r10 r9 r8 rcx rdx rsi rdi
    ret

; void* memmove(void* dest, void* src, size_t n)
memmove:
    push rdi rsi rcx
    cmp rdi, rsi
    jb .forward
    je .done

    lea rdi, [rdi + rdx - 1]
    lea rsi, [rsi + rdx - 1]
    mov rcx, rdx
    std
    rep movsb
    cld
    jmp .done

.forward:
    mov rcx, rdx
    rep movsb

.done:
    pop rcx rsi rdi
    ret
