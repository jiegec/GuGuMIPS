`include "define.vh"

module ifetch(
    input clk,
    input rst,
    input en_pc,
    input en_if,
    input flush,

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
    wire exception_occurred;
    assign exception_occurred = |except_type;

    wire time_to_request;
    assign time_to_request = !rst && en_if && ~flush && (state == RESET || state == IDLE || inst_data_ok);
    wire time_begin_request;
    assign time_begin_request = time_to_request & inst_addr_ok;
    wire time_begin_exception;
    assign time_begin_exception = time_to_request & (state == IDLE && exception_occurred);

    assign inst_size = 2'b10; // 4
    assign inst_wr = 0;
    assign inst_wdata = 0;

    enum {
        RESET,
        IDLE,
        REQUEST
    } state;

    // if inst_addr change upon fetching (e.g. long delay with syscall), redo it
    logic [`InstAddrBus] saved_inst_addr;
    logic [`RegBus] saved_inst_rdata;
    logic [`InstAddrBus] last_inst_addr;

    reg saved_flush;
    wire local_flush;
    assign local_flush = flush | saved_flush;

    assign stall = (rst || state != RESET) && ~(time_begin_request || time_begin_exception);
    assign pc_valid_o = ~local_flush & (state != RESET && ~stall);

    // MMU
    assign mmu_en = 1'b1;
    assign mmu_virt_addr = addr;
    assign inst_addr = mmu_phys_addr;
    assign inst_uncached = mmu_uncached;
    assign inst = (pc_valid_o & ~local_flush) ? (inst_data_ok ? inst_rdata : saved_inst_rdata) : 0;
    assign inst_req = time_to_request & ~exception_occurred;

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= RESET;
            saved_inst_rdata <= 0;
            saved_flush <= 0;
            except_type_o <= 0;
            pc_o <= 0;
        end else begin
            if ((inst_req & inst_addr_ok) | (state == IDLE & exception_occurred)) begin
                pc_o <= addr;
            end
            if (flush) begin
                saved_flush <= flush;
            end else if ((inst_req && inst_addr_ok) || exception_occurred) begin
                saved_flush <= 0;
            end
            if (inst_data_ok) begin
                saved_inst_rdata <= inst_rdata;
            end
            if (time_to_request && time_begin_exception) begin
                except_type_o <= except_type;
            end else begin
                except_type_o <= 0;
            end
            unique case (state)
                RESET, IDLE: begin
                    if (time_begin_request) begin
                        state <= REQUEST;
                    end
                end
                REQUEST: begin
                    if (inst_data_ok && ~inst_addr_ok) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule