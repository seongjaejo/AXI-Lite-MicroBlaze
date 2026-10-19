`timescale 1 ns / 1 ps

module spi_master_v1_0 #
(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
)
(
    // SPI 외부 핀
    output wire sclk,
    output wire mosi,
    input  wire miso,
    output wire ss_n,
    output wire spi_intr,

    // AXI Slave 포트
    input  wire s00_axi_aclk,
    input  wire s00_axi_aresetn,
    input  wire [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr,
    input  wire [2:0] s00_axi_awprot,
    input  wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input  wire [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata,
    input  wire [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb,
    input  wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1:0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input  wire s00_axi_bready,
    input  wire [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr,
    input  wire [2:0] s00_axi_arprot,
    input  wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata,
    output wire [1:0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input  wire s00_axi_rready
);

    // AXI <-> SPI 연결 wire
    wire [7:0] spi_tx_data;
    wire [7:0] spi_rx_data;
    wire       spi_start;
    wire       spi_cpol;
    wire       spi_cpha;
    wire [7:0] spi_clk_div;
    wire       spi_busy;
    wire       spi_done;

    // AXI S00 인스턴스
    spi_master_v1_0_S00_AXI U_spi_master_v1_0_S00_AXI (
        .spi_tx_data  (spi_tx_data),
        .spi_rx_data  (spi_rx_data),
        .spi_start    (spi_start),
        .spi_cpol     (spi_cpol),
        .spi_cpha     (spi_cpha),
        .spi_clk_div  (spi_clk_div),
        .spi_busy     (spi_busy),
        .spi_done     (spi_done),
        // ★ 추가
        .spi_intr     (spi_intr),
        .S_AXI_ACLK   (s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR (s00_axi_awaddr),
        .S_AXI_AWPROT (s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA  (s00_axi_wdata),
        .S_AXI_WSTRB  (s00_axi_wstrb),
        .S_AXI_WVALID (s00_axi_wvalid),
        .S_AXI_WREADY (s00_axi_wready),
        .S_AXI_BRESP  (s00_axi_bresp),
        .S_AXI_BVALID (s00_axi_bvalid),
        .S_AXI_BREADY (s00_axi_bready),
        .S_AXI_ARADDR (s00_axi_araddr),
        .S_AXI_ARPROT (s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA  (s00_axi_rdata),
        .S_AXI_RRESP  (s00_axi_rresp),
        .S_AXI_RVALID (s00_axi_rvalid),
        .S_AXI_RREADY (s00_axi_rready)
    );

    // SPI Master 인스턴스
    spi_master U_SPI_MASTER (
        .clk     (s00_axi_aclk),
        .reset   (~s00_axi_aresetn),
        .start   (spi_start),
        .cpol    (spi_cpol),
        .cpha    (spi_cpha),
        .clk_div (spi_clk_div),
        .tx_data (spi_tx_data),
        .busy    (spi_busy),
        .rx_data (spi_rx_data),
        .done    (spi_done),
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso),
        .ss_n    (ss_n)
    );

endmodule


module spi_master (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire       cpol,
    input  wire       cpha,
    input  wire [7:0] clk_div,
    input  wire [7:0] tx_data,
    output reg        busy,
    output reg  [7:0] rx_data,
    output reg        done,
    output wire       sclk,
    output reg        mosi,
    input  wire       miso,
    output reg        ss_n
);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;

    reg [7:0] div_cnt;
    reg [7:0] clk_div_r;
    reg       half_tick;
    reg [7:0] tx_shift_reg;
    reg [7:0] rx_shift_reg;
    reg [2:0] bit_cnt;
    reg       step;
    reg       cpol_r;
    reg       cpha_r;
    reg       sclk_r;

    assign sclk = sclk_r;

    // 클럭 분주기 (half_tick 생성)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt   <= 0;
            half_tick <= 1'b0;
        end else begin
            if (state == DATA) begin
                if (div_cnt == clk_div_r) begin
                    div_cnt   <= 0;
                    half_tick <= 1'b1;
                end else begin
                    div_cnt   <= div_cnt + 1;
                    half_tick <= 1'b0;
                end
            end else begin
                div_cnt   <= 0;
                half_tick <= 1'b0;
            end
        end
    end

    // SPI FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            mosi         <= 1'b1;
            ss_n         <= 1'b1;
            busy         <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            rx_data      <= 0;
            sclk_r       <= 1'b0;
            cpol_r       <= 1'b0;
            cpha_r       <= 1'b0;
            clk_div_r    <= 0;
            step         <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    mosi   <= 1'b1;
                    ss_n   <= 1'b1;
                    sclk_r <= cpol;
                    if (start) begin
                        state        <= START;
                        cpol_r       <= cpol;
                        cpha_r       <= cpha;
                        tx_shift_reg <= tx_data;
                        clk_div_r    <= clk_div;
                        bit_cnt      <= 0;
                        busy         <= 1'b1;
                        step         <= 1'b0;
                        ss_n         <= 1'b0;
                    end
                end
                START: begin
                    if (cpha_r == 1'b0) begin
                        mosi         <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    end
                    state <= DATA;
                end
                DATA: begin
                    if (half_tick) begin
                        sclk_r <= ~sclk_r;
                        if (step == 0) begin
                            step <= 1'b1;
                            if (cpha_r == 1'b0) begin
                                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            end else begin
                                mosi         <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end
                        end else begin
                            step <= 1'b0;
                            if (cpha_r == 1'b0) begin
                                if (bit_cnt < 7) begin
                                    mosi         <= tx_shift_reg[7];
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                            end else begin
                                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            end
                            if (bit_cnt == 7) begin
                                state <= STOP;
                                if (cpha_r == 1'b0) begin
                                    rx_data <= rx_shift_reg;
                                end else begin
                                    rx_shift_reg <= {rx_shift_reg[6:0], miso};
                                end
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                end
                STOP: begin
                    sclk_r <= cpol_r;
                    ss_n   <= 1'b1;
                    done   <= 1'b1;
                    busy   <= 1'b0;
                    mosi   <= 1'b1;
                    state  <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule


