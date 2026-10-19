/*
 * SPI.h
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */

#ifndef SRC_HAL_SPI_SPI_H_
#define SRC_HAL_SPI_SPI_H_

#include "xparameters.h"
#include <stdint.h>

// -------------------------------------------------------
// SPI 레지스터 구조체
// REG0: CR     [+0x00] bit[15:8]=clk_div, bit[2]=cpha, bit[1]=cpol, bit[0]=start
// REG1: TX_DATA[+0x04] bit[7:0]=tx_data
// REG2: RX_DATA[+0x08] bit[7:0]=rx_data (읽기전용)
// REG3: STATUS [+0x0C] bit[1]=done, bit[0]=busy (읽기전용)
// -------------------------------------------------------
typedef struct {
    uint32_t CR;
    uint32_t TX_DATA;
    uint32_t RX_DATA;
    uint32_t STATUS;
} SPI_TypeDef_t;

extern uint32_t spi_cr_shadow;

#define SPI0_BASEADDR   XPAR_SPI_MASTER_0_S00_AXI_BASEADDR
#define SPI0            ((SPI_TypeDef_t *)SPI0_BASEADDR)

// CR 비트 정의
#define SPI_CR_START_BIT    0
#define SPI_CR_CPOL_BIT     1
#define SPI_CR_CPHA_BIT     2
#define SPI_CR_CLKDIV_POS   8

// STATUS 비트 정의
#define SPI_STATUS_BUSY     (1 << 0)
#define SPI_STATUS_DONE     (1 << 1)

// 기본 clk_div 값 (100MHz / (clk_div+1) = SCLK)
// clk_div=4 → SCLK = 100MHz/5 = 20MHz
#define SPI_CLK_DIV_DEFAULT  4

void SPI_Init(SPI_TypeDef_t *spi, uint8_t clk_div, uint8_t cpol, uint8_t cpha);
void SPI_Transmit(SPI_TypeDef_t *spi, uint8_t data);
uint8_t SPI_Receive(SPI_TypeDef_t *spi);
uint8_t SPI_TransmitReceive(SPI_TypeDef_t *spi, uint8_t data);
uint8_t SPI_IsBusy(SPI_TypeDef_t *spi);


#endif /* SRC_HAL_SPI_SPI_H_ */
