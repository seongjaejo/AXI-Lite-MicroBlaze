`timescale 1ns/1ps
module audit_axi;
reg clk=0,rstn=0;always #5 clk=~clk;
reg[3:0]awaddr=0,araddr=0;reg awvalid=0,wvalid=0,bready=1,arvalid=0,rready=0;
reg[31:0]wdata=0;reg[3:0]wstrb=15;
wire awready,wready,bvalid,arready,rvalid;wire[1:0]bresp,rresp;wire[31:0]rdata;
wire sclk,mosi,miso,ss_n,intr;
spi_master_v1_0 dut(.sclk(sclk),.mosi(mosi),.miso(miso),.ss_n(ss_n),.spi_intr(intr),
 .s00_axi_aclk(clk),.s00_axi_aresetn(rstn),.s00_axi_awaddr(awaddr),.s00_axi_awprot(3'b0),.s00_axi_awvalid(awvalid),.s00_axi_awready(awready),
 .s00_axi_wdata(wdata),.s00_axi_wstrb(wstrb),.s00_axi_wvalid(wvalid),.s00_axi_wready(wready),.s00_axi_bresp(bresp),.s00_axi_bvalid(bvalid),.s00_axi_bready(bready),
 .s00_axi_araddr(araddr),.s00_axi_arprot(3'b0),.s00_axi_arvalid(arvalid),.s00_axi_arready(arready),.s00_axi_rdata(rdata),.s00_axi_rresp(rresp),.s00_axi_rvalid(rvalid),.s00_axi_rready(rready));
reg[7:0]stx=0;wire[7:0]srx;wire sdone,sbusy;
spi_slave s(.clk(clk),.reset(~rstn),.tx_data(stx),.rx_data(srx),.done(sdone),.busy(sbusy),.sclk(sclk),.mosi(mosi),.miso(miso),.ss_n(ss_n));
integer errors=0,k,n,pulses=0;reg[31:0]value,status;reg[7:0]expected,got;reg seen;
always @(posedge clk)begin if(sdone)begin got<=srx;seen<=1;end if(intr)pulses<=pulses+1;end
task wr(input[3:0]a,input[31:0]v);
begin
 @(negedge clk);awaddr=a;wdata=v;awvalid=1;wvalid=1;
 n=0;while(!(awready&&wready)&&n<100)begin @(negedge clk);n=n+1;end
 @(negedge clk);awvalid=0;wvalid=0;
 n=0;while(!bvalid&&n<100)begin @(negedge clk);n=n+1;end
 repeat(3)@(negedge clk);
end endtask
task rd(input[3:0]a,output[31:0]v);
begin
 @(negedge clk);araddr=a;arvalid=1;rready=0;
 n=0;while(!arready&&n<100)begin @(negedge clk);n=n+1;end
 @(negedge clk);arvalid=0;
 n=0;while(!rvalid&&n<100)begin @(negedge clk);n=n+1;end
 v=rdata;rready=1;repeat(2)@(negedge clk);rready=0;
end endtask
initial begin
 repeat(5)@(negedge clk);rstn=1;
 for(k=0;k<16;k=k+1)begin
 expected=k*17;stx=~expected;seen=0;
 wr(4,expected);wr(0,32'h00003101);
 repeat(2000)@(negedge clk);
 rd(12,status);rd(8,value);
 if(status[1]!==1 || value[7:0]!==stx || !seen || got!==expected)begin errors=errors+1;$display("AUDIT AXI SPI FAIL tx=%h rx=%h srx=%h status=%h",expected,value,got,status);end
 rd(12,value);if(value[1]!==0)begin errors=errors+1;$display("AUDIT AXI CLEAR FAIL");end
 end
 $display("AUDIT AXI transactions=16 errors=%0d intrPulses=%0d",errors,pulses);
 if(errors==0)$display("AUDIT AXI SPI PASS");$finish;
end
initial begin #10000000;$display("AUDIT AXI TIMEOUT FAIL");$finish;end
endmodule
