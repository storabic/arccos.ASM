format PE Console 4.0
include 'win32a.inc'
entry init

section '.data' data readable writeable

; FAQ
helpMsg db 'This program calculates value of arccos(x) using Taylor series', 0dh, 0ah, \
	'-1 <= x <= 1', 0dh, 0ah, \
	'For example, enter: arccos.exe 0.5', 0dh, 0ah, 0
; ��� ����
windowName db 'arccos', 0dh, 0ah, 0

; ������ ������ ��� scanf. 1 �������� ������������
readFormat  db '%*s %lf', 0

; ������ ������ ��� printf.
printFormat db 'arccos(%.10g) = %.10g rad', 0

; const num 1
one	dq 1
; const num -1
mOne dq -1
; ��������� �������� �������, ���� = pi / 2.
inAns	dq 1.57079633
; ����������� ��������.
kEps	dq 1E-3
; ��������� ����� (double).
x	dq ?
; ��������� ������
buffer	dd ?
; ����� ��� ������
output db 256 dup(?)


section '.code' code readable executable

init:
  ; ���� ������ �� ��������� ������
  invoke GetCommandLineA
  mov [buffer], eax
  cinvoke sscanf, [buffer], readFormat, x
  cmp eax, 1
  jne faq ; ���� ����� �� ���� ������� ��� ������� � �������

  ; ������ FPU ����������
  finit       ; �������������� FPU
  fld [x]     ; ST(4) - �������� x
  fcom [one]
  fstsw ax
  fld1	      ; ST(3) - ������ i. ���������� = 1
  fld [x]     ; ST(2) - ������� ���� ���� (1 * 3 * ... * (2n - 1) * x^(2n + 1)) / (2 * 4 * ... * 2n * (2n + 1)). ���������� = x
  fldz	      ; ST(1)	����������_�����. ���������� = 0
  fld [inAns] ; ST(0) - �������_����� = pi / 2

whileTrue:
  ; �������� |�������_����� - ����������_�����| < kEps * �������_�����

  fld st0      ; ����� �������_�����
  fsub st0, st2; �������_����� -= ����������_�����
  fabs	       ; abs(�������_����� - ����������_�����)
  fld st1      ; ����� �������_����� 
  fmul [kEps]  ; kEps * �������_�����
  fcom	       ; ��������� |�������_����� - ����������_�����| < kEps * �������_�����
  fstsw ax     ; status -> ax
  fstp st0     ;
  fstp st0     ; ������� ����� �� ������

  ; ��������� ����� �� ax, ����� ������� �������� ��������� C0, C2, C3.
  and ax, 0100010100000000b
  ; ���� ����� C0 = C2 = C3 = 0, ������ �������� ����������
  cmp ax, 0
  je print
  
  ; ����� �������� ����� ����
  fstp st1	; ������� ����_�����
  fld st0	; ����_����� = �������_�����
  fsub st0, st2 ; �������_����� += ����� ���� ����
  
  ; ���������� ������ ����� ���� �� ��������
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

  ; ���������� ����
  jmp whileTrue

print:

  ; �����
  fst [inAns]
  cinvoke sprintf, output, printFormat, dword[x], dword[x + 4], dword[inAns], dword[inAns + 4]
  cinvoke MessageBox, 0, output, windowName, MB_OK
  invoke ExitProcess, 0

; ����� FAQ
faq:
  cinvoke MessageBox, 0, helpMsg, windowName, MB_OK
  invoke ExitProcess, 0


; ����������� ������� �������
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