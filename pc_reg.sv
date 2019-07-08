`include "define.vh"
module pc_reg (
    input wire clk,
    input wire rst,
    input wire en,

    input branch_flag_i,
    input [`RegBus] branch_target_address_i,

    output reg[`InstAddrBus] pc
);

    logic first;
    logic[`RegBus] saved_branch_target_address;
    logic saved_branch_flag_i;

    always_ff @ (posedge clk) begin
      if (rst == `RstEnable) begin
        first <= 1;
      end
    end

    always_ff @ (posedge clk) begin
      if (rst == `RstEnable) begin
        saved_branch_target_address <= 0;
      end else if (branch_flag_i) begin
        saved_branch_target_address <= branch_target_address_i;
        saved_branch_flag_i <= 1;
      end
    end

    always_ff @ (posedge clk) begin
      if (rst == `RstEnable) begin
        pc <= 32'hbfc00000;
      end else if (en) begin
        if (saved_branch_flag_i) begin
          saved_branch_target_address <= 0;
          saved_branch_flag_i <= 0;
          pc <= saved_branch_target_address;
        end else begin
          pc <= pc + 32'h00000004;
        end
      end
    end

endmodule // pc_reg

