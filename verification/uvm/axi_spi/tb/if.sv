
interface axi_spi_if (
    input logic clk
);
    // -------------------------------------------------------
    // AXI4-Lite Write 채널
    // -------------------------------------------------------
    logic        aresetn;
    logic [3:0]  awaddr;
    logic        awvalid;
    logic        awready;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid;
    logic        wready;
    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready;
    // -------------------------------------------------------
    // AXI4-Lite Read 채널
    // -------------------------------------------------------
    logic [3:0]  araddr;
    logic        arvalid;
    logic        arready;
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid;
    logic        rready;
    // -------------------------------------------------------
    // SPI 외부 핀 (모니터링용)
    // -------------------------------------------------------
    logic        sclk;
    logic        mosi;
    logic        miso;
    logic        ss_n;
    logic        spi_intr;
    // -------------------------------------------------------
    // Slave tx_data (driver → slave 직접 주입)
    // -------------------------------------------------------
    logic [7:0]  slave_tx_data;
    // -------------------------------------------------------
    // 모니터링용 래칭 신호 (driver가 TX_DATA/CR 쓸 때 저장)
    // -------------------------------------------------------
    logic [7:0]  mon_tx_data;   // TX_DATA 레지스터에 쓴 값
    logic [7:0]  mon_clk_div;   // CR에 쓴 clk_div 값
    // -------------------------------------------------------
    // driver clocking block
    // -------------------------------------------------------
    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        // AXI Write
        output aresetn;
        output awaddr;
        output awvalid;
        input  awready;
        output wdata;
        output wstrb;
        output wvalid;
        input  wready;
        input  bresp;
        input  bvalid;
        output bready;
        // AXI Read
        output araddr;
        output arvalid;
        input  arready;
        input  rdata;
        input  rresp;
        input  rvalid;
        output rready;
        // Slave tx 주입
        output slave_tx_data;
        // 모니터링용 래칭 신호
        output mon_tx_data;
        output mon_clk_div;
        // 인터럽트
        input  spi_intr;
    endclocking
    // -------------------------------------------------------
    // monitor clocking block
    // -------------------------------------------------------
    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        // AXI Write
        input aresetn;
        input awaddr;
        input awvalid;
        input awready;
        input wdata;
        input wstrb;
        input wvalid;
        input wready;
        input bresp;
        input bvalid;
        input bready;
        // AXI Read
        input araddr;
        input arvalid;
        input arready;
        input rdata;
        input rresp;
        input rvalid;
        input rready;
        // SPI 핀
        input sclk;
        input mosi;
        input miso;
        input ss_n;
        input spi_intr;
        // Slave tx
        input slave_tx_data;
        // 모니터링용 래칭 신호
        input mon_tx_data;
        input mon_clk_div;
    endclocking

    modport DRV(clocking drv_cb, input clk);
    modport MON(clocking mon_cb, input clk);

endinterface
