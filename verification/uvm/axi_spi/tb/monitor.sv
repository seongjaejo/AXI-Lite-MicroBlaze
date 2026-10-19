class axi_spi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_spi_monitor)

    virtual axi_spi_if s_if;
    uvm_analysis_port #(axi_spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_spi_if)::get(this, "", "s_if", s_if))
            `uvm_fatal(get_type_name(), "can't find virtual interface(s_if) from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        axi_spi_seq_item tr;
        forever begin
            // spi_intr(done) 올라올 때까지 대기
            @(s_if.mon_cb iff (s_if.mon_cb.spi_intr === 1));

            // 트랜잭션 캡처
            tr = axi_spi_seq_item::type_id::create("tr");

            // driver가 TX_DATA 쓸 때 미리 래칭해둔 값 캡처
            tr.tx_data       = s_if.mon_cb.mon_tx_data;
            tr.clk_div       = s_if.mon_cb.mon_clk_div;
            tr.slave_tx_data = s_if.mon_cb.slave_tx_data;
            tr.done          = s_if.mon_cb.spi_intr;

            // spi_intr 이후 RVALID 올라올 때 rx_data 캡처
            @(s_if.mon_cb iff (s_if.mon_cb.rvalid === 1));
            tr.rx_data = s_if.mon_cb.rdata[7:0];

            `uvm_info(get_type_name(), $sformatf("%s", tr.convert2string()), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask
endclass
