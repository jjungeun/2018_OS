#ifndef __PAGE_H__
#define __PAGE_H__

#include "Types.h"

//하위 32비트 용 속성 필드
#define PAGE_FLAGS_P 0X00000001	//Present
#define PAGE_FLAGS_RW 0X00000002	//Read/Write
#define PAGE_FLAGS_US 0X00000004	//플래그 설정시 유저 레벨
#define PAGE_FLAGS_PWT 0X00000008
#define PAGE_FLAGS_PCD 0X00000010
#define PAGE_FLAGS_A 0X00000020	//Accessed
#define PAGE_FLAGS_D 0X00000040	//Dirty
#define PAGE_FLAGS_PS 0X00000080	//Page size
#define PAGE_FLAGS_G 0X00000100	//Global
#define PAGE_FLAGS_PAT 0X00001000	//Page Attribute Table Index
//상위 32비트 용 속성 필드
#define PAGE_FLAGS_EXB 0X80000000	//Execute Disable비트
//기타
#define PAGE_FLAGS_DEFAULT (PAGE_FLAGS_P | PAGE_FLAGS_RW)

#define PAGE_TABLESIZE 0x1000
#define PAGE_MAXENTRYCOUNT 512
#define PAGE_DEFAULTSIZE 0x200000

//구조체
#pragma pack(push,1)

//페이지 엔트리에 대한 자료구조
typedef struct pageTableEntryStruct
{
	DWORD dwAttributeAndLowerBaseAddress;	//8바이트 크기의 페이지 엔트리 중 하위 4바이트
	DWORD dwUpperBaseAddressAndEXB;			//8바이트 크기의 페이지 엔트리 중 상위 4바이트
} PML4TENTRY, PDPTENTRY, PDENTRY, PTENTRY;
#pragma pack(pop)

void kInitializePageTables(void);
void kSetPageEntyData(PTENTRY* pstEntry, DWORD dwUpperBaseAddress, DWORD dwLowerBaseAddress, DWORD dwLowerFlags, DWORD dwUpperFlags);

#endif /*__PAGE_H*/


