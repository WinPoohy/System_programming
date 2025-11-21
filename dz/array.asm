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

; Array* create_array()
create_array:
    push rdi rsi

    mov rdi, 24
    call malloc
    test rax, rax
    jz .error

    mov qword [rax], 0        ; data = NULL
    mov qword [rax + 8], 0    ; capacity = 0
    mov qword [rax + 16], 0   ; size = 0

    mov rdi, [initial_capacity]
    shl rdi, 3
    push rax
    call malloc
    pop rcx
    test rax, rax
    jz .error_struct

    mov [rcx], rax
    mov rdx, [initial_capacity]
    mov [rcx + 8], rdx
    mov qword [rcx + 16], 0

    mov rax, rcx
    jmp .done

.error_struct:
    mov rdi, rcx
    call free
.error:
    xor rax, rax
.done:
    pop rsi rdi
    ret

; void free array(Array* arr)
free_array:
    push rdi rsi

    test rdi, rdi
    jz .done

    mov rsi, [rdi]
    test rsi, rsi
    jz .free_struct

    push rdi
    mov rdi, rsi
    call free
    pop rdi

.free_struct:
    call free

.done:
    pop rsi rdi
    ret

; void add to end
add_to_end:
    push rdi rsi rbx r12 r13

    mov r12, rdi  ; Array* arr
    mov r13, rsi  ; value

    ; Check capacity
    mov rbx, [r12 + 16]  ; size
    mov rcx, [r12 + 8]   ; capacity

    cmp rbx, rcx
    jl .add_directly

    shl rcx, 1
    mov [r12 + 8], rcx
    mov rdi, [r12]
    mov rsi, rcx
    shl rsi, 3

    push rdi
    mov rdi, rsi
    call malloc
    pop rdi
    test rax, rax
    jz .done

    ; Copy
    mov rcx, [r12 + 16]  ; size
    test rcx, rcx
    jz .copy_done
    mov rsi, [r12]
    mov rdi, rax

.copy_loop:
    mov rdx, [rsi]
    mov [rdi], rdx
    add rsi, 8
    add rdi, 8
    dec rcx
    jnz .copy_loop

.copy_done:

    push rax
    mov rdi, [r12]
    call free
    pop rax

    mov [r12], rax

.add_directly:
    ; add el
    mov rbx, [r12 + 16]
    mov rcx, [r12]
    mov [rcx + rbx * 8], r13
    inc rbx
    mov [r12 + 16], rbx

.done:
    pop r13 r12 rbx rsi rdi
    ret

; unsigned long remove from start(Array* arr)
remove_from_start:
    push rdi rbx r12

    mov r12, rdi

    call is_empty
    test rax, rax
    jnz .empty

    mov rbx, [r12]
    mov rax, [rbx]

    mov rcx, [r12 + 16]
    dec rcx
    jz .update_size

    mov rdi, [r12]
    lea rsi, [rdi + 8]
    mov rdx, rcx
    shl rdx, 3
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

; int is empty(Array* arr)
is_empty:
    mov rax, [rdi + 16]  ; size
    test rax, rax
    setz al
    movzx rax, al
    ret

; void fill random(Array* arr, unsigned long count)
fill_random:
    push rdi rsi rbx r12 r13 r14

    mov r12, rdi  ; Array* arr
    mov r13, rsi  ; count

    xor r14, r14

.fill_loop:
    cmp r14, r13
    jge .done

    ; gen num 1 to 100
    call simple_random
    mov rdi, r12
    mov rsi, rax
    call add_to_end

    inc r14
    jmp .fill_loop

.done:
    pop r14 r13 r12 rbx rsi rdi
    ret

; (Xorshift)
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
    mov rbx, 100
    div rbx
    mov rax, rdx
    inc rax

    pop rdx rcx rbx
    ret

; void remove even numbers(Array* arr)
remove_even_numbers:
    push rdi rsi rcx r12 r13 r14

    mov r12, rdi

    call is_empty
    test rax, rax
    jnz .done

    mov r13, [r12 + 16]
    xor r14, r14

    mov rbx, [r12]
    xor rcx, rcx

.process_loop:
    cmp rcx, r13
    jge .update_size

    mov rax, [rbx + rcx * 8]
    test rax, 1
    jz .skip_odd

    mov [rbx + r14 * 8], rax
    inc r14

.skip_odd:
    inc rcx
    jmp .process_loop

.update_size:
    mov [r12 + 16], r14

.done:
    pop r14 r13 r12 rcx rsi rdi
    ret

; unsigned int count ends wit one(Array* arr)
count_ends_with_one:
    push rdi rbx r12 r13

    mov r12, rdi
    xor r13, r13

    call is_empty
    test rax, rax
    jnz .done

    mov rbx, [r12]
    mov rcx, [r12 + 16]

.count_loop:
    test rcx, rcx
    jz .done

    mov rax, [rbx]
    and rax, 0xF
    cmp rax, 1
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
    mov rax, 1
    mov rdi, 1
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

; void* malloc(unsigned long size)
malloc:
    push rbx rcx rdx rsi rdi r8 r9 r10 r11

    mov rbx, rdi

    mov rax, 12
    xor rdi, rdi
    syscall

    push rax

    mov rdi, rax
    add rdi, rbx
    mov rax, 12
    syscall

    pop rax

    pop r11 r10 r9 r8 rdi rsi rdx rcx rbx
    ret

; void free(void* ptr)
free:
    ret

; void* memcpy(void* dest, void* src, size_t n)
memcpy:
    push rdi rsi rcx
    mov rcx, rdx
    rep movsb
    pop rcx rsi rdi
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
