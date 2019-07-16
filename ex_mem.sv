`include "define.vh"
module ex_mem(
    input wire clk,
    input wire rst,
    input wire en,
    input wire flush,

    input wire[`RegAddrBus] ex_wd,
    input wire ex_wreg,
    input wire[`RegBus] ex_wdata,
    input wire[`InstAddrBus] ex_pc,

    input wire ex_whilo,
    input wire[`RegBus] ex_hi,
    input wire[`RegBus] ex_lo,

    input wire ex_cp0_reg_we,
    input wire[4:0] ex_cp0_reg_write_addr,
    input wire[`RegBus] ex_cp0_reg_data,

    input [31:0] ex_except_type,
    input ex_is_in_delayslot,

	input wire[`DoubleRegBus] hilo_i,	
	input wire[1:0] cnt_i,	

    input wire[`AluOpBus] ex_aluop,
    input wire[`AluSelBus] ex_alusel,
    input wire[`RegBus] ex_mem_addr,
    input wire[`RegBus] ex_reg2,

    output reg[`RegAddrBus] mem_wd,
    output reg mem_wreg,
    output reg[`RegBus] mem_wdata,
    output reg[`InstAddrBus] mem_pc,

    output reg mem_whilo,
    output reg[`RegBus] mem_hi,
    output reg[`RegBus] mem_lo,

    output logic mem_cp0_reg_we,
    output logic[4:0] mem_cp0_reg_write_addr,
    output logic[`RegBus] mem_cp0_reg_data,

    output logic [31:0] mem_except_type,
    output logic mem_is_in_delayslot,

    output reg[`AluOpBus] mem_aluop,
    output reg[`AluSelBus] mem_alusel,
    output reg[`RegBus] mem_mem_addr,
    output reg[`RegBus] mem_reg2,
	
	output reg[`DoubleRegBus] hilo_o,
	output reg[1:0] cnt_o	
);

    always_ff @(posedge clk) begin
        if (rst == `RstEnable || flush) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;

            mem_whilo <= `WriteDisable;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;

            mem_pc <= 0;

            mem_cp0_reg_we <= 0;
            mem_cp0_reg_write_addr <= 0;
            mem_cp0_reg_data <= 0;

            mem_except_type <= 0;
            mem_is_in_delayslot <= 0;

            mem_aluop <= `EXE_NOP_OP;
            mem_alusel <= `EXE_RES_NOP;
            mem_mem_addr <= `ZeroWord;
            mem_reg2 <= `ZeroWord;
            
	    	hilo_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;	
        end else if (en) begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;

            mem_whilo <= ex_whilo;
            mem_hi <= ex_hi;
            mem_lo <= ex_lo;

            mem_pc <= ex_pc;

            mem_cp0_reg_we <= ex_cp0_reg_we;
            mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
            mem_cp0_reg_data <= ex_cp0_reg_data;

            mem_except_type <= ex_except_type;
            mem_is_in_delayslot <= ex_is_in_delayslot;

            mem_aluop <= ex_aluop;
            mem_alusel <= ex_alusel;
            mem_mem_addr <= ex_mem_addr;
            mem_reg2 <= ex_reg2;
            
	    	hilo_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;	
        end else begin
	    	hilo_o <= hilo_i;
			cnt_o <= cnt_i;			  				    
        end
    end

endmodule // ex_mem
