`include "define.vh"
module id(
    input wire rst,
    input wire[`InstAddrBus] pc_i,
    input wire[`InstBus] inst_i,

    input wire[`RegBus] reg1_data_i, // read reg1 data
    input wire[`RegBus] reg2_data_i, // read reg2 data

    output reg reg1_read_o, // read reg1 or not
    output reg reg2_read_o, // read reg2 or not
    output reg[`RegAddrBus] reg1_addr_o, // read reg1 num
    output reg[`RegAddrBus] reg2_addr_o, // read reg2 num

    output reg[`AluOpBus] aluop_o, // alu op
    output reg[`AluSelBus] alusel_o, // alu selector
    output reg[`RegBus] reg1_o, // reg1 passed to alu
    output reg[`RegBus] reg2_o, // reg2 passed to alu
    output reg[`RegAddrBus] wd_o, // output register num
    output reg wreg_o, // output enabled

    // check if the data is changed in last or the one before last inst
    input wire ex_wreg_i, // last
    input wire[`RegBus] ex_wdata_i,
    input wire[`RegAddrBus] ex_wd_i,

    input wire mem_wreg_i, // the one before last
    input wire[`RegBus] mem_wdata_i,
    input wire[`RegAddrBus] mem_wd_i,

    input is_in_delayslot_i,
    output logic next_inst_in_delayslot_o,
    output logic branch_flag_o,
    output logic[`RegBus] branch_target_address_o,
    output logic[`RegBus] link_addr_o,
    output logic is_in_delayslot_o,
    output logic[`InstAddrBus] pc_o,

    output logic [31:0] except_type_o
);
    wire[5:0] op = inst_i[31:26]; // op type
    wire[4:0] op2 = inst_i[10:6];
    wire[5:0] op3 = inst_i[5:0]; // for special inst
    wire[4:0] op4 = inst_i[20:16];

    reg[`RegBus] imm;
    reg instvalid;

    logic[`RegBus] pc_plus_8;
    logic[`RegBus] pc_plus_4;
    logic[`RegBus] imm_sll2_signedext;

    assign pc_plus_8 = pc_i + 8;
    assign pc_plus_4 = pc_i + 4;

    assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};

    logic except_type_is_syscall;
    logic except_type_is_eret;
    logic except_type_is_break;
    logic except_type_is_address_load; // instruction

    assign except_type_o = {17'b0,
      except_type_is_address_load,
      except_type_is_break, except_type_is_eret, 2'b0,
      ~instvalid, except_type_is_syscall, 8'b0};

    // assign inst_o = inst_i;
    // for instruction load access exception,
    // cp0_badvaddr = cp0_epc = branch_target_address_o
    assign pc_o = except_type_is_address_load ? branch_target_address_o : pc_i;

    always_comb begin
      if (rst == `RstEnable) begin
        aluop_o = `EXE_NOP_OP;
        alusel_o = `EXE_RES_NOP;
        wd_o = `NOPRegAddr;
        wreg_o = `WriteDisable;
        instvalid = `InstValid;
        reg1_read_o = 1'b0;
        reg2_read_o = 1'b0;
        reg1_addr_o = `NOPRegAddr;
        reg2_addr_o = `NOPRegAddr;
        imm = `ZeroWord;
        next_inst_in_delayslot_o = 0;
        branch_flag_o = 0;
        branch_target_address_o = 0;
        link_addr_o = 0;

        except_type_is_eret = 0;
        except_type_is_syscall = 0;
        except_type_is_break = 0;
        except_type_is_address_load = 0;
      end else begin
        aluop_o = `EXE_NOP_OP;
        alusel_o = `EXE_RES_NOP;
        wd_o = inst_i[15:11]; // default to rd
        wreg_o = `WriteDisable;
        instvalid = `InstInvalid;
        reg1_read_o = 1'b0;
        reg2_read_o = 1'b0;
        reg1_addr_o = inst_i[25:21]; // default to rs
        reg2_addr_o = inst_i[20:16]; // default to rt
        imm = `ZeroWord;
        link_addr_o = 0;
        branch_target_address_o = 0;
        branch_flag_o = 0;
        next_inst_in_delayslot_o = 0;
        except_type_is_eret = 0;
        except_type_is_syscall = 0;
        except_type_is_break = 0;
        except_type_is_address_load = 0;

        case (op)
          `EXE_SPECIAL_INST: begin
            case (op2)
              5'b00000:  begin
                case (op3)
                  // bit
                  `EXE_OR:  begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_OR_OP;
                    alusel_o = `EXE_RES_LOGIC;
                    reg1_read_o = 1'b1; // read 1st operand from rs
                    reg2_read_o = 1'b1; // read 2nd operand from rt
                    instvalid = `InstValid;
                  end
                  `EXE_AND:  begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_AND_OP;
                    alusel_o = `EXE_RES_LOGIC;
                    reg1_read_o = 1'b1; // read 1st operand from rs
                    reg2_read_o = 1'b1; // read 2nd operand from rt
                    instvalid = `InstValid;
                  end
                  `EXE_XOR:  begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_XOR_OP;
                    alusel_o = `EXE_RES_LOGIC;
                    reg1_read_o = 1'b1; // read 1st operand from rs
                    reg2_read_o = 1'b1; // read 2nd operand from rt
                    instvalid = `InstValid;
                  end
                  `EXE_NOR:  begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_NOR_OP;
                    alusel_o = `EXE_RES_LOGIC;
                    reg1_read_o = 1'b1; // read 1st operand from rs
                    reg2_read_o = 1'b1; // read 2nd operand from rt
                    instvalid = `InstValid;
                  end
                  `EXE_SLLV:  begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_SLL_OP;
                    alusel_o = `EXE_RES_SHIFT;
                    reg1_read_o = 1'b1; // read 1st operand from rs
                    reg2_read_o = 1'b1; // read 2nd operand from rt
                    instvalid = `InstValid;
                  end
                  `EXE_SRLV:  begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_SRL_OP;
                    alusel_o = `EXE_RES_SHIFT;
                    reg1_read_o = 1'b1; // read 1st operand from rs
                    reg2_read_o = 1'b1; // read 2nd operand from rt
                    instvalid = `InstValid;
                  end
                  `EXE_SRAV:  begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_SRA_OP;
                    alusel_o = `EXE_RES_SHIFT;
                    reg1_read_o = 1'b1; // read 1st operand from rs
                    reg2_read_o = 1'b1; // read 2nd operand from rt
                    instvalid = `InstValid;
                  end

                  // nop
                  `EXE_SYNC:  begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_NOP_OP;
                    alusel_o = `EXE_RES_NOP;
                    reg1_read_o = 1'b0;
                    reg2_read_o = 1'b0;
                    instvalid = `InstValid;
                  end

                  // move
                  `EXE_MFHI: begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_MFHI_OP;
                    alusel_o = `EXE_RES_MOVE;
                    reg1_read_o = 1'b0;
                    reg2_read_o = 1'b0;
                    instvalid = `InstValid;
                  end
                  `EXE_MFLO: begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_MFLO_OP;
                    alusel_o = `EXE_RES_MOVE;
                    reg1_read_o = 1'b0;
                    reg2_read_o = 1'b0;
                    instvalid = `InstValid;
                  end
                  `EXE_MTHI: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_MTHI_OP;
                    alusel_o = `EXE_RES_MOVE;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b0;
                    instvalid = `InstValid;
                  end
                  `EXE_MTLO: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_MTLO_OP;
                    alusel_o = `EXE_RES_MOVE;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b0;
                    instvalid = `InstValid;
                  end
                  `EXE_MOVN: begin
                    aluop_o = `EXE_MOVN_OP;
                    alusel_o = `EXE_RES_MOVE;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = `InstValid;
                    if (reg2_o != `ZeroWord) begin
                      wreg_o = `WriteEnable;
                    end else begin
                      wreg_o = `WriteDisable;
                    end
                  end
                  `EXE_MOVZ: begin
                    aluop_o = `EXE_MOVZ_OP;
                    alusel_o = `EXE_RES_MOVE;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = `InstValid;
                    if (reg2_o == `ZeroWord) begin
                      wreg_o = `WriteEnable;
                    end else begin
                      wreg_o = `WriteDisable;
                    end
                  end

                  // jump
                  `EXE_JR: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_JR_OP;
                    alusel_o = `EXE_RES_JUMP_BRANCH;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b0;
                    link_addr_o = 0;
                    // check alignment
                    if (reg1_o[1:0] != 0) begin
                      except_type_is_address_load = 1;
                    end else begin
                      branch_flag_o = 1;
                    end
                    branch_target_address_o = reg1_o;
                    next_inst_in_delayslot_o = 1;
                    instvalid = 1;
                  end
                  `EXE_JALR: begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_JALR_OP;
                    alusel_o = `EXE_RES_JUMP_BRANCH;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b0;
                    wd_o = inst_i[15:11];
                    link_addr_o = pc_plus_8; // skip delay slot
                    // check alignment
                    if (reg1_o[1:0] != 0) begin
                      except_type_is_address_load = 1;
                    end else begin
                      branch_flag_o = 1;
                    end
                    branch_target_address_o = reg1_o;
                    next_inst_in_delayslot_o = 1;
                    instvalid = 1;
                  end

                  // arithmetic
                  `EXE_SLT: begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_SLT_OP;
                    alusel_o = `EXE_RES_ARITHMETIC;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end
                  `EXE_SLTU: begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_SLTU_OP;
                    alusel_o = `EXE_RES_ARITHMETIC;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end
                  `EXE_ADD: begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_ADD_OP;
                    alusel_o = `EXE_RES_ARITHMETIC;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end
                  `EXE_ADDU: begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_ADDU_OP;
                    alusel_o = `EXE_RES_ARITHMETIC;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end
                  `EXE_SUB: begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_SUB_OP;
                    alusel_o = `EXE_RES_ARITHMETIC;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end
                  `EXE_SUBU: begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_SUBU_OP;
                    alusel_o = `EXE_RES_ARITHMETIC;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end

                  // mult
                  `EXE_MULT: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_MULT_OP;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end
                  `EXE_MULTU: begin
                    wreg_o = `WriteEnable;
                    aluop_o = `EXE_MULTU_OP;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end					

                  // div
                  `EXE_DIV: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_DIV_OP;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1'b1;
                  end
                  `EXE_DIVU: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_DIVU_OP;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1'b1;
                  end

                  // trap
                  `EXE_TEQ: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_TEQ_OP;
                    alusel_o = `EXE_RES_NOP;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end
                  `EXE_TGE: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_TGE_OP;
                    alusel_o = `EXE_RES_NOP;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end
                  `EXE_TLT: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_TLT_OP;
                    alusel_o = `EXE_RES_NOP;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end
                  `EXE_TLTU: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_TLTU_OP;
                    alusel_o = `EXE_RES_NOP;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end
                  `EXE_TNE: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_TNE_OP;
                    alusel_o = `EXE_RES_NOP;
                    reg1_read_o = 1'b1;
                    reg2_read_o = 1'b1;
                    instvalid = 1;
                  end

                  // syscall
                  `EXE_SYSCALL: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_SYSCALL_OP;
                    alusel_o = `EXE_RES_NOP;
                    reg1_read_o = 1'b0;
                    reg2_read_o = 1'b0;
                    instvalid = 1;
                    except_type_is_syscall = 1;
                  end

                  // break
                  `EXE_BREAK: begin
                    wreg_o = `WriteDisable;
                    aluop_o = `EXE_BREAK_OP;
                    alusel_o = `EXE_RES_NOP;
                    reg1_read_o = 1'b0;
                    reg2_read_o = 1'b0;
                    instvalid = 1;
                    except_type_is_break = 1;
                  end
                  default: begin
                    
                  end
                endcase // op3 case
              end
              default: begin
              end
            endcase // op2 case
          end

          // bit
          `EXE_ORI: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_OR_OP;
            alusel_o = `EXE_RES_LOGIC;
            reg1_read_o = 1'b1; // read source from rs
            reg2_read_o = 1'b0; // use imm
            // unsigned extend
            imm = {16'h0, inst_i[15:0]};
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end
          `EXE_ANDI: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_AND_OP;
            alusel_o = `EXE_RES_LOGIC;
            reg1_read_o = 1'b1; // read source from rs
            reg2_read_o = 1'b0; // use imm
            // unsigned extend
            imm = {16'h0, inst_i[15:0]};
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end
          `EXE_XORI: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_XOR_OP;
            alusel_o = `EXE_RES_LOGIC;
            reg1_read_o = 1'b1; // read source from rs
            reg2_read_o = 1'b0; // use imm
            // unsigned extend
            imm = {16'h0, inst_i[15:0]};
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end
          `EXE_LUI: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_OR_OP;
            alusel_o = `EXE_RES_LOGIC;
            reg1_read_o = 1'b1; // read source from rs
            reg2_read_o = 1'b0; // use imm
            // raise to upper
            imm = {inst_i[15:0], 16'h0};
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end

          // arithmetic
          `EXE_SLTI: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_SLT_OP;
            alusel_o = `EXE_RES_ARITHMETIC;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b0;
            // sign extension
            imm = {{16{inst_i[15]}}, inst_i[15:0]};
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end
          `EXE_SLTIU: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_SLTU_OP;
            alusel_o = `EXE_RES_ARITHMETIC;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b0;
            // sign extension
            imm = {{16{inst_i[15]}}, inst_i[15:0]};
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end
          `EXE_ADDI: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_ADDI_OP;
            alusel_o = `EXE_RES_ARITHMETIC;
            reg1_read_o = 1'b1; // read source from rs
            reg2_read_o = 1'b0; // use imm
            // sign extension
            imm = {{16{inst_i[15]}}, inst_i[15:0]};
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end
          `EXE_ADDIU: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_ADDIU_OP;
            alusel_o = `EXE_RES_ARITHMETIC;
            reg1_read_o = 1'b1; // read source from rs
            reg2_read_o = 1'b0; // use imm
            // sign extension
            imm = {{16{inst_i[15]}}, inst_i[15:0]};
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end

          // nop
          `EXE_PREF: begin
            wreg_o = `WriteDisable;
            aluop_o = `EXE_NOR_OP;
            alusel_o = `EXE_RES_NOP;
            reg1_read_o = 1'b0;
            reg2_read_o = 1'b0;
            instvalid = `InstValid;
          end

          // jump
          `EXE_J: begin
            wreg_o = `WriteDisable;
            aluop_o = `EXE_J_OP;
            alusel_o = `EXE_RES_JUMP_BRANCH;
            reg1_read_o = 1'b0;
            reg2_read_o = 1'b0;
            link_addr_o = 0;
            branch_flag_o = 1;
            next_inst_in_delayslot_o = 1;
            instvalid = 1;
            branch_target_address_o = {pc_plus_4[31:28], inst_i[25:0], 2'b00};
          end
          `EXE_JAL: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_JAL_OP;
            alusel_o = `EXE_RES_JUMP_BRANCH;
            reg1_read_o = 1'b0;
            reg2_read_o = 1'b0;
            wd_o = 5'b11111; // last register
            link_addr_o = pc_plus_8; // skip delay slot
            branch_flag_o = 1;
            next_inst_in_delayslot_o = 1;
            instvalid = 1;
            branch_target_address_o = {pc_plus_4[31:28], inst_i[25:0], 2'b00};
          end

          // branch
          `EXE_BEQ: begin // r1 == r2
            wreg_o = `WriteDisable;
            aluop_o = `EXE_BEQ_OP;
            alusel_o = `EXE_RES_JUMP_BRANCH;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b1;
            instvalid = 1;
            if (reg1_o == reg2_o) begin
              branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
              branch_flag_o = 1;
              next_inst_in_delayslot_o = 1;
            end
          end
          `EXE_BGTZ: begin // r > 0
            wreg_o = `WriteDisable;
            aluop_o = `EXE_BGTZ_OP;
            alusel_o = `EXE_RES_JUMP_BRANCH;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b0;
            instvalid = 1;
            if ((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
              branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
              branch_flag_o = 1;
              next_inst_in_delayslot_o = 1;
            end
          end
          `EXE_BLEZ: begin // r <= 0
            wreg_o = `WriteDisable;
            aluop_o = `EXE_BLEZ_OP;
            alusel_o = `EXE_RES_JUMP_BRANCH;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b0;
            instvalid = 1;
            if ((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
              branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
              branch_flag_o = 1;
              next_inst_in_delayslot_o = 1;
            end
          end
          `EXE_BNE: begin // r1 != r2
            wreg_o = `WriteDisable;
            aluop_o = `EXE_BNE_OP;
            alusel_o = `EXE_RES_JUMP_BRANCH;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b1;
            instvalid = 1;
            if (reg1_o != reg2_o) begin
              branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
              branch_flag_o = 1;
              next_inst_in_delayslot_o = 1;
            end
          end

          // load
          `EXE_LB: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_LB_OP;
            alusel_o = `EXE_RES_LOAD_STORE;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b0;
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end
          `EXE_LBU: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_LBU_OP;
            alusel_o = `EXE_RES_LOAD_STORE;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b0;
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end
          `EXE_LH: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_LH_OP;
            alusel_o = `EXE_RES_LOAD_STORE;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b0;
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end
          `EXE_LHU: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_LHU_OP;
            alusel_o = `EXE_RES_LOAD_STORE;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b0;
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end
          `EXE_LW: begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_LW_OP;
            alusel_o = `EXE_RES_LOAD_STORE;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b0;
            wd_o = inst_i[20:16];
            instvalid = `InstValid;
          end

          // store
          `EXE_SB: begin
            wreg_o = `WriteDisable;
            aluop_o = `EXE_SB_OP;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b1;
            instvalid = `InstValid;
            alusel_o = `EXE_RES_LOAD_STORE;
          end
          `EXE_SH: begin
            wreg_o = `WriteDisable;
            aluop_o = `EXE_SH_OP;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b1;
            instvalid = `InstValid;
            alusel_o = `EXE_RES_LOAD_STORE;
          end
          `EXE_SW: begin
            wreg_o = `WriteDisable;
            aluop_o = `EXE_SW_OP;
            reg1_read_o = 1'b1;
            reg2_read_o = 1'b1;
            instvalid = `InstValid;
            alusel_o = `EXE_RES_LOAD_STORE;
          end

          `EXE_REGIMM_INST: begin
            case (op4)
              // branch
              `EXE_BGEZ: begin // r1 >= 0
                wreg_o = `WriteDisable;
                aluop_o = `EXE_BGEZ_OP;
                alusel_o = `EXE_RES_JUMP_BRANCH;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                instvalid = 1;
                if (reg1_o[31] == 1'b0) begin
                  branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                  branch_flag_o = 1;
                  next_inst_in_delayslot_o = 1;
                end
              end
              `EXE_BGEZAL: begin // r1 >= 0, link $31
                wreg_o = `WriteEnable;
                aluop_o = `EXE_BGEZAL_OP;
                alusel_o = `EXE_RES_JUMP_BRANCH;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                link_addr_o = pc_plus_8;
                wd_o = 5'b11111;
                instvalid = 1;
                if (reg1_o[31] == 1'b0) begin
                  branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                  branch_flag_o = 1;
                  next_inst_in_delayslot_o = 1;
                end
              end
              `EXE_BLTZ: begin // r1 < 0
                wreg_o = `WriteDisable;
                aluop_o = `EXE_BLTZ_OP;
                alusel_o = `EXE_RES_JUMP_BRANCH;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                instvalid = 1;
                if (reg1_o[31] == 1'b1) begin
                  branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                  branch_flag_o = 1;
                  next_inst_in_delayslot_o = 1;
                end
              end
              `EXE_BLTZAL: begin // r1 < 0, link $31
                wreg_o = `WriteEnable;
                aluop_o = `EXE_BLTZAL_OP;
                alusel_o = `EXE_RES_JUMP_BRANCH;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                link_addr_o = pc_plus_8;
                wd_o = 5'b11111;
                instvalid = 1;
                if (reg1_o[31] == 1'b1) begin
                  branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                  branch_flag_o = 1;
                  next_inst_in_delayslot_o = 1;
                end
              end

              // trap
              `EXE_TEQI: begin
                wreg_o = `WriteDisable;
                aluop_o = `EXE_TEQI_OP;
                alusel_o = `EXE_RES_NOP;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                imm = {{16{inst_i[15]}}, inst_i[15:0]};
                instvalid = 1;
              end
              `EXE_TGEI: begin
                wreg_o = `WriteDisable;
                aluop_o = `EXE_TGEI_OP;
                alusel_o = `EXE_RES_NOP;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                imm = {{16{inst_i[15]}}, inst_i[15:0]};
                instvalid = 1;
              end
              `EXE_TGEIU: begin
                wreg_o = `WriteDisable;
                aluop_o = `EXE_TGEIU_OP;
                alusel_o = `EXE_RES_NOP;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                imm = {{16{inst_i[15]}}, inst_i[15:0]};
                instvalid = 1;
              end
              `EXE_TLTI: begin
                wreg_o = `WriteDisable;
                aluop_o = `EXE_TLTI_OP;
                alusel_o = `EXE_RES_NOP;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                imm = {{16{inst_i[15]}}, inst_i[15:0]};
                instvalid = 1;
              end
              `EXE_TLTIU: begin
                wreg_o = `WriteDisable;
                aluop_o = `EXE_TLTIU_OP;
                alusel_o = `EXE_RES_NOP;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                imm = {{16{inst_i[15]}}, inst_i[15:0]};
                instvalid = 1;
              end
              `EXE_TNEI: begin
                wreg_o = `WriteDisable;
                aluop_o = `EXE_TNEI_OP;
                alusel_o = `EXE_RES_NOP;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                imm = {{16{inst_i[15]}}, inst_i[15:0]};
                instvalid = 1;
              end
            endcase // op4 case
          end

          `EXE_SPECIAL2_INST: begin		
            case(op3)
              // arithmetic
              `EXE_CLZ: begin
                wreg_o = `WriteEnable;
                aluop_o = `EXE_CLZ_OP;
                alusel_o = `EXE_RES_ARITHMETIC;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                instvalid = 1;
              end
              `EXE_CLO: begin
                wreg_o = `WriteEnable;
                aluop_o = `EXE_CLO_OP;
                alusel_o = `EXE_RES_ARITHMETIC;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                instvalid = 1;
              end
              `EXE_MUL: begin
                wreg_o = `WriteEnable;
                aluop_o = `EXE_MUL_OP;
                alusel_o = `EXE_RES_MUL;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b1;
                instvalid = 1;
              end
			  `EXE_MADD: begin
				wreg_o = `WriteDisable;		
				aluop_o = `EXE_MADD_OP;
                alusel_o = `EXE_RES_ARITHMETIC;
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b1;	  			
		  		instvalid = `InstValid;	
			  end
			  `EXE_MADDU: begin
				wreg_o = `WriteDisable;		
				aluop_o = `EXE_MADDU_OP;
                alusel_o = `EXE_RES_ARITHMETIC;
				reg1_read_o = 1'b1;	
				reg2_read_o = 1'b1;	  			
		  		instvalid = `InstValid;	
			  end
			  `EXE_MSUB: begin
				wreg_o = `WriteDisable;		
				aluop_o = `EXE_MSUB_OP;
                alusel_o = `EXE_RES_ARITHMETIC;
				reg1_read_o = 1'b1;	
				reg2_read_o = 1'b1;	  			
		  		instvalid = `InstValid;	
			  end
			  `EXE_MSUBU: begin
				wreg_o = `WriteDisable;
				aluop_o = `EXE_MSUBU_OP;
                alusel_o = `EXE_RES_ARITHMETIC;
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;	  			
		  		instvalid = `InstValid;	
			  end
            endcase // op3 case
          end
          default: begin
          end
        endcase // op case

        // sll, srl and sra
        if (inst_i[31:21] == 11'b0000000000) begin
          if (op3 == `EXE_SLL) begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_SLL_OP;
            alusel_o = `EXE_RES_SHIFT;
            reg1_read_o = 1'b0;
            reg2_read_o = 1'b1;
            imm[4:0] = inst_i[10:6];
            wd_o = inst_i[15:11];
            instvalid = `InstValid;
          end else if (op3 == `EXE_SRL) begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_SRL_OP;
            alusel_o = `EXE_RES_SHIFT;
            reg1_read_o = 1'b0;
            reg2_read_o = 1'b1;
            imm[4:0] = inst_i[10:6];
            wd_o = inst_i[15:11];
            instvalid = `InstValid;
          end else if (op3 == `EXE_SRA) begin
            wreg_o = `WriteEnable;
            aluop_o = `EXE_SRA_OP;
            alusel_o = `EXE_RES_SHIFT;
            reg1_read_o = 1'b0;
            reg2_read_o = 1'b1;
            imm[4:0] = inst_i[10:6];
            wd_o = inst_i[15:11];
            instvalid = `InstValid;
          end
        end else if (inst_i[31:21] == 11'b01000000000 &&
          inst_i[10:0] == 11'b00000000000) begin
          // mfc0
          aluop_o = `EXE_MFC0_OP;
          alusel_o = `EXE_RES_MOVE;
          wd_o = inst_i[20:16];
          wreg_o = `WriteEnable;
          instvalid = 1;
          reg1_read_o = 1'b0;
          reg2_read_o = 1'b0;
        end else if (inst_i[31:21] == 11'b01000000100 &&
          // mtc0
          inst_i[10:0] == 11'b00000000000) begin
          aluop_o = `EXE_MTC0_OP;
          alusel_o = `EXE_RES_NOP;
          wreg_o = `WriteDisable;
          instvalid = 1;
          reg1_read_o = 1'b1;
          reg1_addr_o = inst_i[20:16];
          reg2_read_o = 1'b0;
        end else if (inst_i == `EXE_ERET) begin
          // eret
          wreg_o = `WriteDisable;
          aluop_o = `EXE_ERET_OP;
          alusel_o = `EXE_RES_NOP;
          reg1_read_o = 1'b0;
          reg2_read_o = 1'b0;
          instvalid = 1;
          except_type_is_eret = 1;
        end

        if (instvalid == `InstInvalid) begin
          $display("Invalid or unsupported instruction %h @ %x", inst_i, pc_i);
        end
      end
    end

    always_comb begin
      if (rst == `RstEnable) begin
        reg1_o = `ZeroWord;
      end else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) &&
                   (ex_wd_i == reg1_addr_o)) begin
        // the reg is overwritten in last inst.
        reg1_o = ex_wdata_i;
      end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) &&
                   (mem_wd_i == reg1_addr_o)) begin
        // the reg is overwritten in the one before last inst.
        reg1_o = mem_wdata_i;
      end else if (reg1_read_o == 1'b1) begin
        reg1_o = reg1_data_i;
      end else if (reg1_read_o == 1'b0) begin
        reg1_o = imm;
      end else begin
        reg1_o = `ZeroWord;
      end
    end

    always_comb begin
      if (rst == `RstEnable) begin
        reg2_o = `ZeroWord;
      end else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) &&
                   (ex_wd_i == reg2_addr_o)) begin
        // the reg is overwritten in last inst.
        reg2_o = ex_wdata_i;
      end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) &&
                   (mem_wd_i == reg2_addr_o)) begin
        // the reg is overwritten in the one before last inst.
        reg2_o = mem_wdata_i;
      end else if (reg2_read_o == 1'b1) begin
        reg2_o = reg2_data_i;
      end else if (reg2_read_o == 1'b0) begin
        reg2_o = imm;
      end else begin
        reg2_o = `ZeroWord;
      end
    end

    always_comb begin
      if (rst == `RstEnable) begin
        is_in_delayslot_o = 0;
      end else begin
        is_in_delayslot_o = is_in_delayslot_i;
      end
    end

endmodule // id
