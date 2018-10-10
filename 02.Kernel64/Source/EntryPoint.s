[BITS 64]

SECTION .text

extern Main	; 외부에서 정의된 함수를 쓸 수 있도록 선언

;;;;;;;;;;;;;;;;;;;
; 코드 영역
;;;;;;;;;;;;;;;;;;;
START : 
	mov ax, 0x10	; IA-32e 모드 커널용 데이터 세그먼트 디스크립터를 AX 레지스터에 저장
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	;스택을 0x600000 ~ 0x6FFFFF 영역에 1MB크기로 생성
	mov ss, ax
	mov rsp, 0x6FFFF8
	mov rbp, 0x6FFFF8

	call Main

	jmp $





