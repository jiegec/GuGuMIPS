`include "define.vh"
module test_rom #(
    parameter delay = 1
) (
    input clk,
    input rst,
    input inst_req,
    input inst_wr,
    input [1 :0] inst_size,
    input [31:0] inst_addr,
    input [31:0] inst_wdata,
    output logic [31:0] inst_rdata,
    output logic inst_addr_ok,
    output logic inst_data_ok
);

    reg[`InstBus] rom[0:`InstMemNum-1];

    assign inst_addr_ok = inst_req;

    logic[delay-1:0][31:0] saved_inst_rdata;
    logic[delay-1:0] saved_inst_data_ok;

    logic[31:0] orig_inst_rdata;
    logic orig_inst_data_ok;

    assign inst_rdata = saved_inst_rdata[delay-1];
    assign inst_data_ok = saved_inst_data_ok[delay-1];

    assign orig_inst_rdata = (rst | !inst_req) ? 0 : rom[inst_addr[`InstMemNumLog2+1:2]];
    assign orig_inst_data_ok = (rst | !inst_req) ? 0 : 1;

    always_ff @ (posedge clk) begin
        if (rst) begin
            saved_inst_rdata <= 0;
            saved_inst_data_ok <= 0;
        end else begin
            saved_inst_rdata <= {saved_inst_rdata, orig_inst_rdata};
            saved_inst_data_ok <= {saved_inst_data_ok, orig_inst_data_ok};
        end
    end

endmodule