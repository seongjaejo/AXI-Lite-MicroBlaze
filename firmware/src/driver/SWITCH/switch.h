/*
 * Switch.h
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_SWITCH_SWITCH_H_
#define SRC_DRIVER_SWITCH_SWITCH_H_

#include "../../HAL/GPIO/GPIO.h"
#include <stdint.h>

// 모드 정의
#define SW_MODE_UART  0x04  // 0b100
#define SW_MODE_SPI   0x02  // 0b010
#define SW_MODE_I2C   0x01  // 0b001

// 스위치 핸들 구조체
typedef struct {
    GPIO_TypeDef *GPIOx;
} hswitch;

extern hswitch hswTxData;  // GPIOC → tx_data
extern hswitch hswCtrl;    // GPIOD → mode, rw_bit

void Switch_Init();
void Switch_SetInit(hswitch *hsw, GPIO_TypeDef *GPIOx);
uint8_t Switch_GetTxData();   // GPIOC[7:0] → tx_data
uint8_t Switch_GetMode();     // GPIOD[7:5] → mode
uint8_t Switch_GetRwBit();    // GPIOD[0]   → rw_bit

#endif /* SRC_DRIVER_SWITCH_SWITCH_H_ */
