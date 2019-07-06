`include "define.vh"
module pc_reg (
    input wire clk,
    input wire rst,
    input wire en,

    output reg[`InstAddrBus] pc
);

    logic first;

    always_ff @ (posedge clk) begin
      if (rst == `RstEnable) begin
        first <= 1;
      end
    end

    always_ff @ (posedge clk) begin
      if (rst == `RstEnable) begin
        pc <= 32'hbfc00000;
      end else if (en) begin
        pc <= pc + 32'h00000004;
      end
    end

endmodule // pc_reg

