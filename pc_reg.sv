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

    logic[`RegBus] reset_pc = 32'hbfc00000;

    logic [`InstAddrBus] out_pc;

    // when flushing, use new pc at once
    assign pc = flush ? new_pc : (branch_flag_i ? branch_target_address_i : out_pc);

    always_ff @ (posedge clk) begin
        if (rst == `RstEnable) begin
            out_pc <= reset_pc;
        end else if (en) begin
            if (flush) begin
                out_pc <= new_pc + 32'h00000004;
            end else if (branch_flag_i) begin
                out_pc <= branch_target_address_i + 32'h00000004;
            end else begin
                out_pc <= out_pc + 32'h00000004;
            end
        end else if (flush) begin
            out_pc <= new_pc;
        end
    end
endmodule // pc_reg

