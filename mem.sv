`include "define.vh"
module mem(
    input wire clk,
    input wire  rst,
    input wire[`RegAddrBus] wd_i,
    input wire wreg_i,
    input wire[`RegBus] wdata_i,

    input wire whilo_i,
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,

    input wire cp0_reg_we_i,
    input wire[4:0] cp0_reg_write_addr_i,
    input wire[`RegBus] cp0_reg_data_i,

    input [31:0] except_type_i,
    input is_in_delayslot_i,
    input [`RegBus] pc_i,
    output logic[`RegBus] pc_o,

    input [`RegBus] cp0_status_i,
    input [`RegBus] cp0_cause_i,
    input [`RegBus] cp0_epc_i,

    input wb_cp0_reg_we,
    input [4:0] wb_cp0_reg_write_addr,
    input [`RegBus] wb_cp0_reg_data,

    input wire [`AluOpBus] aluop_i,
    input wire [`RegBus] mem_addr_i,
    input wire [`RegBus] reg2_i,

    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,

    output reg whilo_o,
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o,

    output logic cp0_reg_we_o,
    output logic[4:0] cp0_reg_write_addr_o,
    output logic[`RegBus] cp0_reg_data_o,

    output logic[31:0] except_type_o,
    output logic[31:0] cp0_epc_o,

    output mem_stall,
    output mem_load,

    // mmu
    output logic [`RegBus] mmu_virt_addr,
    output logic mmu_en,
    input [`RegBus] mmu_phys_addr,
    input mmu_uncached,
    input mmu_except_miss,
    input mmu_except_invalid,
    input mmu_except_user,
    input mmu_except_dirty,

    // sram interface
    output data_req,
    output data_wr,
    output [1 :0] data_size,
    output [31:0] data_addr,
    output [31:0] data_wdata,
    output data_uncached,

    input [31:0] data_rdata,
    input data_addr_ok,
    input data_data_ok
);
    logic [31:0] cp0_status;
    logic [31:0] cp0_cause;
    logic [31:0] cp0_epc;
    logic misaligned_access;
    logic inst_store;

    wire[`RegBus] zero32;

    assign zero32 = `ZeroWord;

    // handle data dependency
    always_comb begin
        if (rst == `RstEnable) begin
            cp0_status = 0;
        end else if (wb_cp0_reg_we == 1 && wb_cp0_reg_write_addr == `CP0_REG_STATUS) begin
            cp0_status = wb_cp0_reg_data;
        end else begin
            cp0_status = cp0_status_i;
        end
    end

    always_comb begin
        if (rst == `RstEnable) begin
            cp0_epc = 0;
        end else if (wb_cp0_reg_we == 1 && wb_cp0_reg_write_addr == `CP0_REG_EPC) begin
            cp0_epc = wb_cp0_reg_data;
        end else begin
            cp0_epc = cp0_epc_i;
        end
    end

    assign cp0_epc_o = cp0_epc;

    always_comb begin
        if (rst == `RstEnable) begin
            cp0_cause = 0;
        end else if (wb_cp0_reg_we == 1 && wb_cp0_reg_write_addr == `CP0_REG_EPC) begin
            cp0_cause = cp0_cause_i;
            // IP[1:0]
            cp0_cause[9:8] = wb_cp0_reg_data[9:8];
            // WP
            cp0_cause[22] = wb_cp0_reg_data[22];
            // IV
            cp0_cause[23] = wb_cp0_reg_data[23];
        end else begin
            cp0_cause = cp0_cause_i;
        end
    end

    always_comb begin
        if (rst == `RstEnable) begin
            whilo_o = `WriteDisable;
            hi_o = `ZeroWord;
            lo_o = `ZeroWord;

            cp0_reg_we_o = 0;
            cp0_reg_write_addr_o = 0;
            cp0_reg_data_o = 0;
        end else begin
            whilo_o = whilo_i;
            hi_o = hi_i;
            lo_o = lo_i;

            cp0_reg_we_o = cp0_reg_we_i;
            cp0_reg_write_addr_o = cp0_reg_write_addr_i;
            cp0_reg_data_o = cp0_reg_data_i;
        end
    end

    always_comb begin
        if (rst == `RstEnable) begin
            except_type_o = 0;
        end else begin
            // MIP32 Vol 3 R6.02 Table6.6
            if (((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) &&
                (cp0_status[1] == 1'b0) && cp0_status[0] == 1'b1) begin
                // Interrupt
                except_type_o = 32'h00000001;
            end else if (except_type_i[14] == 1'b1) begin
                // Address Error - Instruction fetch
                except_type_o = 32'h0000000f;
            end else if (except_type_i[15] == 1'b1) begin
                // TLB Refill - Instruction fetch
                except_type_o = 32'h00000002;
            end else if (except_type_i[16] == 1'b1) begin
                // TLB Invalid - Instruction fetch
                except_type_o = 32'h00000003;
            end else if (except_type_i[9] == 1'b1) begin
                // Instruction Validity Exceptions
                // TODO: Coprocessor Unusable
                except_type_o = 32'h0000000a;
            end else if (except_type_i[8] == 1'b1) begin
                // System Call
                except_type_o = 32'h00000008;
            end else if (except_type_i[13] == 1'b1) begin
                // Breakpoint
                except_type_o = 32'h00000009;
            end else if (except_type_i[11] == 1'b1) begin
                // Integer Overflow
                except_type_o = 32'h0000000c;
            end else if (except_type_i[10] == 1'b1) begin
                // Trap
                except_type_o = 32'h0000000d;
            end else if (misaligned_access | mmu_except_user) begin
                // Address error - Data access
                if (inst_store) begin
                    // AdES
                    except_type_o = 32'h00000005;
                end else begin
                    // AdEL
                    except_type_o = 32'h00000004;
                end
            end else if (mmu_except_miss & ~inst_store) begin
                // TLB Refill - Data access (load)
                except_type_o = 32'h00000010;
            end else if (mmu_except_invalid & ~inst_store) begin
                // TLB Invalid - Data access (load)
                except_type_o = 32'h00000011;
            end else if (mmu_except_miss & inst_store) begin
                // TLB Refill - Data access (store)
                except_type_o = 32'h00000012;
            end else if (mmu_except_invalid & inst_store) begin
                // TLB Invalid - Data access (store)
                except_type_o = 32'h00000013;
            end else if (mmu_except_dirty & inst_store) begin
                // TLB Modified - Data access (store)
                except_type_o = 32'h00000014;
            end else if (except_type_i[12] == 1'b1) begin
                // eret
                except_type_o = 32'h0000000e;
            end else begin
                except_type_o = 32'h0;
            end
        end
    end

    logic [31:0] mem_addr_o;
    logic mem_we;
    logic [31:0]mem_data_i;
    logic [31:0]mem_data_o;
    logic mem_ce_o;
    logic [1:0] state; // 0: no transfer, 1: waiting for addr ok, 2: waiting for data ok
    logic [`RegAddrBus] saved_wd;
    logic [`AluOpBus] saved_aluop;
    logic [`RegBus] saved_mem_addr_i;
    logic [`RegBus] saved_mem_data_o;
    logic [`RegBus] saved_pc_i;
    logic saved_data_uncached;
    logic saved_data_wr;
    logic [1:0] saved_data_size;
    logic [1:0] data_size_o;
    logic data_uncached_o;
    logic exception_occurred;
    assign exception_occurred = |except_type_o;

    assign data_req = state == 2 ? 0 : (state == 1 ? 1 : mem_ce_o & ~exception_occurred);
    assign data_addr = state == 1 ? saved_mem_addr_i : mem_addr_o;
    assign mem_data_i = data_rdata;
    assign data_wdata = state == 0 ? mem_data_o : saved_mem_data_o;
    assign data_wr = state == 0 ? mem_we : (data_req & saved_data_wr);
    assign data_size = state == 0 ? data_size_o : saved_data_size;
    assign data_uncached = state == 0 ? data_uncached_o : saved_data_uncached;
    assign mem_stall = data_req || ((state != 0) && !data_data_ok);
    assign pc_o = data_data_ok ? saved_pc_i : pc_i;
    assign mem_load = state != 0 && !saved_data_wr;

    // MMU
    logic [31:0] mem_phy_addr;
    assign mem_phy_addr = mmu_phys_addr;
    assign mmu_en = mem_ce_o;
    assign mmu_virt_addr = mem_addr_i;
    assign data_uncached_o = mmu_uncached;

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= 0;
            saved_wd <= 0;
            saved_aluop <= 0;
            saved_mem_addr_i <= 0;
            saved_mem_data_o <= 0;
            saved_pc_i <= 0;
            saved_data_wr <= 0;
            saved_data_size <= 0;
            saved_data_uncached <= 0;
        end else if (data_req && state == 0 && !exception_occurred) begin
            state <= data_addr_ok ? 2 : 1;
            saved_wd <= wd_i;
            saved_aluop <= aluop_i;
            saved_mem_addr_i <= mem_addr_o;
            saved_mem_data_o <= mem_data_o;
            saved_pc_i <= pc_i;
            saved_data_wr <= data_wr;
            saved_data_size <= data_size_o;
            saved_data_uncached <= data_uncached_o;
        end else if (state == 1 && data_addr_ok) begin
            state <= 2;
        end else if (data_data_ok) begin
            state <= 0;
            saved_wd <= 0;
            saved_aluop <= 0;
            saved_mem_addr_i <= 0;
            saved_mem_data_o <= 0;
            saved_pc_i <= 0;
            saved_data_wr <= 0;
            saved_data_size <= 0;
            saved_data_uncached <= 0;
        end
    end

    always_comb begin
        if (rst == `RstEnable) begin
            mem_addr_o = `ZeroWord;
            mem_we = `WriteDisable;
            mem_data_o = `ZeroWord;
            mem_ce_o = `ChipDisable;

            wd_o = `NOPRegAddr;
            wreg_o = 0;
            wdata_o = `ZeroWord;

            misaligned_access = 0;
            inst_store = 0;
            data_size_o = 2'b00;
        end else begin
            mem_addr_o = `ZeroWord;
            mem_we = `WriteDisable;
            mem_data_o = `ZeroWord;
            mem_ce_o = `ChipDisable;
            wreg_o = (data_req | state) ? (data_data_ok & !saved_data_wr) : (wreg_i && !exception_occurred);
            wd_o = data_data_ok ? saved_wd : wd_i;
            misaligned_access = 0;
            inst_store = 0;
            data_size_o = 2'b00;

            wdata_o = wdata_i;
            case (aluop_i)
                // load
                `EXE_LB_OP:		begin
                    mem_addr_o = mem_phy_addr;
                    mem_we = `WriteDisable;
                    mem_ce_o = `ChipEnable;
                    data_size_o = 2'b00; // 1
                end
                `EXE_LBU_OP:		begin
                    mem_addr_o = mem_phy_addr;
                    mem_we = `WriteDisable;
                    mem_ce_o = `ChipEnable;
                    data_size_o = 2'b00; // 1
                end
                `EXE_LH_OP:		begin
                    mem_addr_o = mem_phy_addr;
                    mem_we = `WriteDisable;
                    if (mem_addr_o[0] != 0) begin
                        // misaligned
                        misaligned_access = 1;
                    end
                    mem_ce_o = `ChipEnable;
                    data_size_o = 2'b01; // 2
                end
                `EXE_LHU_OP:		begin
                    mem_addr_o = mem_phy_addr;
                    mem_we = `WriteDisable;
                    if (mem_addr_o[0] != 0) begin
                        // misaligned
                        misaligned_access = 1;
                    end
                    mem_ce_o = `ChipEnable;
                    data_size_o = 2'b01; // 2
                end
                `EXE_LW_OP:		begin
                    mem_addr_o = mem_phy_addr;
                    mem_we = `WriteDisable;
                    if (mem_addr_o[1:0] != 0) begin
                        // misaligned
                        misaligned_access = 1;
                    end
                    mem_ce_o = `ChipEnable;
                    data_size_o = 2'b10; // 4
                end

                // store
                `EXE_SB_OP:		begin
                    mem_addr_o = mem_phy_addr;
                    mem_we = `WriteEnable;
                    mem_data_o = {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
                    mem_ce_o = `ChipEnable;
                    data_size_o = 2'b00; // 1
                    inst_store = 1;
                end
                `EXE_SH_OP:		begin
                    mem_addr_o = mem_phy_addr;
                    mem_data_o = {reg2_i[15:0],reg2_i[15:0]};
                    if (mem_addr_o[0] != 0) begin
                        // misaligned
                        mem_we = `WriteDisable;
                        misaligned_access = 1;
                    end else begin
                        mem_we = `WriteEnable;
                    end
                    mem_ce_o = `ChipEnable;
                    data_size_o = 2'b01; // 2
                    inst_store = 1;
                end
                `EXE_SW_OP:		begin
                    mem_addr_o = mem_phy_addr;
                    mem_data_o = reg2_i;
                    if (mem_addr_o[1:0] != 0) begin
                        // misaligned
                        mem_we = `WriteDisable;
                        misaligned_access = 1;
                    end else begin
                        mem_we = `WriteEnable;
                    end
                    mem_ce_o = `ChipEnable;
                    data_size_o = 2'b10; // 4
                    inst_store = 1;
                end
            endcase

            case (saved_aluop)
                // load
                `EXE_LB_OP:		begin
                    case (saved_mem_addr_i[1:0])
                        2'b00:	begin
                            wdata_o = {{24{mem_data_i[7]}},mem_data_i[7:0]};
                        end
                        2'b01:	begin
                            wdata_o = {{24{mem_data_i[15]}},mem_data_i[15:8]};
                        end
                        2'b10:	begin
                            wdata_o = {{24{mem_data_i[23]}},mem_data_i[23:16]};
                        end
                        2'b11:	begin
                            wdata_o = {{24{mem_data_i[31]}},mem_data_i[31:24]};
                        end
                        default:	begin
                            wdata_o = `ZeroWord;
                        end
                    endcase
                end
                `EXE_LBU_OP:		begin
                    case (saved_mem_addr_i[1:0])
                        2'b00:	begin
                            wdata_o = {{24{1'b0}},mem_data_i[7:0]};
                        end
                        2'b01:	begin
                            wdata_o = {{24{1'b0}},mem_data_i[15:8]};
                        end
                        2'b10:	begin
                            wdata_o = {{24{1'b0}},mem_data_i[23:16]};
                        end
                        2'b11:	begin
                            wdata_o = {{24{1'b0}},mem_data_i[31:24]};
                        end
                        default:	begin
                            wdata_o = `ZeroWord;
                        end
                    endcase
                end
                `EXE_LH_OP:		begin
                    case (saved_mem_addr_i[1:0])
                        2'b00:	begin
                            wdata_o = {{16{mem_data_i[15]}},mem_data_i[15:0]};
                        end
                        2'b10:	begin
                            wdata_o = {{16{mem_data_i[31]}},mem_data_i[31:16]};
                        end
                        default:	begin
                            wdata_o = `ZeroWord;
                        end
                    endcase
                end
                `EXE_LHU_OP: begin
                    case (saved_mem_addr_i[1:0])
                        2'b00:	begin
                            wdata_o = {{16{1'b0}},mem_data_i[15:0]};
                        end
                        2'b10:	begin
                            wdata_o = {{16{1'b0}},mem_data_i[31:16]};
                        end
                        default:	begin
                            wdata_o = `ZeroWord;
                        end
                    endcase
                end
                `EXE_LW_OP:	begin
                    wdata_o = mem_data_i;
                end
                default: begin
                end
            endcase
        end
    end

endmodule // mem
