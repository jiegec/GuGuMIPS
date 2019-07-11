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
    input [31:0] except_type_i,
    input [31:0] pc_i,

    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,
    input wire wb_whilo_i,
    input wire[`RegBus] wb_hi_i,
    input wire[`RegBus] wb_lo_i,
    input wire mem_whilo_i,
    input wire[`RegBus] mem_hi_i,
    input wire[`RegBus] mem_lo_i,

    input wire mem_cp0_reg_we,
    input wire[4:0] mem_cp0_reg_write_addr,
    input wire[`RegBus] mem_cp0_reg_data,
    input wire wb_cp0_reg_we,
    input wire[4:0] wb_cp0_reg_write_addr,
    input wire[`RegBus] wb_cp0_reg_data,
    input wire[`RegBus] cp0_reg_data_i,

    output logic cp0_reg_we_o,
    output logic[4:0] cp0_reg_read_addr_o,
    output logic[4:0] cp0_reg_write_addr_o,
    output logic[`RegBus] cp0_reg_data_o,

    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,

    output reg whilo_o,
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o,

    output logic[31:0] except_type_o,

    output wire[`AluOpBus] aluop_o,
    output wire[`RegBus] mem_addr_o,
    output wire[`RegBus] reg2_o

);
    logic[`RegBus] logic_res;
    logic[`RegBus] shift_res;
    logic[`RegBus] move_res;
    logic[`RegBus] arithmetic_res;
    logic[`RegBus] hi;
    logic[`RegBus] lo;
    logic[`RegBus] reg2_i_mux;
    logic[`RegBus] result_sum;
    logic[`RegBus] ov_sum;
    logic reg1_lt_reg2;
    logic[`RegBus] reg1_i_not;

    logic trap_assert;
    logic overflow_assert;

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
        cp0_reg_write_addr_o = inst_i[15:11];
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
      end else begin
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
            cp0_reg_read_addr_o = inst_i[15:11];

            // data dependency
            if (mem_cp0_reg_we == 1 && mem_cp0_reg_write_addr == inst_i[15:11]) begin
              move_res = mem_cp0_reg_data;
            end else if (wb_cp0_reg_we == 1 && wb_cp0_reg_write_addr == inst_i[15:11]) begin
              move_res = wb_cp0_reg_data;
            end else begin
              move_res = cp0_reg_data_i;
            end
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

endmodule // ex