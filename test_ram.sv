`include "define.vh"
module test_ram #(
    parameter delay = 1
) (
    input clk,
    input rst,
    input data_req,
    input data_wr,
    input [1 :0] data_size,
    input [31:0] data_addr,
    input [31:0] data_wdata,
    output logic [31:0] data_rdata,
    output logic data_addr_ok,
    output logic data_data_ok
);

    reg[`InstBus] ram[0:`DataMemNum-1];

    assign data_addr_ok = data_req;

    logic[delay-1:0][31:0] saved_data_rdata;
    logic[delay-1:0] saved_data_data_ok;

    logic[31:0] orig_data_rdata;
    logic orig_data_data_ok;

    logic[31:0] data_write;
    logic[3:0] data_mask;

    always_comb begin
        case (data_size)
            2'b00: begin
                data_mask = 4'b01 << data_addr[1:0];
            end
            2'b01: begin
                data_mask = 4'b11 << data_addr[1:0];
            end
            default: begin
                data_mask = 4'b1111;
            end
        endcase
    end

    always_comb begin
        if (data_wr) begin
            data_write = ram[data_addr[`DataMemNumLog2+1:2]];
            if (data_mask[0]) data_write[7:0] = data_wdata[7:0];
            if (data_mask[1]) data_write[15:8] = data_wdata[15:8];
            if (data_mask[2]) data_write[23:16] = data_wdata[23:16];
            if (data_mask[3]) data_write[31:24] = data_wdata[31:24];
        end else begin
            data_write = 0;
        end
    end

    assign data_rdata = saved_data_rdata[delay-1];
    assign data_data_ok = saved_data_data_ok[delay-1];

    assign orig_data_rdata = (rst | !data_req | data_wr) ? 0 : ram[data_addr[`DataMemNumLog2+1:2]];
    assign orig_data_data_ok = (rst | !data_req) ? 0 : 1;

    always_ff @ (posedge clk) begin
        if (rst) begin
            saved_data_rdata <= 0;
            saved_data_data_ok <= 0;
        end else begin
            if (data_wr && data_req) begin
                ram[data_addr[`DataMemNumLog2+1:2]] <= data_write;
            end
            saved_data_rdata <= {saved_data_rdata, orig_data_rdata};
            saved_data_data_ok <= {saved_data_data_ok, orig_data_data_ok};
        end
    end

endmodule