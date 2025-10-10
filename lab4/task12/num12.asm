;Реализовать функцию, которая для заданного числа n
; определяет, что все его цифры следуют в неубывающем порядке.

format elf64
public _start
include "funcnew.asm"

section '.data' writable
   place db ";oiuygf", 0
   no db "no", 0
   yes db "yes", 0
   n dq 0
   ost dq 0

section '.bss' writable
   msg rb 255

section '.text' executable

_start:
   mov rax, 0
   mov rdi, 0
   mov rsi, msg
   mov rdx, 255
   syscall
    mov rsi, msg
   xor rdx, rdx
   xor rax, rax
   call str_number
   mov [n], rax
    xor rdx, rdx
   mov rbx, 10
   div rbx
   mov [ost], rdx
   mov rbx, 0
   checkost:
        mov rcx, rax
        xor rdx, rdx
        mov rbx, 10
        div rbx ;ost in rdx
        cmp [ost], rdx
        jnae ohno
        inc rbx
        mov [ost], rdx
        mov rcx, rax
        xor rax, rax
        cmp rax, 0
        je ohyes
    jmp checkost

    ohno:
        mov rsi, no
        call print_str
        call new_line
        call exit

    ohyes:
        mov rsi, yes
        call print_str
        call new_line

        call exit

   call exit
