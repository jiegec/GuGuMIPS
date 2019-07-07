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

mips mips_0(
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

    $display("path=%0s", ret);
    return ret;
endfunction

string path=get_path_from_file(`__FILE__);

task test(string name);
    integer i, fans;
    string out, ans;
    string mem;

    for(i = 0;i < $size(test_rom0.rom);i++) begin
        test_rom0.rom[i] = 32'h0;
    end

    mem = $sformatf("%stestbench/%s.mem", path, name);
    $display("path=%0s", mem);
    $readmemh(mem, test_rom0.rom);
    fans = $fopen({path, "testbench/", name, ".ans"}, "r");
    $display("fd=%d", fans);
    if (!fans) begin
        $finish;
    end

    begin
        rst = 1'b1;
        #50 rst = 1'b0;
    end

    $display("testing %0s", name);
    while (!$feof(fans))
    begin
        @ (negedge clk);
        if (debug_wb_rf_wen && debug_wb_rf_wnum != 0) begin
            $sformat(out, "$%0d=0x%x", debug_wb_rf_wnum, debug_wb_rf_wdata);
            $fscanf(fans, "%s\n", ans);
            if (out != ans) begin
                $display("Error: Expected: %0s, Got: %0s", ans, out);
            end
        end
    end

    $display("Done %0s", name);
endtask

initial begin
    clk = 1'b0;
end

always clk = #5 ~clk;

initial begin
    test("inst_ori");
    $finish;
end

endmodule
