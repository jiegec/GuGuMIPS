`include "define.vh"

module ifetch(
    input clk,
    input rst,

    // inst sram-like
    output logic inst_req,
    output logic inst_wr,
    output logic [1 :0] inst_size,
    output logic [31:0] inst_addr,
    output logic [31:0] inst_wdata,
    input [31:0] inst_rdata,
    input inst_addr_ok,
    input inst_data_ok,

    input en,
    input [`RegBus]addr,
    output logic [`RegBus]inst,
    output logic [`RegBus]pc_o,
    output logic stall
);

    assign inst_size = 2'b10; // 4
    assign inst_wr = 0;
    assign inst_wdata = 0;

    // 0: idle
    // 1: wait for addr
    // 2: wait for data
    logic [1:0] state;

    assign stall = !inst_data_ok;
    // TODO: MMU
    assign inst_addr = addr[28:0];
    assign inst = inst_rdata;
    assign inst_req = !rst && (state == 1 || (state == 0));

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= 0;
            //inst_req <= 0;
        end else begin
            if (inst_addr_ok) begin
                pc_o <= addr;
            end
            //inst_req <= ((!inst_data_ok & (state == 0)) | en) & !inst_req;
            case (state)
                0: begin
                    if (inst_req) begin
                        if (inst_addr_ok) begin
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
                    end else if (inst_addr_ok) begin
                        // >= 2 cycle
                        state <= 2;
                    end
                end
                2: begin
                    if (inst_data_ok) begin
                        state <= 0;
                    end
                end
                3: begin
                end
            endcase
        end
    end

endmodule