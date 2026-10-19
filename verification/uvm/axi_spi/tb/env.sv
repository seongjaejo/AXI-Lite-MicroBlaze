class axi_spi_env extends uvm_env;
    `uvm_component_utils(axi_spi_env)

    axi_spi_agent      agt;
    axi_spi_scoreboard scb;
    axi_spi_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = axi_spi_agent::type_id::create("agt", this);
        scb = axi_spi_scoreboard::type_id::create("scb", this);
        cov = axi_spi_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction
endclass
