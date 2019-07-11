`include "define.vh"
module id_ex(
  input wire clk,
  input wire rst,
  input wire en,

  input wire[`AluOpBus] id_aluop,
  input wire[`AluSelBus] id_alusel,
  input wire[`RegBus] id_reg1,
  input wire[`RegBus] id_reg2,
  input wire[`RegAddrBus] id_wd,
  input wire id_wreg,
  input wire[`InstAddrBus]id_pc,
  input wire[`InstBus]id_inst,
  input wire id_is_in_delayslot,
  input wire[`RegBus] id_link_address,
  input wire next_inst_in_delayslot_i,

  output reg[`AluOpBus] ex_aluop,
  output reg[`AluSelBus] ex_alusel,
  output reg[`RegBus] ex_reg1,
  output reg[`RegBus] ex_reg2,
  output reg[`RegAddrBus] ex_wd,
  output reg ex_wreg,
  output reg[`InstAddrBus] ex_pc,
  output reg[`InstBus]ex_inst,
  output reg[`RegBus] ex_link_address,
  output reg ex_is_in_delayslot,
  output reg is_in_delayslot_o
);

    always_ff @(posedge clk) begin
        if (rst == `RstEnable) begin
          ex_aluop <= `EXE_NOP_OP;
          ex_alusel <= `EXE_RES_NOP;
          ex_reg1 <= `ZeroWord;
          ex_reg2 <= `ZeroWord;
          ex_wd <= `NOPRegAddr;
          ex_wreg <= `WriteDisable;
          ex_pc <= 0;
          ex_inst <= 0;

          ex_link_address <= 0;
          ex_is_in_delayslot <= 0;
          is_in_delayslot_o <= 0;
        end else if (en) begin
          ex_aluop <= id_aluop;
          ex_alusel <= id_alusel;
          ex_reg1 <= id_reg1;
          ex_reg2 <= id_reg2;
          ex_wd <= id_wd;
          ex_wreg <= id_wreg;
          ex_pc <= id_pc;
          ex_inst <= id_inst;

          ex_link_address <= id_link_address;
          ex_is_in_delayslot <= id_is_in_delayslot;
          is_in_delayslot_o <= next_inst_in_delayslot_i;
        end
    end

endmodule // id_ex
