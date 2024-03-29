module testbench();
logic clk;
logic rst;

// inst sram-like 
logic         inst_req     ;
logic         inst_wr      ;
logic  [1 :0] inst_size    ;
logic  [31:0] inst_addr    ;
logic  [31:0] inst_wdata   ;
logic [31:0] inst_rdata   ;
logic        inst_addr_ok ;
logic        inst_data_ok ;

// data sram-like 
logic         data_req     ;
logic         data_wr      ;
logic  [1 :0] data_size    ;
logic  [31:0] data_addr    ;
logic  [31:0] data_wdata   ;
logic [31:0] data_rdata   ;
logic        data_addr_ok ;
logic        data_data_ok;

// debug
logic [31:0] debug_wb_pc;
logic [3 :0] debug_wb_rf_wen;
logic [4 :0] debug_wb_rf_wnum;
logic [31:0] debug_wb_rf_wdata;

mips #(
    .ENABLE_TLB(1)
)mips_0(
    .clk(clk),
    .rst(rst),
    .intr(6'b0),
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

test_rom test_rom0(
    .clk(clk),
    .rst(rst),
    .inst_req(inst_req),
    .inst_wr(inst_wr),
    .inst_size(inst_size),
    .inst_addr(inst_addr),
    .inst_wdata(inst_wdata),
    .inst_rdata(inst_rdata),
    .inst_addr_ok(inst_addr_ok),
    .inst_data_ok(inst_data_ok)
);

test_ram test_ram0(
    .clk(clk),
    .rst(rst),
    .data_req(data_req),
    .data_wr(data_wr),
    .data_size(data_size),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_rdata(data_rdata),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok)
);


function string get_path_from_file(string fullpath_filename);
    int i;
    int str_index;
    logic found_path;
    string ret="";

    for (i = fullpath_filename.len()-1; i>0; i=i-1) begin
        if (fullpath_filename[i] == "/") begin
            found_path=1;
            str_index=i;
            break;
        end
    end
    if (found_path==1) begin
        ret=fullpath_filename.substr(0,str_index);
    end else begin
       // `uvm_error("pve_get_path_from_file-1", $sformatf("Not found a valid path for this file: %s",fullpath_filename));
    end

    return ret;
endfunction

string path=get_path_from_file(`__FILE__);

task test(string name);
    integer i, fans, pass, line, stop_on_error, debug, match, res;
    string out, ans;
    string mem;

    for(i = 0;i < $size(test_rom0.rom);i++) begin
        test_rom0.rom[i] = 32'h0;
    end
    for(i = 0;i < $size(test_ram0.ram);i++) begin
        test_ram0.ram[i] = 32'h0;
    end

    mem = $sformatf("%stestbench/%s.mem", path, name);
    $readmemh(mem, test_rom0.rom);
    fans = $fopen({path, "testbench/", name, ".ans"}, "r");
    if (!fans) begin
        $finish;
    end

    begin
        rst = 1'b1;
        repeat (10) @ (posedge clk);
        rst = 1'b0;
    end

    $display("Testing %0s", name);
    pass = 1;
    line = 1;

    // config
    stop_on_error = 1;
    debug = 1;

    while (!$feof(fans))
    begin
        @ (negedge clk);
        match = 0;
        if (debug_wb_rf_wen && debug_wb_rf_wnum != 0) begin
            $sformat(out, "$%0d=0x%x", debug_wb_rf_wnum, debug_wb_rf_wdata);
            res = $fscanf(fans, "%s\n", ans);
            match = 1;
        end
        if (test_ram0.data_req && test_ram0.data_wr && test_ram0.data_addr_ok) begin
            $sformat(out, "[0x%0x,%0d]=0x%x", test_ram0.data_addr, 1 + test_ram0.data_size, test_ram0.data_write);
            res = $fscanf(fans, "%s\n", ans);
            match = 1;
        end
        if (match) begin
            if (debug) begin
                $display("Debug @ %x Excepted: %0s, Got: %0s", debug_wb_pc, ans, out);
            end
            if (out != ans && ans != "skip") begin
                $display("Error(%3d): @ %x Expected: %0s, Got: %0s", line, debug_wb_pc, ans, out);
                pass = 0;
                if (stop_on_error) begin
                    $finish;
                end
            end
            line = line + 1;
        end
    end

    if (pass == 1) begin
        $display("Passed %0s", name);
    end else begin
        $display("Failed %0s", name);
        $finish;
    end
endtask

initial begin
    clk = 1'b0;
end

always clk = #5 ~clk;

initial begin
    // bit
    test("inst_ori");
    test("inst_andi");
    test("test_bit");

    // shift
    test("test_shift");

    // move
    test("test_move");

    // jump
    test("inst_j");
    test("test_jump");

    // arith
    test("test_arith");
    test("test_mul");
    test("test_madd");
    test("test_div");
    test("test_sign_extend");
    
    // mem
    test("test_store");
    test("test_load");
    test("test_mem_unaligned");

    // cp0
    test("test_cp0");

    // exception
    test("inst_syscall");
    test("test_trap");
    test("test_except");
    test("test_except_delayslot");
    test("test_timer_int");

    // tlb
    test("test_tlb1");
    test("test_tlb2");
    test("test_tlb3");
    test("test_tlb4");
    test("test_tlb5");
    test("test_tlb6");
    test("test_tlb7");

    // user mode
    test("test_user");

    $finish;
end

endmodule
