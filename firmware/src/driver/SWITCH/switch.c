/*
 * switch.c
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */


#include "Switch.h"

hswitch hswTxData;
hswitch hswCtrl;

void Switch_Init()
{
    // GPIOC, GPIOD 전부 입력으로 설정
    GPIO_SetMode(GPIOC, 0x00);
    GPIO_SetMode(GPIOD, 0x00);

    Switch_SetInit(&hswTxData, GPIOC);
    Switch_SetInit(&hswCtrl,   GPIOD);
}

void Switch_SetInit(hswitch *hsw, GPIO_TypeDef *GPIOx)
{
    hsw->GPIOx = GPIOx;
}

// GPIOC[7:0] → tx_data (전송할 데이터)
uint8_t Switch_GetTxData()
{
    return (uint8_t)GPIO_ReadPort(hswTxData.GPIOx);
}

// GPIOD[7:5] → mode
// 0b100 = UART, 0b010 = SPI, 0b001 = I2C
uint8_t Switch_GetMode()
{
    return (uint8_t)(GPIO_ReadPort(hswCtrl.GPIOx) >> 5) & 0x07;
}

// GPIOD[0] → rw_bit (I2C Read/Write 구분용)
uint8_t Switch_GetRwBit()
{
    return (uint8_t)(GPIO_ReadPort(hswCtrl.GPIOx)) & 0x01;
}
