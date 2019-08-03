module cache #(
    CACHE_LINE_WIDTH = 6,
    TAG_WIDTH = 20
    `define INDEX_WIDTH (32 - CACHE_LINE_WIDTH - TAG_WIDTH)
    `define NUM_CACHE_LINES (2 ** `INDEX_WIDTH)
    `define OFFSET_WIDTH (CACHE_LINE_WIDTH - 2)
) (
    input clk,
    input rst,

    input cpu_req,
    input cpu_wr,
    input [1:0] cpu_size,
    input [1:0] cpu_addr,
    input [31:0] cpu_wdata,
    output [31:0] cpu_rdata,
    output cpu_data_ok,
    output cpu_addr_ok,
    input cpu_uncached,

    // ar
    output [3:0] arid,
    output [31:0] araddr,
    output [3:0] arlen,
    output [2:0] arsize,
    output [1:0] arburst,
    output [1:0] arlock,
    output [3:0] arcache,
    outptu [2:0] arprot,
    output arvalid,
    input arready,
    // r
    input [3:0] rid,
    input [31:0] rdata,
    input [1:0] rresp,
    input rlast,
    input rvalid,
    output rready,

    // aw
    output [3:0] awid,
    output [31:0] awaddr,
    output [3:0] awlen,
    output [2:0] awsize,
    output [1:0] awburst,
    output [1:0] awlock,
    output [3:0] awcache,
    output [2:0] awprot,
    output awvalid,
    output awready,
    // w
    output [3:0] wid,
    output [31:0] wdata,
    output [3:0] wstrb,
    output wlast,
    output wvalid,
    input wready,
    // b
    input [3:0] bid,
    input [1:0] bresp,
    input bvalid,
    output bready
);

endmodule