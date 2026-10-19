/*
 * SPI.c
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */

#include "SPI.h"

uint32_t spi_cr_shadow = 0;

// -------------------------------------------------------
// SPI_Init
// clk_div, cpol, cpha 설정값을 CR에 저장
// start는 0으로 초기화
// -------------------------------------------------------
void SPI_Init(SPI_TypeDef_t *spi, uint8_t clk_div, uint8_t cpol, uint8_t cpha)
{
    spi_cr_shadow = ((uint32_t)clk_div << SPI_CR_CLKDIV_POS)
                  | ((uint32_t)cpha    << SPI_CR_CPHA_BIT)
                  | ((uint32_t)cpol    << SPI_CR_CPOL_BIT);
    spi->CR = spi_cr_shadow;  // start=0으로 초기화
}

// -------------------------------------------------------
// SPI_TransmitReceive
// 1바이트 전송 + 수신 동시 수행 (SPI 특성상 항상 동시)
// 전송 완료(done) 대기 후 RX_DATA 반환
// -------------------------------------------------------
uint8_t SPI_TransmitReceive(SPI_TypeDef_t *spi, uint8_t data)
{
    spi->TX_DATA = (uint32_t)data;
    // 약간 딜레이
    volatile int i;
    for (i = 0; i < 10; i++);
    spi->CR = spi_cr_shadow | (1 << SPI_CR_START_BIT);
    while (spi->STATUS & SPI_STATUS_BUSY);
    return (uint8_t)(spi->RX_DATA);
}
// -------------------------------------------------------
// SPI_Transmit
// 데이터 보내고 수신값은 버림
// -------------------------------------------------------
void SPI_Transmit(SPI_TypeDef_t *spi, uint8_t data)
{
    SPI_TransmitReceive(spi, data);
}

// -------------------------------------------------------
// SPI_Receive
// 더미 데이터(0xFF)를 보내고 수신값만 반환
// SPI는 송수신이 항상 동시에 일어나므로
// 수신만 할 때는 더미값을 전송해야 클럭이 나옴
// -------------------------------------------------------
uint8_t SPI_Receive(SPI_TypeDef_t *spi)
{
    return SPI_TransmitReceive(spi, 0xFF);
}

// -------------------------------------------------------
// SPI_IsBusy
// 현재 전송 중이면 1 반환
// -------------------------------------------------------
uint8_t SPI_IsBusy(SPI_TypeDef_t *spi)
{
    return (spi->STATUS & SPI_STATUS_BUSY) ? 1 : 0;
}
