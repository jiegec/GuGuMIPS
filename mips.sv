`include "define.vh"
module mips #(
    ENABLE_TLB = 0
)(
    input clk,
    input rst,
    input [5:0] intr,

    // inst sram-like 
    output inst_req,
    output inst_wr,
    output [1:0] inst_size,
    output [31:0] inst_addr,
    output [31:0] inst_wdata,
    input [31:0] inst_rdata,
    input inst_addr_ok,
    input inst_data_ok,
    output inst_uncached,
    
    // data sram-like 
    output data_req,
    output data_wr,
    output [1:0] data_size,
    output [31:0] data_addr,
    output [31:0] data_wdata,
    output data_uncached,

    input [31:0] data_rdata,
    input data_addr_ok,
    input data_data_ok,

    // debug
    output [31:0] debug_wb_pc,
    output [3:0] debug_wb_rf_wen,
    output [4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

    wire[`InstAddrBus] pc;
    wire branch_flag;
    wire[`RegBus] branch_target_address;

    wire[4:0] cp0_raddr_i;
    wire[`RegBus] cp0_data_o;

    wire[`InstAddrBus] rom_data;
    wire[`InstAddrBus] if_pc_o;
    wire[`InstAddrBus] id_pc_i;
    wire[`InstAddrBus] id_pc_o;
    wire[`InstAddrBus] ex_pc;
    wire[`InstAddrBus] mem_pc_i;
    wire[`InstAddrBus] mem_pc_o;
    wire[`InstAddrBus] wb_pc;
    wire[`InstBus] id_inst_i;
    wire[`InstBus] ex_inst_i;

    // if
    wire [31:0] if_except_type_o;
    wire [31:0] if_mmu_virt_addr;
    wire if_mmu_en;
    wire [31:0] if_mmu_phys_addr;
    wire if_mmu_uncached;
    wire if_mmu_except_miss;
    wire if_mmu_except_invalid;
    wire if_mmu_except_user;

    wire[`AluOpBus] id_aluop_o;
    wire[`AluSelBus] id_alusel_o;
    wire[`RegBus] id_reg1_o;
    wire[`RegBus] id_reg2_o;
    wire id_wreg_o;
    wire[`RegAddrBus] id_wd_o;
    wire id_is_in_delayslot_o;
    wire next_inst_in_delayslot;
    wire[`RegBus] id_link_addr;
    wire id_is_in_delayslot_i;
    wire [31:0] id_except_type_i;
    wire [31:0] id_except_type_o;
    wire id_tlb_wi_o;

    wire[`AluOpBus] ex_aluop_i;
    wire[`AluSelBus] ex_alusel_i;
    wire[`RegBus] ex_reg1_i;
    wire[`RegBus] ex_reg2_i;
    wire ex_wreg_i;
    wire[`RegAddrBus] ex_wd_i;
    wire[`RegBus] ex_hi_i;
    wire[`RegBus] ex_lo_i;
    wire[`RegBus] ex_link_address;
    wire ex_is_in_delayslot;
    wire [31:0]ex_except_type_i;
    wire [31:0]ex_except_type_o;

    wire ex_wreg_o;
    wire[`RegAddrBus] ex_wd_o;
    wire[`RegBus] ex_wdata_o;
    wire ex_whilo_o;
    wire[`RegBus] ex_hi_o;
    wire[`RegBus] ex_lo_o;

    wire[`RegBus] ex_cp0_reg_data;
    wire[4:0] ex_cp0_reg_write_addr;
    wire ex_cp0_reg_we;
    wire ex_tlb_wi_o;

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

    wire[`RegBus] mem_cp0_reg_data_i;
    wire[4:0] mem_cp0_reg_write_addr_i;
    wire mem_cp0_reg_we_i;
    wire[`RegBus] mem_cp0_reg_data_o;
    wire[4:0] mem_cp0_reg_write_addr_o;
    wire mem_cp0_reg_we_o;
    wire [31:0]mem_except_type_i;
    wire [31:0]mem_except_type_o;
    wire mem_is_in_delayslot;
    wire mem_tlb_wi_o;

    wire wb_wreg_i;
    wire[`RegAddrBus] wb_wd_i;
    wire[`RegBus] wb_wdata_i;
    wire wb_whilo_i;
    wire[`RegBus] wb_hi_i;
    wire[`RegBus] wb_lo_i;

    wire[`RegBus] wb_cp0_reg_data;
    wire[4:0] wb_cp0_reg_write_addr;
    wire wb_cp0_reg_we;
    wire [31:0]wb_except_type;
    wire wb_is_in_delayslot;
    wire wb_tlb_wi;
    wire wb_tlb_p;
    wire [31:0] wb_tlb_p_res;

    wire [31:0] cp0_status_o;
    wire [31:0] cp0_cause_o;
    wire [31:0] cp0_epc_o;
    wire [31:0] cp0_exception_vector_o;
    wire [85+`TLB_WIDTH:0] cp0_tlb_config_o;
    wire [31:0] cp0_entryhi_o;
    wire cp0_user_mode_o;
    wire [7:0] asid = cp0_entryhi_o[7:0];

    assign debug_wb_pc = wb_pc;
    assign debug_wb_rf_wen = {4{wb_wreg_i}};
    assign debug_wb_rf_wnum = wb_wd_i;
    assign debug_wb_rf_wdata = wb_wdata_i;

    wire reg1_read; // read reg1 or not
    wire reg2_read;
    wire[`RegBus] reg1_data; // the data of reg1
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr; // the index or reg1
    wire[`RegAddrBus] reg2_addr;

    wire[`AluOpBus] ex_mem_aluop_i;
    wire[`RegBus] ex_mem_mem_addr_i;
    wire[`RegBus] ex_mem_reg2_i;
    
    wire[`DoubleRegBus] hilo_temp_o;
    wire[1:0] cnt_o;
    wire[`DoubleRegBus] hilo_temp_i;
    wire[1:0] cnt_i;

    wire[`DoubleRegBus] div_result;
    wire div_ready;
    wire[`RegBus] div_opdata1;
    wire[`RegBus] div_opdata2;
    wire div_start;
    wire div_annul;
    wire signed_div;
    wire ex_stall;

    logic [`AluOpBus] mem_aluop_i;
    logic [`AluSelBus] mem_alusel_i;
    logic [`RegBus] mem_mem_addr_i;
    logic [`RegBus] wb_mem_addr;
    logic [`RegBus] mem_reg2_i;

    logic timer_int_o;

    logic en_pc;
    logic en_if_id;
    logic en_id_ex;
    logic en_ex_mm;
    logic en_mm_wb;
    logic flush;

    logic if_stall;
    logic mem_stall;
    logic mem_load;

    logic [5:0] interrupt;
    assign interrupt = {intr[5] | timer_int_o, intr[4:0]};

    logic [31:0] new_pc;
    logic [31:0] reset_pc = 32'hbfc00380;

    always_comb begin
        if (rst) begin
            flush = 0;
            new_pc = 0;
        end else if (wb_except_type != 0) begin
            flush = 1;
            new_pc = cp0_exception_vector_o;
        end else begin
            flush = 0;
            new_pc = 0;
        end

        if (mem_stall || ex_stall) begin
            {en_pc, en_if_id, en_id_ex, en_ex_mm, en_mm_wb} = 5'b00001;
        end else if (mem_load && (mem_wd_o == reg1_addr || mem_wd_o == reg2_addr)) begin
            {en_pc, en_if_id, en_id_ex, en_ex_mm, en_mm_wb} = 5'b00001;
        end else if (ex_alusel_i == `EXE_RES_LOAD_STORE && (ex_wd_o == reg1_addr || ex_wd_o == reg2_addr)) begin
            {en_pc, en_if_id, en_id_ex, en_ex_mm, en_mm_wb} = 5'b00011;
        end else if (if_stall) begin
            {en_pc, en_if_id, en_id_ex, en_ex_mm, en_mm_wb} = 5'b01111;
        end else begin
            {en_pc, en_if_id, en_id_ex, en_ex_mm, en_mm_wb} = 5'b11111;
        end
    end

    pc_reg pc_reg0(.clk(clk), .rst(rst), .flush(flush),
                    .pc(pc), .en(en_pc), .new_pc(new_pc),
                    .branch_flag_i(branch_flag & en_id_ex), .branch_target_address_i(branch_target_address));

    cp0_reg #(
        .ENABLE_TLB(ENABLE_TLB)
    ) cp0_reg0 (.clk(clk), .rst(rst), .int_i(interrupt),
        .except_type_i(wb_except_type), .pc_i(wb_pc), .is_in_delayslot_i(wb_is_in_delayslot),
        .data_i(wb_cp0_reg_data), .raddr_i(cp0_raddr_i), .waddr_i(wb_cp0_reg_write_addr), .we_i(wb_cp0_reg_we),
        .data_o(cp0_data_o), .timer_int_o(timer_int_o), .mem_addr_i(wb_mem_addr),
        .status_o(cp0_status_o), .cause_o(cp0_cause_o), .epc_o(cp0_epc_o), .exception_vector_o(cp0_exception_vector_o),
        .entryhi_o(cp0_entryhi_o),
        .tlb_config_o(cp0_tlb_config_o), .user_mode(cp0_user_mode_o));

    ifetch if0(.clk(clk), .rst(rst), .en(en_pc),
        .addr(pc), .inst(rom_data), .stall(if_stall), .pc_o(if_pc_o), .except_type_o(if_except_type_o),
        .inst_req(inst_req), .inst_wr(inst_wr), .inst_size(inst_size),
        .inst_addr(inst_addr), .inst_wdata(inst_wdata), .inst_rdata(inst_rdata), .inst_addr_ok(inst_addr_ok), .inst_data_ok(inst_data_ok),
        .inst_uncached(inst_uncached),
        // MMU
        .mmu_virt_addr(if_mmu_virt_addr), .mmu_en(if_mmu_en), .mmu_phys_addr(if_mmu_phys_addr)
        ,.mmu_uncached(if_mmu_uncached), .mmu_except_miss(if_mmu_except_miss), .mmu_except_invalid(if_mmu_except_invalid), .mmu_except_user(if_mmu_except_user));

    if_id if_id0(.clk(clk), .rst(rst), .flush(flush), .en(en_if_id),
                .if_pc(if_pc_o), .if_inst(rom_data), .if_except_type(if_except_type_o),
                .id_pc(id_pc_i), .id_inst(id_inst_i), .id_except_type(id_except_type_i));

    id #(
        .ENABLE_TLB(ENABLE_TLB)
    ) id0 (.rst(rst), .pc_i(id_pc_i), .pc_o(id_pc_o), .inst_i(id_inst_i),
            .reg1_data_i(reg1_data), .reg2_data_i(reg2_data),
            .reg1_read_o(reg1_read), .reg2_read_o(reg2_read),
            .reg1_addr_o(reg1_addr), .reg2_addr_o(reg2_addr),
            .aluop_o(id_aluop_o), .alusel_o(id_alusel_o),
            .reg1_o(id_reg1_o), .reg2_o(id_reg2_o),
            .wd_o(id_wd_o), .wreg_o(id_wreg_o),
            .ex_wd_i(ex_wd_o), .ex_wreg_i(ex_wreg_o), .ex_wdata_i(ex_wdata_o),
            .mem_wd_i(mem_wd_o), .mem_wreg_i(mem_wreg_o), .mem_wdata_i(mem_wdata_o),
            .is_in_delayslot_i(id_is_in_delayslot_i), .is_in_delayslot_o(id_is_in_delayslot_o),
            .next_inst_in_delayslot_o(next_inst_in_delayslot), .branch_flag_o(branch_flag),
            .branch_target_address_o(branch_target_address), .link_addr_o(id_link_addr),
            .except_type_i(id_except_type_i), .except_type_o(id_except_type_o),
            .tlb_wi(id_tlb_wi_o));

    regfile regfile0(.clk(clk), .rst(rst),
                    .we(wb_wreg_i), .waddr(wb_wd_i),
                    .wdata(wb_wdata_i), .re1(reg1_read),
                    .raddr1(reg1_addr), .rdata1(reg1_data),
                    .re2(reg2_read), .raddr2(reg2_addr),
                    .rdata2(reg2_data));

    id_ex id_ex0(.clk(clk), .rst(rst | (!en_id_ex & en_ex_mm)), .en(en_id_ex), .en_pc(en_pc), .flush(flush),
                .id_aluop(id_aluop_o), .id_alusel(id_alusel_o), .id_reg1(id_reg1_o), .id_reg2(id_reg2_o), .id_wd(id_wd_o), .id_wreg(id_wreg_o), .id_pc(id_pc_o), .id_inst(id_inst_i),
                .ex_aluop(ex_aluop_i), .ex_alusel(ex_alusel_i), .ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i), .ex_wd(ex_wd_i), .ex_wreg(ex_wreg_i), .ex_pc(ex_pc), .ex_inst(ex_inst_i),
                .id_is_in_delayslot(id_is_in_delayslot_o), .id_link_address(id_link_addr),
                .next_inst_in_delayslot_i(next_inst_in_delayslot), .ex_link_address(ex_link_address),
                .ex_is_in_delayslot(ex_is_in_delayslot), .is_in_delayslot_o(id_is_in_delayslot_i),
                .id_except_type(id_except_type_o), .ex_except_type(ex_except_type_i),
                .id_tlb_wi(id_tlb_wi_o), .ex_tlb_wi(ex_tlb_wi_o)
    );

    ex ex0(.rst(rst), .aluop_i(ex_aluop_i), .alusel_i(ex_alusel_i), .reg1_i(ex_reg1_i), .reg2_i(ex_reg2_i), .wd_i(ex_wd_i), .wreg_i(ex_wreg_i),
           .inst_i(ex_inst_i), .pc_i(ex_pc), .except_type_i(ex_except_type_i), .except_type_o(ex_except_type_o),
           .wd_o(ex_wd_o), .wreg_o(ex_wreg_o), .wdata_o(ex_wdata_o),
           .hi_i(ex_hi_i), .lo_i(ex_lo_i), .whilo_o(ex_whilo_o), .hi_o(ex_hi_o), .lo_o(ex_lo_o),
           .mem_whilo_i(mem_whilo_i), .mem_hi_i(mem_hi_i), .mem_lo_i(mem_lo_i),
           .wb_whilo_i(wb_whilo_i), .wb_hi_i(wb_hi_i), .wb_lo_i(wb_lo_i),
           .cp0_reg_read_addr_o(cp0_raddr_i), .cp0_reg_data_i(cp0_data_o),
           .cp0_reg_data_o(ex_cp0_reg_data), .cp0_reg_write_addr_o(ex_cp0_reg_write_addr), .cp0_reg_we_o(ex_cp0_reg_we),
           .mem_cp0_reg_data(mem_cp0_reg_data_o), .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o), .mem_cp0_reg_we(mem_cp0_reg_we_o),
           .wb_cp0_reg_data(wb_cp0_reg_data), .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr), .wb_cp0_reg_we(wb_cp0_reg_we),
           .is_in_delayslot_i(ex_is_in_delayslot), .link_address_i(ex_link_address),
           .aluop_o(ex_mem_aluop_i), .mem_addr_o(ex_mem_mem_addr_i), .reg2_o(ex_mem_reg2_i),
           .hilo_temp_i(hilo_temp_i), .cnt_i(cnt_i), .hilo_temp_o(hilo_temp_o), .cnt_o(cnt_o),
           .div_opdata1_o(div_opdata1), .div_opdata2_o(div_opdata2), .div_start_o(div_start), .signed_div_o(signed_div),	
           .div_result_i(div_result), .div_ready_i(div_ready),
           .stallreq(ex_stall));

    ex_mem ex_mem0(.clk(clk), .rst(rst | (!en_ex_mm & en_mm_wb)), .en(en_ex_mm), .flush(flush),
        .ex_wd(ex_wd_o), .ex_wreg(ex_wreg_o), .ex_wdata(ex_wdata_o), .ex_pc(ex_pc),
        .mem_wd(mem_wd_i), .mem_wreg(mem_wreg_i), .mem_wdata(mem_wdata_i), .mem_pc(mem_pc_i),
        .ex_whilo(ex_whilo_o), .ex_hi(ex_hi_o), .ex_lo(ex_lo_o),
        .mem_whilo(mem_whilo_i), .mem_hi(mem_hi_i), .mem_lo(mem_lo_i),
        .ex_cp0_reg_data(ex_cp0_reg_data), .ex_cp0_reg_write_addr(ex_cp0_reg_write_addr), .ex_cp0_reg_we(ex_cp0_reg_we),
        .ex_except_type(ex_except_type_o), .ex_is_in_delayslot(ex_is_in_delayslot),
        .mem_cp0_reg_data(mem_cp0_reg_data_i), .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i), .mem_cp0_reg_we(mem_cp0_reg_we_i),
        .mem_except_type(mem_except_type_i), .mem_is_in_delayslot(mem_is_in_delayslot),
        .ex_alusel(ex_alusel_i), .ex_aluop(ex_mem_aluop_i), .ex_mem_addr(ex_mem_mem_addr_i), .ex_reg2(ex_mem_reg2_i),
        .mem_alusel(mem_alusel_i), .mem_aluop(mem_aluop_i), .mem_mem_addr(mem_mem_addr_i), .mem_reg2(mem_reg2_i),
        .hilo_i(hilo_temp_o), .cnt_i(cnt_o), .hilo_o(hilo_temp_i), .cnt_o(cnt_i),
        .ex_tlb_wi(ex_tlb_wi_o), .mem_tlb_wi(mem_tlb_wi_o)
    );

    mem mem0(.rst(rst), .clk(clk),
             .wd_i(mem_wd_i), .wreg_i(mem_wreg_i), .wdata_i(mem_wdata_i),
             .wd_o(mem_wd_o), .wreg_o(mem_wreg_o), .wdata_o(mem_wdata_o),
             .whilo_i(mem_whilo_i), .hi_i(mem_hi_i), .lo_i(mem_lo_i),
             .whilo_o(mem_whilo_o), .hi_o(mem_hi_o), .lo_o(mem_lo_o),
             .cp0_reg_data_i(mem_cp0_reg_data_i), .cp0_reg_data_o(mem_cp0_reg_data_o),
             .cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i), .cp0_reg_write_addr_o(mem_cp0_reg_write_addr_o),
             .cp0_reg_we_i(mem_cp0_reg_we_i), .cp0_reg_we_o(mem_cp0_reg_we_o),
             .except_type_i(mem_except_type_i), .is_in_delayslot_i(mem_is_in_delayslot), .pc_i(mem_pc_i), .pc_o(mem_pc_o),
             .cp0_status_i(cp0_status_o), .cp0_cause_i(cp0_cause_o), .cp0_epc_i(cp0_epc_o),
             .wb_cp0_reg_we(wb_cp0_reg_we), .wb_cp0_reg_data(wb_cp0_reg_data), .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr),
             .except_type_o(mem_except_type_o), .data_uncached(data_uncached),
             .aluop_i(mem_aluop_i), .mem_addr_i(mem_mem_addr_i), .reg2_i(mem_reg2_i),
             .mem_stall(mem_stall), .mem_load(mem_load),
             .data_req(data_req), .data_wr(data_wr), .data_size(data_size),
             .data_addr(data_addr), .data_wdata(data_wdata), .data_rdata(data_rdata),
             .data_addr_ok(data_addr_ok), .data_data_ok(data_data_ok));
            
    mem_wb mem_wb0(.clk(clk), .rst(rst), .en(en_mm_wb), .flush(flush)
        ,.mem_wd(mem_wd_o), .mem_wreg(mem_wreg_o), .mem_wdata(mem_wdata_o), .mem_pc(mem_pc_o)
        ,.wb_wd(wb_wd_i), .wb_wreg(wb_wreg_i), .wb_wdata(wb_wdata_i), .wb_pc(wb_pc)
        ,.mem_whilo(mem_whilo_o), .mem_hi(mem_hi_o), .mem_lo(mem_lo_o)
        ,.wb_whilo(wb_whilo_i), .wb_hi(wb_hi_i), .wb_lo(wb_lo_i)
        ,.mem_cp0_reg_data(mem_cp0_reg_data_o), .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o), .mem_cp0_reg_we(mem_cp0_reg_we_o)
        ,.wb_cp0_reg_data(wb_cp0_reg_data), .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr), .wb_cp0_reg_we(wb_cp0_reg_we)
        ,.mem_except_type(mem_except_type_o), .wb_except_type(wb_except_type)
        ,.mem_mem_addr(mem_mem_addr_i), .wb_mem_addr(wb_mem_addr)
        ,.mem_is_in_delayslot(mem_is_in_delayslot), .wb_is_in_delayslot(wb_is_in_delayslot)
        ,.mem_tlb_wi(mem_tlb_wi_o), .wb_tlb_wi(wb_tlb_wi)
    );

    hilo_reg hilo_reg0(.clk(clk), .rst(rst)
        ,.we(wb_whilo_i), .hi_i(wb_hi_i), .lo_i(wb_lo_i)
        ,.hi_o(ex_hi_i), .lo_o(ex_lo_i)
    );

    div div0(.clk(clk), .rst(rst)
        ,.signed_div_i(signed_div), .opdata1_i(div_opdata1), .opdata2_i(div_opdata2), .start_i(div_start), .annul_i(1'b0)
        ,.result_o(div_result), .ready_o(div_ready)
    );
        
    mmu #(
        .ENABLE_TLB(ENABLE_TLB)
    ) mmu0 (.clk(clk), .rst(rst)
        ,.user_mode(cp0_user_mode_o), .kseg0_uncached(0), .asid(asid)
        // TODO: translate data
        ,.inst_addr_i(if_mmu_virt_addr), .inst_en(if_mmu_en), .inst_addr_o(if_mmu_phys_addr), .inst_uncached(if_mmu_uncached), .inst_except_miss(if_mmu_except_miss), .inst_except_invalid(if_mmu_except_invalid), .inst_except_user(if_mmu_except_user)
        ,.tlb_config(cp0_tlb_config_o), .tlb_wi(wb_tlb_wi)
        ,.tlb_p(wb_tlb_p), .tlb_p_res_o(wb_tlb_p_res)
    );

endmodule // mips
