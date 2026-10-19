class axi_spi_driver extends uvm_driver #(axi_spi_seq_item);
    `uvm_component_utils(axi_spi_driver)

    virtual axi_spi_if s_if;

    // AXI 레지스터 주소 (오프셋)
    localparam CR_ADDR      = 4'h0;
    localparam TX_DATA_ADDR = 4'h4;
    localparam RX_DATA_ADDR = 4'h8;
    localparam STATUS_ADDR  = 4'hC;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_spi_if)::get(this, "", "s_if", s_if))
            `uvm_fatal(get_type_name(), "can't find virtual interface(s_if) from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // 초기값 설정
        s_if.drv_cb.aresetn       <= 0;
        s_if.drv_cb.awaddr        <= 0;
        s_if.drv_cb.awvalid       <= 0;
        s_if.drv_cb.wdata         <= 0;
        s_if.drv_cb.wstrb         <= 4'hF;
        s_if.drv_cb.wvalid        <= 0;
        s_if.drv_cb.bready        <= 1;
        s_if.drv_cb.araddr        <= 0;
        s_if.drv_cb.arvalid       <= 0;
        s_if.drv_cb.rready        <= 1;
        s_if.drv_cb.slave_tx_data <= 0;
        s_if.drv_cb.mon_tx_data   <= 0;
        s_if.drv_cb.mon_clk_div   <= 0;

        // reset 구간
        repeat(3) @(s_if.drv_cb);
        s_if.drv_cb.aresetn <= 1;
        @(s_if.drv_cb);

        forever begin
            seq_item_port.get_next_item(req);

            // slave tx_data 주입
            s_if.drv_cb.slave_tx_data <= req.slave_tx_data;
            @(s_if.drv_cb);

            // ① AXI Write TX_DATA 레지스터 (0x04)
            //    monitor 캡처용으로 mon_tx_data에 미리 래칭
            s_if.drv_cb.mon_tx_data <= req.tx_data;
            axi_write(TX_DATA_ADDR, {24'h0, req.tx_data});

            // ② AXI Write CR 레지스터 (0x00)
            //    bit[15:8]=clk_div, bit[2]=cpha, bit[1]=cpol, bit[0]=start=1
            //    monitor 캡처용으로 mon_clk_div에 미리 래칭
            s_if.drv_cb.mon_clk_div <= req.clk_div;
            axi_write(CR_ADDR, {16'h0,
                                 req.clk_div,
                                 5'h0,
                                 req.cpha,
                                 req.cpol,
                                 1'b1});  // start=1

            // ③ spi_intr(done) 올라올 때까지 대기
            @(s_if.drv_cb iff (s_if.drv_cb.spi_intr === 1));

            // ④ AXI Read RX_DATA 레지스터 (0x08)
            axi_read(RX_DATA_ADDR, req.rx_data);

            `uvm_info(get_type_name(), $sformatf("run: %s", req.convert2string()), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask

    // -------------------------------------------------------
    // AXI Write 태스크
    // -------------------------------------------------------
    task axi_write(input logic [3:0] addr, input logic [31:0] data);
        // AW + W 채널 동시 구동
        @(s_if.drv_cb);
        s_if.drv_cb.awaddr  <= addr;
        s_if.drv_cb.awvalid <= 1;
        s_if.drv_cb.wdata   <= data;
        s_if.drv_cb.wstrb   <= 4'hF;
        s_if.drv_cb.wvalid  <= 1;

        // AWREADY + WREADY 핸드셰이크 대기
        @(s_if.drv_cb iff (s_if.drv_cb.awready === 1 && s_if.drv_cb.wready === 1));
        s_if.drv_cb.awvalid <= 0;
        s_if.drv_cb.wvalid  <= 0;

        // B 채널 응답 대기
        @(s_if.drv_cb iff (s_if.drv_cb.bvalid === 1));
    endtask

    // -------------------------------------------------------
    // AXI Read 태스크
    // -------------------------------------------------------
    task axi_read(input logic [3:0] addr, output logic [7:0] data);
        @(s_if.drv_cb);
        s_if.drv_cb.araddr  <= addr;
        s_if.drv_cb.arvalid <= 1;
        s_if.drv_cb.rready  <= 1;

        // ARREADY 핸드셰이크 대기
        @(s_if.drv_cb iff (s_if.drv_cb.arready === 1));
        s_if.drv_cb.arvalid <= 0;

        // RVALID 대기 후 데이터 캡처
        @(s_if.drv_cb iff (s_if.drv_cb.rvalid === 1));
        data = s_if.drv_cb.rdata[7:0];
    endtask

endclass
