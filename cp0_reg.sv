`include "define.vh"

module cp0_reg(
    input clk,
    input rst,

    input we_i,
    input [4:0] waddr_i,
    input [4:0] raddr_i,
    input [`RegBus] data_i,
    
    input [5:0] int_i,

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
            data_o <= 0;
            count_o <= 0;
            compare_o <= 0;
            // CU = 4'b0001
            status_o <= 32'b0001_0_0_0_00_0_0_0_0_000_00000000_000_0_0_0_0_0;
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
                        status_o <= data_i;
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
        end
    end

    always_comb begin
        if (rst) begin
            data_o = 0;
        end else begin
            case(raddr_i)
                `CP0_REG_COUNT: begin
                    data_o <= count_o;
                end
                `CP0_REG_COMPARE: begin
                    data_o <= compare_o;
                end
                `CP0_REG_STATUS: begin
                    data_o <= status_o;
                end
                `CP0_REG_CAUSE: begin
                    data_o <= cause_o;
                end
                `CP0_REG_EPC: begin
                    data_o <= epc_o;
                end
                `CP0_REG_PRId: begin
                    data_o <= prid_o;
                end
                `CP0_REG_CONFIG: begin
                    data_o <= config_o;
                end
            endcase
        end
    end
endmodule