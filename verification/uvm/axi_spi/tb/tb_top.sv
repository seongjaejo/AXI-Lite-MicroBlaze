import uvm_pkg::*;
import pkg::*;

module tb_top ();

    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;  // 100MHz

    // -------------------------------------------------------
    // Interface 인스턴스
    // -------------------------------------------------------
    axi_spi_if s_if(.clk(clk));

    // -------------------------------------------------------
    // DUT: spi_master_v1_0
    // -------------------------------------------------------
    spi_master_v1_0 dut (
        // AXI 글로벌
        .s00_axi_aclk   (clk),
        .s00_axi_aresetn(s_if.aresetn),
        // AW 채널
        .s00_axi_awaddr (s_if.awaddr),
        .s00_axi_awprot (3'b0),
        .s00_axi_awvalid(s_if.awvalid),
        .s00_axi_awready(s_if.awready),
        // W 채널
        .s00_axi_wdata  (s_if.wdata),
        .s00_axi_wstrb  (s_if.wstrb),
        .s00_axi_wvalid (s_if.wvalid),
        .s00_axi_wready (s_if.wready),
        // B 채널
        .s00_axi_bresp  (s_if.bresp),
        .s00_axi_bvalid (s_if.bvalid),
        .s00_axi_bready (s_if.bready),
        // AR 채널
        .s00_axi_araddr (s_if.araddr),
        .s00_axi_arprot (3'b0),
        .s00_axi_arvalid(s_if.arvalid),
        .s00_axi_arready(s_if.arready),
        // R 채널
        .s00_axi_rdata  (s_if.rdata),
        .s00_axi_rresp  (s_if.rresp),
        .s00_axi_rvalid (s_if.rvalid),
        .s00_axi_rready (s_if.rready),
        // SPI 외부 핀
        .sclk           (s_if.sclk),
        .mosi           (s_if.mosi),
        .miso           (s_if.miso),
        .ss_n           (s_if.ss_n),
        .spi_intr       (s_if.spi_intr)
    );

    // -------------------------------------------------------
    // SPI Slave 인스턴스 (MISO echo 응답용)
    // -------------------------------------------------------
    spi_slave u_slave (
        .clk    (clk),
        .reset  (~s_if.aresetn),
        .tx_data(s_if.slave_tx_data),
        .rx_data(),
        .done   (),
        .busy   (),
        .sclk   (s_if.sclk),
        .mosi   (s_if.mosi),
        .miso   (s_if.miso),
        .ss_n   (s_if.ss_n)
    );

    // -------------------------------------------------------
    // UVM 시작
    // -------------------------------------------------------
    initial begin
        uvm_config_db #(virtual axi_spi_if)::set(null, "*", "s_if", s_if);
        run_test();
    end

    // -------------------------------------------------------
    // 파형 덤프
    // -------------------------------------------------------
	initial begin
	    $fsdbDumpfile("axi_spi_tb.fsdb");
	    $fsdbDumpvars(0, tb_top);
	    $fsdbDumpvars(0, tb_top.s_if);
	end

endmodule
