`include "define.vh"
module mem_wb(
    input wire clk,
    input wire rst,
    input wire en,
    input wire flush,

    input wire[`RegAddrBus] mem_wd,
    input wire mem_wreg,
    input wire[`RegBus] mem_wdata,
    input wire[`InstAddrBus]mem_pc,

    input wire mem_whilo,
    input wire[`RegBus] mem_hi,
    input wire[`RegBus] mem_lo,

    input wire mem_cp0_reg_we,
    input wire[4:0] mem_cp0_reg_write_addr,
    input wire[`RegBus] mem_cp0_reg_data,
    input wire mem_is_in_delayslot,
    input wire[31:0] mem_except_type,
    input wire[`RegBus] mem_mem_addr,

    output reg[`RegAddrBus] wb_wd,
    output reg wb_wreg,
    output reg[`RegBus] wb_wdata,
    output reg[`InstAddrBus]wb_pc,

    output reg wb_whilo,
    output reg[`RegBus] wb_hi,
    output reg[`RegBus] wb_lo,

    output logic wb_cp0_reg_we,
    output logic[4:0] wb_cp0_reg_write_addr,
    output logic[`RegBus] wb_cp0_reg_data,

    output logic[31:0] wb_except_type,
    output logic[31:0] wb_mem_addr,
    output logic wb_is_in_delayslot
);

    always_ff @(posedge clk) begin
        if (rst == `RstEnable || flush) begin
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
            wb_wdata <= `ZeroWord;

            wb_whilo <= `WriteDisable;
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;

            wb_pc <= 0;

            wb_cp0_reg_we <= 0;
            wb_cp0_reg_write_addr <= 0;
            wb_cp0_reg_data <= 0;

            wb_is_in_delayslot <= 0;
            wb_except_type <= 0;
            wb_mem_addr <= 0;
        end else if (en) begin
            wb_wd <= mem_wd;
            wb_wreg <= mem_wreg;
            wb_wdata <= mem_wdata;

            wb_whilo <= mem_whilo;
            wb_hi <= mem_hi;
            wb_lo <= mem_lo;

            wb_pc <= mem_pc;

            wb_cp0_reg_we <= mem_cp0_reg_we;
            wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
            wb_cp0_reg_data <= mem_cp0_reg_data;

            wb_is_in_delayslot <= mem_is_in_delayslot;
            wb_except_type <= mem_except_type;
            wb_mem_addr <= mem_mem_addr;
        end
    end

endmodule // mem_wb
