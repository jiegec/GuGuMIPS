`include "define.vh"

module tlb_lookup (
    input [85:0] tlb_entries [0:`TLB_ENTRIES - 1],

    input [31:0] virt_addr,
    input [7:0] asid,
    output logic [31:0]  phys_addr,
    output logic miss,
    output logic valid,
    output logic [`TLB_WIDTH-1:0] match_index,
    output logic dirty,
    output logic uncached
);

    logic [`TLB_ENTRIES-1:0] matched;
    logic [23:0] pfn;
    logic [2:0] cache_flag;

    // virt_addr[12] muxes 1 or 0
    // PFN1 = [51:28] PFN0 = [25:2]
    assign pfn = virt_addr[12] ? tlb_entries[match_index][51:28] : tlb_entries[match_index][25:2];
    // D1 = [27] D0 = [1]
    assign dirty = virt_addr[12] ? tlb_entries[match_index][27] : tlb_entries[match_index][1];
    // V1 = [26] V0 = [0]
    assign valid = virt_addr[12] ? tlb_entries[match_index][26] : tlb_entries[match_index][0];
    // C1 = [82:80] C0 = [85:83]
    assign cache_flag = virt_addr[12] ? tlb_entries[match_index][82:80] : tlb_entries[match_index][85:83];

    assign uncached = (cache_flag == 3'b10);

    assign phys_addr = {pfn[19:0], virt_addr[11:0]};

    assign miss = (matched == `TLB_ENTRIES'b0);

    generate
        genvar i;
        for (i = 0;i < `TLB_ENTRIES;i = i + 1) begin
            // VPN2 & Mask == VA & ~Mask
            // G or ASID equals
            assign matched[i] = (tlb_entries[i][70:52] == virt_addr[31:13]) && (tlb_entries[i][79:72] == asid || tlb_entries[i][71]);
        end
    endgenerate

    always_comb begin
        match_index = 'b0;
        for (int i = `TLB_ENTRIES - 1;i >= 0;i = i - 1) begin
            if (matched[i])
                match_index = i;
        end
    end

endmodule