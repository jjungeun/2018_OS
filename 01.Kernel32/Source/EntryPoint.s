[ORG 0x00]	;코드의 시작 주소는 0x00
[BITS 16]	

SECTION .text

;;;;;;;;;;;;;;;;;;;;;;
; 코드 영역
;;;;;;;;;;;;;;;;;;;;;;

START:
	mov ax, 0x1000		; 보호 모드 엔트리 포인트의 시작 어드레스(0x10000)를 세그먼트 레지스터 값으로 변환
	mov ds, ax
	mov es, ax

	cli			; 인터럽트가 발생하지 못하게 설정	
	lgdt[ GDTR ]		; 프로세서에 GDTR자료구조를 설정하여 GDT테이블을 로드

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 보호모드로 진입
	; Disable Paging, Disable Cache, Internal FPU
	; Disable Align Check, Enable ProtectedMode
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	mov eax, 0x4000003B	; PG=0, CD=1, NW=0, AM=0, WP=0, NE=1,ET=1,TS=1, EM=0, MP=1, PE=1
	mov cr0, eax		; CR0 컨트롤 레지스터에 위에서 저장한 플래그를 설정하여 보호모드로 전환
	
	; kernel 코드 세그먼트를 0x00을 기준으로 하는 것으로 교체하고 EIP값을 0x00을 기준으로 재설정
	; CS 세그먼트 셀렉터 : EIP
	jmp dword 0x08: (PROTECTEDMODE - $$ + 0x10000 )	; 실제 코드는 0x10000을 기준으로 실행되므로 오프셋+기준주소

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 이하는 32비트 보호모드용 코드
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 32]

PROTECTEDMODE:
	mov ax, 0x10	; 보호 모드 커널용 데이터 세그먼트 디스크립터를 AX레지스터에 저장(0x10은 오프셋)
	mov ds, ax	; DS 세그먼트 셀렉터에 설정
	mov es, ax	; ES 세그먼트 셀렉터에 설정
	mov fs, ax	; FS 세그먼트 셀렉터에 설정
	mov gs, ax	; GS 세그먼트 셀렉터에 설정

	; 스택을 0x00000000 ~ 0x0000FFFF 영역에 64KB크기로 생성
	mov ss, ax	; SS 세그먼트 셀렉터에 설정
	mov esp, 0xFFFE	; ESP 레지스터의 어드레스를 0xFFFE로 설정
	mov ebp, 0xFFFE ; EBP 레지스터의 어드레스를 0xFFFE로 설정

	push ( SWITCHSUCCESSMESSAGE - $$ + 0x10000 )	; 출력할 메시지의 어드레스를 스택에 삽입
	push 4						; y좌표
	push 0						; x좌표
	call PRINTMESSAGE
	add sp, 12					; 삽입한 파라미터 제거

	jmp dword 0x08: 0x10200				; C언어 커널이 존재하는 0x10200 어드레스로 이동하여 C언어 커널 수행


;;;;;;;;;;;;;;;;;;;;;;;
; 함수 영역
;;;;;;;;;;;;;;;;;;;;;;;

;메시지 출력 함수( 파라미터는 x좌표, y좌표, 문자열 )
 PRINTMESSAGE:
	push ebp	; BP(베이스 포인터 레지스터)를 스택에 삽입
	mov ebp, esp	; BP에 SP값으로 설정
	push esi	; 함수에서 임시로 사용하는 레지스터로 함수의 마지막 부분에서
	push edi	; 스택에 삽입된 값을 꺼내 원래 값으로 복원
	push eax
	push ecx
	push edx

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; X, Y의 좌표로 비디오 메모리의 어드레스 계산
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	; Y 좌표를 이용해서 먼저 라인 어드레스를 구함
	mov eax, dword [ ebp+12 ]	; Y좌표를 EAX 레지스터에 설정
	mov esi,160			; 한 라인의 바이트수(2*80)를 ESI레지스터에 설정
	mul esi				; EAX 레지스터와 ESI 레지스터를 곱해 Y어드레스 계산
	mov edi, eax			; Y어드레스를 EDI레지스터에 설정

	; X 좌표를 이용해서 2를 곱한 후 최종 어드레스를 구함
	mov eax, dword[ ebp+8 ]		; X좌표를 EAX 레지스터에 설정
	mov esi, 2			; 한 문자를 나타내는 바이트 수(2)를 ESI레지스터에 설정
	mul esi				; X어드레스 계산
	add edi, eax			; 최종 어드레스를 EDI레지스터에 설정

	; 출력할 문자열의 어드레스
	mov esi, dword[ ebp+16 ]	; 출력할 문자열의 주소

.MESSAGELOOP:
	mov cl, byte[ esi ]		; ESI레지스터가  가리키는 문자열 위치에서 한 문자를 CL레지스터에 복사

	cmp cl, 0			; 복사된 문자열과 0을 비교
	je .MESSAGEEND			; 0이면 문자열이 종료되었음을 의미

	mov byte[ edi+0xB8000 ], cl	; 보호모드에서는 32비트 오프셋 사용 가능(바로 접근가능)	
	add esi, 1			; 다음 문자열로 이동
	add edi, 2			; 비디오 메모리의 다음 문자 위치로 이동

	jmp .MESSAGELOOP

.MESSAGEEND:
	pop edx
	pop ecx
	pop eax
	pop edi
	pop esi
	pop ebp
	ret


;;;;;;;;;;;;;;;;;;;;;;;;
; 데이터 영역
;;;;;;;;;;;;;;;;;;;;;;;;

; 아래의 데이터들을 8바이트에 맞춰 정렬하기 위함
align 8, db 0

; GDTR의 끝을 8byte에 맞춰 정렬하기 위함
dw 0x0000

; GDTR 자료구조 정의
GDTR:
	dw GDTEND - GDT - 1	; GDT테이블 크기
	dd (GDT - $$ + 0x10000)	; GDT테이블의 시작 어드레스

; GDT 테이블 정의
GDT:
	; 널 디스트립터. 반드시 0으로 초기화
	NULLDescriptor:
		dw 0x0000
		dw 0x0000
		db 0x00	
		db 0x00	
		db 0x00	
		db 0x00	
 
	; 보호모드 커널용 코드 세그먼트 디스트립터
	CODEDESCRIPTOR : 
		dw 0xFFFF	; Limit [15:0]
		dw 0x0000	; Base [15:0]
		db 0x00		; Base [23:16]
		db 0x9A		; P=1, DPL=0, S=1, 코드세그먼트, 실행/읽기
		db 0xCF		; G=1, D/B=1, L=0, AVL=0, 세그먼트 크기 = 20MB
		db 0x00		; Base [23:24]

	; 보호모드 커널용 데이터 세그먼트 디스크립터
	DATADESCRIPTOR :
		dw 0xFFFF	; Limit [15:0]
		dw 0x0000	; Base [15:0]
		db 0x00		; Base [23:16]
		db 0x92		; P=1, DPL=0, S=1, 데이터 세그먼트, 읽기/쓰기
		db 0xCF		; G=1, D/B=1, L=0, AVL=0, 세그먼트 크기 = 20MB
		db 0x00		; Base [31:24]
GDTEND:

; 보모호드로 전환되었다는 메시지
SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success~!!', 0

times 512 - ( $ - $$ ) db 0x00	; 512바이트를 맞추기 위해 남은 부분을 0으로 채움

