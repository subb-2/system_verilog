/*
 * FND.c
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */

#include "FND.h"

uint16_t fndNumData = 0;

//변환
	uint8_t fndFont[16] = {
			0xc0,
		    0xf9,
		    0xa4,
		    0xb0,
		    0x99,
		    0x92,
		    0x82,
		    0xf8,
		    0x80,
		    0x90,
			0x88,
			0x83,
			0xc6,
			0xa1,
			0x86,
			0x8e};

void FND_Init() {

}

void FND_SetComPort(GPIO_Typedef_t *FND_Port, uint32_t Seg_Pin,int OnOFF){
	GPIO_WritePin(FND_Port, Seg_Pin, OnOFF);
}

void FND_Digit() {
	//GPIO에 대한 선언  : 어떤 GPIO를 만들지

	//GPIOA0,1,2,3 = COM 연결
	GPIO_SetMode(FND_COM_PORT, FND_COM_DIG_1|FND_COM_DIG_2|FND_COM_DIG_3|FND_COM_DIG_4, OUTPUT);

	//GPIO_SetMode(GPIOA, GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7, INPUT);

	//GPIOB seg abcdefg,dp와 연결
	GPIO_SetMode(FND_FONT_PORT, SEG_PIN_A|SEG_PIN_B|SEG_PIN_C|SEG_PIN_D|SEG_PIN_E|SEG_PIN_F|SEG_PIN_G|SEG_PIN_DP, OUTPUT);

	static uint8_t fndDigState = 0;
	fndDigState = (fndDigState + 1) % 4;
	switch(fndDigState) {
	case 0 : FND_Digit_1();
		break;
	case 1 : FND_Digit_10();
			break;
	case 2 : FND_Digit_100();
			break;
	case 3 : FND_Digit_1000();
			break;
	default: FND_Digit_1();
		break;
	}
}

void FND_Digit_1() {

	// num의 자리수 분리
	uint8_t digitData1 = fndNumData % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData1]);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_1, ON);
}

void FND_Digit_10() {
	// num의 자리수 분리
	uint8_t digitData10 = (fndNumData / 10) % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData10]);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_2, ON);
}

void FND_Digit_100() {
	// num의 자리수 분리
	uint8_t digitData100 = (fndNumData / 100) % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData100]);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_3, ON);
}
void FND_Digit_1000() {
	// num의 자리수 분리
	uint8_t digitData1000 = (fndNumData / 1000) % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData1000]);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_4, ON);
}

//실제로 많이 사용하게 될 부분
void FND_SetNum(uint16_t num) {
	fndNumData = num;
}
void FND_DispAllOn() {
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_1|FND_COM_DIG_2|FND_COM_DIG_3|FND_COM_DIG_4, ON);
}
void FND_DispAllOff() {
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_1|FND_COM_DIG_2|FND_COM_DIG_3|FND_COM_DIG_4, OFF);
}
