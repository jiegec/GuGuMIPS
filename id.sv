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
    output logic is_in_delayslot_o
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
                    branch_target_address_o = reg1_o;
                    branch_flag_o = 1;
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
                    branch_target_address_o = reg1_o;
                    branch_flag_o = 1;
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
          `EXE_BEQ: begin
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