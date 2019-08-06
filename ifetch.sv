`include "define.vh"

module ifetch(
    input clk,
    input rst,
    input en,

    // inst sram-like
    output logic inst_req,
    output logic inst_wr,
    output logic [1 :0] inst_size,
    output logic [31:0] inst_addr,
    output logic [31:0] inst_wdata,
    input [31:0] inst_rdata,
    input inst_addr_ok,
    input inst_data_ok,
    output inst_uncached,

    // mmu
    output [31:0] mmu_virt_addr,
    output mmu_en,
    input [31:0] mmu_phys_addr,
    input mmu_uncached,
    input mmu_except_miss,
    input mmu_except_invalid,
    input mmu_except_user,

    input [`RegBus]addr,
    output logic [`RegBus]inst,
    output logic [`RegBus]pc_o,
    output logic pc_valid_o,
    output logic [31:0] except_type_o,
    output logic stall
);

    // for instruction load access exception,
    // cp0_badvaddr = cp0_epc = branch_target_address_o
    logic misaligned_access;
    assign misaligned_access = addr[1:0] != 0;

    wire [31:0] except_type;
    assign except_type = {15'b0, mmu_except_invalid, mmu_except_miss, misaligned_access | mmu_except_user, 14'b0};
    logic exception_occurred;
    assign exception_occurred = |except_type;

    assign inst_size = 2'b10; // 4
    assign inst_wr = 0;
    assign inst_wdata = 0;

    enum {
        IDLE,
        WAIT_ADDR,
        WAIT_DATA
    } state;

    // if inst_addr change upon fetching (e.g. long delay with syscall), redo it
    logic [`InstAddrBus] saved_inst_addr;
    logic [`RegBus] saved_inst_rdata;
    logic [`InstAddrBus] last_inst_addr;

    assign stall = rst ? 1'b1 : ((!inst_data_ok || state == WAIT_ADDR) && state != IDLE);
    assign pc_valid_o = exception_occurred | ~stall;

    // MMU
    assign mmu_en = 1'b1;
    assign mmu_virt_addr = addr;
    assign inst_addr = mmu_phys_addr;
    assign inst_uncached = mmu_uncached;
    assign inst = inst_data_ok ? inst_rdata : saved_inst_rdata;
    assign inst_req = !rst && en && (state == WAIT_ADDR || state == IDLE || inst_data_ok) && !exception_occurred;

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= IDLE;
            saved_inst_rdata <= 0;
            except_type_o <= 0;
        end else begin
            if ((inst_req && inst_addr_ok) || exception_occurred) begin
                pc_o <= addr;
            end
            if (inst_data_ok) begin
                saved_inst_rdata <= inst_rdata;
            end
            except_type_o <= except_type;
            unique case (state)
                IDLE: begin
                    if (inst_req) begin
                        if (inst_addr_ok) begin
                            //saved_inst_addr <= inst_addr;
                            state <= WAIT_DATA;
                        end else begin
                            state <= WAIT_ADDR;
                        end
                    end
                end
                WAIT_ADDR: begin
                    if (inst_data_ok) begin
                        // 1 cycle
                        state <= IDLE;
                        //saved_inst_addr <= 0;
                    end else if (inst_addr_ok) begin
                        // >= 2 cycle
                        state <= WAIT_DATA;
                        //saved_inst_addr <= inst_addr;
                    end
                end
                WAIT_DATA: begin
                    if (inst_data_ok & ~inst_addr_ok) begin
                        state <= IDLE;
                        //saved_inst_addr <= 0;
                    end
                end
            endcase
        end
    end

endmodule