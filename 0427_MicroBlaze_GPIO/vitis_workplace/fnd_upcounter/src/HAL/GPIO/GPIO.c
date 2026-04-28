
#include "GPIO.h"


//typedef unint32_t unsigned int : 이렇게 선언이 되어있음

void GPIO_SetMode(GPIO_Typedef_t* GPIOx, uint32_t GPIO_PIN, int GPIO_Dir) {
	//GPIOx->CR |= (INOUT << GPIO_PIN_x);
	if (GPIO_Dir == OUTPUT) {
		GPIOx->CR |= GPIO_PIN;
	} else {
		GPIOx->CR &= ~(GPIO_PIN);
	}
}

void GPIO_WritePin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_PIN, int level) {
	if (level == SET) {
		GPIOx->ODR |= GPIO_PIN;
	} else {
		GPIOx->ODR &= ~GPIO_PIN;
	}
}

uint32_t GPIO_ReadPin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_PIN) {
	return (GPIOx->IDR & GPIO_PIN) ? 1 : 0; //괄호 안이 0이면 거짓이고 0이 아닌 것은 모두 참
}

void GPIO_WritePort(GPIO_Typedef_t *GPIOx, int data){
	GPIOx->ODR = data;
}

uint32_t GPIO_ReadPort(GPIO_Typedef_t *GPIOx){
	return(GPIOx->IDR);
}
