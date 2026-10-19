class axi_spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_spi_scoreboard)

    uvm_analysis_imp #(axi_spi_seq_item, axi_spi_scoreboard) imp;

    int trans_count = 0;
    int pass_count  = 0;
    int fail_count  = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void write(axi_spi_seq_item tr);
        bit tx_rx_ok;
        bit echo_ok;
        trans_count++;

        echo_ok = (tr.rx_data === tr.slave_tx_data);

        if (echo_ok) begin
            pass_count++;
            `uvm_info(get_type_name(), $sformatf(
                "PASS : %s", tr.convert2string()), UVM_HIGH)
        end else begin
            fail_count++;
            `uvm_error(get_type_name(), $sformatf(
                "FAIL [echo] slave_tx=0x%02h rx_data=0x%02h",
                tr.slave_tx_data, tr.rx_data))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB", "==================================", UVM_LOW)
        `uvm_info("SCB", "=========Scoreboard report========", UVM_LOW)
        `uvm_info("SCB", $sformatf("  trans   count : %0d", trans_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  pass    count : %0d", pass_count),  UVM_LOW)
        `uvm_info("SCB", $sformatf("  fail    count : %0d", fail_count),  UVM_LOW)
        `uvm_info("SCB", "==================================", UVM_LOW)
    endfunction
endclass
