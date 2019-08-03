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
    input [31:0] cpu_addr,
    input [31:0] cpu_wdata,
    output logic [31:0] cpu_rdata,
    output logic cpu_data_ok,
    output logic cpu_addr_ok,
    input cpu_uncached,

    // ar
    output logic [3:0] arid,
    output logic [31:0] araddr,
    output logic [3:0] arlen,
    output logic [2:0] arsize,
    output logic [1:0] arburst,
    output logic [1:0] arlock,
    output logic [3:0] arcache,
    output logic [2:0] arprot,
    output logic [3:0] arqos,
    output logic arvalid,
    input arready,
    // r
    input [3:0] rid,
    input [31:0] rdata,
    input [1:0] rresp,
    input rlast,
    input rvalid,
    output logic rready,

    // aw
    output logic [3:0] awid,
    output logic [31:0] awaddr,
    output logic [3:0] awlen,
    output logic [2:0] awsize,
    output logic [1:0] awburst,
    output logic [1:0] awlock,
    output logic [3:0] awcache,
    output logic [2:0] awprot,
    output logic [3:0] awqos,
    output logic awvalid,
    input awready,
    // w
    output logic [3:0] wid,
    output logic [31:0] wdata,
    output logic [3:0] wstrb,
    output logic wlast,
    output logic wvalid,
    input wready,
    // b
    input [3:0] bid,
    input [1:0] bresp,
    input bvalid,
    output logic bready
);

    localparam FSM_IDLE = 4'd0;
    localparam FSM_WRITEBACK_FIRST = 4'd1;
    localparam FSM_WRITEBACK = 4'd2;
    localparam FSM_MEMREAD_FIRST = 4'd3;
    localparam FSM_MEMREAD = 4'd4;
    localparam FSM_WAIT_WRITE = 4'd5;
    localparam FSM_UNCACHED_READ_AR = 4'd6;
    localparam FSM_UNCACHED_READ_R = 4'd7;
    localparam FSM_UNCACHED_WRITE_AW = 4'd8;
    localparam FSM_UNCACHED_WRITE_W = 4'd9;
    localparam FSM_UNCACHED_WRITE_B = 4'd10;

    logic [`OFFSET_WIDTH-1:0] r_offset;
    logic [31:0] r_data[`NUM_CACHE_LINES-1:0];
    logic r_dirty[`NUM_CACHE_LINES-1:0];
    logic r_valid[`NUM_CACHE_LINES-1:0];
    logic [TAG_WIDTH-1:0] r_tag[`NUM_CACHE_LINES-1:0];

    logic w_en[`OFFSET_WIDTH-1:0];
    logic [TAG_WIDTH-1:0] w_tag;
    logic [`OFFSET_WIDTH-1:0] w_offset;
    logic [31:0] w_data;
    logic [3:0] w_strb;
    logic w_dirty;
    logic w_valid;

    generate
        for (genvar i = 0;i < `NUM_CACHE_LINES;i = i + 1) begin
            cache_line #(
                .TAG_WIDTH(TAG_WIDTH),
                .CACHE_LINE_WIDTH(CACHE_LINE_WIDTH)
            ) cache_line_inst (
                .clk(clk), .rst(rst),
                .r_offset(r_offset), .r_data(r_data[i]),
                .r_dirty(r_dirty[i]), .r_valid(r_valid[i]), .r_tag(r_tag[i]),
                .w_en(w_en[i]),
                .w_tag(w_tag), .w_data(w_data), .w_offset(w_offset),
                .w_strb(w_strb), .w_dirty(w_dirty), .w_valid(w_valid)
            );
        end
    endgenerate

    logic [3:0] state;

    assign arid = 4'b0;
    assign arlock = 2'b0;
    assign arcache = 4'b0;
    assign arprot = 3'b0;
    assign arqos = 3'b0;
    assign awid = 4'b0;
    assign awlock = 2'b0;
    assign awcache = 4'b0;
    assign awprot = 3'b0;
    assign awqos = 3'b0;
    assign wid = 4'b0;

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= FSM_IDLE;

            araddr <= 32'b0;
            arlen <= 4'b0;
            arsize <= 3'b0;
            arburst <= 2'b0;
            arvalid <= 1'b0;
            rready <= 1'b0;
            awaddr <= 32'b0;
            awlen <= 4'b0;
            awsize <= 3'b0;
            awburst <= 2'b0;
            awvalid <= 1'b0;
            wdata <= 32'b0;
            wstrb <= 4'b0;
            wlast <= 1'b0;
            wvalid <= 1'b0;
            bready <= 1'b0;
        end else begin
            case (state)
                FSM_IDLE: begin
                end
            endcase
        end
    end

endmodule