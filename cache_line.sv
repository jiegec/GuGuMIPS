`include "define.vh"
module cache_line #(
    TAG_WIDTH = 20,
    CACHE_LINE_WIDTH = 6
    `define OFFSET_WIDTH (CACHE_LINE_WIDTH - 2)
) (
    input clk,
    input rst,

    input [`OFFSET_WIDTH-1:0] r_offset,
    output [31:0] r_data,

    output r_dirty,
    output r_valid,
    output [TAG_WIDTH-1:0] r_tag,

    input w_en,
    input [TAG_WIDTH-1:0] w_tag,
    input [`OFFSET_WIDTH-1:0] w_offset,
    input [31:0] w_data,
    input [3:0] w_strb,
    input w_dirty,
    input w_valid
);

    logic [TAG_WIDTH-1:0] tag;
    logic dirty;
    logic valid;

    xpm_memory_sdpram #(
        .MEMORY_PRIMITIVE("distributed"),
        .MEMORY_SIZE(32*(2**`OFFSET_WIDTH)),
        .WRITE_DATA_WIDTH_A(32),
        .READ_DATA_WIDTH_B(32),
        .BYTE_WRITE_WIDTH_A(8),
        .ADDR_WIDTH_A(`OFFSET_WIDTH),
        .ADDR_WIDTH_B(`OFFSET_WIDTH),
        .READ_LATENCY_B(1),
        .WRITE_MODE_B("read_first"),
        .MEMORY_INIT_FILE("none"),
        .MEMORY_INIT_PARAM("")
    ) storage (
        .clka(clk),
        .ena(w_en),
        .addra(w_offset),
        .wea(w_strb),
        .dina(w_data),

        .clkb(clk),
        .rstb(rst),
        .enb(1'b1),
        .addrb(r_offset),
        .doutb(r_data)
    );

    assign r_tag = tag;
    assign r_dirty = valid ? dirty : 0;
    assign r_valid = valid;

    always_ff @ (posedge clk) begin
        if (rst) begin
            tag <= 0; 
            dirty <= 0;
            valid <= 0;
        end else if (w_en) begin
            tag <= w_tag;
            dirty <= w_dirty;
            valid <= w_valid;
        end
    end


endmodule