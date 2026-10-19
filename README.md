# AXI4-Lite Custom IP · MicroBlaze · SPI UVM Verification

**AXI4-Lite Slave 인터페이스를 갖춘 Custom Peripheral IP를 MicroBlaze SoC에 연결하고, SPI Master의 레지스터 제어와 송수신 경로를 UVM으로 검증한 프로젝트**입니다.

GPIO·Timer·UART·SPI Master의 RTL/AXI 래퍼, MicroBlaze 펌웨어와 보드 연동을 다루며, UVM 환경은 그중 **AXI-SPI Master IP**를 대상으로 합니다. I2C Master IP는 팀원 담당 구현으로 SoC 의존성에 포함되어 있습니다.

- **언어**: Verilog / SystemVerilog / C
- **설계·펌웨어 도구**: Vivado / Vitis / MicroBlaze
- **검증 도구**: Synopsys VCS, UVM 1.2, Verdi
- **하드웨어**: Basys3 (Artix-7), SPI Master / Slave 구성

[UVM 검증 코드](https://github.com/seongjaejo/AXI-Lite-MicroBlaze/tree/add-axi-spi-uvm/verification/uvm/axi_spi) · [테스트 시나리오](https://github.com/seongjaejo/AXI-Lite-MicroBlaze/tree/add-axi-spi-uvm/verification/uvm/axi_spi/tb)

> UVM 소스는 `add-axi-spi-uvm` 브랜치에 업로드되어 있습니다. `main`에서 `verification/uvm/axi_spi`가 보이지 않으면 위 링크 또는 해당 브랜치를 선택하세요. 아래 UVM 구조·실행 방법은 이 브랜치 기준입니다.

---

## 1. 프로젝트 목표

- AXI4-Lite의 AW/W/B/AR/R 채널을 통해 Custom IP의 레지스터를 제어한다.
- RTL → IP 패키징 → MicroBlaze Block Design → Vitis 펌웨어의 연결 과정을 구현한다.
- UVM driver가 AXI 접근을 수행하고, SPI 전송 완료 후 AXI readback까지 이어지는 경로를 확인한다.
- Directed / constrained-random 시나리오와 scoreboard, functional coverage로 검증 범위를 정리한다.

---

## 2. 아키텍처

### FPGA / 펌웨어 구성

```text
MicroBlaze + Vitis Application (C)
            │ AXI4-Lite
            ├── GPIO IP
            ├── Timer IP
            ├── UART IP
            ├── I2C Master IP (팀원 담당)
            └── SPI Master IP
                 ├── AXI Slave 레지스터 인터페이스
                 └── SPI Master ── SCLK/MOSI/MISO/SS_N ── SPI Slave
```

이 IP는 **AXI 버스에서는 Slave, SPI 버스에서는 Master**입니다.

### UVM 검증 구성

```text
tb_top
 ├── axi_spi_if s_if
 ├── spi_master_v1_0 (AXI wrapper + SPI Master)
 ├── spi_slave (송신 데이터 직접 주입)
 └── uvm_test_top
     └── axi_spi_env
         ├── axi_spi_agent
         │   ├── sequencer → driver → AXI write/read
         │   └── monitor → analysis_port
         ├── axi_spi_scoreboard
         └── axi_spi_coverage
```

| 레지스터 오프셋 | 이름 | 기능 |
|---|---|---|
| `0x00` | CR | `[15:8] clk_div`, `[2] CPHA`, `[1] CPOL`, `[0] start` |
| `0x04` | TX_DATA | SPI 송신 데이터 `[7:0]` |
| `0x08` | RX_DATA | 완료 시 저장한 SPI 수신 데이터 `[7:0]` |
| `0x0C` | STATUS | `[0] busy`, `[1] done`; done은 STATUS read 시 clear |

---

## 3. 파일 구조

```text
AXI-Lite-MicroBlaze/
├── ip_repo/               GPIO / Timer / UART / SPI / I2C 패키징 IP
├── hardware/              MicroBlaze Block Design (.bd)
├── firmware/src/          Vitis Application / HAL / Driver 소스
├── constraints/           Master 보드 핀 제약
├── slave-board/           SPI Echo Slave 보드 RTL / 제약
├── tb/original/           기존 RTL 테스트벤치
└── verification/
    ├── tb/, evidence/     별도의 로컬 RTL 확인 테스트 / 결과
    └── uvm/axi_spi/       서버 VCS UVM 환경
```

```text
verification/uvm/axi_spi/
├── Makefile
├── rtl/
│   ├── spi_master.v
│   ├── spi_master_v1_0.v
│   ├── spi_master_v1_0_S00_AXI.v
│   └── spi_slave.sv
└── tb/
    ├── if.sv          interface / clocking block / modport
    ├── seq_item.sv    transaction과 constraint
    ├── sequence.sv    directed / random sequence
    ├── driver.sv      DUT 입력 구동
    ├── monitor.sv     완료 시점 관찰 / transaction 재구성
    ├── agent.sv       sequencer / driver / monitor 연결
    ├── scoreboard.sv  데이터 비교 / pass·fail 집계
    ├── coverage.sv    functional coverage
    ├── env.sv         agent / scoreboard / coverage 조립
    ├── test.sv        test 선택 / objection 관리
    ├── pkg.sv         class include 순서 관리
    ├── tb_top.sv             clock / DUT / config_db / FSDB
    └── template.sv           보관된 템플릿
```

`template.sv`는 보관 파일이며 현재 package의 include 대상인지와 실제 컴파일 목록은 `pkg.sv` 및 Makefile을 기준으로 확인합니다.

UVM의 `rtl/`은 서버 검증 당시 사용한 DUT입니다. 패키징 IP의 `spi_master_v1_0.v`에는 Master 코어가 함께 들어 있으므로 두 소스 묶음을 한 번에 중복 컴파일하지 않습니다.

---

## 4. 검증 시나리오

| 테스트 | 구성 | 확인 항목 |
|---|---|---|
| `axi_spi_basic_test` | 고정 패턴 15건 | 00/FF, FE/01, MSB/LSB, 55/AA, 서로 다른 양방향 데이터 |
| `axi_spi_random_test` | 랜덤 1,000건 | Master TX와 Slave TX를 랜덤화한 반복 전송 |

랜덤 constraint는 **Mode 0 (`CPOL=0`, `CPHA=0`), `clk_div=50`**입니다. 두 테스트는 별도 실행이며 기본 실행은 random test입니다.

Driver는 `TX_DATA write → CR write(start) → spi_intr 대기 → RX_DATA read` 순서로 동작합니다. Monitor는 완료 시점의 송신 정보를 보존한 뒤 RVALID에서 수신 레지스터 값을 수집합니다.

Scoreboard의 현재 비교식은 **`rx_data === slave_tx_data`**입니다. Slave 수신 포트는 이 UVM Top에서 관찰하지 않으므로, 이 scoreboard가 Master→Slave 경로까지 독립적으로 비교한다고 설명하지 않습니다.

---

## 5. 핵심 구현과 커버리지

| 구현 | 의도 |
|---|---|
| AXI register access task | 전송 시나리오에서 버스 접근 절차를 분리 |
| `spi_intr` 완료 관찰 | SPI 완료와 RX_DATA read 순서를 연결 |
| `mon_tx_data`, `mon_clk_div` | driver가 레지스터에 쓴 설정을 monitor가 transaction으로 정리 |
| Monitor analysis port 분기 | 하나의 관찰 transaction을 scoreboard와 coverage에 전달 |
| Clocking block | 구동·샘플링 시점을 명시하고 같은 시점 접근의 혼선을 줄임 |

| Coverpoint | Bin |
|---|---|
| TX_DATA / Slave TX / RX_DATA | 00, FF, 80, 01, 55, AA, 기타 데이터 범위 |

기타 데이터 범위에는 55/AA도 포함되므로 특수 패턴 bin과 겹치는 값이 있습니다. 현재 coverage는 데이터 패턴을 측정하며, AXI 채널 지연·WSTRB·응답 오류·SPI 모드 조합은 측정하지 않습니다.

---

## 6. 검증 결과와 확인 범위

| 구분 | 결과 / 기준 |
|---|---|
| 기존 서버 UVM 검증 기록 | 고정 15건 + 랜덤 1,000건, functional coverage 100%, scoreboard fail 0 |
| 기존 실보드 검증 기록 | Basys3 2대의 SPI Echo 통신 |
| 저장소 정리 시 로컬 RTL 재검증 | 16회 송수신, RX_DATA, sticky done/read-clear, 완료 인터럽트 16펄스 확인 |

서버 UVM 결과는 기존 포트폴리오에 기록한 결과입니다. 현재 업로드에는 VCS 실행 원본 로그와 functional coverage 보고서가 포함되어 있지 않아, 이 문서 정리 과정에서 해당 수치를 다시 실행·확인한 결과로 표기하지 않았습니다. 아래 실행 명령으로 재현한 뒤 scoreboard 처리 건수, fail count, UVM_ERROR/FATAL 및 coverage report를 함께 확인할 수 있습니다.

Functional coverage 100%는 **현재 정의한 bin을 모두 hit했다는 의미**입니다. 코드 커버리지 100% 또는 프로토콜 전체 검증 완료와는 구분합니다. `verification/evidence/`의 로컬 테스트 기록도 VCS UVM 실행 결과와 별도로 관리합니다.

---

## 7. 실행 방법

VCS / UVM 1.2 / Verdi 및 FSDB 연동 환경이 필요합니다.

```sh
git switch add-axi-spi-uvm
cd verification/uvm/axi_spi
make run TEST=axi_spi_basic_test INFO_LEVEL=UVM_MEDIUM
make run TEST=axi_spi_random_test SEED=1234 INFO_LEVEL=UVM_MEDIUM
verdi -dbdir ./simv.daidir -ssf axi_spi_tb.fsdb
```

테스트별 결과를 남기려면 실행 후 로그와 coverage DB를 구분해 보관합니다. 현재 Makefile은 `coverage.vdb`, `sim1`을 공통으로 사용합니다. `make wave`에는 잘못된 `//` 주석과 dump 파일명 불일치가 있어 위 Verdi 직접 실행 명령을 사용합니다.

별도의 로컬 RTL 테스트는 저장소 루트에서 `python verification/run_checks.py`로 실행합니다. 이 테스트는 VCS UVM 실행과 구분합니다. Vitis에는 사용자 C/헤더 소스를 보관하며 BSP·실행 파일은 재생성이 필요합니다.

---

## 8. 검증 범위와 향후 확장

- 현재 서버 UVM은 Mode 0, full-strobe, AW/W 동시 구동 조건입니다. 독립 채널 지연, backpressure, 오류 응답 시나리오를 추가할 수 있습니다.
- 기존 RTL에는 WSTRB 미반영과 읽기 응답 대기 중 새 주소 수락 문제가 남아 있습니다. 현재 시나리오의 통과를 AXI 전체 적합성으로 확대하지 않습니다.
- Master의 CPHA=1 수신 결과 반영은 보완이 필요합니다. 모드 1/3 지원 완료로 표기하지 않습니다.
- Scoreboard의 양방향 비교, 완료 timeout, SPI/AXI protocol assertion 및 cross coverage를 확장할 수 있습니다.
- 정리된 원본 프로젝트와 BD는 Vivado 2020.2 기준입니다. 새 환경에서 합성·타이밍·Vitis 빌드·보드 동작은 별도 확인이 필요합니다.

원본 선택 및 로컬 확인 이력은 [SELECTION_AND_VALIDATION.md](SELECTION_AND_VALIDATION.md), 파일 출처는 [SOURCE_MANIFEST.json](SOURCE_MANIFEST.json)에 기록했습니다.
