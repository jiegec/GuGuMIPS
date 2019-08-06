module cpu_axi_adapter_split_cache #(
    ENABLE_CHECKER = 1
) (
    input         clk,
    input         resetn,

    //inst sram-like
    input         inst_req,
    input         inst_wr,
    input  [1 :0] inst_size,
    input  [31:0] inst_addr,
    input  [31:0] inst_wdata,
    output [31:0] inst_rdata,
    output        inst_addr_ok,
    output        inst_data_ok,
    input         inst_uncached,

    //data sram-like 
    input         data_req,
    input         data_wr,
    input  [1 :0] data_size,
    input  [31:0] data_addr,
    input  [31:0] data_wdata,
    output [31:0] data_rdata,
    output        data_addr_ok,
    output        data_data_ok,
    input         data_uncached,

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
    output        bready
);

// icache
// ar
wire [31:0] icache_araddr ;
wire [1 :0] icache_arburst;
wire [3 :0] icache_arcache;
wire [3 :0] icache_arid   ;
wire [3 :0] icache_arlen  ;
wire [1 :0] icache_arlock ;
wire [2 :0] icache_arprot ;
wire [3 :0] icache_arqos ;
wire        icache_arready;
wire [2 :0] icache_arsize ;
wire        icache_arvalid;
// r
wire [3 :0] icache_rid    ;
wire [31:0] icache_rdata  ;
wire [1 :0] icache_rresp  ;
wire        icache_rlast  ;
wire        icache_rvalid ;
wire        icache_rready ;
// aw
wire [31:0] icache_awaddr ;
wire [1 :0] icache_awburst;
wire [3 :0] icache_awcache;
wire [3 :0] icache_awid   ;
wire [3 :0] icache_awlen  ;
wire [1 :0] icache_awlock ;
wire [2 :0] icache_awprot ;
wire [3 :0] icache_awqos  ;
wire        icache_awready;
wire [2 :0] icache_awsize ;
wire        icache_awvalid;
// w
wire [3 :0] icache_wid    ;
wire [31:0] icache_wdata  ;
wire        icache_wlast  ;
wire        icache_wready ;
wire [3 :0] icache_wstrb  ;
wire        icache_wvalid ;
// b
wire [3 :0] icache_bid    ;
wire        icache_bready ;
wire [1 :0] icache_bresp  ;
wire        icache_bvalid ;

cache # (
    .MEMORY_PRIMITIVE("block"),
    .TAG_WIDTH(19)
) icache (
    .clk(clk),
    .rst(~resetn),

    .cpu_req(inst_req),
    .cpu_wr(inst_wr),
    .cpu_size(inst_size),
    .cpu_addr(inst_addr),
    .cpu_wdata(inst_wdata),
    .cpu_rdata(inst_rdata),
    .cpu_addr_ok(inst_addr_ok),
    .cpu_data_ok(inst_data_ok),
    .cpu_uncached(inst_uncached),

    .arid      (icache_arid      ),
    .araddr    (icache_araddr    ),
    .arlen     (icache_arlen     ),
    .arsize    (icache_arsize    ),
    .arburst   (icache_arburst   ),
    .arlock    (icache_arlock    ),
    .arcache   (icache_arcache   ),
    .arprot    (icache_arprot    ),
    .arqos     (icache_arqos     ),
    .arvalid   (icache_arvalid   ),
    .arready   (icache_arready   ),

    .rid       (icache_rid       ),
    .rdata     (icache_rdata     ),
    .rresp     (icache_rresp     ),
    .rlast     (icache_rlast     ),
    .rvalid    (icache_rvalid    ),
    .rready    (icache_rready    ),

    .awid      (icache_awid      ),
    .awaddr    (icache_awaddr    ),
    .awlen     (icache_awlen     ),
    .awsize    (icache_awsize    ),
    .awburst   (icache_awburst   ),
    .awlock    (icache_awlock    ),
    .awcache   (icache_awcache   ),
    .awprot    (icache_awprot    ),
    .awqos     (icache_awqos     ),
    .awvalid   (icache_awvalid   ),
    .awready   (icache_awready   ),

    .wid       (icache_wid       ),
    .wdata     (icache_wdata     ),
    .wstrb     (icache_wstrb     ),
    .wlast     (icache_wlast     ),
    .wvalid    (icache_wvalid    ),
    .wready    (icache_wready    ),

    .bid       (icache_bid       ),
    .bresp     (icache_bresp     ),
    .bvalid    (icache_bvalid    ),
    .bready    (icache_bready    )
);

// dcache
// ar
wire [31:0] dcache_araddr ;
wire [1 :0] dcache_arburst;
wire [3 :0] dcache_arcache;
wire [3 :0] dcache_arid   ;
wire [3 :0] dcache_arlen  ;
wire [1 :0] dcache_arlock ;
wire [2 :0] dcache_arprot ;
wire [3 :0] dcache_arqos ;
wire        dcache_arready;
wire [2 :0] dcache_arsize ;
wire        dcache_arvalid;
// r
wire [3 :0] dcache_rid    ;
wire [31:0] dcache_rdata  ;
wire [1 :0] dcache_rresp  ;
wire        dcache_rlast  ;
wire        dcache_rvalid ;
wire        dcache_rready ;
// aw
wire [31:0] dcache_awaddr ;
wire [1 :0] dcache_awburst;
wire [3 :0] dcache_awcache;
wire [3 :0] dcache_awid   ;
wire [3 :0] dcache_awlen  ;
wire [1 :0] dcache_awlock ;
wire [2 :0] dcache_awprot ;
wire [3 :0] dcache_awqos  ;
wire        dcache_awready;
wire [2 :0] dcache_awsize ;
wire        dcache_awvalid;
// w
wire [3 :0] dcache_wid    ;
wire [31:0] dcache_wdata  ;
wire        dcache_wlast  ;
wire        dcache_wready ;
wire [3 :0] dcache_wstrb  ;
wire        dcache_wvalid ;
// b
wire [3 :0] dcache_bid    ;
wire        dcache_bready ;
wire [1 :0] dcache_bresp  ;
wire        dcache_bvalid ;

cache # (
    .MEMORY_PRIMITIVE("distributed")
) dcache (
    .clk(clk),
    .rst(~resetn),

    .cpu_req(data_req),
    .cpu_wr(data_wr),
    .cpu_size(data_size),
    .cpu_addr(data_addr),
    .cpu_wdata(data_wdata),
    .cpu_rdata(data_rdata),
    .cpu_addr_ok(data_addr_ok),
    .cpu_data_ok(data_data_ok),
    .cpu_uncached(data_uncached),

    .arid      (dcache_arid      ),
    .araddr    (dcache_araddr    ),
    .arlen     (dcache_arlen     ),
    .arsize    (dcache_arsize    ),
    .arburst   (dcache_arburst   ),
    .arlock    (dcache_arlock    ),
    .arcache   (dcache_arcache   ),
    .arprot    (dcache_arprot    ),
    .arqos     (dcache_arqos     ),
    .arvalid   (dcache_arvalid   ),
    .arready   (dcache_arready   ),

    .rid       (dcache_rid       ),
    .rdata     (dcache_rdata     ),
    .rresp     (dcache_rresp     ),
    .rlast     (dcache_rlast     ),
    .rvalid    (dcache_rvalid    ),
    .rready    (dcache_rready    ),

    .awid      (dcache_awid      ),
    .awaddr    (dcache_awaddr    ),
    .awlen     (dcache_awlen     ),
    .awsize    (dcache_awsize    ),
    .awburst   (dcache_awburst   ),
    .awlock    (dcache_awlock    ),
    .awcache   (dcache_awcache   ),
    .awprot    (dcache_awprot    ),
    .awqos     (dcache_awqos     ),
    .awvalid   (dcache_awvalid   ),
    .awready   (dcache_awready   ),

    .wid       (dcache_wid       ),
    .wdata     (dcache_wdata     ),
    .wstrb     (dcache_wstrb     ),
    .wlast     (dcache_wlast     ),
    .wvalid    (dcache_wvalid    ),
    .wready    (dcache_wready    ),

    .bid       (dcache_bid       ),
    .bresp     (dcache_bresp     ),
    .bvalid    (dcache_bvalid    ),
    .bready    (dcache_bready    )
);

axi_crossbar_0 crossbar (
    .aclk(clk),
    .aresetn(resetn),

    // slave
    .s_axi_awid({icache_awid, dcache_awid}),
    .s_axi_awaddr({icache_awaddr, dcache_awaddr}),
    .s_axi_awlen({icache_awlen, dcache_awlen}),
    .s_axi_awsize({icache_awsize, dcache_awsize}),
    .s_axi_awburst({icache_awburst, dcache_awburst}),
    .s_axi_awlock({icache_awlock, dcache_awlock}),
    .s_axi_awcache({icache_awcache, dcache_awcache}),
    .s_axi_awprot({icache_awprot, dcache_awprot}),
    .s_axi_awqos({icache_awqos, dcache_awqos}),
    .s_axi_awvalid({icache_awvalid, dcache_awvalid}),
    .s_axi_awready({icache_awready, dcache_awready}),

    .s_axi_wid({icache_wid, dcache_wid}),
    .s_axi_wdata({icache_wdata, dcache_wdata}),
    .s_axi_wstrb({icache_wstrb, dcache_wstrb}),
    .s_axi_wlast({icache_wlast, dcache_wlast}),
    .s_axi_wvalid({icache_wvalid, dcache_wvalid}),
    .s_axi_wready({icache_wready, dcache_wready}),

    .s_axi_bid({icache_bid, dcache_bid}),
    .s_axi_bresp({icache_bresp, dcache_bresp}),
    .s_axi_bvalid({icache_bvalid, dcache_bvalid}),
    .s_axi_bready({icache_bready, dcache_bready}),

    .s_axi_arid({icache_arid, dcache_arid}),
    .s_axi_araddr({icache_araddr, dcache_araddr}),
    .s_axi_arlen({icache_arlen, dcache_arlen}),
    .s_axi_arsize({icache_arsize, dcache_arsize}),
    .s_axi_arburst({icache_arburst, dcache_arburst}),
    .s_axi_arlock({icache_arlock, dcache_arlock}),
    .s_axi_arcache({icache_arcache, dcache_arcache}),
    .s_axi_arprot({icache_arprot, dcache_arprot}),
    .s_axi_arqos({icache_arqos, dcache_arqos}),
    .s_axi_arvalid({icache_arvalid, dcache_arvalid}),
    .s_axi_arready({icache_arready, dcache_arready}),

    .s_axi_rid({icache_rid, dcache_rid}),
    .s_axi_rdata({icache_rdata, dcache_rdata}),
    .s_axi_rresp({icache_rresp, dcache_rresp}),
    .s_axi_rlast({icache_rlast, dcache_rlast}),
    .s_axi_rvalid({icache_rvalid, dcache_rvalid}),
    .s_axi_rready({icache_rready, dcache_rready}),

    // master
    // ar
    .m_axi_arid    (arid),
    .m_axi_araddr  (araddr),
    .m_axi_arlen   (arlen),
    .m_axi_arsize  (arsize),
    .m_axi_arburst (arburst),
    .m_axi_arlock  (arlock),
    .m_axi_arcache (arcache),
    .m_axi_arprot  (arprot),
    //.m_axi_arqos   (arqos),
    .m_axi_arvalid (arvalid),
    .m_axi_arready (arready),

    // r
    .m_axi_rid       (rid       ),
    .m_axi_rdata     (rdata     ),
    .m_axi_rresp     (rresp     ),
    .m_axi_rlast     (rlast     ),
    .m_axi_rvalid    (rvalid    ),
    .m_axi_rready    (rready    ),

    // aw
    .m_axi_awid      (awid      ),
    .m_axi_awaddr    (awaddr    ),
    .m_axi_awlen     (awlen     ),
    .m_axi_awsize    (awsize    ),
    .m_axi_awburst   (awburst   ),
    .m_axi_awlock    (awlock    ),
    .m_axi_awcache   (awcache   ),
    .m_axi_awprot    (awprot    ),
    //.m_axi_awqos   (awqos      ),
    .m_axi_awvalid   (awvalid   ),
    .m_axi_awready   (awready   ),

    // w
    .m_axi_wid       (wid       ),
    .m_axi_wdata     (wdata     ),
    .m_axi_wstrb     (wstrb     ),
    .m_axi_wlast     (wlast     ),
    .m_axi_wvalid    (wvalid    ),
    .m_axi_wready    (wready    ),

    // b
    .m_axi_bid       (bid       ),
    .m_axi_bresp     (bresp     ),
    .m_axi_bvalid    (bvalid    ),
    .m_axi_bready    (bready    )
);

generate
    if (ENABLE_CHECKER) begin
        axi_protocol_checker_0 axi_protocol_checker_icache (
            .aclk(clk),
            .aresetn(resetn),

            // slave
            // ar
            .pc_axi_arid      (icache_arid      ),
            .pc_axi_araddr    (icache_araddr    ),
            .pc_axi_arlen     (icache_arlen     ),
            .pc_axi_arsize    (icache_arsize    ),
            .pc_axi_arburst   (icache_arburst   ),
            .pc_axi_arlock    (icache_arlock    ),
            .pc_axi_arcache   (icache_arcache   ),
            .pc_axi_arprot    (icache_arprot    ),
            .pc_axi_arqos     (icache_arqos     ),
            .pc_axi_arvalid   (icache_arvalid   ),
            .pc_axi_arready   (icache_arready   ),

            // r
            .pc_axi_rid       (icache_rid       ),
            .pc_axi_rdata     (icache_rdata     ),
            .pc_axi_rresp     (icache_rresp     ),
            .pc_axi_rlast     (icache_rlast     ),
            .pc_axi_rvalid    (icache_rvalid    ),
            .pc_axi_rready    (icache_rready    ),

            // aw
            .pc_axi_awid      (icache_awid      ),
            .pc_axi_awaddr    (icache_awaddr    ),
            .pc_axi_awlen     (icache_awlen     ),
            .pc_axi_awsize    (icache_awsize    ),
            .pc_axi_awburst   (icache_awburst   ),
            .pc_axi_awlock    (icache_awlock    ),
            .pc_axi_awcache   (icache_awcache   ),
            .pc_axi_awprot    (icache_awprot    ),
            .pc_axi_awqos     (icache_awqos     ),
            .pc_axi_awvalid   (icache_awvalid   ),
            .pc_axi_awready   (icache_awready   ),

            // w
            .pc_axi_wid       (icache_wid       ),
            .pc_axi_wdata     (icache_wdata     ),
            .pc_axi_wstrb     (icache_wstrb     ),
            .pc_axi_wlast     (icache_wlast     ),
            .pc_axi_wvalid    (icache_wvalid    ),
            .pc_axi_wready    (icache_wready    ),

            // b
            .pc_axi_bresp     (icache_bresp     ),
            .pc_axi_bid       (icache_bid       ),
            .pc_axi_bvalid    (icache_bvalid    ),
            .pc_axi_bready    (icache_bready    )
        );

        axi_protocol_checker_0 axi_protocol_checker_dcache (
            .aclk(clk),
            .aresetn(resetn),

            // slave
            // ar
            .pc_axi_arid      (dcache_arid      ),
            .pc_axi_araddr    (dcache_araddr    ),
            .pc_axi_arlen     (dcache_arlen     ),
            .pc_axi_arsize    (dcache_arsize    ),
            .pc_axi_arburst   (dcache_arburst   ),
            .pc_axi_arlock    (dcache_arlock    ),
            .pc_axi_arcache   (dcache_arcache   ),
            .pc_axi_arprot    (dcache_arprot    ),
            .pc_axi_arqos     (dcache_arqos     ),
            .pc_axi_arvalid   (dcache_arvalid   ),
            .pc_axi_arready   (dcache_arready   ),

            // r
            .pc_axi_rid       (dcache_rid       ),
            .pc_axi_rdata     (dcache_rdata     ),
            .pc_axi_rresp     (dcache_rresp     ),
            .pc_axi_rlast     (dcache_rlast     ),
            .pc_axi_rvalid    (dcache_rvalid    ),
            .pc_axi_rready    (dcache_rready    ),

            // aw
            .pc_axi_awid      (dcache_awid      ),
            .pc_axi_awaddr    (dcache_awaddr    ),
            .pc_axi_awlen     (dcache_awlen     ),
            .pc_axi_awsize    (dcache_awsize    ),
            .pc_axi_awburst   (dcache_awburst   ),
            .pc_axi_awlock    (dcache_awlock    ),
            .pc_axi_awcache   (dcache_awcache   ),
            .pc_axi_awprot    (dcache_awprot    ),
            .pc_axi_awqos     (dcache_awqos     ),
            .pc_axi_awvalid   (dcache_awvalid   ),
            .pc_axi_awready   (dcache_awready   ),

            // w
            .pc_axi_wid       (dcache_wid       ),
            .pc_axi_wdata     (dcache_wdata     ),
            .pc_axi_wstrb     (dcache_wstrb     ),
            .pc_axi_wlast     (dcache_wlast     ),
            .pc_axi_wvalid    (dcache_wvalid    ),
            .pc_axi_wready    (dcache_wready    ),

            // b
            .pc_axi_bresp     (dcache_bresp     ),
            .pc_axi_bid       (dcache_bid       ),
            .pc_axi_bvalid    (dcache_bvalid    ),
            .pc_axi_bready    (dcache_bready    )
        );
    end
endgenerate

endmodule
