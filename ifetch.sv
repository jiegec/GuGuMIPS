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
    output logic [31:0] except_type_o,
    output logic stall
);

    // for instruction load access exception,
    // cp0_badvaddr = cp0_epc = branch_target_address_o
    logic misaligned_access;
    assign misaligned_access = addr[1:0] != 0;
    assign except_type_o = {17'b0, misaligned_access, 14'b0};

    assign inst_size = 2'b10; // 4
    assign inst_wr = 0;
    assign inst_wdata = 0;

    // 0: idle
    // 1: wait for addr
    // 2: wait for data
    logic [1:0] state;

    // if inst_addr change upon fetching (e.g. long delay with syscall), redo it
    logic [`InstAddrBus] saved_inst_addr;

    assign stall = !inst_data_ok || (saved_inst_addr != inst_addr);
    // MMU
    // TODO: MMU Exception Handling
    assign mmu_en = 1'b1;
    assign mmu_virt_addr = addr;
    assign inst_addr = mmu_phys_addr;
    assign inst_uncached = mmu_uncached;
    assign inst = (inst_data_ok && (saved_inst_addr == inst_addr)) ? inst_rdata : 0;
    assign inst_req = !rst && (state == 1 || (state == 0)) && !misaligned_access;
    assign pc_o = addr;

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= 0;
            saved_inst_addr <= 0;
        end else begin
            case (state)
                0: begin
                    if (inst_req) begin
                        if (inst_addr_ok) begin
                            saved_inst_addr <= inst_addr;
                            state <= 2;
                        end else begin
                            state <= 1;
                        end
                    end
                end
                1: begin
                    if (inst_data_ok) begin
                        // 1 cycle
                        state <= 0;
                        saved_inst_addr <= 0;
                    end else if (inst_addr_ok) begin
                        // >= 2 cycle
                        state <= 2;
                    end
                end
                2: begin
                    if (inst_data_ok) begin
                        state <= 0;
                        saved_inst_addr <= 0;
                    end
                end
                3: begin
                    // impossible
                    state <= 0;
                end
            endcase
        end
    end

endmodule