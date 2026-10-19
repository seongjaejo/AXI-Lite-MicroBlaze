/*
 * Interrupt.c
 *
 *  Created on: 2026. 6. 26.
 *      Author: kccistc
 */

#include "interrupt.h"
#include "../delay/delay.h"
#include "../../driver/FND/FND.h"
#include "../../driver/LED/LED.h"
#include "../../HAL/UART/UART.h"

#include "xparameters.h"
#include "xintc.h"
#include "xil_exception.h"

XIntc IntrContoller;
extern uint8_t rx_data;

void TMR_ISR(void *CallbackRef)
{
	FND_Excute();
	incTick();
}

void UART_ISR(void *CallbackRef)
{
	rx_data = UART_Receive(UART0);
}

int SetupInterruptSystem()
{
	int status;

	// ** 변경 없음. 1. 인터럽트 컨트롤러 초기화
	status = XIntc_Initialize(&IntrContoller, INTC_DEV_ID);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	// 2-1. TMR_ISR 함수를 Intc와 연결
	status = XIntc_Connect(&IntrContoller, TMR_VEC_ID, (XInterruptHandler)TMR_ISR, (void *)0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	// 2-2. UART_ISR 함수를 Intc와 연결
	status = XIntc_Connect(&IntrContoller, UART_VEC_ID, (XInterruptHandler)UART_ISR, (void *)0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// ** 변경 없음. 3. Interrupt Controller 시작 (Hardware Mode)
	status = XIntc_Start(&IntrContoller, XIN_REAL_MODE);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// 4. 각각의 인터럽트 채널 활성화
	XIntc_Enable(&IntrContoller, TMR_VEC_ID);
	XIntc_Enable(&IntrContoller, UART_VEC_ID);

	//** 변경 없음. 5. Microblaze의 Exception 초기화 및 활성화
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XIntc_InterruptHandler, &IntrContoller);
	Xil_ExceptionEnable();

	return XST_SUCCESS;
}
















