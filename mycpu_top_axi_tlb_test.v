`define USE_DEBUG

module mycpu_top #(
    ENABLE_TLB = 1,
    ENABLE_CHECKER = 1
) (
    input aclk,
    input aresetn,

    // AXI
    // ar
    output [3 :0] arid,
    output [31:0] araddr,
    output [3 :0] arlen,
    output [2 :0] arsize,
    output [1 :0] arburst,
    output [1 :0] arlock,
    output [3 :0] arcache,
    output [2 :0] arprot,
    output        arvalid,
    input         arready,
    // r
    input [3 :0]  rid,
    input [31:0]  rdata,
    input [1 :0]  rresp,
    input         rlast,
    input         rvalid,
    output        rready,
    // aw
    output [3 :0] awid,
    output [31:0] awaddr,
    output [3 :0] awlen,
    output [2 :0] awsize,
    output [1 :0] awburst,
    output [1 :0] awlock,
    output [3 :0] awcache,
    output [2 :0] awprot,
    output        awvalid,
    input         awready,
    // w
    output [3 :0] wid,
    output [31:0] wdata,
    output [3 :0] wstrb,
    output        wlast,
    output        wvalid,
    input         wready,
    // b
    input [3 :0]  bid,
    input [1 :0]  bresp,
    input         bvalid,
    output        bready,

    // debug
    output [31:0] debug_wb_pc,
    output [3 :0] debug_wb_rf_wen,
    output [4 :0] debug_wb_rf_wnum,
`ifdef USE_DEBUG
    output [31:0] debug_wb_rf_wdata,
`else
    output [31:0] debug_wb_rf_data,
`endif
    output [31:0] cp0_status_o,
    output [31:0] cp0_cause_o,
    output [31:0] cp0_epc_o,

    input [5:0] int
);

wire inst_req;
wire inst_wr;
wire [1 :0] inst_size;
wire [31:0] inst_addr;
wire [31:0] inst_wdata;
wire [31:0] inst_rdata;
wire inst_addr_ok;
wire inst_data_ok;
wire inst_uncached;

wire data_req;
wire data_wr;
wire [1 :0] data_size;
wire [31:0] data_addr;
wire [31:0] data_wdata;
wire [31:0] data_rdata;
wire data_addr_ok;
wire data_data_ok;
wire data_uncached;

wire rst;
assign rst = ~aresetn;

mips #(
    .ENABLE_TLB(ENABLE_TLB)
) mips_inst (
    .clk(aclk),
    .rst(rst),
    .intr(int),

    .inst_req(inst_req),
    .inst_wr(inst_wr),
    .inst_size(inst_size),
    .inst_addr(inst_addr),
    .inst_wdata(inst_wdata),
    .inst_rdata(inst_rdata),
    .inst_addr_ok(inst_addr_ok),
    .inst_data_ok(inst_data_ok),
    .inst_uncached(inst_uncached),

    .data_req(data_req),
    .data_wr(data_wr),
    .data_size(data_size),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_rdata(data_rdata),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok),
    .data_uncached(data_uncached),

    .debug_wb_pc(debug_wb_pc),
    .debug_wb_rf_wen(debug_wb_rf_wen),
    .debug_wb_rf_wnum(debug_wb_rf_wnum),
`ifdef USE_DEBUG
    .debug_wb_rf_wdata(debug_wb_rf_wdata),
`else
    .debug_wb_rf_wdata(debug_wb_rf_data),
`endif

    .cp0_status_o(cp0_status_o),
    .cp0_cause_o(cp0_cause_o),
    .cp0_epc_o(cp0_epc_o)
);

cpu_axi_adapter_system_cache #(
    .ENABLE_CHEKER(ENABLE_CHECKER)
) adapter (
    .clk(aclk),
    .resetn(aresetn),

    .inst_req(inst_req),
    .inst_wr(inst_wr),
    .inst_size(inst_size),
    .inst_addr(inst_addr),
    .inst_wdata(inst_wdata),
    .inst_rdata(inst_rdata),
    .inst_addr_ok(inst_addr_ok),
    .inst_data_ok(inst_data_ok),
    .inst_uncached(inst_uncached),

    .data_req(data_req),
    .data_wr(data_wr),
    .data_size(data_size),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_rdata(data_rdata),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok),
    .data_uncached(data_uncached),

    .arid      (arid      ),
    .araddr    (araddr    ),
    .arlen     (arlen     ),
    .arsize    (arsize    ),
    .arburst   (arburst   ),
    .arlock    (arlock    ),
    .arcache   (arcache   ),
    .arprot    (arprot    ),
    .arvalid   (arvalid   ),
    .arready   (arready   ),

    .rid       (rid       ),
    .rdata     (rdata     ),
    .rresp     (rresp     ),
    .rlast     (rlast     ),
    .rvalid    (rvalid    ),
    .rready    (rready    ),

    .awid      (awid      ),
    .awaddr    (awaddr    ),
    .awlen     (awlen     ),
    .awsize    (awsize    ),
    .awburst   (awburst   ),
    .awlock    (awlock    ),
    .awcache   (awcache   ),
    .awprot    (awprot    ),
    .awvalid   (awvalid   ),
    .awready   (awready   ),

    .wdata     (wdata     ),
    .wstrb     (wstrb     ),
    .wlast     (wlast     ),
    .wvalid    (wvalid    ),
    .wready    (wready    ),

    .bid       (bid       ),
    .bresp     (bresp     ),
    .bvalid    (bvalid    ),
    .bready    (bready    )
);

endmodule