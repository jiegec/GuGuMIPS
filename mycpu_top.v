//`define USE_AXI

module mycpu_top(
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

    input [5:0] int,

    // debug
    output [31:0] debug_wb_pc,
    output [3 :0] debug_wb_rf_wen,
    output [4 :0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

`ifdef USE_AXI
wire         inst_req     ;
wire         inst_wr      ;
wire  [1 :0] inst_size    ;
wire  [31:0] inst_addr    ;
wire  [31:0] inst_wdata   ;
wire [31:0] inst_rdata   ;
wire        inst_addr_ok ;
wire        inst_data_ok ;

wire         data_req     ;
wire         data_wr      ;
wire  [1 :0] data_size    ;
wire  [31:0] data_addr    ;
wire  [31:0] data_wdata   ;
wire [31:0] data_rdata   ;
wire        data_addr_ok ;
wire        data_data_ok;

wire rst;
assign rst = ~aresetn;

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

    .data_req(data_req),
    .data_wr(data_wr),
    .data_size(data_size),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_rdata(data_rdata),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok),

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
    
    .wid       (wid       ),
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