
module spi_master_v1_0_S00_AXI
(
    // SPI Master 연결 포트
    output wire [7:0] spi_tx_data,
    input  wire [7:0] spi_rx_data,
    output wire       spi_start,
    output wire       spi_cpol,
    output wire       spi_cpha,
    output wire [7:0] spi_clk_div,
    input  wire       spi_busy,
    input  wire       spi_done,
    output wire       spi_intr,

    // AXI 글로벌 신호
    input  wire        S_AXI_ACLK,
    input  wire        S_AXI_ARESETN,
    // AW channel
    input  wire [3:0]  S_AXI_AWADDR,
    input  wire [2:0]  S_AXI_AWPROT,
    input  wire        S_AXI_AWVALID,
    output wire        S_AXI_AWREADY,
    // W channel
    input  wire [31:0] S_AXI_WDATA,
    input  wire [3:0]  S_AXI_WSTRB,
    input  wire        S_AXI_WVALID,
    output wire        S_AXI_WREADY,
    // B channel
    output wire [1:0]  S_AXI_BRESP,
    output wire        S_AXI_BVALID,
    input  wire        S_AXI_BREADY,
    // AR channel
    input  wire [3:0]  S_AXI_ARADDR,
    input  wire [2:0]  S_AXI_ARPROT,
    input  wire        S_AXI_ARVALID,
    output wire        S_AXI_ARREADY,
    // R channel
    output wire [31:0] S_AXI_RDATA,
    output wire [1:0]  S_AXI_RRESP,
    output wire        S_AXI_RVALID,
    input  wire        S_AXI_RREADY
);

    // AXI 내부 신호
    reg [3:0]  axi_awaddr;
    reg        axi_awready;
    reg        axi_wready;
    reg [1:0]  axi_bresp;
    reg        axi_bvalid;
    reg [3:0]  axi_araddr;
    reg        axi_arready;
    reg [31:0] axi_rdata;
    reg [1:0]  axi_rresp;
    reg        axi_rvalid;
    reg        aw_en;

    // ★ SPI 레지스터 4개
    // REG0: CR     [+0x00] bit[15:8]=clk_div, bit[2]=cpha, bit[1]=cpol, bit[0]=start
    // REG1: TX_DATA[+0x04] bit[7:0]=tx_data
    // REG2: RX_DATA[+0x08] bit[7:0]=rx_data (읽기전용)
    // REG3: STATUS [+0x0C] bit[1]=done, bit[0]=busy (읽기전용)
    reg [31:0] spi_cr;
    reg [31:0] spi_tx_dr;
    reg [31:0] spi_rx_dr;
    reg [31:0] spi_status;

    wire       slv_reg_rden;
    wire       slv_reg_wren;
    reg [31:0] reg_data_out;
    reg        start_r;
    reg        start_delay;  // ★ 추가: 1클럭 지연용

    // AXI 출력 연결
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // SPI Master 출력 연결
    assign spi_tx_data = spi_tx_dr[7:0];
    assign spi_cpol    = spi_cr[1];
    assign spi_cpha    = spi_cr[2];
    assign spi_clk_div = spi_cr[15:8];
    assign spi_start   = start_r;  // ★ 1클럭 지연된 start 출력

    // ★ 추가: done 신호를 인터럽트로 출력
    assign spi_intr = spi_done;

    // -------------------------------------------------------
    // AXI Write 핸드셰이크
    // -------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en       <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en       <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en       <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0)
            axi_awaddr <= 0;
        else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            axi_awaddr <= S_AXI_AWADDR;
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0)
            axi_wready <= 1'b0;
        else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en)
                axi_wready <= 1'b1;
            else
                axi_wready <= 1'b0;
        end
    end

    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    // -------------------------------------------------------
    //  REG0: CR 쓰기 + start 펄스 생성 (★ 1클럭 지연 추가)
    // -------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            spi_cr      <= 0;
            start_delay <= 1'b0;
            start_r     <= 1'b0;
        end else begin
            start_delay <= 1'b0;       // 매 클럭 기본값: 0
            start_r     <= start_delay; // ★ 1클럭 지연: delay → start_r
            if (slv_reg_wren && axi_awaddr[3:2] == 2'h0) begin
                spi_cr      <= S_AXI_WDATA;
                start_delay <= S_AXI_WDATA[0]; // CR 쓰기 다음 클럭에 start 출력
            end
        end
    end

    //  REG1: TX_DATA 쓰기
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0)
            spi_tx_dr <= 0;
        else if (slv_reg_wren && axi_awaddr[3:2] == 2'h1)
            spi_tx_dr[7:0] <= S_AXI_WDATA[7:0];
    end

    //  REG2: RX_DATA 래칭 (done 신호 왔을 때 자동 저장)
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0)
            spi_rx_dr <= 0;
        else if (spi_done)
            spi_rx_dr[7:0] <= spi_rx_data;
    end

    //  REG3: STATUS (busy, done 반영)
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0)
            spi_status <= 0;
        else begin
            spi_status[0] <= spi_busy;
            if (spi_done)
                spi_status[1] <= 1'b1;
            else if (slv_reg_rden && axi_araddr[3:2] == 2'h3)
                spi_status[1] <= 1'b0;
        end
    end

    // -------------------------------------------------------
    // AXI Write Response
    // -------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------
    // AXI Read 핸드셰이크
    // -------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 4'b0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------
    //  Read 디코딩
    // -------------------------------------------------------
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    always @(*) begin
        case (axi_araddr[3:2])
            2'h0: reg_data_out = spi_cr;
            2'h1: reg_data_out = spi_tx_dr;
            2'h2: reg_data_out = spi_rx_dr;
            2'h3: reg_data_out = spi_status;
            default: reg_data_out = 0;
        endcase
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0)
            axi_rdata <= 0;
        else if (slv_reg_rden)
            axi_rdata <= reg_data_out;
    end

endmodule
