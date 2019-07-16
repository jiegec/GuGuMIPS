`include "define.vh"
module if_id(
    input clk,
    input rst,
    input en,
    input flush,

    input [`InstAddrBus] if_pc,
    input [`InstBus] if_inst,
    input [31:0] if_except_type,

    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus] id_inst,
    output reg[31:0] id_except_type
);

  always_ff @ (posedge clk) begin
        if (rst == `RstEnable || flush) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;

            id_except_type <= 0;
        end else if (en) begin
            id_pc <= if_pc;
            id_inst <= if_inst;

            id_except_type <= if_except_type;
        end
  end

endmodule // if_id