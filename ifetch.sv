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
    output logic stall
);

    assign inst_size = 2'b10; // 4
    assign inst_wr = 0;
    assign inst_wdata = 0;

    // 0: idle
    // 1: wait for addr
    // 2: wait for data
    logic [1:0] state;
    logic last_data_ok;
    logic last_inst_req;

    assign stall = !inst_data_ok;
    // TODO: MMU
    assign inst_addr = addr[28:0];
    assign inst = inst_rdata;

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= 0;
            last_data_ok <= 0;
            inst_req <= 0;
            last_inst_req <= 0;
        end else begin
            inst_req <= ((!inst_data_ok & (state == 0)) | en) & !inst_req;
            last_inst_req <= inst_req;
            last_data_ok <= inst_data_ok;
            case (state)
                0: begin
                    state <= 1;
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