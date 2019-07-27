`include "define.vh"
module pc_reg (
    input clk,
    input rst,
    input en,
    input flush,
    input [31:0] new_pc,

    input branch_flag_i,
    input [`RegBus] branch_target_address_i,

    output reg[`InstAddrBus] pc
);
    // sync with clk
    logic[`RegBus] saved_branch_target_address_clk;
    logic saved_branch_flag_i_clk;

    logic[`RegBus] reset_pc = 32'hbfc00000;

    logic [`InstAddrBus] out_pc;

    // when flushing, use new pc at once
    assign pc = flush ? new_pc : out_pc;

    always_ff @ (posedge clk) begin
        if (rst == `RstEnable) begin
            out_pc <= reset_pc;
            saved_branch_target_address_clk <= 0;
            saved_branch_flag_i_clk <= 0;
        end else if (flush) begin
            out_pc <= new_pc;
            saved_branch_target_address_clk <= 0;
            saved_branch_flag_i_clk <= 0;
        end else if (en) begin
            if (saved_branch_flag_i_clk) begin
                saved_branch_target_address_clk <= 0;
                saved_branch_flag_i_clk <= 0;
                out_pc <= saved_branch_target_address_clk;
            end else if (branch_flag_i) begin
                saved_branch_flag_i_clk <= 0;
                out_pc <= branch_target_address_i;
            end else begin
                out_pc <= out_pc + 32'h00000004;
            end
        end else if (branch_flag_i) begin
            saved_branch_target_address_clk <= branch_target_address_i;
            saved_branch_flag_i_clk <= 1;
        end
    end
endmodule // pc_reg

