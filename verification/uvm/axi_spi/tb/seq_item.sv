class axi_spi_seq_item extends uvm_sequence_item;
    // -------------------------------------------------------
    // driver 입력 필드
    // -------------------------------------------------------
    rand bit [7:0]  clk_div;       // constraint로 고정하지만 확장성 위해 rand 유지
    rand bit        cpol;          // constraint로 mode 0 고정
    rand bit        cpha;          // constraint로 mode 0 고정
    rand bit [7:0]  tx_data;       // AXI TX_DATA 레지스터에 쓸 값
    rand bit [7:0]  slave_tx_data; // Slave가 Master에게 돌려줄 값
    // -------------------------------------------------------
    // monitor 캡처 필드
    // -------------------------------------------------------
         bit [7:0]  rx_data;       // AXI RX_DATA 레지스터에서 읽은 값
         bit        done;          // spi_intr(done) 수신 여부

    // clk_div 50 고정 (2MHz, 실제 보드 검증값)
    constraint c_clk_div { clk_div == 50; }
    // slave mode 0 고정이라 cpol, cpha 0으로 제한
    constraint c_mode    { cpol == 0; cpha == 0; }

    `uvm_object_utils_begin(axi_spi_seq_item)
        `uvm_field_int(clk_div,       UVM_ALL_ON)
        `uvm_field_int(cpol,          UVM_ALL_ON)
        `uvm_field_int(cpha,          UVM_ALL_ON)
        `uvm_field_int(tx_data,       UVM_ALL_ON)
        `uvm_field_int(slave_tx_data, UVM_ALL_ON)
        `uvm_field_int(rx_data,       UVM_ALL_ON)
        `uvm_field_int(done,          UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_spi_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "clk_div=%0d cpol=%0d cpha=%0d | tx=0x%02h slave_tx=0x%02h | rx=0x%02h done=%0d",
            clk_div, cpol, cpha, tx_data, slave_tx_data, rx_data, done);
    endfunction
endclass
