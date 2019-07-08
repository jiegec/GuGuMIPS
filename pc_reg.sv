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
    // sync with clk
    logic[`RegBus] saved_branch_target_address_clk;
    logic saved_branch_flag_i_clk;

    logic[`RegBus] reset_pc = 32'hbfc000000;

    always_ff @ (posedge clk) begin
      if (rst == `RstEnable) begin
        first <= 1;
      end
    end

    always_ff @ (posedge clk) begin
      if (rst == `RstEnable) begin
        saved_branch_target_address_clk <= 0;
        saved_branch_flag_i_clk <= 0;
      end else if (branch_flag_i) begin
        saved_branch_target_address_clk <= branch_target_address_i;
        saved_branch_flag_i_clk <= 1;
      end
    end

    always_ff @ (posedge clk) begin
      if (rst == `RstEnable) begin
        pc <= reset_pc;
      end else if (en) begin
        if (saved_branch_flag_i_clk) begin
          saved_branch_target_address_clk <= 0;
          saved_branch_flag_i_clk <= 0;
          pc <= saved_branch_target_address_clk;
        end else begin
          pc <= pc + 32'h00000004;
        end
      end
    end

endmodule // pc_reg

