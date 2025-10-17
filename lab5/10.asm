format elf64
public _start

include 'func.asm' ;;я не доделдал второй файл тоже через ввод подается

section '.bss' writable
  buffer rb 100               ; Буфер для чтения строки из файла
  sent_buf rb 100             ; buf for sentence
  buf64 rb 64
  buf2 rb 64
  stro dq 0
  rev_buf rb 100

section '.data' writable
  endfile db '10e', 0         ; Имя второго файла для записи

section '.text' executable

_start:
  ;; Открываем первый файл для чтения
  mov rdi, [rsp+16]            ; Имя первого файла из аргументов командной строки
  mov rax, 2               ; Системный вызов open
  mov rsi, 0o                 ; O_RDONLY (режим только для чтения)
  syscall
  cmp rax, 0
  jl l1

  mov r8, rax                 ; Сохраняем дескриптор первого файла в r8

  ;; Открываем второй файл для записи
  mov rdi, [rsp + 24]            ; Имя второго файла
  mov rax, 2                  ; Системный вызов open
  mov rsi, 577                ; O_WRONLY | O_CREAT | O_TRUNC (для записи, создать, если не существует)
  mov rdx, 777o               ; Права доступа к файлу
  syscall
  cmp rax, 0
  jl l1

  mov r10, rax                ; Сохраняем дескриптор второго файла в r10

  ;; Читаем содержимое первого файла в buffer
  mov rax, 0                  ; Системный вызов read
  mov rdi, r8                 ; Дескриптор первого файла
  mov rsi, buffer             ; Куда читать (в buffer)
  mov rdx, 100                ; Сколько читать (до 100 байт)
  syscall
  mov r9, rax                 ; Сохраняем количество прочитанных байт в r9

  ;; Разделяем строку на предложения
  mov rdi, sent_buf           ; Указатель для записи предложения в sent_buf
  mov rcx, 0                  ; Счетчик символов предложения

  mov rsi, buffer

xor rcx,rcx
next_char:

  cmp rcx, r9                 ; Проверяем, достигли ли конца buffer
  je end_of_text             ; Если да, завершить обработку

  mov al, [buffer + rcx]         ; Получаем текущий символ
  inc rcx                     ; Переходим к следующему символу

  mov [rdi], al               ; Сохраняем символ в sent_buf
  inc rdi                     ; Переходим к следующему месту в sent_buf
  cmp al, '.'                 ; Проверка на конец предложения
  je .end_sentence
  cmp al, '!'
  je .end_sentence
  cmp al, '?'
  je .end_sentence





  jmp next_char              ; Переход к следующему символу

.end_sentence:
  mov byte [rdi], 0           ; Завершаем предложение нулевым байтом
  mov rsi, sent_buf           ; Указатель на начало предложения
  sub rdi, sent_buf           ; Вычисляем длину предложения
  mov rdx, rdi                ; Устанавливаем длину предложения в rdx
  push rdx
;rdx len, rsi start
 call revert_rsi
     ;call print_str
 pop rdx
 inc rdx
  call write_sentence



  mov rdi, sent_buf           ; Сбрасываем указатель на начало sent_buf
  jmp next_char              ; Переход к обработке следующего предложения
revert_rsi:
    push rax
    push rbx
    push rcx
    push rdx

    ;rdx = len
    xor rcx,rcx
    ;call new_line

    .iter:
      mov rbx, rdx
      sub rbx, rcx

      mov al, [rsi+rcx] ; start s
      mov byte [buf2+rbx], al
      inc rcx
      cmp rcx, rdx
      jl .iter

    mov [buf2], ' '
    mov rsi, buf2



    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

end_of_text:
  ;; Закрываем оба файла

  mov rdi, r8
  mov rax, 3                  ; Системный вызов close для первого файла
  syscall
  mov rdi, r10
  syscall                     ; Системный вызов close для второго файла

  ;; Завершение программы
l1:
  call exit

write_sentence:
  push rdi
  push rsi
  push rax
  push rcx
  push rdx
 ;call print_str

  mov rax, 1                  ; Системный вызов write
  mov rdi, r10                ; Дескриптор второго файла
  syscall
  pop rdx
  pop rcx
  pop rax
  pop rsi
  pop rdi
  ret
