/*
 * I2C.c
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */

#include "I2C.h"

static void I2C_WaitDone(void)
{
    /* 이전 DONE이 클리어될 때까지 대기 */
    while (Xil_In32(I2C_BASEADDR + I2C_SR) & I2C_DONE);

    /* 새로운 DONE이 올라올 때까지 대기 */
    while (!(Xil_In32(I2C_BASEADDR + I2C_SR) & I2C_DONE));
}

void I2C_Init(void)
{

}

void I2C_Write(uint8_t addr, uint8_t data)
{
    uint32_t tdr;

    tdr = ((uint32_t)addr << 8) | data;

    Xil_Out32(I2C_BASEADDR + I2C_TDR, tdr);

    Xil_Out32(I2C_BASEADDR + I2C_CR, I2C_START);

     I2C_WaitDone();
}

uint8_t I2C_Read(uint8_t addr)
{
    uint32_t tdr;

    tdr = ((uint32_t)addr << 8);

    Xil_Out32(I2C_BASEADDR + I2C_TDR, tdr);

    Xil_Out32(I2C_BASEADDR + I2C_CR,
              I2C_START | I2C_READ);

    I2C_WaitDone();

    return (uint8_t)Xil_In32(I2C_BASEADDR + I2C_RDR);
}
