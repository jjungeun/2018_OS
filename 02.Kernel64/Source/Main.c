#include "Types.h"

void kPrintString(int iX, int iY, const char* pcString);

void Main(void)
{
	kPrintString(0,12,"Switch To Ia-32e Mode Success~!!");
	kPrintString(0,13,"IA-32e C Language Kernel Start........[Pass]");
}

void kPrintString(int iX, int iY, const char* pcString)
{
	CHARACTER* pstScreen =(CHARACTER*) 0xB8000;
	int i;

	//X,Y좌표를 이용해서 문자열을 출력할 어드레스를 계산
	pstScreen += (iY*80)+iX;

	//NULL이 나올 떄 까지 문자열 출력
	for(i =0; pcString[i] !=0;i++)
	{
		pstScreen[i].bCharactor = pcString[i];
	}
}


