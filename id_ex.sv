`include "define.vh"
module id_ex(
    input wire clk,
    input wire rst,
    input wire en,
    input wire en_pc,
    input wire flush,

    input wire[`AluOpBus] id_aluop,
    input wire[`AluSelBus] id_alusel,
    input wire[`RegBus] id_reg1,
    input wire[`RegBus] id_reg2,
    input wire[`RegAddrBus] id_wd,
    input wire id_wreg,
    input wire[`InstAddrBus]id_pc,
    input wire[`InstBus]id_inst,
    input wire id_is_in_delayslot,
    input wire[`RegBus] id_link_address,
    input wire next_inst_in_delayslot_i,
    input wire[31:0] id_except_type,
    input wire id_tlb_we,
    input wire id_tlb_wr,
    input wire id_tlb_p,

    output reg[`AluOpBus] ex_aluop,
    output reg[`AluSelBus] ex_alusel,
    output reg[`RegBus] ex_reg1,
    output reg[`RegBus] ex_reg2,
    output reg[`RegAddrBus] ex_wd,
    output reg ex_wreg,
    output reg[`InstAddrBus] ex_pc,
    output reg[`InstBus]ex_inst,
    output reg[`RegBus] ex_link_address,
    output reg ex_is_in_delayslot,
    output reg is_in_delayslot_o,
    output reg [31:0] ex_except_type,
    output reg ex_tlb_we,
    output reg ex_tlb_wr,
    output reg ex_tlb_p
);
    logic saved_next_inst_in_delayslot_i;

    always_ff @(posedge clk) begin
        if (rst == `RstEnable || flush) begin
            ex_aluop <= `EXE_NOP_OP;
            ex_alusel <= `EXE_RES_NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            ex_wd <= `NOPRegAddr;
            ex_wreg <= `WriteDisable;
            ex_pc <= 0;
            ex_inst <= 0;

            ex_link_address <= 0;
            ex_is_in_delayslot <= 0;

            ex_except_type <= 0;
            ex_tlb_we <= 0;
            ex_tlb_wr <= 0;
            ex_tlb_p <= 0;
        end else if (en) begin
            ex_aluop <= id_aluop;
            ex_alusel <= id_alusel;
            ex_reg1 <= id_reg1;
            ex_reg2 <= id_reg2;
            ex_wd <= id_wd;
            ex_wreg <= id_wreg;
            ex_pc <= id_pc;
            ex_inst <= id_inst;

            ex_link_address <= id_link_address;
            ex_is_in_delayslot <= id_is_in_delayslot;

            ex_except_type <= id_except_type;
            ex_tlb_we <= id_tlb_we;
            ex_tlb_wr <= id_tlb_wr;
            ex_tlb_p <= id_tlb_p;
        end
    end
    
    logic [1:0] saved_en_pc;
    logic en_delayslot;
    // after if, two cycles: if->id, id->ex
    assign en_delayslot = saved_en_pc[0];
    // capture next_inst_delayslot_i for multicycle instruction fetch
    always_ff @(posedge clk) begin
        if (rst == `RstEnable || flush) begin
          is_in_delayslot_o <= 0;
          saved_next_inst_in_delayslot_i <= 0;
          saved_en_pc <= 0;
        end else begin
            saved_en_pc <= {saved_en_pc[0], en_pc};
            if (en_delayslot) begin
                is_in_delayslot_o <= saved_next_inst_in_delayslot_i | next_inst_in_delayslot_i;
                saved_next_inst_in_delayslot_i <= 0;
            end else if (en) begin
                saved_next_inst_in_delayslot_i <= saved_next_inst_in_delayslot_i | next_inst_in_delayslot_i;
            end
        end
    end

endmodule // id_ex
