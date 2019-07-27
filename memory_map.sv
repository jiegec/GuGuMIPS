`include "define.vh"
module memory_map #(
    ENABLE_TLB = 0
)(
    input logic [31:0] addr_i,
    input logic en,
    input logic user_mode,
    input logic kseg0_uncached,

    output logic [31:0] addr_o,
    output logic except_user,
    output logic use_tlb,
    output logic uncached
);

    // TODO: CP0 Status ERL Bit should be considered

    always_comb begin
        addr_o = 32'b0;
        // kseg
        except_user = en & user_mode & addr_i[31];
        use_tlb = 1'b0;
        uncached = 1'b0;
        if (en) begin
            case (addr_i[31:29])
                // kseg2, kseg3, kuseg
                3'b110, 3'b111, 3'b000, 3'b001, 3'b010, 3'b011: begin
                    if (ENABLE_TLB) begin
                        use_tlb = 1;
                    end else begin
                        addr_o = addr_i;
                    end
                end
                // kseg0
                3'b100: begin
                    uncached = kseg0_uncached;
                    addr_o = {3'b0, addr_i[28:0]};
                end
                // kseg1
                3'b101: begin
                    uncached = 1'b1;
                    addr_o = {3'b0, addr_i[28:0]};
                end
            endcase
        end
    end

endmodule