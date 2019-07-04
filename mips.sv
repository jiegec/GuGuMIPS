`include "define.vh"
module mips(
    input clk,
    input rst,

    // inst sram-like 
    output         inst_req     ,
    output         inst_wr      ,
    output  [1 :0] inst_size    ,
    output  [31:0] inst_addr    ,
    output  [31:0] inst_wdata   ,
    input [31:0] inst_rdata   ,
    input        inst_addr_ok ,
    input        inst_data_ok ,
    
    // data sram-like 
    output         data_req     ,
    output         data_wr      ,
    output  [1 :0] data_size    ,
    output  [31:0] data_addr    ,
    output  [31:0] data_wdata   ,
    input [31:0] data_rdata   ,
    input        data_addr_ok ,
    input        data_data_ok,

    // debug
    output [31:0] debug_wb_pc,
    output [3 :0] debug_wb_rf_wen,
    output [4 :0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

    wire[`InstAddrBus] pc;
    wire rom_ce;

    wire[`InstAddrBus] rom_data;
    wire[`InstAddrBus] id_pc_i;
    wire[`InstAddrBus] ex_pc;
    wire[`InstAddrBus] mem_pc;
    wire[`InstAddrBus] wb_pc;
    wire[`InstBus] id_inst_i;

    wire[`AluOpBus] id_aluop_o;
    wire[`AluSelBus] id_alusel_o;
    wire[`RegBus] id_reg1_o;
    wire[`RegBus] id_reg2_o;
    wire id_wreg_o;
    wire[`RegAddrBus] id_wd_o;

    wire[`AluOpBus] ex_aluop_i;
    wire[`AluSelBus] ex_alusel_i;
    wire[`RegBus] ex_reg1_i;
    wire[`RegBus] ex_reg2_i;
    wire ex_wreg_i;
    wire[`RegAddrBus] ex_wd_i;
    wire[`RegBus] ex_hi_i;
    wire[`RegBus] ex_lo_i;

    wire ex_wreg_o;
    wire[`RegAddrBus] ex_wd_o;
    wire[`RegBus] ex_wdata_o;
    wire ex_whilo_o;
    wire[`RegBus] ex_hi_o;
    wire[`RegBus] ex_lo_o;

    wire mem_wreg_i;
    wire[`RegAddrBus] mem_wd_i;
    wire[`RegBus] mem_wdata_i;
    wire mem_whilo_i;
    wire[`RegBus] mem_hi_i;
    wire[`RegBus] mem_lo_i;

    wire mem_wreg_o;
    wire[`RegAddrBus] mem_wd_o;
    wire[`RegBus] mem_wdata_o;
    wire mem_whilo_o;
    wire[`RegBus] mem_hi_o;
    wire[`RegBus] mem_lo_o;

    wire wb_wreg_i;
    wire[`RegAddrBus] wb_wd_i;
    wire[`RegBus] wb_wdata_i;
    wire wb_whilo_i;
    wire[`RegBus] wb_hi_i;
    wire[`RegBus] wb_lo_i;

    assign debug_wb_pc = wb_pc;
    assign debug_wb_rf_wen = wb_wreg_i;
    assign debug_wb_rf_wnum = wb_wd_i;
    assign debug_wb_rf_wdata = wb_wdata_i;

    wire reg1_read; // read reg1 or not
    wire reg2_read;
    wire[`RegBus] reg1_data; // the data of reg1
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr; // the index or reg1
    wire[`RegAddrBus] reg2_addr;

    logic en_pc;
    logic en_if_id;
    logic en_id_ex;
    logic en_ex_mm;
    logic en_mm_wb;

    logic if_stall;

    always_comb begin
        if (if_stall) begin
            {en_pc, en_if_id, en_id_ex, en_ex_mm, en_mm_wb} = 5'b00011;
        end else begin
            {en_pc, en_if_id, en_id_ex, en_ex_mm, en_mm_wb} = 5'b11111;
        end
    end

    pc_reg pc_reg0(.clk(clk), .rst(rst),
                    .pc(pc), .ce(rom_ce), .en(en_pc));

    ifetch if0(.clk(clk), .rst(rst), .en(en_pc),
        .addr(pc), .inst(rom_data), .stall(if_stall),
        .inst_req(inst_req), .inst_wr(inst_wr), .inst_size(inst_size),
        .inst_addr(inst_addr), .inst_wdata(inst_wdata), .inst_rdata(inst_rdata), .inst_addr_ok(inst_addr_ok), .inst_data_ok(inst_data_ok));

    assign data_req = 0;

    if_id if_id0(.clk(clk), .rst(rst), .if_pc(pc), .if_inst(rom_data),
                 .id_pc(id_pc_i), .id_inst(id_inst_i));

    id id0(.rst(rst), .pc_i(id_pc_i), .inst_i(id_inst_i),
            .reg1_data_i(reg1_data), .reg2_data_i(reg2_data),
            .reg1_read_o(reg1_read), .reg2_read_o(reg2_read),
            .reg1_addr_o(reg1_addr), .reg2_addr_o(reg2_addr),
            .aluop_o(id_aluop_o), .alusel_o(id_alusel_o),
            .reg1_o(id_reg1_o), .reg2_o(id_reg2_o),
            .wd_o(id_wd_o), .wreg_o(id_wreg_o),
            .ex_wd_i(ex_wd_o), .ex_wreg_i(ex_wreg_o), .ex_wdata_i(ex_wdata_o),
            .mem_wd_i(mem_wd_o), .mem_wreg_i(mem_wreg_o), .mem_wdata_i(mem_wdata_o));

    regfile regfile0(.clk(clk), .rst(rst),
                    .we(wb_wreg_i), .waddr(wb_wd_i),
                    .wdata(wb_wdata_i), .re1(reg1_read),
                    .raddr1(reg1_addr), .rdata1(reg1_data),
                    .re2(reg2_read), .raddr2(reg2_addr),
                    .rdata2(reg2_data));

    id_ex id_ex0(.clk(clk), .rst(rst), .en(id_ex),
                .id_aluop(id_aluop_o), .id_alusel(id_alusel_o), .id_reg1(id_reg1_o), .id_reg2(id_reg2_o), .id_wd(id_wd_o), .id_wreg(id_wreg_o), .id_pc(id_pc_i),
                .ex_aluop(ex_aluop_i), .ex_alusel(ex_alusel_i), .ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i), .ex_wd(ex_wd_i), .ex_wreg(ex_wreg_i), .ex_pc(ex_pc)
    );

    ex ex0(.rst(rst), .aluop_i(ex_aluop_i), .alusel_i(ex_alusel_i), .reg1_i(ex_reg1_i), .reg2_i(ex_reg2_i), .wd_i(ex_wd_i), .wreg_i(ex_wreg_i),
           .wd_o(ex_wd_o), .wreg_o(ex_wreg_o), .wdata_o(ex_wdata_o),
           .hi_i(ex_hi_i), .lo_i(ex_lo_i), .whilo_o(ex_whilo_o), .hi_o(ex_hi_o), .lo_o(ex_lo_o),
           .mem_whilo_i(mem_whilo_i), .mem_hi_i(mem_hi_i), .mem_lo_i(mem_lo_i),
           .wb_whilo_i(wb_whilo_i), .wb_hi_i(wb_hi_i), .wb_lo_i(wb_lo_i));

    ex_mem ex_mem0(.clk(clk), .rst(rst), .en(en_ex_mm), .ex_wd(ex_wd_o), .ex_wreg(ex_wreg_o), .ex_wdata(ex_wdata_o), .ex_pc(ex_pc),
                   .mem_wd(mem_wd_i), .mem_wreg(mem_wreg_i), .mem_wdata(mem_wdata_i), .mem_pc(mem_pc),
                   .ex_whilo(ex_whilo_o), .ex_hi(ex_hi_o), .ex_lo(ex_lo_o),
                   .mem_whilo(mem_whilo_i), .mem_hi(mem_hi_i), .mem_lo(mem_lo_i));

    mem mem0(.rst(rst),
             .wd_i(mem_wd_i), .wreg_i(mem_wreg_i), .wdata_i(mem_wdata_i),
             .wd_o(mem_wd_o), .wreg_o(mem_wreg_o), .wdata_o(mem_wdata_o),
             .whilo_i(mem_whilo_i), .hi_i(mem_hi_i), .lo_i(mem_lo_i),
             .whilo_o(mem_whilo_o), .hi_o(mem_hi_o), .lo_o(mem_lo_o));
            
    mem_wb mem_wb0(.clk(clk), .rst(rst), .en(en_mm_wb),
                   .mem_wd(mem_wd_o), .mem_wreg(mem_wreg_o), .mem_wdata(mem_wdata_o), .mem_pc(mem_pc),
                   .wb_wd(wb_wd_i), .wb_wreg(wb_wreg_i), .wb_wdata(wb_wdata_i), .wb_pc(wb_pc),
                   .mem_whilo(mem_whilo_o), .mem_hi(mem_hi_o), .mem_lo(mem_lo_o),
                   .wb_whilo(wb_whilo_i), .wb_hi(wb_hi_i), .wb_lo(wb_lo_i));

    hilo_reg hilo_reg0(.clk(clk), .rst(rst),
                        .we(wb_whilo_i), .hi_i(wb_hi_i), .lo_i(wb_lo_i),
                        .hi_o(ex_hi_i), .lo_o(ex_lo_i));

endmodule // mips