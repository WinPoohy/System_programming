;Разработать программу аутентификации пользователя: вводится пароль.
;Если пароль неверен, выдается сообщение «Невереный пароль» и пароль вводится снова.
;Повтор допускается до 5 раз. Если правильный пароль так и не будет введен,
;выдается сообщение "Неудача",
;если пароль подобран, то выдается сообщение "Вошли"

format elf64
public _start
include "funcnew.asm"

section '.data' writable
   wrong db "Неверный пароль", 0xA,  0
   right db "Вошли", 0xA, 0
   fail db "Неудача", 0xA, 0

section '.bss' writable
   place rb 255
   parol dq ?
   try dq ?


section '.text' executable

_start:
   mov rsi, parol
   call input_keyboard

   xor rdx, rdx
   xor rax, rax
   mov rbx, 5
   check:
      mov rsi, try
      call input_keyboard
      xor rsi, rsi
      mov rax, [parol]
      mov rcx, [try]
      cmp rax, rcx ;cmp two peremennih to diff results
      je good
      dec rbx
      cmp rbx, 0
      je failed
      jmp bad
      call new_line
   jmp check

   failed: ;errors
      mov rsi, fail
      mov rax, 1
      mov rdi, 1
      push rax
      mov rax, rsi
      call len_str
      mov rdx, rax
      pop rax
      syscall
      ;call new_line
      call exit

   bad: ;errors
      mov rsi, wrong
      mov rax, 1
      mov rdi, 1
      push rax
      mov rax, rsi
      call len_str
      mov rdx, rax
      pop rax
      syscall
      ;call new_line
      jmp check

   good: ;errors
      mov rsi, right
      mov rax, 1
      mov rdi, 1
      push rax
      mov rax, rsi
      call len_str
      mov rdx, rax
      pop rax
      syscall
      call exit

   mov rax, 60 ; I don't understand the place for this
   mov rdi, 0
   syscall
