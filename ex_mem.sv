`include "define.vh"
module ex_mem(
  input wire clk,
  input wire rst,
  input wire en,

  input wire[`RegAddrBus] ex_wd,
  input wire ex_wreg,
  input wire[`RegBus] ex_wdata,
  input wire[`InstAddrBus] ex_pc,

  input wire ex_whilo,
  input wire[`RegBus] ex_hi,
  input wire[`RegBus] ex_lo,

  input wire ex_cp0_reg_we,
  input wire[4:0] ex_cp0_reg_write_addr,
  input wire[`RegBus] ex_cp0_reg_data,

  output reg[`RegAddrBus] mem_wd,
  output reg mem_wreg,
  output reg[`RegBus] mem_wdata,
  output reg[`InstAddrBus] mem_pc,

  output reg mem_whilo,
  output reg[`RegBus] mem_hi,
  output reg[`RegBus] mem_lo,

  output logic mem_cp0_reg_we,
  output logic[4:0] mem_cp0_reg_write_addr,
  output logic[`RegBus] mem_cp0_reg_data
);

    always_ff @(posedge clk) begin
        if (rst == `RstEnable) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;

            mem_whilo <= `WriteDisable;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;

            mem_pc <= 0;

            mem_cp0_reg_we <= 0;
            mem_cp0_reg_write_addr <= 0;
            mem_cp0_reg_data <= 0;
        end else if (en) begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;

            mem_whilo <= ex_whilo;
            mem_hi <= ex_hi;
            mem_lo <= ex_lo;

            mem_pc <= ex_pc;

            mem_cp0_reg_we <= ex_cp0_reg_we;
            mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
            mem_cp0_reg_data <= ex_cp0_reg_data;
        end
    end

endmodule // ex_mem
