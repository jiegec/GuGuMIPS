`define USE_DEBUG

module mycpu_top #(
    ENABLE_TLB = 1,
    ENABLE_CHECKER = 1
) (
    input aclk,
    input aresetn,

    // AXI
    // ar
    output [3 :0] arid   ,
    output [31:0] araddr ,
    output [3 :0] arlen  ,
    output [2 :0] arsize ,
    output [1 :0] arburst,
    output [1 :0] arlock ,
    output [3 :0] arcache,
    output [2 :0] arprot ,
    output        arvalid,
    input        arready,
    // r
    input [3 :0] rid    ,
    input [31:0] rdata  ,
    input [1 :0] rresp  ,
    input        rlast  ,
    input        rvalid ,
    output        rready ,
    // aw
    output [3 :0] awid   ,
    output [31:0] awaddr ,
    output [3 :0] awlen  ,
    output [2 :0] awsize ,
    output [1 :0] awburst,
    output [1 :0] awlock ,
    output [3 :0] awcache,
    output [2 :0] awprot ,
    output        awvalid,
    input        awready,
    // w
    output [3 :0] wid    ,
    output [31:0] wdata  ,
    output [3 :0] wstrb  ,
    output        wlast  ,
    output        wvalid ,
    input        wready ,
    // b
    input [3 :0] bid    ,
    input [1 :0] bresp  ,
    input        bvalid ,
    output        bready ,

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

// ar
wire [31:0] cache_araddr ;
wire [1 :0] cache_arburst;
wire [3 :0] cache_arcache;
wire [0 :0] cache_arid   ;
wire [7 :0] cache_arlen  ;
wire [0 :0] cache_arlock ;
wire [2 :0] cache_arprot ;
wire [3 :0] cache_arqos ;
wire        cache_arready;
wire [2 :0] cache_arsize ;
wire        cache_arvalid;
// r
wire [0 :0] cache_rid    ;
wire [31:0] cache_rdata  ;
wire [1 :0] cache_rresp  ;
wire        cache_rlast  ;
wire        cache_rvalid ;
wire        cache_rready ;
// aw
wire [31:0] cache_awaddr ;
wire [1 :0] cache_awburst;
wire [3 :0] cache_awcache;
wire [0 :0] cache_awid   ;
wire [7 :0] cache_awlen  ;
wire [0 :0] cache_awlock ;
wire [2 :0] cache_awprot ;
wire [3 :0] cache_awqos  ;
wire        cache_awready;
wire [2 :0] cache_awsize ;
wire        cache_awvalid;
// w
wire [31:0] cache_wdata  ;
wire        cache_wlast  ;
wire        cache_wready ;
wire [3 :0] cache_wstrb  ;
wire        cache_wvalid ;
// b
wire [0 :0] cache_bid    ;
wire        cache_bready ;
wire [1 :0] cache_bresp  ;
wire        cache_bvalid ;

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

cpu_axi_interface cpu_axi_interface_inst(
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

    .arid      (cache_arid      ),
    .araddr    (cache_araddr    ),
    .arlen     (cache_arlen     ),
    .arsize    (cache_arsize    ),
    .arburst   (cache_arburst   ),
    .arlock    (cache_arlock    ),
    .arcache   (cache_arcache   ),
    .arprot    (cache_arprot    ),
    .arvalid   (cache_arvalid   ),
    .arready   (cache_arready   ),

    .rid       (cache_rid       ),
    .rdata     (cache_rdata     ),
    .rresp     (cache_rresp     ),
    .rlast     (cache_rlast     ),
    .rvalid    (cache_rvalid    ),
    .rready    (cache_rready    ),

    .awid      (cache_awid      ),
    .awaddr    (cache_awaddr    ),
    .awlen     (cache_awlen     ),
    .awsize    (cache_awsize    ),
    .awburst   (cache_awburst   ),
    .awlock    (cache_awlock    ),
    .awcache   (cache_awcache   ),
    .awprot    (cache_awprot    ),
    .awvalid   (cache_awvalid   ),
    .awready   (cache_awready   ),

    .wdata     (cache_wdata     ),
    .wstrb     (cache_wstrb     ),
    .wlast     (cache_wlast     ),
    .wvalid    (cache_wvalid    ),
    .wready    (cache_wready    ),

    .bid       (cache_bid       ),
    .bresp     (cache_bresp     ),
    .bvalid    (cache_bvalid    ),
    .bready    (cache_bready    )
);

assign arlock[1] = 1'b0;
assign awlock[1] = 1'b0;
assign wid = 4'b0;

system_cache_0 system_cache_inst(
    .ACLK(aclk),
    .ARESETN(aresetn),

    // slave
    // ar
    .S0_AXI_ARID    (cache_arid),
    .S0_AXI_ARADDR  (cache_araddr),
    .S0_AXI_ARLEN   (cache_arlen),
    .S0_AXI_ARSIZE  (cache_arsize),
    .S0_AXI_ARBURST (cache_arburst),
    .S0_AXI_ARLOCK  (cache_arlock),
    .S0_AXI_ARCACHE  (cache_arcache),
    .S0_AXI_ARPROT  (cache_arprot),
    .S0_AXI_ARQOS   (cache_arqos),
    .S0_AXI_ARVALID (cache_arvalid),
    .S0_AXI_ARREADY (cache_arready),

    // r
    .S0_AXI_RID       (cache_rid       ),
    .S0_AXI_RDATA     (cache_rdata     ),
    .S0_AXI_RRESP     (cache_rresp     ),
    .S0_AXI_RLAST     (cache_rlast     ),
    .S0_AXI_RVALID    (cache_rvalid    ),
    .S0_AXI_RREADY    (cache_rready    ),

    // aw
    .S0_AXI_AWID      (cache_awid      ),
    .S0_AXI_AWADDR    (cache_awaddr    ),
    .S0_AXI_AWLEN     (cache_awlen     ),
    .S0_AXI_AWSIZE    (cache_awsize    ),
    .S0_AXI_AWBURST   (cache_awburst   ),
    .S0_AXI_AWLOCK    (cache_awlock    ),
    .S0_AXI_AWCACHE   (cache_awcache   ),
    .S0_AXI_AWPROT    (cache_awprot    ),
    .S0_AXI_AWQOS     (cache_awqos     ),
    .S0_AXI_AWVALID   (cache_awvalid   ),
    .S0_AXI_AWREADY   (cache_awready   ),

    // w
    .S0_AXI_WDATA     (cache_wdata     ),
    .S0_AXI_WSTRB     (cache_wstrb     ),
    .S0_AXI_WLAST     (cache_wlast     ),
    .S0_AXI_WVALID    (cache_wvalid    ),
    .S0_AXI_WREADY    (cache_wready    ),

    // b
    .S0_AXI_BRESP     (cache_bresp     ),
    .S0_AXI_BID       (cache_bid       ),
    .S0_AXI_BVALID    (cache_bvalid    ),
    .S0_AXI_BREADY    (cache_bready    ),

    // master
    // ar
    .M0_AXI_ARID    (arid),
    .M0_AXI_ARADDR  (araddr),
    .M0_AXI_ARLEN   (arlen),
    .M0_AXI_ARSIZE  (arsize),
    .M0_AXI_ARBURST (arburst),
    .M0_AXI_ARLOCK  (arlock[0]),
    .M0_AXI_ARCACHE (arcache),
    .M0_AXI_ARPROT  (arprot),
    //.M0_AXI_ARQOS   (arqos),
    .M0_AXI_ARVALID (arvalid),
    .M0_AXI_ARREADY (arready),

    // r
    .M0_AXI_RID       (rid       ),
    .M0_AXI_RDATA     (rdata     ),
    .M0_AXI_RRESP     (rresp     ),
    .M0_AXI_RLAST     (rlast     ),
    .M0_AXI_RVALID    (rvalid    ),
    .M0_AXI_RREADY    (rready    ),

    // aw
    .M0_AXI_AWID      (awid      ),
    .M0_AXI_AWADDR    (awaddr    ),
    .M0_AXI_AWLEN     (awlen     ),
    .M0_AXI_AWSIZE    (awsize    ),
    .M0_AXI_AWBURST   (awburst   ),
    .M0_AXI_AWLOCK    (awlock[0] ),
    .M0_AXI_AWCACHE   (awcache   ),
    .M0_AXI_AWPROT    (awprot    ),
    //.M0_AXI_AWQOS   (awqos      ),
    .M0_AXI_AWVALID   (awvalid   ),
    .M0_AXI_AWREADY   (awready   ),

    // w
    .M0_AXI_WDATA     (wdata     ),
    .M0_AXI_WSTRB     (wstrb     ),
    .M0_AXI_WLAST     (wlast     ),
    .M0_AXI_WVALID    (wvalid    ),
    .M0_AXI_WREADY    (wready    ),

    // b
    .M0_AXI_BRESP     (bresp     ),
    .M0_AXI_BID       (bid       ),
    .M0_AXI_BVALID    (bvalid    ),
    .M0_AXI_BREADY    (bready    )
);

generate
    if (ENABLE_CHECKER) begin
        axi_protocol_checker_0 axi_protocol_checker_inst (
            .aclk(aclk),
            .aresetn(aresetn),

            // slave
            // ar
            .pc_axi_arid    (cache_arid),
            .pc_axi_araddr  (cache_araddr),
            .pc_axi_arlen   (cache_arlen),
            .pc_axi_arsize  (cache_arsize),
            .pc_axi_arburst (cache_arburst),
            .pc_axi_arlock  (cache_arlock),
            .pc_axi_arcache  (cache_arcache),
            .pc_axi_arprot  (cache_arprot),
            .pc_axi_arqos   (4'b0),
            .pc_axi_arvalid (cache_arvalid),
            .pc_axi_arready (cache_arready),

            // r
            .pc_axi_rid       (cache_rid       ),
            .pc_axi_rdata     (cache_rdata     ),
            .pc_axi_rresp     (cache_rresp     ),
            .pc_axi_rlast     (cache_rlast     ),
            .pc_axi_rvalid    (cache_rvalid    ),
            .pc_axi_rready    (cache_rready    ),

            // aw
            .pc_axi_awid      (cache_awid      ),
            .pc_axi_awaddr    (cache_awaddr    ),
            .pc_axi_awlen     (cache_awlen),
            .pc_axi_awsize    (cache_awsize    ),
            .pc_axi_awburst   (cache_awburst   ),
            .pc_axi_awlock    (cache_awlock    ),
            .pc_axi_awcache   (cache_awcache   ),
            .pc_axi_awprot    (cache_awprot    ),
            .pc_axi_awqos     (4'b0            ),
            .pc_axi_awvalid   (cache_awvalid   ),
            .pc_axi_awready   (cache_awready   ),

            // w
            .pc_axi_wdata     (cache_wdata     ),
            .pc_axi_wstrb     (cache_wstrb     ),
            .pc_axi_wlast     (cache_wlast     ),
            .pc_axi_wvalid    (cache_wvalid    ),
            .pc_axi_wready    (cache_wready    ),

            // b
            .pc_axi_bresp     (cache_bresp     ),
            .pc_axi_bid       (cache_bid       ),
            .pc_axi_bvalid    (cache_bvalid    ),
            .pc_axi_bready    (cache_bready    )
        );
    end
endgenerate

endmodule