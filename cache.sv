module cache #(
    CACHE_LINE_WIDTH = 6,
    TAG_WIDTH = 18,
    MEMORY_PRIMITIVE = "distributed"
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

    localparam INDEX_WIDTH = 32 - CACHE_LINE_WIDTH - TAG_WIDTH;
    localparam NUM_CACHE_LINES = 2 ** INDEX_WIDTH;
    localparam OFFSET_WIDTH = CACHE_LINE_WIDTH - 2;

    enum {
        IDLE,
        QUERY_CACHE,
        WRITEBACK_AW,
        WRITEBACK_W,
        WRITEBACK_B,
        MEMREAD_WAIT,
        MEMREAD_FIRST,
        MEMREAD,
        WAIT_WRITE,
        UNCACHED_READ_AR,
        UNCACHED_READ_R,
        UNCACHED_WRITE_AW,
        UNCACHED_WRITE_W,
        UNCACHED_WRITE_B
    } state;

    logic [OFFSET_WIDTH-1:0] r_offset;
    logic [31:0] r_data[NUM_CACHE_LINES-1:0];
    logic r_dirty[NUM_CACHE_LINES-1:0];
    logic r_valid[NUM_CACHE_LINES-1:0];
    logic [TAG_WIDTH-1:0] r_tag[NUM_CACHE_LINES-1:0];

    logic w_en[NUM_CACHE_LINES-1:0];
    logic [TAG_WIDTH-1:0] w_tag;
    logic [OFFSET_WIDTH-1:0] w_offset;
    logic [31:0] w_data;
    logic [3:0] w_strb;
    logic w_dirty;
    logic w_valid;

    wire uncached = (cpu_req && cpu_uncached) || (state == UNCACHED_READ_AR) || (state == UNCACHED_READ_R) || (state == UNCACHED_WRITE_AW) || (state == UNCACHED_WRITE_W) || (state == UNCACHED_WRITE_B);

    logic [31:0] cached_cpu_rdata;
    logic [31:0] uncached_cpu_rdata;
    assign cpu_rdata = uncached ? uncached_cpu_rdata : cached_cpu_rdata;
    logic cached_cpu_data_ok;
    logic uncached_cpu_data_ok;
    assign cpu_data_ok = uncached ? uncached_cpu_data_ok : cached_cpu_data_ok;
    logic cached_cpu_addr_ok;
    logic uncached_cpu_addr_ok;
    assign cpu_addr_ok = uncached ? uncached_cpu_addr_ok : cached_cpu_addr_ok;

    logic [31:0] cached_araddr;
    logic [31:0] uncached_araddr;
    assign araddr = uncached ? uncached_araddr : cached_araddr;
    logic [3:0] cached_arlen;
    logic [3:0] uncached_arlen;
    assign arlen = uncached ? uncached_arlen : cached_arlen;
    logic [2:0] cached_arsize;
    logic [2:0] uncached_arsize;
    assign arsize = uncached ? uncached_arsize : cached_arsize;
    logic [1:0] cached_arburst;
    logic [1:0] uncached_arburst;
    assign arburst = uncached ? uncached_arburst : cached_arburst;
    logic cached_arvalid;
    logic uncached_arvalid;
    assign arvalid = uncached ? uncached_arvalid : cached_arvalid;

    logic cached_rready;
    logic uncached_rready;
    assign rready = uncached ? uncached_rready : cached_rready;

    logic [31:0] cached_awaddr;
    logic [31:0] uncached_awaddr;
    assign awaddr = uncached ? uncached_awaddr : cached_awaddr;
    logic [3:0] cached_awlen;
    logic [3:0] uncached_awlen;
    assign awlen = uncached ? uncached_awlen : cached_awlen;
    logic [2:0] cached_awsize;
    logic [2:0] uncached_awsize;
    assign awsize = uncached ? uncached_awsize : cached_awsize;
    logic [1:0] cached_awburst;
    logic [1:0] uncached_awburst;
    assign awburst = uncached ? uncached_awburst : cached_awburst;
    logic cached_awvalid;
    logic uncached_awvalid;
    assign awvalid = uncached ? uncached_awvalid : cached_awvalid;

    logic [31:0] cached_wdata;
    logic [31:0] uncached_wdata;
    assign wdata = uncached ? uncached_wdata : cached_wdata;
    logic [3:0] cached_wstrb;
    logic [3:0] uncached_wstrb;
    assign wstrb = uncached ? uncached_wstrb : cached_wstrb;
    logic cached_wlast;
    logic uncached_wlast;
    assign wlast = uncached ? uncached_wlast : cached_wlast;
    logic cached_wvalid;
    logic uncached_wvalid;
    assign wvalid = uncached ? uncached_wvalid : cached_wvalid;

    logic [1:0] cached_bready;
    logic [1:0] uncached_bready;
    assign bready = uncached ? uncached_bready : cached_bready;

    assign uncached_araddr = cpu_addr;
    assign uncached_arlen = 4'd0;
    assign uncached_arsize = 3'd2;
    assign uncached_arburst = 2'd1; // INCR
    assign uncached_arvalid = cpu_req & ~cpu_wr;
    assign uncached_rready = state == UNCACHED_READ_R;

    assign uncached_awaddr = cpu_addr;
    assign uncached_awlen = 4'd0;
    assign uncached_awsize = 3'd2;
    assign uncached_awburst = 2'd1; // INCR
    assign uncached_awvalid = cpu_req & cpu_wr & (state == IDLE || state == UNCACHED_WRITE_AW);
    assign uncached_bready = state == UNCACHED_WRITE_B;

    assign uncached_cpu_data_ok = (uncached_rready & rvalid) | (uncached_bready & bvalid);
    assign uncached_cpu_rdata = rdata;
    assign uncached_cpu_addr_ok = (uncached_arvalid & arready) | (uncached_awvalid & awready);

    generate
        for (genvar i = 0;i < NUM_CACHE_LINES;i = i + 1) begin
            cache_line #(
                .TAG_WIDTH(TAG_WIDTH),
                .CACHE_LINE_WIDTH(CACHE_LINE_WIDTH),
                .MEMORY_PRIMITIVE(MEMORY_PRIMITIVE)
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

    reg write_cache;
    reg [INDEX_WIDTH-1:0] write_index;
    generate
        for (genvar i = 0; i < NUM_CACHE_LINES; i = i + 1) begin
            assign w_en[i] = write_cache ? i == write_index : 1'b0;
        end
    endgenerate

    wire [TAG_WIDTH-1:0] cache_cpu_tag;
    wire [INDEX_WIDTH-1:0] cache_cpu_index;
    wire [OFFSET_WIDTH-1:0] cache_cpu_offset;
    wire [1:0] cache_cpu_byte;

    reg [31:0] saved_cpu_addr;
    wire [31:0] current_cpu_addr = state == IDLE ? cpu_addr : saved_cpu_addr;

    reg saved_cpu_wr;
    wire current_cpu_wr = state == IDLE ? cpu_wr : saved_cpu_wr;

    reg [31:0] saved_cpu_wdata;
    wire [31:0] current_cpu_wdata = state == IDLE ? cpu_wdata : saved_cpu_wdata;

    reg [1:0] saved_cpu_size;
    wire [1:0] current_cpu_size = state == IDLE ? cpu_size : saved_cpu_size;

    wire [3:0] current_cpu_strb = current_cpu_size == 2'd0 ? 4'b0001 << current_cpu_addr[1:0] :
                        current_cpu_size == 2'd1 ? 4'b0011 << current_cpu_addr[1:0] :
                        current_cpu_size == 2'd2 ? 4'b0111 << current_cpu_addr[1:0] : 4'b1111;

    assign {
        cache_cpu_tag, cache_cpu_index,
        cache_cpu_offset, cache_cpu_byte
    } = current_cpu_addr;

    reg [OFFSET_WIDTH-1:0] cache_writeback_offset;

    assign r_offset = state == WRITEBACK_W ? cache_writeback_offset : cache_cpu_offset;
    // after one cycle
    wire cache_line_valid = r_valid[cache_cpu_index];
    wire cache_line_dirty = r_dirty[cache_cpu_index];
    wire [TAG_WIDTH-1:0] cache_line_tag = r_tag[cache_cpu_index];
    wire cache_line_hit = cache_line_tag == cache_cpu_tag;
    wire [31:0] cache_line_data = r_data[cache_cpu_index];

    assign w_data = (current_cpu_wr && state == WAIT_WRITE) ? current_cpu_wdata : rdata;
    assign w_tag = cache_cpu_tag;

    wire need_writeback = cache_line_valid && cache_line_dirty && ~cache_line_hit;
    wire need_memread = ~cache_line_valid || ~cache_line_hit;

    assign cached_cpu_addr_ok = cpu_req && state == IDLE;
    assign cached_cpu_data_ok = state == QUERY_CACHE;
    assign cached_cpu_rdata = state == MEMREAD_FIRST ? rdata : cache_line_data;

    assign cached_araddr = {current_cpu_addr[31:2], 2'b0};
    assign cached_arlen = (2 ** OFFSET_WIDTH) - 1;
    assign cached_arsize = 3'b10; // 4
    assign cached_arburst = 2'b10; // WRAP
    assign cached_arvalid = state == MEMREAD_WAIT;

    assign cached_rready = state == MEMREAD_FIRST || state == MEMREAD;

    assign cached_awaddr = {cache_line_tag, cache_cpu_index, cache_cpu_offset, 2'b0};
    assign cached_awlen = (2 ** OFFSET_WIDTH) - 1;
    assign cached_awsize = 3'b10; // 4
    assign cached_awburst = 2'b10; // WRAP
    assign cached_awvalid = state == WRITEBACK_AW;

    // assume that wready don't not go down in a burst transfer
    assign cached_wdata = cache_line_data;
    assign cached_wstrb = 4'b1111;
    assign cached_wlast = cache_writeback_offset == cache_cpu_offset;
    assign cached_wvalid = state == WRITEBACK_W;

    assign cached_bready = state == WRITEBACK_B;

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

    // statistics
    integer requests_count = 0, uncached_count = 0, hit_count = 0, miss_count = 0, writeback_count = 0, read_count = 0;
`ifdef XILINX_SIMULATOR
    real hit_rate;
    assign hit_rate = hit_count / real'(hit_count + miss_count);
`endif

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= IDLE;

            uncached_wdata <= 32'b0;
            uncached_wstrb <= 4'b0;
            uncached_wlast <= 1'b0;
            uncached_wvalid <= 1'b0;

            saved_cpu_addr <= 32'b0;
            saved_cpu_wdata <= 32'b0;
            saved_cpu_wr <= 1'b0;
            saved_cpu_size <= 2'b0;

            write_cache <= 1'b0;
            write_index <= 'b0;

            w_offset <= 'b0;
            w_strb <= 4'b0;
            w_dirty <= 1'b0;
            w_valid <= 1'b0;

            cache_writeback_offset <= 'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (cpu_req) begin
                        requests_count = requests_count + 1;
                        if (uncached) begin
                            uncached_count = uncached_count + 1;
                            // uncached
                            if (cpu_wr) begin
                                // uncached write
                                if (awready) begin
                                    state <= UNCACHED_WRITE_W;
                                end else begin
                                    state <= UNCACHED_WRITE_AW;
                                end
                            end else begin
                                // uncached read
                                if (arready) begin
                                    state <= UNCACHED_READ_R;
                                end else begin
                                    state <= UNCACHED_READ_AR;
                                end
                            end
                        end else begin
                            // cached
                            if (need_writeback) begin
                                miss_count = miss_count + 1;
                                writeback_count = writeback_count + 1;
                                state <= WRITEBACK_AW;
                            end else if (need_memread) begin
                                miss_count = miss_count + 1;
                                read_count = read_count + 1;
                                state <= MEMREAD_WAIT;
                            end else begin
                                hit_count = hit_count + 1;
                                state <= QUERY_CACHE;
                            end
                            saved_cpu_addr <= cpu_addr;
                            saved_cpu_wr <= cpu_wr;
                            saved_cpu_wdata <= cpu_wdata;
                            saved_cpu_size <= cpu_size;
                        end
                    end
                end
                QUERY_CACHE: begin
                    if (current_cpu_wr) begin
                        // write
                        write_cache <= 1;
                        write_index <= cache_cpu_index;
                        w_offset <= cache_cpu_offset;
                        w_strb <= current_cpu_strb;
                        w_dirty <= 1'b1;
                        w_valid <= 1'b1;
                        state <= WAIT_WRITE;
                    end else begin
                        // read
                        if (cpu_req & !uncached & !need_memread & !need_writeback) begin
                            // continue
                        end else begin
                            state <= IDLE;
                            saved_cpu_addr <= 32'b0;
                        end
                    end
                end
                MEMREAD_WAIT: begin
                    if (arready) begin
                        state <= MEMREAD_FIRST;
                        write_cache <= 1;
                        write_index <= cache_cpu_index;
                        w_offset <= cache_cpu_offset;
                        w_strb <= 4'b1111;
                        w_dirty <= 1'b0;
                        w_valid <= 1'b1;
                    end
                end
                MEMREAD_FIRST, MEMREAD: begin
                    if (rvalid) begin
                        w_offset <= w_offset + 1;
                        state <= MEMREAD;
                        if (rlast) begin
                            write_cache <= 0;
                            state <= QUERY_CACHE;
                        end
                    end
                end
                WRITEBACK_AW: begin
                    if (awready) begin
                        cache_writeback_offset <= cache_cpu_offset + 1;
                        state <= WRITEBACK_W;
                    end
                end
                WRITEBACK_W: begin
                    if (wready) begin
                        if (wlast) begin
                            state <= WRITEBACK_B;

                            cache_writeback_offset <= 'b0;
                            write_cache <= 1;
                            write_index <= cache_cpu_index;
                            w_offset <= 'b0;
                            w_strb <= 'b0;
                            w_dirty <= 1'b0;
                            w_valid <= 1'b0;
                        end else begin
                            cache_writeback_offset <= cache_writeback_offset + 1;
                        end
                    end
                end
                WRITEBACK_B: begin
                    write_cache <= 0;
                    if (bvalid) begin
                        if (need_memread) begin
                            state <= MEMREAD_WAIT;
                        end else begin
                            state <= QUERY_CACHE;
                        end
                    end
                end
                UNCACHED_READ_AR: begin
                    if (arready) begin
                        state <= UNCACHED_READ_R;
                    end
                end
                UNCACHED_READ_R: begin
                    if (rvalid) begin
                        state <= IDLE;
                    end
                end
                UNCACHED_WRITE_AW: begin
                    if (awready) begin
                        state <= UNCACHED_WRITE_W;
                        uncached_wdata <= cpu_wdata;
                        uncached_wstrb <= current_cpu_strb;
                        uncached_wlast <= 1'b1;
                        uncached_wvalid <= 1'b1;
                    end
                end
                UNCACHED_WRITE_W: begin
                    if (wready) begin
                        state <= UNCACHED_WRITE_B;
                        uncached_wdata <= 32'b0;
                        uncached_wstrb <= 4'b0;
                        uncached_wlast <= 1'b0;
                        uncached_wvalid <= 1'b0;
                    end
                end
                UNCACHED_WRITE_B: begin
                    if (bvalid) begin
                        state <= IDLE;
                    end
                end
                WAIT_WRITE: begin
                    write_cache <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule