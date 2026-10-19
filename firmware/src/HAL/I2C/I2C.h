/*
 * I2C.h
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */

#ifndef SRC_HAL_I2C_I2C_H_
#define SRC_HAL_I2C_I2C_H_

#include "xparameters.h"
#include "xil_io.h"
#include <stdint.h>

#define I2C_BASEADDR XPAR_I2C_MASTER_0_S00_AXI_BASEADDR

/* Register Offset */
#define I2C_CR     0x00
#define I2C_TDR    0x04
#define I2C_RDR    0x08
#define I2C_SR     0x0C

/* Status Register */
#define I2C_BUSY   (1 << 0)
#define I2C_DONE   (1 << 1)
#define I2C_ACK    (1 << 2)

void I2C_Init(void);

void I2C_Write(uint8_t addr, uint8_t data);
uint8_t I2C_Read(uint8_t addr);

#endif /* SRC_HAL_I2C_I2C_H_ */
