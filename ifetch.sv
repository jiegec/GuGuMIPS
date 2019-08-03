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

    logic exception_occurred;
    assign exception_occurred = misaligned_access | mmu_except_miss | mmu_except_invalid | mmu_except_user;
    assign except_type_o = {15'b0, mmu_except_invalid, mmu_except_miss, misaligned_access | mmu_except_user, 14'b0};

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

    assign stall = !inst_data_ok || (saved_inst_addr != inst_addr);
    assign pc_valid_o = exception_occurred | ~stall;

    // MMU
    assign mmu_en = 1'b1;
    assign mmu_virt_addr = addr;
    assign inst_addr = mmu_phys_addr;
    assign inst_uncached = mmu_uncached;
    assign inst = (inst_data_ok && (saved_inst_addr == inst_addr)) ? inst_rdata : 0;
    assign inst_req = !rst && (state == 1 || (state == 0)) && !exception_occurred;
    assign pc_o = addr;

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= IDLE;
            saved_inst_addr <= 0;
        end else begin
            unique case (state)
                IDLE: begin
                    if (inst_req) begin
                        if (inst_addr_ok) begin
                            saved_inst_addr <= inst_addr;
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
                        saved_inst_addr <= 0;
                    end else if (inst_addr_ok) begin
                        // >= 2 cycle
                        state <= WAIT_DATA;
                        saved_inst_addr <= inst_addr;
                    end
                end
                WAIT_DATA: begin
                    if (inst_data_ok) begin
                        state <= IDLE;
                        saved_inst_addr <= 0;
                    end
                end
            endcase
        end
    end

endmodule