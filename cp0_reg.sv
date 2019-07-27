`include "define.vh"

module cp0_reg #(
    ENABLE_TLB = 0
)(
    input wire clk,
    input wire rst,
    input wire [5:0] int_i,

    input wire we_i,
    input wire [4:0] waddr_i,
    input wire [4:0] raddr_i,
    input wire [`RegBus] data_i,

    input wire [31:0] except_type_i,
    input wire [`RegBus] pc_i,
    input wire is_in_delayslot_i,
    input wire [31:0] mem_addr_i, // for misaligned access error

    output reg [`RegBus] data_o,
    output reg [`RegBus] count_o,
    output reg [`RegBus] compare_o,
    output reg [`RegBus] status_o,
    output reg [`RegBus] cause_o,
    output reg [`RegBus] epc_o,
    output reg [`RegBus] config_o,
    output reg [`RegBus] prid_o,
    output reg [`RegBus] badvaddr_o,
    // Reset PC
    output reg [`RegBus] exception_vector_o,
    // TLB
    output reg [`RegBus] index_o,
    output reg [`RegBus] entryhi_o,
    output reg [`RegBus] pagemask_o,
    output reg [`RegBus] entrylo0_o,
    output reg [`RegBus] entrylo1_o,
    output reg [85+`TLB_WIDTH:0] tlb_config_o,

    output reg user_mode,

    output reg timer_int_o
);
    wire status_bev;
    wire [1:0] status_ksu;
    wire status_erl;
    wire status_exl;
    wire cause_iv;

    assign status_bev = status_o[22];
    assign status_ksu = status_o[4:3];
    assign status_erl = status_o[2];
    assign status_exl = status_o[1];
    assign cause_iv = cause_o[23];

    assign tlb_config_o = {
        entrylo0_o[5:3], // C0 85:83
        entrylo1_o[5:3], // C1 82:80
        entryhi_o[7:0], // ASID 79:72
        entrylo1_o[0] & entrylo0_o[0], // G 71
        entryhi_o[31:13], // VPN2 70:52
        entrylo1_o[29:6], // PFN1 51:28
        entrylo1_o[2:1], // D1 V1 27:26
        entrylo0_o[29:6], // PFN0 25:2
        entrylo0_o[2:1], // D0 V0 1:0
        index_o[`TLB_WIDTH-1:0]
    };

    // MIPS Vol3 3.4
    assign user_mode = (status_ksu == 2'b10 && ~status_exl && ~status_erl);

    always_ff @ (posedge clk) begin
        if (rst == `RstEnable) begin
            count_o <= 0;
            compare_o <= 0;
            // CU = 4'b0000, BEV = 1
            status_o <= 32'b0000_0_0_0_00_1_0_0_0_000_00000000_000_0_0_0_0_0;
            cause_o <= 0;
            epc_o <= 0;
            config_o <= 32'b0_000000000000000_0_00_000_000_000_0_000;
            prid_o <= 32'b00000000_00000000_0000000000_000000;
            timer_int_o <= 0;
            badvaddr_o <= 0;
            index_o <= 0;
            entryhi_o <= 0;
            pagemask_o <= 0;
            entrylo0_o <= 0;
            entrylo1_o <= 0;
        end else begin
            count_o <= count_o + 1;
            // IP[7:2] = I[5:0]
            // IP[1:2] left for software
            cause_o[15:10] <= int_i;

            if (compare_o != 0 && count_o == compare_o) begin
                timer_int_o <= 1;
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
                            // only low 26bits writable
                            entrylo0_o[25:0] <= data_i[25:0];
                        end
                    end
                    `CP0_REG_ENTRYLO1: begin
                        if (ENABLE_TLB) begin
                            // only low 26bits writable
                            entrylo1_o[25:0] <= data_i[25:0];
                        end
                    end
                    `CP0_REG_PAGEMASK: begin
                        if (ENABLE_TLB) begin
                            // only support 4k pages now
                            //pagemask_o[24:13] <= data_i[24:13];
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
                        timer_int_o <= 0;
                    end
                    `CP0_REG_STATUS: begin
                        // BEV
                        status_o[22] <= data_i[22];
                        // IM7..IM0
                        status_o[15:8] <= data_i[15:8];
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
                endcase
            end
            case (except_type_i)
                32'h00000001: begin
                    // interrupt
                    if (is_in_delayslot_i) begin
                        epc_o <= pc_i - 4;
                        cause_o[31] <= 1'b1;
                    end else begin
                        epc_o <= pc_i;
                        cause_o[31] <= 1'b0;
                    end
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 0
                    cause_o[6:2] <= 5'b00000;
                end
                32'h00000004: begin
                    // memory address error load
                    // EXL = 0
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 4
                    cause_o[6:2] <= 5'h04;
                    // BadVAddr
                    badvaddr_o <= mem_addr_i;
                end
                32'h0000000f: begin
                    // instruction address error load
                    // EXL = 0
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 4
                    cause_o[6:2] <= 5'h04;
                    // BadVAddr
                    badvaddr_o <= pc_i;
                    // EPC
                    epc_o <= pc_i;
                end
                32'h00000005: begin
                    // memory address error store
                    // EXL = 0
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 5
                    cause_o[6:2] <= 5'h05;
                    // BadVAddr
                    badvaddr_o <= mem_addr_i;
                end
                32'h00000008: begin
                    // syscall
                    // EXL = 0
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 8
                    cause_o[6:2] <= 5'h08;
                end
                32'h00000009: begin
                    // break
                    // EXL = 0
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 9
                    cause_o[6:2] <= 5'h09;
                end
                32'h0000000a: begin
                    // inst invalid
                    // EXL = 0
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 10
                    cause_o[6:2] <= 5'b01010;
                end
                32'h0000000d: begin
                    // trap
                    // EXL = 0
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 11
                    cause_o[6:2] <= 5'b01011;
                end
                32'h0000000c: begin
                    // overflow
                    // EXL = 0
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    // EXL = 1
                    status_o[1] <= 1'b1;
                    // ExcCode = 11
                    cause_o[6:2] <= 5'b01100;
                end
                32'h0000000e: begin
                    // eret
                    // EXL = 0
                    status_o[1] <= 1'b0;
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
            case(raddr_i)
                `CP0_REG_INDEX: begin
                    data_o = index_o;
                end
                `CP0_REG_ENTRYLO0: begin
                    data_o = entrylo0_o;
                end
                `CP0_REG_ENTRYLO1: begin
                    data_o = entrylo1_o;
                end
                `CP0_REG_PAGEMASK: begin
                    data_o = pagemask_o;
                end
                `CP0_REG_BADVADDR: begin
                    data_o = badvaddr_o;
                end
                `CP0_REG_COUNT: begin
                    data_o = count_o;
                end
                `CP0_REG_ENTRYHI: begin
                    data_o = entryhi_o;
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
                `CP0_REG_CONFIG: begin
                    data_o = config_o;
                end
                default: begin
                    data_o = 0;
                end
            endcase
        end
    end

    // MIPS32 Volume 3 Table 5-4 Exception Vectors
    always_comb begin
        exception_vector_o = status_bev ? 32'hbfc00380 : 32'h80000180;
        case (except_type_i)
            32'h00000001: begin
                // interrupt
                if (status_bev && cause_iv) begin
                    exception_vector_o = 32'hbfc00400;
                end else if (status_bev && !cause_iv) begin
                    exception_vector_o = 32'hbfc00380;
                end else if (!status_bev && cause_iv) begin
                    exception_vector_o = 32'h80000200;
                end else if (!status_bev && !cause_iv) begin
                    exception_vector_o = 32'h80000180;
                end
            end
            32'h00000000e: begin
                // eret
                exception_vector_o = epc_o;
            end
        endcase
    end
endmodule