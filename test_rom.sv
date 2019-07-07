`include "define.vh"
module test_rom(
    input clk,
    input rst,
    input inst_req,
    input inst_wr,
    input [1 :0] inst_size,
    input [31:0] inst_addr,
    input [31:0] inst_wdata,
    output logic [31:0] inst_rdata,
    output logic inst_addr_ok ,
    output logic inst_data_ok
);

    reg[`InstBus] rom[0:`InstMemNum-1];

    assign inst_addr_ok = inst_req;

    always_ff @ (posedge clk) begin
        if (rst) begin
            inst_rdata <= 0;
            inst_data_ok <= 0;
        end else begin
            if (inst_req) begin
                inst_rdata <= rom[inst_addr[`InstMemNumLog2+1:2]];
                inst_data_ok <= 1;
            end else begin
                inst_rdata <= 0;
                inst_data_ok <= 0;
            end
        end
    end

endmodule