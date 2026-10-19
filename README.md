# AXI4-Lite Custom IP / MicroBlaze

선정 원본: `D:\OndeviceAI2\ip_repo + 260626_MicroBlaze_Timer_UART`

Top: `design_1_wrapper`

현재 spi_master_1.0을 선정했습니다. 패키지 안 spi_master_v1_0.v에는 spi_master 코어도 포함되므로 별도 spi_master.v를 중복 등록하지 않습니다. firmware/src는 사용자 소스이며 BSP와 실행 파일은 재생성이 필요합니다.

선정 근거와 실제 테스트 범위·알려진 제한은 [검증 기록](SELECTION_AND_VALIDATION.md)을 확인하세요.

## 검증 실행

Icarus Verilog 13과 Python이 필요합니다. 저장소 루트에서 실행합니다.

```sh
python verification/run_checks.py
```

실행한 테스트와 로그는 `verification/`에 있습니다. 실물 보드 재시험·합성·타이밍 검증 완료를 의미하지 않습니다.
