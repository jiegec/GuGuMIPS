`include "define.vh"

module mmu #(
    ENABLE_TLB = 0
)(
    input logic clk,
    input logic rst,

    input logic user_mode,
    input logic kseg0_uncached,
    input [7:0] asid,

    input logic [31:0] inst_addr_i,
    input logic inst_en,
    output logic [31:0] inst_addr_o,
    output logic inst_uncached,
    output logic inst_except_miss,
    output logic inst_except_invalid,
    output logic inst_except_user,

    input logic [31:0] data_addr_i,
    input logic data_en,
    output logic [31:0] data_addr_o,
    output logic data_uncached,
    output logic data_except_miss,
    output logic data_except_invalid,
    output logic data_except_user,
    output logic data_except_dirty,

    // TLBWR/TLBWI
    input logic [85:0] tlb_config,
    input logic [`TLB_WIDTH-1:0] tlb_we_index,
    input tlb_we,

    // TLBP
    input tlb_p,
    output logic [31:0] tlb_p_res_o,

    // TLBR
    input [`TLB_WIDTH-1:0] tlb_read_index,
    output [85:0] tlb_read_config_o
);

    logic [31:0] inst_addr_mmap;
    logic [31:0] inst_addr_tlb;
    logic inst_uncached_mmap;
    logic inst_uncached_tlb;
    logic inst_miss_tlb;
    logic inst_valid_tlb;
    logic inst_use_tlb;

    assign inst_except_miss = inst_use_tlb & inst_miss_tlb;
    assign inst_except_invalid = inst_use_tlb & ~inst_valid_tlb;
    assign inst_uncached = inst_use_tlb ? inst_uncached_tlb : inst_uncached_mmap;
    assign inst_addr_o = inst_use_tlb ? inst_addr_tlb : inst_addr_mmap;

    memory_map #(
        .ENABLE_TLB(ENABLE_TLB)
    ) memory_map_inst (
        .addr_i(inst_addr_i),
        .en(inst_en),
        .user_mode(user_mode),
        .kseg0_uncached(kseg0_uncached),
        .addr_o(inst_addr_mmap),
        .except_user(inst_except_user),
        .use_tlb(inst_use_tlb),
        .uncached(inst_uncached_mmap)
    );

    logic [31:0] data_addr_mmap;
    logic [31:0] data_addr_tlb;
    logic data_uncached_mmap;
    logic data_uncached_tlb;
    logic data_miss_tlb;
    logic data_valid_tlb;
    logic data_dirty_tlb;
    logic data_use_tlb;

    assign data_except_miss = data_use_tlb & data_miss_tlb;
    assign data_except_invalid = data_use_tlb & ~data_valid_tlb;
    assign data_except_dirty = data_use_tlb & data_dirty_tlb;
    assign data_uncached = data_use_tlb ? data_uncached_tlb : data_uncached_mmap;
    assign data_addr_o = data_use_tlb ? data_addr_tlb : data_addr_mmap;

    memory_map #(
        .ENABLE_TLB(ENABLE_TLB)
    ) memory_map_data (
        .addr_i(data_addr_i),
        .en(data_en),
        .user_mode(user_mode),
        .kseg0_uncached(kseg0_uncached),
        .addr_o(data_addr_mmap),
        .except_user(data_except_user),
        .use_tlb(data_use_tlb),
        .uncached(data_uncached_mmap)
    );

    generate
        if (ENABLE_TLB) begin
            tlb tlb_inst (
                .clk(clk),
                .rst(rst),

                .inst_addr_i(inst_addr_i),
                .inst_addr_o(inst_addr_tlb),
                .inst_uncached(inst_uncached_tlb),
                .inst_miss(inst_miss_tlb),
                .inst_valid(inst_valid_tlb),

                .data_addr_i(data_addr_i),
                .data_addr_o(data_addr_tlb),
                .data_uncached(data_uncached_tlb),
                .data_miss(data_miss_tlb),
                .data_valid(data_valid_tlb),
                .data_dirty(data_dirty_tlb),

                .tlb_config(tlb_config),
                .tlb_config_index(tlb_we_index),
                .tlb_we(tlb_we),

                .tlb_p(tlb_p),
                .tlb_p_res_o(tlb_p_res_o),

                .tlb_read_index(tlb_read_index),
                .tlb_read_config_o(tlb_read_config_o),

                .asid(asid)
            );
        end
    endgenerate

endmodule
