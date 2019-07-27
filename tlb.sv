module tlb(
    input clk,
    input rst,
    input [7:0] asid,

    input [31:0] inst_addr_i,
    output logic [31:0] inst_addr_o,
    output logic inst_uncached,
    output logic inst_miss,
    output logic inst_valid,

    input [31:0] data_addr_i,
    output logic [31:0] data_addr_o,
    output logic data_uncached,
    output logic data_miss,
    output logic data_valid,
    output logic data_dirty,

    input [85+`TLB_WIDTH:0] tlb_config,
    input tlb_wi,

    input tlb_p,
    output [31:0] tlb_p_res_o
);

    logic [85:0] tlb_entries [0:`TLB_ENTRIES-1];

    tlb_lookup tlb_lookup_inst(
        .tlb_entries(tlb_entries),
        .virt_addr(inst_addr_i),
        .asid(asid),
        .phys_addr(inst_addr_o),
        .miss(inst_miss),
        .valid(inst_valid),
        .match_index(), // ignore
        .dirty(), // ignore
        .uncached(inst_uncached)
    );

    tlb_lookup tlb_lookup_data(
        .tlb_entries(tlb_entries),
        .virt_addr(data_addr_i),
        .asid(asid),
        .phys_addr(data_addr_o),
        .miss(data_miss),
        .valid(data_valid),
        .match_index(), // ignore
        .dirty(data_dirty),
        .uncached(data_uncached)
    );

    tlb_lookup tlb_lookup_probe(
        .tlb_entries(tlb_entries),
        .virt_addr({tlb_config[74:56], {13{1'b0}}}),
        .asid(asid),
        .phys_addr(), // ignore
        .miss(tlb_p_res_o[31]),
        .valid(), // ignore
        .match_index(tlb_p_res_o[`TLB_WIDTH-1:0]),
        .dirty(), // ignore
        .uncached() // ignore
    );

    always_ff @ (posedge clk) begin
        if (rst) begin
            for (int i = 0;i < `TLB_ENTRIES;i = i + 1) begin
                tlb_entries[i] <= 80'd0;
            end
        end else begin
            if (tlb_wi) begin
                tlb_entries[tlb_config[`TLB_WIDTH-1:0]][85:0] <= tlb_config[85 + `TLB_WIDTH:`TLB_WIDTH];
            end
        end
    end

endmodule