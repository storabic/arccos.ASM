format PE Console 4.0
include 'win32a.inc'
entry init

section '.data' data readable writeable

; FAQ
helpMsg db 'This program calculates value of arccos(x) using Taylor series', 0dh, 0ah, \
	'-1 <= x <= 1', 0dh, 0ah, \
	'For example, enter: arccos.exe 0.5', 0dh, 0ah, 0
; имя окна
windowName db 'arccos', 0dh, 0ah, 0

; формат вывода для scanf. 1 аргумент игнорируется
readFormat  db '%*s %lf', 0

; формат вывода для printf.
printFormat db 'arccos(%.10g) = %.10g rad', 0

; const num 1
one	dq 1
; const num -1
mOne dq -1
; начальное значение функции, ряда = pi / 2.
inAns	dq 1.57079633
; коэффициент точности.
kEps	dq 1E-3
; введенное число (double).
x	dq ?
; временная строка
buffer	dd ?
; буфер для вывода
output db 256 dup(?)


section '.code' code readable executable

init:
  ; Ввод данных из командной строки
  invoke GetCommandLineA
  mov [buffer], eax
  cinvoke sscanf, [buffer], readFormat, x
  cmp eax, 1
  jne faq ; если число не было считано или считано с ошибкой

  ; Начало FPU вычислений
  finit       ; инициализируем FPU
  fld [x]     ; ST(4) - значение x
  fcom [one]
  fstsw ax
  fld1	      ; ST(3) - индекс i. Изначально = 1
  fld [x]     ; ST(2) - текущий член ряда (1 * 3 * ... * (2n - 1) * x^(2n + 1)) / (2 * 4 * ... * 2n * (2n + 1)). Изначально = x
  fldz	      ; ST(1)	предыдущий_ответ. Изначально = 0
  fld [inAns] ; ST(0) - текущий_ответ = pi / 2

whileTrue:
  ; проверка |текущий_ответ - предыдущий_ответ| < kEps * текущий_ответ

  fld st0      ; пушим текущий_ответ
  fsub st0, st2; текущий_ответ -= предыдущий_ответ
  fabs	       ; abs(текущий_ответ - предыдущий_ответ)
  fld st1      ; пушим текущий_ответ 
  fmul [kEps]  ; kEps * текущий_ответ
  fcom	       ; сравнение |текущий_ответ - предыдущий_ответ| < kEps * текущий_ответ
  fstsw ax     ; status -> ax
  fstp st0     ;
  fstp st0     ; очистка стека от мусора

  ; наложение маски на ax, чтобы достать значения регистров C0, C2, C3.
  and ax, 0100010100000000b
  ; Если флаги C0 = C2 = C3 = 0, нужная точность достигнута
  cmp ax, 0
  je print
  
  ; Новое значение суммы ряда
  fstp st1	; стираем пред_ответ
  fld st0	; пред_ответ = текущий_ответ
  fsub st0, st2 ; текущий_ответ += новый член ряда
  
  ; вычисление нового члена ряда по рекурсии
  fld st2
  fmul st, st4
  fmul st, st4
  fmul st, st5
  fmul st, st5

  fld1
  fadd st5, st
  fstp st0
  fdiv st, st4

  fld1
  fadd st5, st
  fstp st0
  fdiv st, st4

  fstp st3

  ; продолжаем цикл
  jmp whileTrue

print:

  ; вывод
  fst [inAns]
  cinvoke sprintf, output, printFormat, dword[x], dword[x + 4], dword[inAns], dword[inAns + 4]
  cinvoke MessageBox, 0, output, windowName, MB_OK
  invoke ExitProcess, 0

; вывод FAQ
faq:
  cinvoke MessageBox, 0, helpMsg, windowName, MB_OK
  invoke ExitProcess, 0


; подключение внешних функций
section '.idata' import data readable

  library msvcrt, 'msvcrt.dll',\
	  kernel32, 'kernel32.dll',\
	  user32, 'user32.dll'

  import user32, MessageBox, 'MessageBoxA'

  import msvcrt, sscanf, 'sscanf',\
	 printf, 'printf',\
	 sprintf, 'sprintf'

  import kernel32, GetCommandLineA, 'GetCommandLineA',\
	 ExitProcess, 'ExitProcess'
