`define RstEnable 1'b1
`define RstDisable 1'b0
`define ZeroWord 32'h00000000
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define AluOpBus 7:0
`define AluSelBus 2:0
`define InstValid 1'b1
`define InstInvalid 1'b0
`define True_v 1'b1
`define False_v 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0

// op = 31:26
// op2 = 10:6
// op3 = 5:0
// op4 = 20:16
// op5 = 25:21

// op = SPECIAL
`define EXE_SPECIAL_INST 6'b000000
// op3
`define EXE_SLL 6'b000000
`define EXE_SRL 6'b000010
`define EXE_SRA 6'b000011
`define EXE_SLLV 6'b000100
`define EXE_SRLV 6'b000110
`define EXE_SRAV 6'b000111
`define EXE_JR 6'b001000
`define EXE_JALR 6'b001001
`define EXE_MOVZ 6'b001010
`define EXE_MOVN 6'b001011
`define EXE_SYSCALL 6'b001100
`define EXE_BREAK 6'b001101
`define EXE_SYNC 6'b001111
`define EXE_MFHI 6'b010000
`define EXE_MTHI 6'b010001
`define EXE_MFLO 6'b010010
`define EXE_MTLO 6'b010011
`define EXE_MULT 6'b011000
`define EXE_MULTU 6'b011001
`define EXE_DIV 6'b011010
`define EXE_DIVU 6'b011011
`define EXE_ADD 6'b100000
`define EXE_ADDU 6'b100001
`define EXE_SUB 6'b100010
`define EXE_SUBU 6'b100011
`define EXE_AND 6'b100100
`define EXE_OR 6'b100101
`define EXE_XOR 6'b100110
`define EXE_NOR 6'b100111
`define EXE_SLT 6'b101010
`define EXE_SLTU 6'b101011
`define EXE_TGE 6'b110000
`define EXE_TGEU 6'b110001
`define EXE_TLT 6'b110010
`define EXE_TLTU 6'b110011
`define EXE_TEQ 6'b110100
`define EXE_TNE 6'b110110

// op = REGIMM
`define EXE_REGIMM_INST 6'b000001
// op4
`define EXE_BLTZ 5'b00000
`define EXE_BGEZ 5'b00001
`define EXE_BLTZL 5'b00010
`define EXE_BGEZL 5'b00011
`define EXE_TGEI 5'b01000
`define EXE_TGEIU 5'b01001
`define EXE_TLTI 5'b01010
`define EXE_TLTIU 5'b01011
`define EXE_TEQI 5'b01100
`define EXE_TNEI 5'b01110
`define EXE_BLTZAL 5'b10000
`define EXE_BGEZAL 5'b10001
`define EXE_BLTZALL 5'b10010
`define EXE_BGEZALL 5'b10011
`define EXE_SYNCI 5'b11111

// op = COP0
`define EXE_COP0_INST 6'b010000
// op5
`define EXE_MFC0 5'b00000
`define EXE_MTC0 5'b00100
`define EXE_CO 5'b10000
// op5 = CO
// op3
`define EXE_TLBR 6'b000001
`define EXE_TLBWI 6'b000010
`define EXE_TLBWR 6'b000110
`define EXE_TLBP 6'b001000
`define EXE_WAIT 6'b100000

// op = COP1
`define EXE_COP1_INST 6'b010001

// op = COP2
`define EXE_COP2_INST 6'b010010

// op = SPECIAL2
`define EXE_SPECIAL2_INST 6'b011100
// op3
`define EXE_MADD 6'b000000
`define EXE_MADDU 6'b000001
`define EXE_MUL 6'b000010
`define EXE_MSUB 6'b000100
`define EXE_MSUBU 6'b000101
`define EXE_CLZ 6'b100000
`define EXE_CLO 6'b100001
`define EXE_SDBBP 6'b111111

// op = SPECIAL3
`define EXE_SPECIAL3_INST 6'b011111
// op3
`define EXE_BSHFL 6'b100000
// op3 = BSHFL
// op2
`define EXE_SEB 5'b10000
`define EXE_SEH 5'b11000

// op
`define EXE_J 6'b000010
`define EXE_JAL 6'b000011
`define EXE_BEQ 6'b000100
`define EXE_BNE 6'b000101
`define EXE_BLEZ 6'b000110
`define EXE_BGTZ 6'b000111
`define EXE_ADDI 6'b001000
`define EXE_ADDIU 6'b001001
`define EXE_SLTI 6'b001010
`define EXE_SLTIU 6'b001011
`define EXE_ANDI 6'b001100
`define EXE_ORI 6'b001101
`define EXE_XORI 6'b001110
`define EXE_LUI 6'b001111
`define EXE_LB 6'b100000
`define EXE_LH 6'b100001
`define EXE_LWL 6'b100010
`define EXE_LW 6'b100011
`define EXE_LBU 6'b100100
`define EXE_LHU 6'b100101
`define EXE_LWR 6'b100110
`define EXE_SB 6'b101000
`define EXE_SH 6'b101001
`define EXE_SWL 6'b101010
`define EXE_SW 6'b101011
`define EXE_SWR 6'b101110
`define EXE_CACHE 6'b101111
`define EXE_PREF 6'b110011

// others
`define EXE_ERET 32'b01000010_00000000_00000000_00011000

// just assign one by one, order is unrelated
`define EXE_NOP_OP 8'b00000000
`define EXE_AND_OP 8'b00000001
`define EXE_OR_OP 8'b00000010
`define EXE_NOR_OP 8'b00000011
`define EXE_XOR_OP 8'b00000100

`define EXE_SLL_OP 8'b00000101
`define EXE_SRL_OP 8'b00000110
`define EXE_SRA_OP 8'b00000111

`define EXE_MFHI_OP 8'b00001000
`define EXE_MFLO_OP 8'b00001001
`define EXE_MOVZ_OP 8'b00001010
`define EXE_MOVN_OP 8'b00001011
`define EXE_MTHI_OP 8'b00001100
`define EXE_MTLO_OP 8'b00001101

`define EXE_ADDI_OP 8'b00001110
`define EXE_ADDIU_OP 8'b00001111
`define EXE_SUB_OP 8'b00010000
`define EXE_SUBU_OP 8'b00010001

`define EXE_JR_OP 8'b00010010
`define EXE_JALR_OP 8'b00010011
`define EXE_J_OP 8'b00010100
`define EXE_JAL_OP 8'b00010101

`define EXE_SLT_OP 8'b00010111
`define EXE_SLTU_OP 8'b00011000
`define EXE_ADD_OP 8'b00011001
`define EXE_ADDU_OP 8'b00011010
`define EXE_MULT_OP 8'b00011011
`define EXE_MULTU_OP 8'b00011100
`define EXE_MUL_OP 8'b00011101
`define EXE_CLZ_OP 8'b00011110
`define EXE_CLO_OP 8'b00011111

`define EXE_BEQ_OP 8'b00100000
`define EXE_BGEZ_OP 8'b00100001
`define EXE_BGEZAL_OP 8'b00100010
`define EXE_BGTZ_OP 8'b00100011
`define EXE_BLEZ_OP 8'b00100100
`define EXE_BLTZ_OP 8'b00100101
`define EXE_BLTZAL_OP 8'b00100110
`define EXE_BNE_OP 8'b00100111

`define EXE_MFC0_OP 8'b00101000
`define EXE_MTC0_OP 8'b00101001

`define EXE_SYSCALL_OP 8'b00101010

// trap
`define EXE_TEQ_OP 8'b00101011
`define EXE_TEQI_OP 8'b00101100
`define EXE_TGE_OP 8'b00101101
`define EXE_TGEI_OP 8'b00101110
`define EXE_TGEIU_OP 8'b00101111
`define EXE_TGEU_OP 8'b00110000
`define EXE_TLT_OP 8'b00110001
`define EXE_TLTI_OP 8'b00110010
`define EXE_TLTIU_OP 8'b00110011
`define EXE_TLTU_OP 8'b00110100
`define EXE_TNE_OP 8'b00110101
`define EXE_TNEI_OP 8'b00110110

`define EXE_ERET_OP 8'b00110111

`define EXE_MADD_OP 8'b00111000
`define EXE_MADDU_OP 8'b00111001
`define EXE_MSUB_OP 8'b00111010
`define EXE_MSUBU_OP 8'b00111011

`define EXE_LB_OP  8'b00111100
`define EXE_LBU_OP  8'b00111101
`define EXE_LH_OP  8'b00111110
`define EXE_LHU_OP  8'b00111111
`define EXE_LW_OP  8'b01000000
`define EXE_SB_OP  8'b01000001
`define EXE_SH_OP  8'b01000010
`define EXE_SW_OP  8'b01000011

`define EXE_PREF_OP  8'b01000110

`define EXE_DIV_OP 8'b01000111
`define EXE_DIVU_OP 8'b01001000

`define EXE_BREAK_OP 8'b01001001

`define EXE_SEB_OP 8'b01001010
`define EXE_SEH_OP 8'b01001011

`define EXE_LWL_OP  8'b01001100
`define EXE_LWR_OP  8'b01001101
`define EXE_SWL_OP  8'b01001110
`define EXE_SWR_OP  8'b01001111

`define EXE_RES_NOP 3'b000
`define EXE_RES_LOGIC 3'b001
`define EXE_RES_SHIFT 3'b010
`define EXE_RES_MOVE 3'b011
`define EXE_RES_ARITHMETIC 3'b100
`define EXE_RES_JUMP_BRANCH 3'b101
`define EXE_RES_MUL 3'b110
`define EXE_RES_LOAD_STORE 3'b111	

`define CP0RegAddrBus 7:0
`define CP0_REG_INDEX {5'd0,3'd0}
`define CP0_REG_ENTRYLO0 {5'd2,3'd0}
`define CP0_REG_ENTRYLO1 {5'd3,3'd0}
`define CP0_REG_CONTEXT {5'd4,3'd0}
`define CP0_REG_PAGEMASK {5'd5,3'd0}
`define CP0_REG_WIRED {5'd6,3'd0}
`define CP0_REG_BADVADDR {5'd8,3'd0}
`define CP0_REG_COUNT {5'd9,3'd0}
`define CP0_REG_ENTRYHI {5'd10,3'd0}
`define CP0_REG_COMPARE {5'd11,3'd0}
`define CP0_REG_STATUS {5'd12,3'd0}
`define CP0_REG_CAUSE {5'd13,3'd0}
`define CP0_REG_EPC {5'd14,3'd0}
`define CP0_REG_PRId {5'd15,3'd0}
`define CP0_REG_EBASE {5'd15,3'd1}
`define CP0_REG_CONFIG {5'd16,3'd0}
`define CP0_REG_CONFIG1 {5'd16,3'd1}


`define InstAddrBus 31:0
`define InstBus 31:0
`define InstMemNum 131071 // 128KB
`define InstMemNumLog2 17
`define DataMemNum 131071 // 128KB
`define DataMemNumLog2 17

`define RegAddrBus 4:0
`define RegBus 31:0
`define RegWidth 32
`define DoubleRegWidth 64
`define DoubleRegBus 63:0
`define RegNum 32
`define RegNumLog2 5
`define NOPRegAddr 5'b0000

`define ExceptTypeBus 31:0
`define TLBConfigBus 85:0

`define TlbOpBus 2:0
`define TlbOpWidth 3
`define TLB_OP_NOP 3'b000
`define TLB_OP_TLBR 3'b001
`define TLB_OP_TLBWI 3'b010
`define TLB_OP_TLBWR 3'b011
`define TLB_OP_TLBP 3'b100

`define DivFree 2'b00
`define DivByZero 2'b01
`define DivOn 2'b10
`define DivEnd 2'b11
`define DivResultReady 1'b1
`define DivResultNotReady 1'b0
`define DivStart 1'b1
`define DivStop 1'b0
`define Stop 1'b1
`define NoStop 1'b0

// 32 entries
`define TLB_WIDTH 5
`define TLB_ENTRIES 32