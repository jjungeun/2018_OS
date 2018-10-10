[ORG 0x00]
[BITS 16]

SECTION .text

START:
	mov ax, 0x1000

	mov ds, ax
	mov es, ax

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; A20게이트를 활성화
	; BIOS이용한 전환이 실패한 경우 시스템 컨트롤 포트로 전환
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ax, 0x2401	; A20게이트 활성화 서비스 설정
	int 0x15		; BIOS인터럽트 서비스 호출

	jc .A20GATEERROR	;활성화 성공했는지 확인
	jmp .A20GATESUCCESS

.A20GATEERROR:
	in al, 0x92	; 시스템 컨트롤 포트에서 1바이트 읽어 al레지스터에 저장
	or al, 0x02	; 읽은 값에 A20게이트 비트(비트 1)를 1로 설정
	and al, 0xFE	; 시스템 리셋방지를 위해 비트0을 0으로 설정
	out 0x92, al	; 시스템 컨트롤 포트에 변경된 값을 설정

.A20GATESUCCESS:
	


	cli
	lgdt [GDTR]

	mov eax, 0x4000003B
	mov cr0, eax

	jmp dword 0x18: (PROTECTEDMODE - $$ + 0x10000)

[BITS 32]
PROTECTEDMODE:
	mov ax , 0x20
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax


	mov ss, ax
	mov esp, 0xFFFE
	mov ebp, 0xFFFE

	push (SWITCHSUCCESSMESSAGE - $$ + 0x10000)
	push 3
	push 0
	call PRINTMESSAGE
	add esp, 12

	jmp dword 0x18: 0x10200


PRINTMESSAGE:
	push ebp
	mov ebp, esp
	push esi
	push edi
	push eax
	push ecx
	push edx


	mov eax, dword [ebp + 12]
	mov esi, 160
	mul esi
	mov edi, eax

	mov eax, dword [ebp + 8]
	mov esi, 2
	mul esi
	add edi, eax

	mov esi, dword [ebp + 16]

.MESSAGELOOP:
	mov cl ,byte [esi]
	cmp cl, 0
	je .MESSAGEEND

	mov byte [edi + 0xB8000], cl
	add esi, 1
	add edi, 2
	jmp .MESSAGELOOP

.MESSAGEEND:
	pop edx
	pop ecx
	pop eax
	pop edi
	pop esi
	pop ebp
	ret



align 8, db 0

dw 0x0000

GDTR:
	dw GDTEND - GDT - 1
	dd (GDT - $$ + 0x10000)

GDT:
	NULLDescriptor:
		dw 0x0000
		dw 0x0000
		db 0x00
		db 0x00
		db 0x00
		db 0x00
	
	;IA-32e 모드 커널용 코드 세그먼트 디스크립터
	IA_32eCODEDESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x9A	
		db 0xAF		;G=1, D=0,L=1
		db 0x00

	;IA-32e 모드 커널용 데이터 세그먼트 디스크립터
	IA_32eDATADESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x92
		db 0xAF
		db 0x00

	; 보호모드 커널용 코드 세그먼트 디스크립터
	CODEDESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x9A
		db 0xCF
		db 0x00

	; 보호모드 커널용 데이터 세그먼트 디스크립터
	DATADESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x92
		db 0xCF
		db 0x00

GDTEND:

SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success~!!', 0


times 512 - ($ - $$) db 0x00
