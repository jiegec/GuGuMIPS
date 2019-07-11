`include "define.vh"
module mem(
    input wire  rst,
    input wire[`RegAddrBus] wd_i,
    input wire wreg_i,
    input wire[`RegBus] wdata_i,

    input wire whilo_i,
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,

    input wire cp0_reg_we_i,
    input wire[4:0] cp0_reg_write_addr_i,
    input wire[`RegBus] cp0_reg_data_i,

    input [31:0] except_type_i,
    input is_in_delayslot_i,
    input [`RegBus] pc_i,

    input [`RegBus] cp0_status_i,
    input [`RegBus] cp0_cause_i,
    input [`RegBus] cp0_epc_i,

    input wb_cp0_reg_we,
    input [4:0] wb_cp0_reg_write_addr,
    input [`RegBus] wb_cp0_reg_data,

    input wire [`AluOpBus] aluop_i,
    input wire [`RegBus] mem_addr_i,
    input wire [`RegBus] reg2_i,

    input wire [`RegBus] mem_data_i,

    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,

    output reg whilo_o,
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o,

    output logic cp0_reg_we_o,
    output logic[4:0] cp0_reg_write_addr_o,
    output logic[`RegBus] cp0_reg_data_o,

    output logic[31:0] except_type_o,
    output logic[31:0] cp0_epc_o,

	  output reg[`RegBus] mem_addr_o,
	  output wire mem_we_o,
	  output reg[3:0] mem_sel_o,
	  output reg[`RegBus] mem_data_o,
	  output reg mem_ce_o	
);
  logic [31:0] cp0_status;
  logic [31:0] cp0_cause;
  logic [31:0] cp0_epc;

  wire[`RegBus] zero32;
  reg mem_we;

  assign mem_we_o = mem_we;
  assign zero32 = `ZeroWord;

  // handle data dependency
  always_comb begin
    if (rst == `RstEnable) begin
      cp0_status = 0;
    end else if (wb_cp0_reg_we == 1 && wb_cp0_reg_write_addr == `CP0_REG_STATUS) begin
      cp0_status = wb_cp0_reg_data;
    end else begin
      cp0_status = cp0_status_i;
    end
  end

  always_comb begin
    if (rst == `RstEnable) begin
      cp0_epc = 0;
    end else if (wb_cp0_reg_we == 1 && wb_cp0_reg_write_addr == `CP0_REG_EPC) begin
      cp0_epc = wb_cp0_reg_data;
    end else begin
      cp0_epc = cp0_epc_i;
    end
  end

  assign cp0_epc_o = cp0_epc;

  always_comb begin
    if (rst == `RstEnable) begin
      cp0_cause = 0;
    end else if (wb_cp0_reg_we == 1 && wb_cp0_reg_write_addr == `CP0_REG_EPC) begin
      // IP[1:0]
      cp0_cause[9:8] = wb_cp0_reg_data[9:8];
      // WP
      cp0_cause[22] = wb_cp0_reg_data[22];
      // IV
      cp0_cause[23] = wb_cp0_reg_data[23];
    end else begin
      cp0_cause = cp0_cause_i;
    end
  end

  always_comb begin
    if (rst == `RstEnable) begin
      wd_o = `NOPRegAddr;
      wreg_o = `WriteDisable;
      wdata_o = `ZeroWord;

      whilo_o = `WriteDisable;
      hi_o = `ZeroWord;
      lo_o = `ZeroWord;

      cp0_reg_we_o = 0;
      cp0_reg_write_addr_o = 0;
      cp0_reg_data_o = 0;
    end else begin
      wd_o = wd_i;
      wreg_o = wreg_i;
      wdata_o = wdata_i;

      whilo_o = whilo_i;
      hi_o = hi_i;
      lo_o = lo_i;

      cp0_reg_we_o = cp0_reg_we_i;
      cp0_reg_write_addr_o = cp0_reg_write_addr_i;
      cp0_reg_data_o = cp0_reg_data_i;
    end
  end

  always_comb begin
    if (rst == `RstEnable) begin
      except_type_o = 0;
    end else begin
      if (((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) &&
        (cp0_status[1] == 1'b0) && cp0_status[0] == 1'b1) begin
        // interrupt
        except_type_o = 32'h00000001;
      end else if (except_type_i[8] == 1'b1) begin
        // syscall
        except_type_o = 32'h00000008;
      end else if (except_type_i[9] == 1'b1) begin
        // inst_valid
        except_type_o = 32'h0000000a;
      end else if (except_type_i[10] == 1'b1) begin
        // trap
        except_type_o = 32'h0000000d;
      end else if (except_type_i[11] == 1'b1) begin
        // overflow
        except_type_o = 32'h0000000c;
      end else if (except_type_i[12] == 1'b1) begin
        // eret
        except_type_o = 32'h0000000e;
      end else begin
        except_type_o = 32'h0;
      end
    end
  end

  always_comb begin
    if (rst == `RstEnable) begin
      mem_addr_o = `ZeroWord;
      mem_we = `WriteDisable;
      mem_sel_o = 4'b0000;
      mem_data_o = `ZeroWord;
      mem_ce_o = `ChipDisable;
    end else begin
      mem_addr_o = `ZeroWord;
      mem_we = `WriteDisable;
      mem_sel_o = 4'b1111;
      mem_ce_o = `ChipDisable;
      case (aluop_i)
				`EXE_LB_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						2'b01:	begin
							wdata_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b10:	begin
							wdata_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b11:	begin
							wdata_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						default:	begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LBU_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o <= {{24{1'b0}},mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						2'b01:	begin
							wdata_o <= {{24{1'b0}},mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b10:	begin
							wdata_o <= {{24{1'b0}},mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b11:	begin
							wdata_o <= {{24{1'b0}},mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						default:	begin
							wdata_o <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LH_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o <= {{16{mem_data_i[31]}},mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						2'b10:	begin
							wdata_o <= {{16{mem_data_i[15]}},mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						default:	begin
							wdata_o <= `ZeroWord;
						end
					endcase					
				end
				`EXE_LHU_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o <= {{16{1'b0}},mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						2'b10:	begin
							wdata_o <= {{16{1'b0}},mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						default:	begin
							wdata_o <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LW_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b1111;
					mem_ce_o <= `ChipEnable;		
				end
				`EXE_LWL_OP:		begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o <= mem_data_i[31:0];
						end
						2'b01:	begin
							wdata_o <= {mem_data_i[23:0],reg2_i[7:0]};
						end
						2'b10:	begin
							wdata_o <= {mem_data_i[15:0],reg2_i[15:0]};
						end
						2'b11:	begin
							wdata_o <= {mem_data_i[7:0],reg2_i[23:0]};	
						end
						default:	begin
							wdata_o <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LWR_OP:		begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_o <= {reg2_i[31:8],mem_data_i[31:24]};
						end
						2'b01:	begin
							wdata_o <= {reg2_i[31:16],mem_data_i[31:16]};
						end
						2'b10:	begin
							wdata_o <= {reg2_i[31:24],mem_data_i[31:8]};
						end
						2'b11:	begin
							wdata_o <= mem_data_i;	
						end
						default:	begin
							wdata_o <= `ZeroWord;
						end
					endcase					
				end
				`EXE_SB_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							mem_sel_o <= 4'b1000;
						end
						2'b01:	begin
							mem_sel_o <= 4'b0100;
						end
						2'b10:	begin
							mem_sel_o <= 4'b0010;
						end
						2'b11:	begin
							mem_sel_o <= 4'b0001;	
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase				
				end
				`EXE_SH_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {reg2_i[15:0],reg2_i[15:0]};
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							mem_sel_o <= 4'b1100;
						end
						2'b10:	begin
							mem_sel_o <= 4'b0011;
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase						
				end
				`EXE_SW_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= reg2_i;
					mem_sel_o <= 4'b1111;	
					mem_ce_o <= `ChipEnable;		
				end
				`EXE_SWL_OP:		begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin						  
							mem_sel_o <= 4'b1111;
							mem_data_o <= reg2_i;
						end
						2'b01:	begin
							mem_sel_o <= 4'b0111;
							mem_data_o <= {zero32[7:0],reg2_i[31:8]};
						end
						2'b10:	begin
							mem_sel_o <= 4'b0011;
							mem_data_o <= {zero32[15:0],reg2_i[31:16]};
						end
						2'b11:	begin
							mem_sel_o <= 4'b0001;	
							mem_data_o <= {zero32[23:0],reg2_i[31:24]};
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase							
				end
				`EXE_SWR_OP:		begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin						  
							mem_sel_o <= 4'b1000;
							mem_data_o <= {reg2_i[7:0],zero32[23:0]};
						end
						2'b01:	begin
							mem_sel_o <= 4'b1100;
							mem_data_o <= {reg2_i[15:0],zero32[15:0]};
						end
						2'b10:	begin
							mem_sel_o <= 4'b1110;
							mem_data_o <= {reg2_i[23:0],zero32[7:0]};
						end
						2'b11:	begin
							mem_sel_o <= 4'b1111;	
							mem_data_o <= reg2_i[31:0];
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase											
				end 
				default:		begin
          //do nothing
				end
			endcase							
    end
  end

endmodule // mem
