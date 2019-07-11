`include "define.vh"
module mem(
    input wire  rst,
    input wire[`RegAddrBus] wd_i,
    input wire wreg_i,
    input wire[`RegBus] wdata_i,

    input wire whilo_i,
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,

    input wire cp0_reg_we_i,
    input wire[4:0] cp0_reg_write_addr_i,
    input wire[`RegBus] cp0_reg_data_i,

    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,

    output reg whilo_o,
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o,

    output logic cp0_reg_we_o,
    output logic[4:0] cp0_reg_write_addr_o,
    output logic[`RegBus] cp0_reg_data_o
);

    always_comb begin
      if (rst == `RstEnable) begin
        wd_o = `NOPRegAddr;
        wreg_o = `WriteDisable;
        wdata_o = `ZeroWord;

        whilo_o = `WriteDisable;
        hi_o = `ZeroWord;
        lo_o = `ZeroWord;

        cp0_reg_we_o = 0;
        cp0_reg_write_addr_o = 0;
        cp0_reg_data_o = 0;
      end else begin
        wd_o = wd_i;
        wreg_o = wreg_i;
        wdata_o = wdata_i;

        whilo_o = whilo_i;
        hi_o = hi_i;
        lo_o = lo_i;

        cp0_reg_we_o = cp0_reg_we_i;
        cp0_reg_write_addr_o = cp0_reg_write_addr_i;
        cp0_reg_data_o = cp0_reg_data_i;
      end
    end

endmodule // mem
