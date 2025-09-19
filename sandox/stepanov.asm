format ELF64
public _start

section '.data' writable
    surname db 'Stepanov', 0xA    ; Латинскими буквами
    name db 'Andrey', 0xA         ; чтобы избежать проблем с кодировкой
    patronymic db 'Dmitrievich', 0xA

section '.text' executable

_start:
    ;
    mov rax, 4                  ;
    mov rbx, 1                  ;
    mov rcx, surname            ;
    mov rdx, 9                  ;
    int 0x80

    ;
    mov rax, 4
    mov rbx, 1
    mov rcx, name
    mov rdx, 7                  ;
    int 0x80

    ;
    mov rax, 4
    mov rbx, 1
    mov rcx, patronymic
    mov rdx, 12                  ;
    int 0x80

    ;
    mov rax, 1                  ;
    xor rbx, 0                ;
    int 0x80
