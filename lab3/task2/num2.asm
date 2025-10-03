format ELF64
public _start
place db "23453", 0
a dq 0
b dq 0
c dq 0
chis dq 0
include 'func.asm'


_start:
    add rsp, 23
    xor rsi, rsi
    xor rax, rax
    ;mov byte al, [rsi]
    pop rsi
    call str_to_int
    mov [a], rax
    ;call print_int
    ;call new_line
    xor rsi, rsi
    pop rsi
    call str_to_int
    mov [b], rax
    ;call print_int
    ;call new_line
    xor rsi, rsi
    pop rsi
    call str_to_int
    mov [c], rax
    ;call print_int
    ;call new_line
    xor rsi, rsi
    ;( ( ( ( (b*c) -b) + c) -a )-b)
    mov rax, [b]
    imul rax, [c] ; rdx = b*c
    sub rax, [b] ;rdx = b*c - b
    ;mov rax, rbx
    add rax, [c]; rdx = b*c - b + c
    sub rax, [a]; rdx = b*c - b + c - a
    ;mov rax, rbx
    sub rax, [b] ; b = b*c - b + c - a -b
    ;mov rax, rbx
    call print_int
    xor rsi, rsi
    call new_line
    call exit


str_to_int:
    push rsi
    push rbx
    push rcx
    push rdx
    xor rax, rax
    xor rdx, rdx
    mov rcx, 10
    itera:
        mov byte bl, [rsi + rdx]

        cmp bl, '0'
        jl next
        cmp bl, '9'
        jg next
        sub bl, '0'
        add rax, rbx
        cmp byte [rsi+rdx+1], 0
        je next
        push rdx
        mov rcx, 10
        mul rcx
        pop rdx
        inc rdx
    jmp itera
    next:
    pop rdx
    pop rcx
    pop rbx
    pop rsi
  ret

print_int:

    mov rcx, 10
    xor rbx, rbx
    .iter1:
      xor rdx, rdx
      div rcx
      add rdx, '0'
      push rdx
      inc rbx
      cmp rax,0
    jne .iter1
    .iter2:
      pop rax
      call print_symbl
      dec rbx
      cmp rbx, 0
    jne .iter2

 ret
