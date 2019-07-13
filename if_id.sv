`include "define.vh"
module if_id(
    input clk,
    input rst,
    input en,
    input flush,

    input [`InstAddrBus] if_pc,
    input [`InstBus] if_inst,

    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus] id_inst
);

  always_ff @ (posedge clk) begin
        if (rst == `RstEnable || flush) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end else if (en) begin
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
  end

endmodule // if_id