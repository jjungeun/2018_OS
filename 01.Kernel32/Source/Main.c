#include "Types.h"
#include "Page.h"
#include "ModeSwitch.h"

//함수 선언
void kPrintString(int iX, int iY, const char* pcString);
BOOL kIsMemoryEnough( void );
BOOL kInitializeKernel64Area( void );
void kCopyKernel64ImageTo2Mbyte(void);

void main(void)
{
	DWORD i;
	DWORD dwEAX,dwEBX,dwECX,dwEDX;
	char vcVendorString[ 13 ]={0,};

	kPrintString(0,4,"C Language Kernel Start...........[Pass]");

	//최소 메모리 크기를 만족하는지 검사
	kPrintString(0,5,"Minimum Memory Size Check.........[    ]");
	if(kIsMemoryEnough() == FALSE)
	{
		kPrintString(35,5,"Fail");
		kPrintString(0,6,"Not Enough Memory~!! MINT64OS Requires Over 64Mbyte Memory~!!");
		while(1);
	}
	else{
		kPrintString(35,5,"Pass");
	}
	//1A32e 모드의 커널 영역을 초기화
	kPrintString(0,6,"IA-32e Kernel Area Initialize.....[    ]");
	if(kInitializeKernel64Area()==FALSE)
	{
		kPrintString(35,6,"Fail");
		kPrintString(0,7,"1A-32e Kernel Area Initialization Complete");
		while(1);
	}
	kPrintString(35,6,"Pass");

	//IA-32e모드 커널을 위한 페이지 테이블 생성
	kPrintString(0,7,"IA-32e PageTables Initialize......[    ]");
	kInitializePageTables();
	kPrintString(35,7,"Pass");

	// 프로세서 제조사 정보 일기
	kReadCPUID(0x00, &dwEAX, &dwEBX, &dwECX, &dwEDX );
	*( DWORD* ) vcVendorString = dwEBX;
	*((DWORD*) vcVendorString+1) = dwEDX;
	*((DWORD*) vcVendorString+2) = dwECX;
	kPrintString(0,8,"Processor Vendor String...........[            ]");
	kPrintString(35,8,vcVendorString);

	//64비트 지원 유무 확인
	kReadCPUID(0x80000001, &dwEAX, &dwEBX,&dwECX,&dwEDX);
	kPrintString(0,9,"64bit Mode Support Check..........[    ]");
	
	if(dwEDX & (1 <<29))
	{
		kPrintString(35,9,"Pass");
	}
	else
	{
		kPrintString(35,9,"Fail");
		kPrintString(0,10,"This processor does not support 64bit mode~!!");
		while(1);
	}

	//IA-32e 모드 커널을 2MB 어드레스로 이동
	kPrintString(0,10,"Copy IA-32e Kernel To 2MB address......[    ]");
	kCopyKernel64ImageTo2Mbyte();
	kPrintString(40,10,"Pass");

	//IA-32e모드로 전환
	kPrintString(0,11,"Switch To IA-32e Mode");
	kSwitchAndExecute64bitKernel();
	while(1);
}

void kPrintString(int iX, int iY, const char* pcString)
{
	CHARACTER* pstScreen = (CHARACTER*) 0xB8000;
	int i;

	pstScreen += (iY * 80) + iX;
	for(i=0;pcString[i]!=0;i++)
	{
		pstScreen[i].bCharactor = pcString[i];
	}
}

//1A-32e 모드용 커널 영역을 0으로 초기화
BOOL kInitializeKernel64Area( void )
{
	DWORD* pdwCurrentAddress;

	//초기화를 시작할 어드레스인 0x100000(1MB)을 설정
	pdwCurrentAddress = (DWORD*) 0x100000;

	//마지막 어드레스인 6MB까지 루프를 돌면서 4바이트씩 0으로 채움
	while((DWORD) pdwCurrentAddress < 0x600000)
	{
		*pdwCurrentAddress = 0x00;

		//0으로 저장한 후 다시 읽었을 때 0이 나오지 않으면 문제생긴것
		if( *pdwCurrentAddress != 0)
		{
			return FALSE;
		}
		
		pdwCurrentAddress++;
	}
	return TRUE;
}

// MINT64 OS를 실행하기에 충분한 메모리를 가지고 있는지 체크
BOOL kIsMemoryEnough( void )
{
	DWORD* pdwCurrentAddress;
	
	//1MB부터 검사 시작
	pdwCurrentAddress = (DWORD*) 0x100000;

	//64MB까지 루프 돌면서 확인
	while((DWORD)pdwCurrentAddress < 0x4000000)
	{
		*pdwCurrentAddress = 0x12345678;

		//다시 읽었을 때 0x12345678이 나오지 않으면 문제 생긴 것
		if(*pdwCurrentAddress != 0x12345678)
		{
			return FALSE;
		}
		//1MB씩 이동하면서 확인
		pdwCurrentAddress += (0x100000/4);
	}
	
	return TRUE;
}

//IA-32e 모드 커널을 2MB 어드레스에 복사
void kCopyKernel64ImageTo2Mbyte(void)
{
	WORD wKernel32SectorCount, wTotalKernelSectorCount;
	DWORD* pdwSourceAddress,* pdwDestinationAddress;
	int i;

	//0x7C05에 총 커널 섹터 수, 0x7C07에 보호모드 커널 섹터수가 들어있음
	wTotalKernelSectorCount = *((WORD* )0x7C05);
	wKernel32SectorCount = *((WORD* )0x7C07);

	pdwSourceAddress = (DWORD*)(0x10000+(wKernel32SectorCount*512));
	pdwDestinationAddress = (DWORD*)(0x200000);

	//IA-32e모드 커널 섹터 크기만큼 복사
	for(i=0;i<512*(wTotalKernelSectorCount-wKernel32SectorCount)/4;i++)
	{
		*pdwDestinationAddress = *pdwSourceAddress;
		pdwDestinationAddress++;
		pdwSourceAddress++;
	}

}







