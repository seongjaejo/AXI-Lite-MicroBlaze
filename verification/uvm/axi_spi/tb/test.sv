class axi_spi_base_test extends uvm_test;
    `uvm_component_utils(axi_spi_base_test)

    axi_spi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_spi_env::type_id::create("env", this);
    endfunction
endclass

// -------------------------------------------------------
// 고정값 테스트
// -------------------------------------------------------
class axi_spi_basic_test extends axi_spi_base_test;
    `uvm_component_utils(axi_spi_basic_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi_spi_basic_seq seq;
        phase.raise_objection(this);
        seq = axi_spi_basic_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask
endclass

// -------------------------------------------------------
// 랜덤 테스트
// -------------------------------------------------------
class axi_spi_random_test extends axi_spi_base_test;
    `uvm_component_utils(axi_spi_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi_spi_random_seq seq;
        phase.raise_objection(this);
        seq = axi_spi_random_seq::type_id::create("seq");
        seq.num = 1000;
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask
endclass
