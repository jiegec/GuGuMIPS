`include "define.vh"
module if_id(
    input wire clk,
    input wire rst,
    input wire en,

    input wire[`InstAddrBus] if_pc,
    input wire[`InstBus] if_inst,

    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus] id_inst
);

  always_ff @ (posedge clk) begin
    if (rst == `RstEnable) begin
      id_pc <= `ZeroWord;
      id_inst <= `ZeroWord;
    end else if (en) begin
      id_pc <= if_pc;
      id_inst <= if_inst;
    end
  end

endmodule // if_id