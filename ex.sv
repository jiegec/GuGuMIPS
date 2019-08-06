`include "define.vh"
module ex(
    input wire rst,

    input wire[`AluOpBus] aluop_i,
    input wire[`AluSelBus] alusel_i,
    input wire[`RegBus] reg1_i,
    input wire[`RegBus] reg2_i,
    input wire[`RegAddrBus] wd_i,
    input wire wreg_i,
    input wire[`RegBus] link_address_i,
    input wire is_in_delayslot_i,
    input wire[`InstBus] inst_i,
    input wire[31:0] except_type_i,
    input wire[31:0] pc_i,

    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,
    input wire wb_whilo_i,
    input wire[`RegBus] wb_hi_i,
    input wire[`RegBus] wb_lo_i,
    input wire mem_whilo_i,
    input wire[`RegBus] mem_hi_i,
    input wire[`RegBus] mem_lo_i,

    input wire mem_cp0_reg_we,
    input wire[`CP0RegAddrBus] mem_cp0_reg_write_addr,
    input wire[`RegBus] mem_cp0_reg_data,
    input wire wb_cp0_reg_we,
    input wire[`CP0RegAddrBus] wb_cp0_reg_write_addr,
    input wire[`RegBus] wb_cp0_reg_data,
    input wire[`RegBus] cp0_reg_data_i,

    input wire[`DoubleRegBus] div_result_i,
    input wire div_ready_i,

    input wire[`DoubleRegBus] hilo_temp_i,
    input wire[1:0] cnt_i,

    output logic cp0_reg_we_o,
    output logic[`CP0RegAddrBus] cp0_reg_read_addr_o,
    output logic[`CP0RegAddrBus] cp0_reg_write_addr_o,
    output logic[`RegBus] cp0_reg_data_o,

    output logic[`RegAddrBus] wd_o,
    output logic wreg_o,
    output logic[`RegBus] wdata_o,

    output logic whilo_o,
    output logic[`RegBus] hi_o,
    output logic[`RegBus] lo_o,

    output logic[31:0] except_type_o,

    output logic[`AluOpBus] aluop_o,
    output logic[`RegBus] mem_addr_o,
    output logic[`RegBus] reg2_o,

    output logic[`RegBus] div_opdata1_o,
    output logic[`RegBus] div_opdata2_o,
    output logic div_start_o,
    output logic signed_div_o,

    output logic[`DoubleRegBus] hilo_temp_o,
    output logic[1:0] cnt_o,

    output logic stallreq
);
    logic[`RegBus] logic_res;
    logic[`RegBus] shift_res;
    logic[`RegBus] move_res;
    logic[`RegBus] arithmetic_res;
    logic[`DoubleRegBus] mult_res;

    logic[`RegBus] hi;
    logic[`RegBus] lo;
    logic[`RegBus] reg2_i_mux;
    logic[`RegBus] result_sum;
    logic ov_sum;
    logic reg1_lt_reg2;
    logic[`RegBus] reg1_i_not;
    logic signed [`RegBus] opdata1_mult;
    logic signed [`RegBus] opdata2_mult;
    logic[`DoubleRegBus] hilo_temp;
    reg[`DoubleRegBus] hilo_temp1;

    logic trap_assert;
    logic overflow_assert;

    reg stallreq_for_madd_msub;			
    reg stallreq_for_div;

    assign except_type_o = {except_type_i[31:12], overflow_assert, trap_assert, except_type_i[9:8], 8'h00};

    // Top level selector
    always_comb begin
        wd_o = wd_i;

        case (alusel_i)
            `EXE_RES_LOGIC: begin
                wdata_o = logic_res;
            end
            `EXE_RES_SHIFT: begin
                wdata_o = shift_res;
            end
            `EXE_RES_MOVE: begin
                wdata_o = move_res;
            end
            `EXE_RES_ARITHMETIC: begin
                wdata_o = arithmetic_res;
            end
            `EXE_RES_MUL: begin
                wdata_o = hilo_temp1[31:0];
            end
            `EXE_RES_JUMP_BRANCH: begin
                wdata_o = link_address_i;
            end
            default: begin
                wdata_o = `ZeroWord;
            end
        endcase
    end
    
    assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || 
                          (aluop_i == `EXE_SUBU_OP) ||
                          (aluop_i == `EXE_SLT_OP) ||
                          (aluop_i == `EXE_TLT_OP) ||
                          (aluop_i == `EXE_TLTI_OP) ||
                          (aluop_i == `EXE_TGE_OP) ||
                          (aluop_i == `EXE_TGEI_OP)) ?
                          (~reg2_i)+1 : reg2_i;

    assign result_sum = reg1_i + reg2_i_mux;

    assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31])
      || ((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));

    assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP) ||
      (aluop_i == `EXE_TLT_OP) ||
      (aluop_i == `EXE_TLTI_OP) ||
      (aluop_i == `EXE_TGE_OP) ||
      (aluop_i == `EXE_TGEI_OP)) ?
      ((reg1_i[31] && !reg2_i[31]) ||
      (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
      (reg1_i[31] && reg2_i[31] && result_sum[31])) : (reg1_i < reg2_i);

    assign reg1_i_not = ~reg1_i;

    assign aluop_o = aluop_i;
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
    assign reg2_o = reg2_i;

    always_comb begin
        if (rst == `RstEnable) begin
            logic_res = `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_OR_OP: begin
                    logic_res = reg1_i | reg2_i;
                end
                `EXE_AND_OP: begin
                    logic_res = reg1_i & reg2_i;
                end
                `EXE_NOR_OP: begin
                    logic_res = ~(reg1_i | reg2_i);
                end
                `EXE_XOR_OP: begin
                    logic_res = reg1_i ^ reg2_i;
                end
                default: begin
                    logic_res = `ZeroWord;
                end
            endcase
        end
    end

    always_comb begin
        if (rst == `RstEnable) begin
            shift_res = `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_SLL_OP: begin
                    shift_res = reg2_i << reg1_i[4:0]; // logic left shift
                end
                `EXE_SRL_OP: begin
                    shift_res = reg2_i >> reg1_i[4:0]; // logic right shift
                end
                `EXE_SRA_OP: begin
                    shift_res = ({32{reg2_i[31]}} << (6'd32-{1'b0,reg1_i[4:0]})) |
                                reg2_i >> reg1_i[4:0]; // arithmetic right shift
                end
                default: begin
                    shift_res = `ZeroWord;
                end
            endcase
        end
    end


    // hi, lo
    always_comb begin
        if (rst == `RstEnable) begin
            {hi, lo} = {`ZeroWord, `ZeroWord};
        end else if (mem_whilo_i == `WriteEnable) begin
            {hi, lo} = {mem_hi_i, mem_lo_i};
        end else if (wb_whilo_i == `WriteEnable) begin
            {hi, lo} = {wb_hi_i, wb_lo_i};
        end else begin
            {hi, lo} = {hi_i, lo_i};
        end
    end

    always_comb begin
        if (rst == `RstEnable) begin
            whilo_o = `WriteDisable;
            hi_o = `ZeroWord;
            lo_o = `ZeroWord;
        end else if (aluop_i == `EXE_MTHI_OP) begin
            whilo_o = `WriteEnable;
            hi_o = reg1_i;
            lo_o = lo;
        end else if (aluop_i == `EXE_MTLO_OP) begin
            whilo_o = `WriteEnable;
            hi_o = hi;
            lo_o = reg1_i;
        end else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP)) begin
            whilo_o = `WriteEnable;
            hi_o = hilo_temp1[63:32];
            lo_o = hilo_temp1[31:0];
        end else if ((aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MADDU_OP)) begin
            whilo_o = `WriteEnable;
            hi_o = hilo_temp1[63:32];
            lo_o = hilo_temp1[31:0];
        end else if ((aluop_i == `EXE_MSUB_OP) || (aluop_i == `EXE_MSUBU_OP)) begin
            whilo_o = `WriteEnable;
            hi_o = hilo_temp1[63:32];
            lo_o = hilo_temp1[31:0];
        end else if ((aluop_i == `EXE_DIV_OP) || (aluop_i == `EXE_DIVU_OP)) begin
            whilo_o = `WriteEnable;
            hi_o = div_result_i[63:32];
            lo_o = div_result_i[31:0];
        end else begin
            whilo_o = `WriteDisable;
            hi_o = `ZeroWord;
            lo_o = `ZeroWord;
        end
    end

    // cp0
    always_comb begin
        if (rst) begin
            cp0_reg_write_addr_o = 0;
            cp0_reg_we_o = 0;
            cp0_reg_data_o = 0;
        end else if (aluop_i == `EXE_MTC0_OP) begin
            cp0_reg_write_addr_o = {inst_i[15:11], inst_i[2:0]};
            cp0_reg_we_o = 1;
            cp0_reg_data_o = reg1_i;
        end else begin
            cp0_reg_write_addr_o = 0;
            cp0_reg_we_o = 0;
            cp0_reg_data_o = 0;
        end
    end

    always_comb begin
        if (rst == `RstEnable) begin
            move_res = `ZeroWord;
            cp0_reg_read_addr_o = 0;
        end else begin
            cp0_reg_read_addr_o = 0;
            case (aluop_i)
                `EXE_MFHI_OP: begin
                    move_res = hi;
                end
                `EXE_MFLO_OP: begin
                    move_res = lo;
                end
                `EXE_MOVZ_OP: begin
                    move_res = reg1_i;
                end
                `EXE_MOVN_OP: begin
                    move_res = reg1_i;
                end
                `EXE_MFC0_OP: begin
                    cp0_reg_read_addr_o = {inst_i[15:11], inst_i[2:0]};

                    // data dependency
                    if (mem_cp0_reg_we == 1 && mem_cp0_reg_write_addr == {inst_i[15:11], inst_i[2:0]}) begin
                        move_res = mem_cp0_reg_data;
                    end else if (wb_cp0_reg_we == 1 && wb_cp0_reg_write_addr == {inst_i[15:11], inst_i[2:0]}) begin
                        move_res = wb_cp0_reg_data;
                    end else begin
                        move_res = cp0_reg_data_i;
                    end
                end
                `EXE_SEB_OP: begin
                    move_res = {{24{reg2_i[7]}}, reg2_i[7:0]};
                end
                `EXE_SEH_OP: begin
                    move_res = {{16{reg2_i[15]}}, reg2_i[15:0]};
                end
                default: begin
                    move_res = `ZeroWord;
                end
            endcase
        end
    end

    always_comb begin
        if (rst == `RstEnable) begin
            arithmetic_res = `ZeroWord;
        end else begin
            case (aluop_i)
            // compare
            `EXE_SLT_OP, `EXE_SLTU_OP: begin
                arithmetic_res = reg1_lt_reg2;
            end

            // add/sub
            `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP, `EXE_SUBU_OP, `EXE_SUB_OP: begin
                arithmetic_res = result_sum;
            end

            `EXE_CLZ_OP: begin
                arithmetic_res = reg1_i[31] ? 0 : reg1_i[30] ? 1 :
                    reg1_i[29] ? 2 : reg1_i[28] ? 3 :
                    reg1_i[27] ? 4 : reg1_i[26] ? 5 :
                    reg1_i[25] ? 6 : reg1_i[24] ? 7 :
                    reg1_i[23] ? 8 : reg1_i[22] ? 9 :
                    reg1_i[21] ? 10 : reg1_i[20] ? 11 :
                    reg1_i[19] ? 12 : reg1_i[18] ? 13 :
                    reg1_i[17] ? 14 : reg1_i[16] ? 15 :
                    reg1_i[15] ? 16 : reg1_i[14] ? 17 :
                    reg1_i[13] ? 18 : reg1_i[12] ? 19 :
                    reg1_i[11] ? 20 : reg1_i[10] ? 21 :
                    reg1_i[9] ? 22 : reg1_i[8] ? 23 :
                    reg1_i[7] ? 24 : reg1_i[6] ? 25 :
                    reg1_i[5] ? 26 : reg1_i[4] ? 27 :
                    reg1_i[3] ? 28 : reg1_i[2] ? 29 :
                    reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32;
            end

            `EXE_CLO_OP: begin
                arithmetic_res = reg1_i_not[31] ? 0 : reg1_i_not[30] ? 1 :
                    reg1_i_not[29] ? 2 : reg1_i_not[28] ? 3 :
                    reg1_i_not[27] ? 4 : reg1_i_not[26] ? 5 :
                    reg1_i_not[25] ? 6 : reg1_i_not[24] ? 7 :
                    reg1_i_not[23] ? 8 : reg1_i_not[22] ? 9 :
                    reg1_i_not[21] ? 10 : reg1_i_not[20] ? 11 :
                    reg1_i_not[19] ? 12 : reg1_i_not[18] ? 13 :
                    reg1_i_not[17] ? 14 : reg1_i_not[16] ? 15 :
                    reg1_i_not[15] ? 16 : reg1_i_not[14] ? 17 :
                    reg1_i_not[13] ? 18 : reg1_i_not[12] ? 19 :
                    reg1_i_not[11] ? 20 : reg1_i_not[10] ? 21 :
                    reg1_i_not[9] ? 22 : reg1_i_not[8] ? 23 :
                    reg1_i_not[7] ? 24 : reg1_i_not[6] ? 25 :
                    reg1_i_not[5] ? 26 : reg1_i_not[4] ? 27 :
                    reg1_i_not[3] ? 28 : reg1_i_not[2] ? 29 :
                    reg1_i_not[1] ? 30 : reg1_i_not[0] ? 31 : 32;
            end

            // TODO: clz/clo
            default: begin
                arithmetic_res = `ZeroWord;
            end
            endcase
        end
    end

    always_comb begin
        if (rst == `RstEnable) begin
            trap_assert = 0;
        end else begin
            trap_assert = 0;
            case(aluop_i)
            `EXE_TEQ_OP, `EXE_TEQI_OP: begin
                if (reg1_i == reg2_i) begin
                    trap_assert = 1;
                end
            end
            `EXE_TGE_OP, `EXE_TGEI_OP, `EXE_TGEIU_OP, `EXE_TGEU_OP: begin
                if (~reg1_lt_reg2) begin
                    trap_assert = 1;
                end
            end
            `EXE_TLT_OP, `EXE_TLTI_OP, `EXE_TLTIU_OP, `EXE_TLTU_OP: begin
                if (reg1_lt_reg2) begin
                    trap_assert = 1;
                end
            end
            `EXE_TNE_OP, `EXE_TNEI_OP: begin
                if (reg1_i != reg2_i) begin
                    trap_assert = 1;
                end
            end
            endcase
        end
    end

    always_comb begin
        if (rst == `RstEnable) begin
            overflow_assert = 1;
            wreg_o = 0;
        end else begin
            if (((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) ||
            (aluop_i == `EXE_SUB_OP)) && ov_sum) begin
                wreg_o = `WriteDisable;
                overflow_assert = 1;
            end else begin
                wreg_o = wreg_i;
                overflow_assert = 0;
            end
        end
    end

    assign opdata1_mult = reg1_i;

    assign opdata2_mult = reg2_i;

    assign hilo_temp = opdata1_mult * opdata2_mult;

    always_comb begin
        if (rst) begin
            mult_res = {`ZeroWord, `ZeroWord};
        end else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP)
        || (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP)) begin
            mult_res = hilo_temp;
        end else begin
            mult_res = reg1_i * reg2_i;
        end
    end
    
    always_comb begin
        if(rst) begin
            hilo_temp_o = {`ZeroWord,`ZeroWord};
            hilo_temp1 = {`ZeroWord, `ZeroWord};
            cnt_o = 2'b00;
            stallreq_for_madd_msub = `NoStop;
        end else begin	
            hilo_temp_o = {`ZeroWord, `ZeroWord};
            hilo_temp1 = {`ZeroWord, `ZeroWord};
            cnt_o = 2'b00;
            stallreq_for_madd_msub = `NoStop;				

            case (aluop_i) 
                `EXE_MADD_OP, `EXE_MADDU_OP: begin
                    if (cnt_i == 2'b00) begin
                        hilo_temp_o = mult_res;
                        cnt_o = 2'b01;
                        stallreq_for_madd_msub = `Stop;//Stop
                        hilo_temp1 = {`ZeroWord, `ZeroWord};
                    end else if(cnt_i == 2'b01) begin
                        hilo_temp_o = {`ZeroWord, `ZeroWord};						
                        cnt_o = 2'b00;
                        hilo_temp1 = hilo_temp_i + {hi, lo};
                        stallreq_for_madd_msub = `NoStop;
                    end
                end
                `EXE_MSUB_OP, `EXE_MSUBU_OP: begin
                    if (cnt_i == 2'b00) begin
                        hilo_temp_o = ~mult_res + 1;
                        cnt_o = 2'b01;
                        stallreq_for_madd_msub = `Stop; //Stop
                    end else if (cnt_i == 2'b01)begin
                        hilo_temp_o = {`ZeroWord, `ZeroWord};						
                        cnt_o = 2'b00;
                        hilo_temp1 = hilo_temp_i + {hi, lo};
                        stallreq_for_madd_msub = `NoStop;
                    end	
                end
                `EXE_MULT_OP, `EXE_MULTU_OP, `EXE_MUL_OP: begin
                    if (cnt_i == 2'b00) begin
                        hilo_temp_o = mult_res;
                        cnt_o = 2'b01;
                        stallreq_for_madd_msub = `Stop; //Stop
                    end else if (cnt_i == 2'b01) begin
                        hilo_temp_o = {`ZeroWord, `ZeroWord};
                        cnt_o = 2'b00;
                        hilo_temp1 = hilo_temp_i;
                        stallreq_for_madd_msub = `NoStop;
                    end
                end
            endcase
        end
    end	

    always_comb begin
        if (rst) begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
        end else begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
            case (aluop_i)
                `EXE_DIV_OP: begin
                    if(div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `NoStop;
                    end else begin						
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end					
                end
                `EXE_DIVU_OP: begin
                    if(div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end else begin						
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end					
                end
                default: begin
                end
            endcase
        end
    end

    always_comb begin 
        stallreq = stallreq_for_madd_msub || stallreq_for_div;
    end

endmodule // ex
