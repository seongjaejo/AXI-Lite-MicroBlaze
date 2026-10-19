`timescale 1 ns / 1 ps

module i2c_master_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    output wire scl,
    inout  wire sda,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire s00_axi_rready
);
    wire       cmd_start;
    wire       cmd_read;
    wire [7:0] slave_addr;
    wire [7:0] tx_data;
    wire [7:0] rx_data;
    wire       ack_in;
    wire       ack_out;
    wire       busy;
    wire       done;

    assign ack_in = 1'b1;
    // Instantiation of Axi Bus Interface S00_AXI
    i2c_master_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) i2c_master_v1_0_S00_AXI_inst (
        .cmd_start(cmd_start),
        .cmd_read(cmd_read),
        .slave_addr(slave_addr),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .busy(busy),
        .done(done),
        .ack_out(ack_out),
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    // Add user logic here
    i2c_master_top U_I2C (
        .clk(s00_axi_aclk),
        .rst(~s00_axi_aresetn),
        .cmd_start(cmd_start),
        .cmd_read(cmd_read),

        .slave_addr(slave_addr),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ack_in(ack_in),
        .ack_out(ack_out),
        .busy(busy),
        .done(done),
        .scl(scl),
        .sda(sda)
    );
    // User logic ends

endmodule

module i2c_master_top (
    input  wire       clk,
    input  wire       rst,
    input  wire       cmd_start,
    input  wire       cmd_read,
    input  wire [7:0] slave_addr,
    input  wire [7:0] tx_data,
    output wire [7:0] rx_data,
    input  wire       ack_in,
    output wire       ack_out,
    output wire       busy,
    output wire       done,
    output wire       scl,
    inout  wire       sda
);
    wire sda_o, sda_i;
    assign sda_i = sda;
    assign sda   = (sda_o) ? 1'bz : 1'b0;
    i2c_master U_I2C_MASTER (
        .clk(clk),
        .rst(rst),
        .cmd_start(cmd_start),
        .cmd_read(cmd_read),

        .slave_addr(slave_addr),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ack_in(ack_in),
        .ack_out(ack_out),
        .busy(busy),
        .done(done),
        .scl(scl),
        .sda_o(sda_o),
        .sda_i(sda_i)
    );

endmodule

module i2c_master (
    input wire clk,
    input wire rst,
    input wire cmd_start,
    input wire cmd_read,

    input  wire [7:0] slave_addr,
    input  wire [7:0] tx_data,
    output reg  [7:0] rx_data,
    input  wire       ack_in,
    output reg        ack_out,
    output wire       busy,
    output reg        done,
    output wire       scl,
    output wire       sda_o,
    input  wire       sda_i
);

    parameter IDLE      = 3'd0,
          START     = 3'd1,
          SEND_ADDR = 3'd2,
          ADDR_ACK  = 3'd3,
          SEND_DATA = 3'd4,
          DATA_ACK  = 3'd5,
          STOP      = 3'd6;

    reg [2:0] state;
    reg scl_r;
    reg sda_r;
    reg [7:0] div_cnt;
    reg qtr_tick;
    reg [1:0] step;
    reg [7:0] tx_shift_reg;
    reg [7:0] rx_shift_reg;
    reg [2:0] bit_cnt;
    reg is_read;
    reg ack_in_r;

    assign scl   = scl_r;
    assign sda_o = sda_r;
    assign busy  = (state != IDLE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_cnt  <= 0;
            qtr_tick <= 1'b0;
        end else begin
            if (state == IDLE) begin
                div_cnt  <= 0;
                qtr_tick <= 1'b0;
            end else begin
                if (div_cnt == 8'd249) begin
                    div_cnt  <= 0;
                    qtr_tick <= 1'b1;
                end else begin
                    div_cnt  <= div_cnt + 1'b1;
                    qtr_tick <= 1'b0;
                end
            end
        end
    end

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            scl_r        <= 1'b1;
            sda_r        <= 1'b1;
            step         <= 0;
            bit_cnt      <= 0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            rx_data      <= 0;
            is_read      <= 1'b0;
            ack_out      <= 1'b1;
            done         <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    scl_r <= 1'b1;
                    sda_r <= 1'b1;
                    step  <= 2'd0;
                    if (cmd_start) begin
                        is_read <= cmd_read;

                        tx_shift_reg <= slave_addr;

                        bit_cnt <= 0;
                        step <= 0;

                        state <= START;
                    end
                end
                START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b1;
                                sda_r <= 1'b1;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                sda_r <= 1'b0;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b0;
                                sda_r <= 1'b0;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                sda_r <= 1'b0;
                                step <= 2'd0;
                                bit_cnt <= 0;

                                state <= SEND_ADDR;
                            end
                        endcase
                    end
                end
                SEND_ADDR: begin
                    if (qtr_tick) begin
                        case (step)

                            2'd0: begin
                                scl_r <= 1'b0;
                                sda_r <= tx_shift_reg[7];
                                step  <= 2'd1;
                            end

                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end

                            2'd2: begin
                                scl_r <= 1'b1;
                                step  <= 2'd3;
                            end

                            2'd3: begin
                                scl_r <= 1'b0;

                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};

                                if (bit_cnt == 3'd7) begin
                                    bit_cnt <= 0;
                                    step <= 0;
                                    state <= ADDR_ACK;
                                end else begin
                                    bit_cnt <= bit_cnt + 1'b1;
                                    step <= 0;
                                end
                            end

                        endcase
                    end
                end
                ADDR_ACK: begin

                    if (qtr_tick) begin

                        case (step)

                            2'd0: begin
                                scl_r <= 1'b0;
                                sda_r <= 1'b1;
                                step  <= 2'd1;
                            end

                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end

                            2'd2: begin

                                scl_r <= 1'b1;

                                ack_out <= sda_i;

                                step <= 2'd3;

                            end

                            2'd3: begin

                                scl_r <= 1'b0;

                                step <= 0;
                                bit_cnt <= 0;

                                if (is_read) begin
                                    rx_shift_reg <= 0;
                                end else begin
                                    tx_shift_reg <= tx_data;
                                end

                                state <= SEND_DATA;

                            end

                        endcase

                    end

                end
                SEND_DATA: begin

                    if (qtr_tick) begin

                        case (step)

                            2'd0: begin

                                scl_r <= 1'b0;

                                if (is_read) sda_r <= 1'b1;
                                else sda_r <= tx_shift_reg[7];

                                step <= 2'd1;

                            end

                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end

                            2'd2: begin

                                scl_r <= 1'b1;

                                if (is_read)
                                    rx_shift_reg <= {rx_shift_reg[6:0], sda_i};

                                step <= 2'd3;

                            end
                            2'd3: begin

                                scl_r <= 1'b0;

                                if (!is_read)
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};

                                if (bit_cnt == 3'd7) begin
                                    bit_cnt <= 0;
                                    step    <= 0;
                                    state   <= DATA_ACK;
                                end else begin
                                    bit_cnt <= bit_cnt + 1'b1;
                                    step    <= 0;
                                end

                            end

                        endcase

                    end

                end
                DATA_ACK: begin

                    if (qtr_tick) begin

                        case (step)

                            2'd0: begin
                                scl_r <= 1'b0;

                                if (is_read) sda_r <= ack_in;
                                else sda_r <= 1'b1;

                                step <= 2'd1;
                            end

                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end

                            2'd2: begin

                                scl_r <= 1'b1;

                                if (is_read) rx_data <= rx_shift_reg;
                                else ack_out <= sda_i;

                                step <= 2'd3;

                            end

                            2'd3: begin

                                scl_r <= 1'b0;

                                step  <= 0;

                                state <= STOP;

                            end

                        endcase

                    end

                end
                STOP: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                sda_r <= 1'b0;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                sda_r <= 1'b0;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                sda_r <= 1'b1;
                                step  <= 2'd3;
                            end
                            2'd3: begin

                                scl_r <= 1'b1;
                                sda_r <= 1'b1;

                                step  <= 0;

                                done  <= 1'b1;

                                state <= IDLE;

                            end
                        endcase
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
