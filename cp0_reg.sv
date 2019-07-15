`include "define.vh"

module cp0_reg(
    input clk,
    input rst,
    input [5:0] int_i,

    input we_i,
    input [4:0] waddr_i,
    input [4:0] raddr_i,
    input [`RegBus] data_i,

    input [31:0] except_type_i,
    input [`RegBus] pc_i,
    input is_in_delayslot_i,

    output logic [`RegBus] data_o,
    output logic [`RegBus] count_o,
    output logic [`RegBus] compare_o,
    output logic [`RegBus] status_o,
    output logic [`RegBus] cause_o,
    output logic [`RegBus] epc_o,
    output logic [`RegBus] config_o,
    output logic [`RegBus] prid_o,

    output logic timer_int_o
);

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
        end else begin
            count_o <= count_o + 1;
            cause_o[15:10] <= int_i;

            if (compare_o != 0 && count_o == compare_o) begin
                timer_int_o <= 1;
            end

            if (we_i) begin
                case(waddr_i)
                    `CP0_REG_COUNT: begin
                        count_o <= data_i;
                    end
                    `CP0_REG_COMPARE: begin
                        compare_o <= data_i;
                        timer_int_o <= 0;
                    end
                    `CP0_REG_STATUS: begin
                        // IM7..IM0
                        status_o[15:8] <= data_i[15:8];
                        // EXL
                        status_o[1] <= data_i[1];
                        // IE
                        status_o[1] <= data_i[0];
                    end
                    `CP0_REG_EPC: begin
                        epc_o <= data_i;
                    end
                    `CP0_REG_CAUSE: begin
                        // IP[1:2]
                        cause_o[9:8] <= data_i[9:8];
                        // IV
                        cause_o[23] <= data_i[23];
                        // WP
                        cause_o[22] <= data_i[22];
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
                `CP0_REG_COUNT: begin
                    data_o = count_o;
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
            endcase
        end
    end
endmodule