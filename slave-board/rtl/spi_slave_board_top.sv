`timescale 1ns / 1ps

module spi_slave_board_top (
    input  logic clk,
    input  logic reset,

    input  logic sclk,
    input  logic mosi,
    output logic miso,
    input  logic ss_n
);

    logic [7:0] slave_tx_data;
    logic [7:0] slave_rx_data;
    logic       slave_done;

    assign slave_tx_data = echo_data_reg;

    logic [7:0] echo_data_reg;

    spi_slave U_SPI_SLAVE (
        .clk    (clk),
        .reset  (reset),
        .tx_data(slave_tx_data),
        .rx_data(slave_rx_data),
        .done   (slave_done),
        .busy   (),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            echo_data_reg <= 8'h00;
        else if (slave_done)
            echo_data_reg <= slave_rx_data;
    end

endmodule
