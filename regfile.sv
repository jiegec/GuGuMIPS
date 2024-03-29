`include "define.vh"
module regfile(
    input wire clk,
    input wire rst,

    input wire we,
    input wire[`RegAddrBus] waddr,
    input wire[`RegBus] wdata,

    input wire re1,
    input wire[`RegAddrBus] raddr1,
    output reg[`RegBus] rdata1,

    input wire re2,
    input wire[`RegAddrBus] raddr2,
    output reg[`RegBus] rdata2
);

    // the first reg is always zero
    reg[`RegBus] regs[0:`RegNum-1] = '{`RegNum{0}};

    always_ff @ (posedge clk) begin
      if (rst == `RstDisable) begin
        if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
          regs[waddr] <= wdata;
          //$display("time %3d r%d = %h", $time, waddr, wdata); 
        end
      end
    end

    always_comb begin
      if (rst == `RstEnable) begin
        rdata1 = `ZeroWord;
      end else if (raddr1 == `RegNumLog2'h0) begin
        rdata1 = `ZeroWord;
      end else if ((raddr1 == waddr) && (we == `WriteEnable)
                    && (re1 == `ReadEnable)) begin
        rdata1 = wdata;
      end else if (re1 == `ReadEnable) begin
        rdata1 = regs[raddr1];
      end else begin
        rdata1 = regs[raddr1];
      end
    end

    always_comb begin
      if (rst == `RstEnable) begin
        rdata2 = `ZeroWord;
      end else if (raddr2 == `RegNumLog2'h0) begin
        rdata2 = `ZeroWord;
      end else if ((raddr2 == waddr) && (we == `WriteEnable)
                    && (re2 == `ReadEnable)) begin
        rdata2 = wdata;
      end else if (re2 == `ReadEnable) begin
        rdata2 = regs[raddr2];
      end else begin
        rdata2 = regs[raddr2];
      end
    end

endmodule // regfile    