class axi_spi_base_seq extends uvm_sequence #(axi_spi_seq_item);
    `uvm_object_utils(axi_spi_base_seq)

    function new(string name = "axi_spi_base_seq");
        super.new(name);
    endfunction

    // 기본 전송 태스크
    task do_transfer(bit [7:0] tx, bit [7:0] slave_tx,
                     bit cpol=0, bit cpha=0, bit [7:0] clk_div=50);
        axi_spi_seq_item item;
        item = axi_spi_seq_item::type_id::create("item");
        start_item(item);
            item.cpol          = cpol;
            item.cpha          = cpha;
            item.clk_div       = clk_div;
            item.tx_data       = tx;
            item.slave_tx_data = slave_tx;
        finish_item(item);
    endtask
endclass

// -------------------------------------------------------
// 고정값 전송 시나리오
// -------------------------------------------------------
class axi_spi_basic_seq extends axi_spi_base_seq;
    `uvm_object_utils(axi_spi_basic_seq)

    int num;

    function new(string name = "axi_spi_basic_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "basic scenario start", UVM_LOW)

        // 경계값
        do_transfer(8'h00, 8'h00, 0, 0, 50);  // 둘 다 0
        do_transfer(8'hFF, 8'hFF, 0, 0, 50);  // 둘 다 최대
        do_transfer(8'h01, 8'h01, 0, 0, 50);  // 최솟값+1
        do_transfer(8'hFE, 8'hFE, 0, 0, 50);  // 최댓값-1

        // 교차 (tx ≠ slave_tx)
        do_transfer(8'h00, 8'hFF, 0, 0, 50);  // 교차
        do_transfer(8'hFF, 8'h00, 0, 0, 50);  // 교차

        // 단일 비트 (비트 시프트 버그 검출용)
        do_transfer(8'h80, 8'h80, 0, 0, 50);  // MSB만 1
        do_transfer(8'h01, 8'h80, 0, 0, 50);  // LSB tx, MSB slave
        do_transfer(8'h80, 8'h01, 0, 0, 50);  // MSB tx, LSB slave

        // 체커보드 패턴
        do_transfer(8'h55, 8'hAA, 0, 0, 50);  // 0101_0101 / 1010_1010
        do_transfer(8'hAA, 8'h55, 0, 0, 50);  // 1010_1010 / 0101_0101

        // 일반 패턴
        do_transfer(8'hA5, 8'h5A, 0, 0, 50);  // 1010_0101 / 0101_1010
        do_transfer(8'h12, 8'h34, 0, 0, 50);  // 서로 다른 값
        do_transfer(8'hAB, 8'hCD, 0, 0, 50);  // 서로 다른 값
        do_transfer(8'h88, 8'hCC, 0, 0, 50);  // 패턴

        `uvm_info(get_type_name(), "basic scenario end", UVM_LOW)
    endtask
endclass

// -------------------------------------------------------
// 랜덤 전송 시나리오
// -------------------------------------------------------
class axi_spi_random_seq extends axi_spi_base_seq;
    `uvm_object_utils(axi_spi_random_seq)

    int num;

    function new(string name = "axi_spi_random_seq");
        super.new(name);
    endfunction

    task body();
        axi_spi_seq_item item;
        `uvm_info(get_type_name(), $sformatf("random scenario start (%0d repeat)", num), UVM_LOW)
        repeat(num) begin
            item = axi_spi_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_error("SEQ", "randomize fail")
            finish_item(item);
        end
        `uvm_info(get_type_name(), "random scenario end", UVM_LOW)
    endtask
endclass
