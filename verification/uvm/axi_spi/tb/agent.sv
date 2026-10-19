class axi_spi_agent extends uvm_agent;
    `uvm_component_utils(axi_spi_agent)

    uvm_sequencer #(axi_spi_seq_item) sqr;
    axi_spi_driver                    drv;
    axi_spi_monitor                   mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sqr = uvm_sequencer#(axi_spi_seq_item)::type_id::create("sqr", this);
        drv = axi_spi_driver::type_id::create("drv", this);
        mon = axi_spi_monitor::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass
