`timescale 1ns / 1ps

module tb_axi_spi ();

    logic clk;
    logic reset_n;

    logic [3:0]  s00_axi_awaddr;
    logic [2:0]  s00_axi_awprot;
    logic        s00_axi_awvalid;
    logic        s00_axi_awready;
    logic [31:0] s00_axi_wdata;
    logic [3:0]  s00_axi_wstrb;
    logic        s00_axi_wvalid;
    logic        s00_axi_wready;
    logic [1:0]  s00_axi_bresp;
    logic        s00_axi_bvalid;
    logic        s00_axi_bready;
    logic [3:0]  s00_axi_araddr;
    logic [2:0]  s00_axi_arprot;
    logic        s00_axi_arvalid;
    logic        s00_axi_arready;
    logic [31:0] s00_axi_rdata;
    logic [1:0]  s00_axi_rresp;
    logic        s00_axi_rvalid;
    logic        s00_axi_rready;

    logic sclk;
    logic mosi;
    logic miso;
    logic ss_n;

    assign miso = mosi;

    localparam SPI_CR_ADDR     = 32'h00000000;
    localparam SPI_TX_ADDR     = 32'h00000004;
    localparam SPI_RX_ADDR     = 32'h00000008;
    localparam SPI_STATUS_ADDR = 32'h0000000C;

    spi_master_v1_0 dut (
        .sclk            (sclk),
        .mosi            (mosi),
        .miso            (miso),
        .ss_n            (ss_n),
        .s00_axi_aclk    (clk),
        .s00_axi_aresetn (reset_n),
        .s00_axi_awaddr  (s00_axi_awaddr),
        .s00_axi_awprot  (s00_axi_awprot),
        .s00_axi_awvalid (s00_axi_awvalid),
        .s00_axi_awready (s00_axi_awready),
        .s00_axi_wdata   (s00_axi_wdata),
        .s00_axi_wstrb   (s00_axi_wstrb),
        .s00_axi_wvalid  (s00_axi_wvalid),
        .s00_axi_wready  (s00_axi_wready),
        .s00_axi_bresp   (s00_axi_bresp),
        .s00_axi_bvalid  (s00_axi_bvalid),
        .s00_axi_bready  (s00_axi_bready),
        .s00_axi_araddr  (s00_axi_araddr),
        .s00_axi_arprot  (s00_axi_arprot),
        .s00_axi_arvalid (s00_axi_arvalid),
        .s00_axi_arready (s00_axi_arready),
        .s00_axi_rdata   (s00_axi_rdata),
        .s00_axi_rresp   (s00_axi_rresp),
        .s00_axi_rvalid  (s00_axi_rvalid),
        .s00_axi_rready  (s00_axi_rready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic AXI_WriteData(logic [31:0] addr, logic [31:0] data);
        s00_axi_awaddr  <= addr[3:0];
        s00_axi_awvalid <= 1'b1;
        s00_axi_wdata   <= data;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_bready  <= 1'b1;
        s00_axi_wstrb   <= 4'b1111;
        @(posedge clk);
        wait (s00_axi_awready & s00_axi_wready);
        @(posedge clk);
        s00_axi_awvalid <= 1'b0;
        s00_axi_wvalid  <= 1'b0;
        @(posedge clk);
        wait (s00_axi_bvalid);
        @(posedge clk);
        s00_axi_bready <= 1'b0;
        @(posedge clk);
    endtask

    task automatic AXI_ReadData(input logic [31:0] addr, output logic [31:0] rdata);
        s00_axi_araddr  <= addr[3:0];
        s00_axi_arvalid <= 1'b1;
        s00_axi_rready  <= 1'b1;
        @(posedge clk);
        wait (s00_axi_arready);
        @(posedge clk);
        s00_axi_arvalid <= 1'b0;
        wait (s00_axi_rvalid);
        rdata = s00_axi_rdata;
        @(posedge clk);
        s00_axi_rready <= 1'b0;
        @(posedge clk);
    endtask

    task automatic SPI_Transfer(input logic [7:0] tx_byte, input logic [7:0] expected);
        logic [31:0] status;
        logic [31:0] rx_val;

        $display("[TB] TX: 0x%02X", tx_byte);

        // ① TX_DATA 쓰기
        AXI_WriteData(SPI_TX_ADDR, {24'h0, tx_byte});

        // ② CR 쓰기: clk_div=4, cpha=0, cpol=0, start=1
        AXI_WriteData(SPI_CR_ADDR, (4 << 8) | 1);

        // ③ done(bit1) 폴링 → 1클럭짜리 펄스라 busy보다 안정적
        status = 32'h0;
        while (!(status & 32'h2))
            AXI_ReadData(SPI_STATUS_ADDR, status);

        // ④ RX 읽기
        AXI_ReadData(SPI_RX_ADDR, rx_val);

        $display("[TB] RX: 0x%02X (예상: 0x%02X) %s",
            rx_val[7:0], expected,
            (rx_val[7:0] == expected) ? "PASS" : "FAIL");
    endtask

    initial begin
        reset_n         = 0;
        s00_axi_awaddr  = 0;
        s00_axi_awprot  = 0;
        s00_axi_awvalid = 0;
        s00_axi_wdata   = 0;
        s00_axi_wstrb   = 0;
        s00_axi_wvalid  = 0;
        s00_axi_bready  = 0;
        s00_axi_araddr  = 0;
        s00_axi_arprot  = 0;
        s00_axi_arvalid = 0;
        s00_axi_rready  = 0;

        repeat (5) @(posedge clk);
        reset_n = 1;
        @(posedge clk);

        $display("==============================================");
        $display("[TB] SPI Loopback 테스트 시작");
        $display("==============================================");

        SPI_Transfer(8'hAA, 8'hAA);
        SPI_Transfer(8'h55, 8'h55);
        SPI_Transfer(8'h12, 8'h12);
        SPI_Transfer(8'hA5, 8'hA5);
        SPI_Transfer(8'hFF, 8'hFF);

        $display("==============================================");
        $display("[TB] 테스트 완료");
        $display("==============================================");

        #100;
        $finish;
    end

endmodule
