package pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    // 의존성 순서대로 include
    `include "seq_item.sv"
    `include "sequence.sv"
    `include "driver.sv"
    `include "monitor.sv"
    `include "agent.sv"
    `include "scoreboard.sv"
    `include "coverage.sv"
    `include "env.sv"
    `include "test.sv"
endpackage
