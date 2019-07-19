`define USE_AXI
//`define USE_DEBUG

module mycpu_top (
`ifdef USE_AXI 
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
`else
    input clk,
    input resetn,

    output inst_sram_en,
    output [3:0] inst_sram_wen, 
    output [31:0] inst_sram_addr,
    input [31:0] inst_sram_wdata,
    input [31:0] inst_sram_rdata,

    output data_sram_en,
    output [3:0] data_sram_wen, 
    output [31:0] data_sram_addr,
    input [31:0] data_sram_wdata,
    input [31:0] data_sram_rdata,
`endif

`ifdef USE_DEBUG
    // debug
    output [31:0] debug_wb_pc,
    output [3 :0] debug_wb_rf_wen,
    output [4 :0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata,
`endif

    input [5:0] int
);

`ifdef USE_AXI
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
wire [0 :0] cache_arid   ;
wire [31:0] cache_araddr ;
wire [3 :0] cache_arlen  ;
wire [2 :0] cache_arsize ;
wire [1 :0] cache_arburst;
wire [0 :0] cache_arlock ;
wire [3 :0] cache_arcache;
wire [2 :0] cache_arprot ;
wire        cache_arvalid;
wire        cache_arready;
// r
wire [0 :0] cache_rid    ;
wire [31:0] cache_rdata  ;
wire [1 :0] cache_rresp  ;
wire        cache_rlast  ;
wire        cache_rvalid ;
wire        cache_rready ;
// aw
wire [3 :0] cache_awid   ;
wire [31:0] cache_awaddr ;
wire [3 :0] cache_awlen  ;
wire [2 :0] cache_awsize ;
wire [1 :0] cache_awburst;
wire [0 :0] cache_awlock ;
wire [3 :0] cache_awcache;
wire [2 :0] cache_awprot ;
wire        cache_awvalid;
wire        cache_awready;
// w
wire [3 :0] cache_wid    ;
wire [31:0] cache_wdata  ;
wire [3 :0] cache_wstrb  ;
wire        cache_wlast  ;
wire        cache_wvalid ;
wire        cache_wready ;
// b
wire [3 :0] cache_bid    ;
wire [1 :0] cache_bresp  ;
wire        cache_bvalid ;
wire        cache_bready ;

mips mips_inst(
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
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
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
    
    .wid       (cache_wid       ),
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
    .S0_AXI_ARLEN   ({4'b0, cache_arlen}),
    .S0_AXI_ARSIZE  (cache_arsize),
    .S0_AXI_ARBURST (cache_arburst),
    .S0_AXI_ARLOCK  (cache_arlock),
    .S0_AXI_ARCACHE  (cache_arcache),
    .S0_AXI_ARPROT  (cache_arprot),
    .S0_AXI_ARQOS   (4'b0),
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
    .S0_AXI_AWLEN     ({4'b0, cache_awlen}),
    .S0_AXI_AWSIZE    (cache_awsize    ),
    .S0_AXI_AWBURST   (cache_awburst   ),
    .S0_AXI_AWLOCK    (cache_awlock    ),
    .S0_AXI_AWCACHE   (cache_awcache   ),
    .S0_AXI_AWPROT    (cache_awprot    ),
    .S0_AXI_AWQOS     (4'b0            ),
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

`else
wire rst;
assign rst = ~resetn;

wire inst_req;
wire inst_wr;
wire [1:0] inst_size;
wire [31:0] inst_addr;
wire [31:0] inst_wdata;
wire [31:0] inst_rdata;
wire inst_addr_ok;
reg inst_data_ok;

assign inst_sram_en = 1;
assign inst_addr_ok = inst_req;
assign inst_sram_wdata = inst_wdata;
assign inst_rdata = inst_sram_rdata;
assign inst_sram_addr = {inst_addr[31:2], 2'b00};
assign inst_sram_wen = inst_wr ? (inst_size == 2'b00 ? 4'b001 << inst_addr[1:0] :
            (inst_size == 2'b01 ? (4'b0011 << inst_addr[1:0]) : 4'b1111)) : 4'b0000;

wire data_req;
wire data_wr;
wire [1:0] data_size;
wire [31:0] data_addr;
wire [31:0] data_wdata;
wire [31:0] data_rdata;
wire data_addr_ok;
reg data_data_ok;

assign data_sram_en = 1;
assign data_addr_ok = data_req;
assign data_sram_wdata = data_wdata;
assign data_rdata = data_sram_rdata;
assign data_sram_addr = {data_addr[31:2], 2'b00};
assign data_sram_wen = data_wr ? (data_size == 2'b00 ? 4'b001 << data_addr[1:0] :
            (data_size == 2'b01 ? (4'b0011 << data_addr[1:0]) : 4'b1111)) : 4'b0000;

always @ (posedge clk) begin
    if (rst) begin
        inst_data_ok <= 0;
        data_data_ok <= 0;
    end else begin
        inst_data_ok <= inst_req;
        data_data_ok <= data_req;
    end
end

mips mips_inst(
    .clk(clk),
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

    .data_req(data_req),
    .data_wr(data_wr),
    .data_size(data_size),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_rdata(data_rdata),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok),

    .debug_wb_pc(debug_wb_pc),
    .debug_wb_rf_wen(debug_wb_rf_wen),
    .debug_wb_rf_wnum(debug_wb_rf_wnum),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

`endif

endmodule