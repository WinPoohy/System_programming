format ELF64

public _start
place db "23453", 0

include 'func.asm'


_start:
    add rsp, 16
    xor rsi, rsi
    pop rsi
    mov byte al, [rsi]
    call print_int
    call new_line
    call exit


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
