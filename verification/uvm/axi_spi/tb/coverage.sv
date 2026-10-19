class axi_spi_coverage extends uvm_subscriber #(axi_spi_seq_item);
    `uvm_component_utils(axi_spi_coverage)

    axi_spi_seq_item tr;

    covergroup axi_spi_cg;
        option.per_instance = 1;

        // tx_data 커버리지
        cp_tx_data : coverpoint tr.tx_data {
            bins data_zero     = {8'h00};
            bins data_max      = {8'hFF};
            bins data_msb_only = {8'h80};
            bins data_lsb_only = {8'h01};
            bins data_checker1 = {8'h55};
            bins data_checker2 = {8'hAA};
            bins data_etc      = {[8'h02:8'h7F],
                                  [8'h81:8'hFE]};
        }

        // slave_tx_data 커버리지
        cp_slave_tx : coverpoint tr.slave_tx_data {
            bins data_zero     = {8'h00};
            bins data_max      = {8'hFF};
            bins data_msb_only = {8'h80};
            bins data_lsb_only = {8'h01};
            bins data_checker1 = {8'h55};
            bins data_checker2 = {8'hAA};
            bins data_etc      = {[8'h02:8'h7F],
                                  [8'h81:8'hFE]};
        }

        // rx_data 커버리지
        cp_rx_data : coverpoint tr.rx_data {
            bins data_zero     = {8'h00};
            bins data_max      = {8'hFF};
            bins data_msb_only = {8'h80};
            bins data_lsb_only = {8'h01};
            bins data_checker1 = {8'h55};
            bins data_checker2 = {8'hAA};
            bins data_etc      = {[8'h02:8'h7F],
                                  [8'h81:8'hFE]};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        axi_spi_cg = new();
    endfunction

    function void write(axi_spi_seq_item t);
        tr = t;
        axi_spi_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", "==========================================", UVM_LOW)
        `uvm_info("COV", "======= Functional Coverage  result ======", UVM_LOW)
        `uvm_info("COV", $sformatf(" total      : %6.2f %%", axi_spi_cg.get_inst_coverage()),              UVM_LOW)
        `uvm_info("COV", $sformatf(" tx_data    : %6.2f %%", axi_spi_cg.cp_tx_data.get_inst_coverage()),  UVM_LOW)
        `uvm_info("COV", $sformatf(" slave_tx   : %6.2f %%", axi_spi_cg.cp_slave_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf(" rx_data    : %6.2f %%", axi_spi_cg.cp_rx_data.get_inst_coverage()),  UVM_LOW)
        `uvm_info("COV", "==========================================", UVM_LOW)
        if (axi_spi_cg.get_inst_coverage() < 100.0) begin
            `uvm_warning("COV", "Coverage below 100%! Add more test scenarios or perform additional testing.")
        end
    endfunction
endclass
