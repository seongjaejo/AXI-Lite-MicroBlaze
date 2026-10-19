#include "xil_printf.h"
#include "common/delay/delay.h"
#include "ap/StopWatch.h"
#include "common/Interrupt/interrupt.h"
#include "HAL/TMR/TMR.h"
#include "HAL/UART/UART.h"
#include "HAL/SPI/SPI.h"
#include "driver/Button/Button.h"
#include "driver/Switch/Switch.h"
#include "driver/FND/FND.h"
#include "xparameters.h"

int main()
{
    TMR_SetPSC(TMR0, 100-1);
    TMR_SetARR(TMR0, 1000-1);
    TMR_StartInterrupt(TMR0);
    TMR_StartTimer(TMR0);
    UART_StartInterrupt(UART0);
    StopWatch_Init();
    Switch_Init();
    SPI_Init(SPI0, 50, 0, 0);
    SetupInterruptSystem();

    uint8_t rx_val = 0;

    while (1)
    {
        uint8_t tx_data = Switch_GetTxData();
        uint8_t mode    = Switch_GetMode();

        // UART 모드
        if (mode == SW_MODE_UART) {
            // 스톱워치 시간 카운트 + FND 표시 (10진수)
            StopWatch_RunTime();
            StopWatch_ControlState();
            StopWatch_DispWatch();

            if (Button_GetState(&hbtnLeft) == ACT_RELEASED) {
                xil_printf("%d:%02d:%02d\r\n",
                    stopWatchTimeData.min,
                    stopWatchTimeData.sec,
                    stopWatchTimeData.ms);
            }
        }
        // SPI 모드
        else if (mode == SW_MODE_SPI) {
            // 시간은 계속 카운트하되 FND/버튼 제어는 SPI용으로
            StopWatch_RunTime();

            // Left → TX only
            if (Button_GetState(&hbtnLeft) == ACT_RELEASED) {
                SPI_Transmit(SPI0, tx_data);
                FND_SetHex(0x00, tx_data);  // rx없으니 hi=0
            }
            // Right → TX+RX
            else if (Button_GetState(&hbtnRight) == ACT_RELEASED) {
                rx_val = SPI_TransmitReceive(SPI0, tx_data);
                FND_SetHex(rx_val, tx_data);
            }
        }
    }
    return 0;
}
