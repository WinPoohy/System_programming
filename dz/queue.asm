; queue.asm
format elf64
    public create_queue
    public free_queue
    public enqueue
    public dequeue
    public is_empty
    public fill_random
    public remove_even_numbers
    public count_primes
    public count_even_numbers
    public print_queue
    public ranint
    public is_prime

    section '.data' writable
f  db "/dev/urandom", 0
newline db 10, 0
space db " ", 0
empty_msg db "Queue is empty", 10, 0

    section '.bss' writable
number rq 1
temp_buffer rb 32
heap_start rq 1
current_brk rq 1

    section '.text' executable

; Queue* create_queue()
create_queue:
    push rdi

    mov rdi, 24
    call malloc
    test rax, rax
    jz .error

    mov qword [rax], 0      ; front = NULL
    mov qword [rax + 8], 0  ; rear = NULL
    mov qword [rax + 16], 0 ; size = 0
    jmp .done

.error:
    xor rax, rax

.done:
    pop rdi
    ret

; void free_queue(Queue* q)
free_queue:
    push rdi
    push rsi
    push rbx
    push r12

    mov r12, rdi
    test r12, r12
    jz .done

    mov rbx, [r12]  ; q->front

.free_nodes:
    test rbx, rbx
    jz .free_struct

    mov rdi, rbx
    mov rbx, [rbx + 8]  ; node->next

    push rbx
    call free
    pop rbx

    jmp .free_nodes

.free_struct:
    mov rdi, r12
    call free

.done:
    pop r12
    pop rbx
    pop rsi
    pop rdi
    ret

; void enqueue(Queue* q, unsigned long value)
enqueue:
    push rdi
    push rsi
    push rbx
    push r12
    push r13

    mov r12, rdi  ; Queue* q
    mov r13, rsi  ; unsigned long value

    mov rdi, 16
    call malloc
    test rax, rax
    jz .done

    mov [rax], r13       ; node->data = value
    mov qword [rax + 8], 0 ; node->next = NULL

    mov rbx, [r12 + 8]   ; q->rear
    test rbx, rbx
    jz .first_node

    mov [rbx + 8], rax   ; q->rear->next = newNode
    jmp .update_rear

.first_node:
    mov [r12], rax       ; q->front = newNode

.update_rear:
    mov [r12 + 8], rax   ; q->rear = newNode

    mov rbx, [r12 + 16]
    inc rbx
    mov [r12 + 16], rbx

.done:
    pop r13
    pop r12
    pop rbx
    pop rsi
    pop rdi
    ret

; unsigned long dequeue(Queue* q)
dequeue:
    push rdi
    push rbx
    push r12

    mov r12, rdi  ; Queue* q

    mov rdi, r12
    call is_empty
    test rax, rax
    jnz .empty

    mov rbx, [r12]       ; q->front
    mov rax, [rbx]       ; return value = q->front->data

    mov rcx, [rbx + 8]   ; q->front->next
    mov [r12], rcx       ; q->front = q->front->next

    test rcx, rcx
    jnz .update_size
    mov qword [r12 + 8], 0 ; q->rear = NULL

.update_size:
    mov rcx, [r12 + 16]
    dec rcx
    mov [r12 + 16], rcx

    push rax
    mov rdi, rbx
    call free
    pop rax
    jmp .done

.empty:
    xor rax, rax

.done:
    pop r12
    pop rbx
    pop rdi
    ret

; int is_empty(Queue* q)
is_empty:
    mov rax, [rdi]      ; q->front
    test rax, rax
    setz al
    movzx rax, al
    ret

; void fill_random(Queue* q, unsigned long count)
fill_random:
    push rdi
    push rsi
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi  ; Queue* q
    mov r13, rsi  ; unsigned long count

    xor r14, r14

.fill_loop:
    cmp r14, r13
    jge .done

    call ranint
    mov rdi, r12
    mov rsi, rax
    and rsi, 0xFF
    inc rsi
    call enqueue

    inc r14
    jmp .fill_loop

.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rsi
    pop rdi
    ret

; void remove_even_numbers(Queue* q)
remove_even_numbers:
    push rdi
    push rsi
    push rcx
    push r12
    push r13

    mov r12, rdi  ; Queue* q
    mov rdi, r12
    call is_empty
    test rax, rax
    jnz .done

    call create_queue
    mov r13, rax
    test r13, r13
    jz .done

.process_loop:
    mov rdi, r12
    call is_empty
    test rax, rax
    jnz .transfer_back

    mov rdi, r12
    call dequeue
    mov rsi, rax

    test rsi, 1
    jz .skip_odd

    mov rdi, r13
    call enqueue

.skip_odd:
    jmp .process_loop

.transfer_back:
.transfer_loop:
    mov rdi, r13
    call is_empty
    test rax, rax
    jnz .cleanup

    mov rdi, r13
    call dequeue
    mov rsi, rax

    mov rdi, r12
    call enqueue
    jmp .transfer_loop

.cleanup:
    mov rdi, r13
    call free_queue

.done:
    pop r13
    pop r12
    pop rcx
    pop rsi
    pop rdi
    ret

; unsigned int count_primes(Queue* q)
count_primes:
    push rdi
    push rbx
    push r12
    push r13

    mov r12, rdi
    xor r13, r13

    mov rdi, r12
    call is_empty
    test rax, rax
    jnz .done

    mov rbx, [r12]  ; q->front

.count_loop:
    test rbx, rbx
    jz .done
    mov rdi, [rbx]  ; node->data
    call is_prime
    test rax, rax
    jz .not_prime

    inc r13

.not_prime:
    mov rbx, [rbx + 8]  ; node->next
    jmp .count_loop

.done:
    mov rax, r13
    pop r13
    pop r12
    pop rbx
    pop rdi
    ret

; unsigned int count_even_numbers(Queue* q)
count_even_numbers:
    push rdi
    push rbx
    push r12
    push r13

    mov r12, rdi
    xor r13, r13

    mov rdi, r12
    call is_empty
    test rax, rax
    jnz .done

    mov rbx, [r12]  ; q->front

.count_loop:
    test rbx, rbx
    jz .done

    mov rax, [rbx]  ; node->data
    test rax, 1
    jnz .not_even

    inc r13

.not_even:
    mov rbx, [rbx + 8]  ; node->next
    jmp .count_loop

.done:
    mov rax, r13
    pop r13
    pop r12
    pop rbx
    pop rdi
    ret

; void print_queue(Queue* q)
print_queue:
    push rdi
    push rbx
    push r12

    mov r12, rdi  ; Queue* q

    mov rdi, r12
    call is_empty
    test rax, rax
    jz .print_elements

    mov rdi, empty_msg
    call print_string
    jmp .done

.print_elements:
    mov rbx, [r12]  ; q->front

.print_loop:
    test rbx, rbx
    jz .end_print

    mov rdi, [rbx]  ; node->data
    call print_number

    mov rdi, space
    call print_string

    mov rbx, [rbx + 8]  ; node->next
    jmp .print_loop

.end_print:
    mov rdi, newline
    call print_string

.done:
    pop r12
    pop rbx
    pop rdi
    ret

; Генерация случайного числа
ranint:
    push rdi
    push rsi
    push rdx
    push r8
    push r9
    push r10
    push r11

    mov rax, 228    ; sys_clock_gettime
    mov rdi, 1      ; CLOCK_MONOTONIC
    mov rsi, number
    syscall

    mov rax, [number + 8]
    jmp .done

.done:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rsi
    pop rdi
    ret

; int is_prime(unsigned long n)
is_prime:
    push rbx
    push rcx
    push rdx
    push r12

    mov r12, rdi

    cmp r12, 1
    jbe .not_prime

    cmp r12, 2
    je .prime

    test r12, 1
    jz .not_prime

    mov rbx, 3

.loop:
    mov rax, rbx
    mul rax

    jc .check_overflow
    cmp rax, r12
    ja .prime
    jmp .check_divisible

.check_overflow:
    jmp .prime

.check_divisible:
    mov rax, r12
    xor rdx, rdx
    div rbx

    test rdx, rdx
    jz .not_prime

    add rbx, 2
    jmp .loop

.prime:
    mov rax, 1
    jmp .end

.not_prime:
    mov rax, 0

.end:
    pop r12
    pop rdx
    pop rcx
    pop rbx
    ret

; void print_string(const char* str)
print_string:
    push rdi
    push rsi
    push rdx
    push rax
    push rcx
    push r11

    mov rsi, rdi
    xor rdx, rdx
.length_loop:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .length_loop

.print:
    mov rax, 1
    mov rdi, 1
    syscall

    pop r11
    pop rcx
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

; void print_number(unsigned long n)
print_number:
    push rdi
    push rsi
    push rdx
    push rcx
    push r8
    push r9
    push r10
    push r11

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

    pop r11
    pop r10
    pop r9
    pop r8
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

; void* malloc(unsigned long size)
malloc:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11

    mov rbx, rdi

    mov rax, 12
    xor rdi, rdi
    syscall
    mov [current_brk], rax

    mov rdi, rax
    add rdi, rbx
    mov rax, 12
    syscall

    cmp rax, [current_brk]
    je .error

    mov rax, [current_brk]
    jmp .done

.error:
    xor rax, rax

.done:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; void free(void* ptr)
free:
    ret
