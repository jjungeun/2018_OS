[BITS 32]

global kReadCPUID	; C언어에서 호출할 수 있도록 이름을 노출
global kSwitchAndExecute64bitKernel

SECTION .text

;CPUID 반환
;인자 : DWORD dwEAX,
;		DWORD *pdwEAX,*pdwEBX, *pdwECX,*pdwEDX 
kReadCPUID:
	push ebp		;베이스 포인터 레지스터를 스택에 삽입
	mov ebp, esp	;베이스 포인터 레지스터에 스택 포인터 레지스터의 값을 설정
	push eax		; 함수에서 임시로 사용하는 레지스터
	push ebx
	push ecx
	push edx
	push esi

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; EAX 레지스터의 값으로 CPUID 명령어 실행
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, dword [ebp + 8]	; 파라미터 1(dwEAX)를 EAX레지스터에 저장
	cpuid						; CPUID 명령어 실행

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 반환된 값을 파라미터에 저장
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; *pdwEAX
	mov esi, dword [ebp + 12]	; 파라미터 2(dwEAX)를 ESI 레지스터에 저장
	mov dword[esi], eax			; pdwEAX가 포인터이므로 포인터가 가리키는 어드레스에 EAX레지스터의 값을 저장

	; *pdwEBX
	mov esi, dword [ebp + 16]	;파라미터 3(dwEBX)를 ESI 레지스터에 저장
	mov dword[esi], ebx			

	; *pdwECX
	mov esi, dword [ebp + 20]	;파라미터 4(dwECX)를 ESI 레지스터에 저장
	mov dword[esi], ecx

	; *pdwEDX
	mov esi, dword [ebp+24]		; 파라미터 5(dwEDX)를 ESI 레지스터에 저장
	mov dword[esi], edx

	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret


; IA-32e모드로 전환하고 64비트 커널을 수행
; 인자는 없다
kSwitchAndExecute64bitKernel:
	; CR4컨트롤 레지스터의 PAE비트를 1로 설정
	mov eax, cr4	; cr4컨트롤 레지스터 값을 eax레지스터에 저장
	or eax, 0x20	; PAE비트를 1로 설정
	mov cr4, eax	; PAE비트가 1로 설정된 값을 cr4 컨트롤 레지스터에 저장

	; CR3컨트롤 레지스터에 PML4테이블의 어드레스 및 캐시활성화
	mov eax, 0x100000	;EAX레지스터에 PML4테이블이 존재하는 1MB를 저장
	mov cr3, eax		; cr3컨트롤 레지스터에 1MB를 저장
	
	; IA32_EFER LME를 1로 설정하여 IA-32e모드 활성화
	mov ecx, 0xC0000080	;MSR레지스터의 어드레스 저장
	rdmsr				;MSR 레지스터 읽기
	or eax, 0x0100		;MSR의 하위 32비트에서 LME비트(비트8)를 1로 설정
	wrmsr				;MSR 레지스터에 쓰기

	; 캐시기능과 페이징 기능 활성화
	mov eax, cr0
	or eax, 0xE0000000
	xor eax, 0x60000000
	mov cr0, eax

	jmp 0x08:0x200000	; cs세그먼트 셀렉터를 jmp를 통해 교체하고 IA-32e모드용 코드 세그먼트 디스크립터로 교체하고
						; IA-32e모드 커널이 존재하는 2MB로 이동

	; 여기는 실행되지 않음
	jmp $








