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
    output reg[`RegBus] lo_o
);
    logic[`RegBus] logicout;
    logic[`RegBus] shiftres;
    logic[`RegBus] moveres;
    logic[`RegBus] arithmeticres;
    logic[`RegBus] hi;
    logic[`RegBus] lo;
    logic[`RegBus] reg2_i_mux;
    logic[`RegBus] result_sum;
    logic[`RegBus] ov_sum;
    logic reg1_lt_reg2;
    logic[`RegBus] reg1_i_not;

    // Top level selector
    always_comb begin
      wd_o = wd_i;
      wreg_o = wreg_i;

      case (alusel_i)
        `EXE_RES_LOGIC: begin
          wdata_o = logicout;
        end
        `EXE_RES_SHIFT: begin
          wdata_o = shiftres;
        end
        `EXE_RES_MOVE: begin
          wdata_o = moveres;
        end
        `EXE_RES_ARITHMETIC: begin
          wdata_o = arithmeticres;
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
                          (aluop_i == `EXE_SLT_OP)) ?
                          (~reg2_i)+1 : reg2_i;

    assign result_sum = reg1_i + reg2_i_mux;

    assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31])
      || ((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));

    assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)) ?
      ((reg1_i[31] && !reg2_i[31]) ||
      (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
      (reg1_i[31] && reg2_i[31] && result_sum[31])) : (reg1_i < reg2_i);

    assign reg1_i_not = ~reg1_i;

    always_comb begin
      if (rst == `RstEnable) begin
        logicout = `ZeroWord;
      end else begin
        case (aluop_i)
            `EXE_OR_OP: begin
              logicout = reg1_i | reg2_i;
            end
            `EXE_AND_OP: begin
              logicout = reg1_i & reg2_i;
            end
            `EXE_NOR_OP: begin
              logicout = ~(reg1_i | reg2_i);
            end
            `EXE_XOR_OP: begin
              logicout = reg1_i ^ reg2_i;
            end
            default: begin
              logicout = `ZeroWord;
            end
        endcase
      end
    end

    always_comb begin
      if (rst == `RstEnable) begin
        shiftres = `ZeroWord;
      end else begin
        case (aluop_i)
            `EXE_SLL_OP: begin
              shiftres = reg2_i << reg1_i[4:0]; // logic left shift
            end
            `EXE_SRL_OP: begin
              shiftres = reg2_i >> reg1_i[4:0]; // logic right shift
            end
            `EXE_SRA_OP: begin
              shiftres = ({32{reg2_i[31]}} << (6'd32-{1'b0,reg1_i[4:0]})) |
                          reg2_i >> reg1_i[4:0]; // arithmetic right shift
            end
            default: begin
              shiftres = `ZeroWord;
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
        moveres = `ZeroWord;
      end else begin
        case (aluop_i)
          `EXE_MFHI_OP: begin
            moveres = hi;
          end
          `EXE_MFLO_OP: begin
            moveres = lo;
          end
          `EXE_MOVZ_OP: begin
            moveres = reg1_i;
          end
          `EXE_MOVN_OP: begin
            moveres = reg1_i;
          end
          `EXE_MFC0_OP: begin
            cp0_reg_read_addr_o = inst_i[15:11];

            // data dependency
            if (mem_cp0_reg_we == 1 && mem_cp0_reg_write_addr == inst_i[15:11]) begin
              moveres = mem_cp0_reg_data;
            end else if (wb_cp0_reg_we == 1 && wb_cp0_reg_write_addr == inst_i[15:11]) begin
              moveres = wb_cp0_reg_data;
            end else begin
              moveres = cp0_reg_data_i;
            end
          end
          default: begin
            moveres = `ZeroWord;
          end
        endcase
      end
    end

    always_comb begin
      if (rst == `RstEnable) begin
        arithmeticres = `ZeroWord;
      end else begin
        case (aluop_i)
          // compare
          `EXE_SLT_OP, `EXE_SLTU_OP: begin
            arithmeticres = reg1_lt_reg2;
          end

          // add/sub
          `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP, `EXE_SUBU_OP, `EXE_SUB_OP: begin
            arithmeticres = result_sum;
          end

          // TODO: clz/clo
          default: begin
            arithmeticres = `ZeroWord;
          end
        endcase
      end
    end

endmodule // ex