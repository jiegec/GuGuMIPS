`include "define.vh"

module cp0_reg #(
    ENABLE_TLB = 0
)(
    input wire clk,
    input wire rst,
    input wire [5:0] int_i,

    input wire we_i,
    input wire [`CP0RegAddrBus] waddr_i,
    input wire [`CP0RegAddrBus] raddr_i,
    input wire [`RegBus] data_i,

    input wire [`ExceptTypeBus] except_type_i,
    input wire [`RegBus] pc_i,
    input wire is_in_delayslot_i,
    input wire [`InstAddrBus] mem_addr_i, // for misaligned access error

    output reg [`RegBus] data_o,
    output reg [`RegBus] count_o,
    output reg [`RegBus] compare_o,
    output reg [`RegBus] status_o,
    output reg [`RegBus] cause_o,
    output reg [`RegBus] epc_o,
    output reg [`RegBus] config_o,
    output reg [`RegBus] config1_o,
    output reg [`RegBus] prid_o,
    output reg [`RegBus] badvaddr_o,
    output reg [`RegBus] ebase_o,
    // Reset PC
    output reg [`RegBus] exception_vector_o,
    // TLB
    output reg [`RegBus] index_o,
    output reg [`RegBus] random_o,
    output reg [`RegBus] entryhi_o,
    output reg [`RegBus] pagemask_o,
    output reg [`RegBus] entrylo0_o,
    output reg [`RegBus] entrylo1_o,
    output reg [`RegBus] wired_o,
    output reg [`RegBus] context_o,

    // TLBWR/TLBWI
    input wire tlb_wr,
    output logic [`TLB_WIDTH-1:0] tlb_config_index_o,
    output logic [`TLBConfigBus] tlb_config_o,

    // TLBP
    input wire tlb_p,
    input wire [`RegBus] tlb_p_res,

    // TLBR
    input wire tlb_r,
    input wire [`TLBConfigBus] tlb_config_i,

    output reg user_mode,

    output wire timer_int_o
);
    wire status_bev;
    wire [1:0] status_ksu;
    wire status_erl;
    wire status_exl;
    wire cause_ti;
    wire cause_iv;

    assign status_bev = status_o[22];
    assign status_ksu = status_o[4:3];
    assign status_erl = status_o[2];
    assign status_exl = status_o[1];
    assign cause_ti = cause_o[30];
    assign cause_iv = cause_o[23];

    assign timer_int_o = cause_ti;

    assign tlb_config_o = {
        entrylo0_o[5:3], // C0 85:83
        entrylo1_o[5:3], // C1 82:80
        entryhi_o[7:0], // ASID 79:72
        entrylo1_o[0] & entrylo0_o[0], // G 71
        entryhi_o[31:13], // VPN2 70:52
        entrylo1_o[29:6], // PFN1 51:28
        entrylo1_o[2:1], // D1 V1 27:26
        entrylo0_o[29:6], // PFN0 25:2
        entrylo0_o[2:1] // D0 V0 1:0
    };

    assign tlb_config_index_o = tlb_wr ? random_o : index_o;

    // MIPS Vol3 3.4
    assign user_mode = (status_ksu == 2'b10 && ~status_exl && ~status_erl);

    logic [5:0] mmu_size;
    assign mmu_size = `TLB_ENTRIES - 1;

    logic count_add;

    always_ff @ (posedge clk) begin
        if (rst == `RstEnable) begin
            count_o <= 0;
            count_add <= 0;
            compare_o <= 0;
            // CU = 4'b0001, BEV = 1, ERL = 1
            status_o <= 32'b0001_0_0_0_00_1_0_0_0_000_00000000_000_0_0_1_0_0;
            cause_o <= 0;
            epc_o <= 0;
            // Has Config1
            // TLB based MMU
            // kseg0 cached
            config_o <= 32'b1_000_000_000000000_0_00_000_001_000_0_011;
            // No Config2
            // 4way 16bytes 64K cache for both I/D cache
            config1_o <= {1'b0, mmu_size, 3'd4, 3'd3, 3'd3, 3'd4, 3'd3, 3'd3, 7'b0};
            // MIPS32 4Kc
            prid_o <= 32'b00000000_00000001_10000000_00000000;
            badvaddr_o <= 0;
            index_o <= 0;
            entryhi_o <= 0;
            pagemask_o <= 0;
            entrylo0_o <= 0;
            entrylo1_o <= 0;
            random_o <= {`TLB_WIDTH{1'b1}};
            wired_o <= 0;
            context_o <= 0;
            // CPUNum = 0
            ebase_o <= 32'b10_000000000000000000_00_0000000000;
        end else begin
            count_add <= ~count_add;
            count_o <= count_o + count_add;
            // IP[7:2] = I[5:0]
            // IP[1:2] left for software
            cause_o[15:10] <= int_i;

            if (compare_o != 0 && count_o == compare_o) begin
                cause_o[30] <= 1;
            end

            if (ENABLE_TLB) begin
                if (random_o != wired_o) begin
                    random_o[`TLB_WIDTH-1:0] <= random_o[`TLB_WIDTH-1:0] - 1;
                end else begin
                    random_o <= {`TLB_WIDTH{1'b1}};
                end

                if (tlb_p) begin
                    index_o <= tlb_p_res;
                end else if (tlb_r) begin
                    entryhi_o <= {tlb_config_i[70:52], 5'b0, tlb_config_i[79:72]};
                    entrylo0_o <= {2'b0, tlb_config_i[25:2], tlb_config_i[85:83], tlb_config_i[1:0], tlb_config_i[71]};
                    entrylo1_o <= {2'b0, tlb_config_i[51:28], tlb_config_i[82:80], tlb_config_i[27:26], tlb_config_i[71]};
                end
            end

            if (we_i) begin
                case(waddr_i)
                    `CP0_REG_INDEX: begin
                        if (ENABLE_TLB) begin
                            // only low TLB_WIDTH bits are writable
                            index_o[`TLB_WIDTH-1:0] <= data_i[`TLB_WIDTH-1:0];
                        end
                    end
                    `CP0_REG_ENTRYLO0: begin
                        if (ENABLE_TLB) begin
                            // only low 30bits writable
                            entrylo0_o[29:0] <= data_i[29:0];
                        end
                    end
                    `CP0_REG_ENTRYLO1: begin
                        if (ENABLE_TLB) begin
                            // only low 30bits writable
                            entrylo1_o[29:0] <= data_i[29:0];
                        end
                    end
                    `CP0_REG_CONTEXT: begin
                        if (ENABLE_TLB) begin
                            // PTEBase
                            context_o[31:23] <= data_i[31:23];
                        end
                    end
                    `CP0_REG_PAGEMASK: begin
                        if (ENABLE_TLB) begin
                            // only support 4k pages now
                            //pagemask_o[24:13] <= data_i[24:13];
                        end
                    end
                    `CP0_REG_WIRED: begin
                        if (ENABLE_TLB) begin
                            random_o <= {`TLB_WIDTH{1'b1}};
                            wired_o[`TLB_WIDTH-1:0] <= data_i[`TLB_WIDTH-1:0];
                        end
                    end
                    `CP0_REG_COUNT: begin
                        count_o <= data_i;
                    end
                    `CP0_REG_ENTRYHI: begin
                        // vpn2
                        entryhi_o[31:13] <= data_i[31:13];
                        // asid
                        entryhi_o[7:0] <= data_i[7:0];
                    end
                    `CP0_REG_COMPARE: begin
                        compare_o <= data_i;
                        cause_o[30] <= 0;
                    end
                    `CP0_REG_STATUS: begin
                        // CU0
                        status_o[28] <= data_i[28];
                        // BEV
                        status_o[22] <= data_i[22];
                        // IM7..IM0
                        status_o[15:8] <= data_i[15:8];
                        // UM
                        status_o[4] <= data_i[4];
                        // ERL
                        status_o[2] <= data_i[2];
                        // EXL
                        status_o[1] <= data_i[1];
                        // IE
                        status_o[0] <= data_i[0];
                    end
                    `CP0_REG_CAUSE: begin
                        // IP[1:2]
                        cause_o[9:8] <= data_i[9:8];
                        // IV
                        cause_o[23] <= data_i[23];
                        // WP
                        cause_o[22] <= data_i[22];
                    end
                    `CP0_REG_EPC: begin
                        epc_o <= data_i;
                    end
                    `CP0_REG_EBASE: begin
                        // exception base
                        ebase_o[29:12] <= data_i[29:12];
                    end
                    `CP0_REG_CONFIG: begin
                        // kseg0 cache attribute
                        config_o[2:0] <= data_i[2:0];
                    end
                endcase
            end

            if (|except_type_i & except_type_i != 32'h0000000e) begin
                // exception occurred
                // EXL = 0
                if (~status_exl) begin
                    if (is_in_delayslot_i) begin
                        epc_o <= pc_i - 4;
                        cause_o[31] <= 1'b1;
                    end else begin
                        epc_o <= pc_i;
                        cause_o[31] <= 1'b0;
                    end
                end
            end

            case (except_type_i)
                32'h00000001: begin
                    // interrupt
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 0
                    cause_o[6:2] <= 5'h00;
                end
                32'h00000002, 32'h00000003: begin
                    // tlb refill(2)/invalid(3) on instruction fetch
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 2
                    cause_o[6:2] <= 5'h02;
                    // BadVAddr
                    badvaddr_o <= pc_i;
                    // EntryHi VPN2
                    entryhi_o[31:13] <= pc_i[31:13];
                    // Context BadVPN2
                    context_o[22:4] <= pc_i[31:13];
                end
                32'h00000004: begin
                    // memory address error load
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 4
                    cause_o[6:2] <= 5'h04;
                    // BadVAddr
                    badvaddr_o <= mem_addr_i;
                end
                32'h00000005: begin
                    // memory address error store
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 5
                    cause_o[6:2] <= 5'h05;
                    // BadVAddr
                    badvaddr_o <= mem_addr_i;
                end
                32'h00000008: begin
                    // syscall
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 8
                    cause_o[6:2] <= 5'h08;
                end
                32'h00000009: begin
                    // break
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 9
                    cause_o[6:2] <= 5'h09;
                end
                32'h0000000a: begin
                    // inst invalid
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 10
                    cause_o[6:2] <= 5'h0a;
                end
                32'h0000000d: begin
                    // trap
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 13
                    cause_o[6:2] <= 5'h0d;
                end
                32'h0000000c: begin
                    // overflow
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 12
                    cause_o[6:2] <= 5'h0c;
                end
                32'h0000000e: begin
                    // eret
                    // EXL = 0
                    status_o[1] <= 1'b0;
                end
                32'h0000000f: begin
                    // instruction address error load
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 4
                    cause_o[6:2] <= 5'h04;
                    // BadVAddr
                    badvaddr_o <= pc_i;
                end
                32'h00000010, 32'h00000011: begin
                    // tlb refill(0x10)/invalid(0x11) on data load
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 2
                    cause_o[6:2] <= 5'h02;
                    // BadVAddr
                    badvaddr_o <= mem_addr_i;
                    // EntryHi VPN2
                    entryhi_o[31:13] <= mem_addr_i[31:13];
                    // Context BadVPN2
                    context_o[22:4] <= mem_addr_i[31:13];
                end
                32'h00000012, 32'h00000013: begin
                    // tlb refill(0x12)/invalid(0x13) on data store
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 3
                    cause_o[6:2] <= 5'h03;
                    // BadVAddr
                    badvaddr_o <= mem_addr_i;
                    // EntryHi VPN2
                    entryhi_o[31:13] <= mem_addr_i[31:13];
                    // Context BadVPN2
                    context_o[22:4] <= mem_addr_i[31:13];
                end
                32'h00000014: begin
                    // tlb modified on data store
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 1
                    cause_o[6:2] <= 5'h01;
                    // BadVAddr
                    badvaddr_o <= mem_addr_i;
                    // EntryHi VPN2
                    entryhi_o[31:13] <= mem_addr_i[31:13];
                    // Context BadVPN2
                    context_o[22:4] <= mem_addr_i[31:13];
                end
                default: begin
                end
            endcase
        end
    end

    always_comb begin
        if (rst) begin
            data_o = 0;
        end else begin
            data_o = 0;
            case(raddr_i)
                `CP0_REG_INDEX: begin
                    if (ENABLE_TLB) begin
                        data_o = index_o;
                    end
                end
                `CP0_REG_ENTRYLO0: begin
                    if (ENABLE_TLB) begin
                        data_o = entrylo0_o;
                    end
                end
                `CP0_REG_ENTRYLO1: begin
                    if (ENABLE_TLB) begin
                        data_o = entrylo1_o;
                    end
                end
                `CP0_REG_CONTEXT: begin
                    if (ENABLE_TLB) begin
                        data_o = context_o;
                    end
                end
                `CP0_REG_PAGEMASK: begin
                    if (ENABLE_TLB) begin
                        data_o = pagemask_o;
                    end
                end
                `CP0_REG_WIRED: begin
                    if (ENABLE_TLB) begin
                        data_o = wired_o;
                    end
                end
                `CP0_REG_BADVADDR: begin
                    data_o = badvaddr_o;
                end
                `CP0_REG_COUNT: begin
                    data_o = count_o;
                end
                `CP0_REG_ENTRYHI: begin
                    if (ENABLE_TLB) begin
                        data_o = entryhi_o;
                    end
                end
                `CP0_REG_COMPARE: begin
                    data_o = compare_o;
                end
                `CP0_REG_STATUS: begin
                    data_o = status_o;
                end
                `CP0_REG_CAUSE: begin
                    data_o = cause_o;
                end
                `CP0_REG_EPC: begin
                    data_o = epc_o;
                end
                `CP0_REG_PRId: begin
                    data_o = prid_o;
                end
                `CP0_REG_EBASE: begin
                    data_o = ebase_o;
                end
                `CP0_REG_CONFIG: begin
                    data_o = config_o;
                end
                `CP0_REG_CONFIG1: begin
                    data_o = config1_o;
                end
            endcase
        end
    end

    logic [31:0] exception_vector_base;
    logic [31:0] exception_vector_offset;

    // MIPS32 Volume 3 R0.95 Table 5-4 Exception Vectors
    always_comb begin
        exception_vector_base = status_bev ? 32'hbfc00200 : {ebase_o[31:12], 12'b0};
        exception_vector_offset = 32'h00000180;
        case (except_type_i)
            32'h00000001: begin
                // TODO: IntCtl
                if (cause_iv) begin
                    exception_vector_offset = 32'h00000200;
                end
            end
            32'h00000002, 32'h00000010, 32'h00000012: begin
                // TLB Refill
                if (~status_exl) begin
                    exception_vector_offset = 32'h00000000;
                end
            end
        endcase
        exception_vector_o = exception_vector_base + exception_vector_offset;
        if (except_type_i == 32'h0000000e) begin
            // eret
            exception_vector_o = epc_o;
        end
    end
endmodule