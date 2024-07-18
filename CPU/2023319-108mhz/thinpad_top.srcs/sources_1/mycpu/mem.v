`include "defines.v"

module mem(

	input  wire					  rst,
	
	//来自执行阶段的信息	
	input  wire [            4:0] reg_waddr,
	input  wire                   reg_we,
	input  wire [           31:0] reg_wdata,

	//访存
	input  wire [`AluOpBus - 1:0] alu_op,
	input  wire [           31:0] mem_addr_i,
	input  wire [           31:0] reg2_data,
	
	input  wire [           31:0] mem_data_i,
	
	//送到回写阶段的信息
	output reg  [            4:0] reg_waddr_o,
	output reg                    reg_we_o,
	output reg  [           31:0] reg_wdata_o,
	//访存
	output reg  [           31:0] mem_addr_o,
	output reg					  mem_we_o,   
	output reg  [            3:0] mem_be_o,
	output reg  [           31:0] mem_data_o,
	output reg                    mem_ce_o	
	
);
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			reg_waddr_o       = 5'b0;
			reg_we_o     = `RegWDisable;
		  	reg_wdata_o    = 32'b0;
		   	mem_addr_o = 32'b0;
		  	mem_we_o     = `RegWDisable;
		  	mem_be_o  = 4'b0000;
		  	mem_data_o = 32'b0;
		  	mem_ce_o   = 1'b0;	
		end else begin
		  	reg_waddr_o       = reg_waddr;
			reg_we_o     = reg_we;
			reg_wdata_o    = reg_wdata;
			mem_we_o     = `RegWDisable;
			mem_addr_o = 32'b0;
			mem_be_o  = 4'b0000;
			mem_ce_o   = 1'b0;
			case (alu_op)

			`EXE_LW_OP:	begin
				mem_addr_o = mem_addr_i;
				mem_we_o     = `RegWDisable;
				reg_wdata_o    = mem_data_i;
				mem_be_o  = 4'b1111;
				mem_ce_o   = 1'b1;		
			end

            `EXE_SW_OP:	begin
                mem_addr_o = mem_addr_i;
                mem_we_o     = `RegWEnable;
                mem_data_o = reg2_data;
                mem_be_o  = 4'b1111;	
                mem_ce_o   = 1'b1;		
            end

            `EXE_LB_OP:	begin
				mem_addr_o = mem_addr_i;
				mem_we_o     = `RegWDisable;
				mem_ce_o   = 1'b1;
				case (mem_addr_i[1:0])
					2'b11:	begin
						reg_wdata_o   = {{24{mem_data_i[31]}},mem_data_i[31:24]};
						mem_be_o = 4'b1000;
					end
					2'b10:	begin
						reg_wdata_o   = {{24{mem_data_i[23]}},mem_data_i[23:16]};
						mem_be_o = 4'b0100;
					end
					2'b01:	begin
						reg_wdata_o   = {{24{mem_data_i[15]}},mem_data_i[15:8]};
						mem_be_o = 4'b0010;
					end
					2'b00:	begin
						reg_wdata_o   = {{24{mem_data_i[7]}},mem_data_i[7:0]};
						mem_be_o = 4'b0001;
					end
					default:	begin
						reg_wdata_o   = 32'b0;
					end
				endcase
			end
			
			`EXE_SB_OP:	begin
				mem_addr_o = mem_addr_i;
				mem_we_o     = `RegWEnable;
				mem_data_o = {reg2_data[7:0],reg2_data[7:0],reg2_data[7:0],reg2_data[7:0]};
				mem_ce_o   = 1'b1;
				case (mem_addr_i[1:0])
					2'b11:	begin
						mem_be_o = 4'b1000;
					end
					2'b10:	begin
						mem_be_o = 4'b0100;
					end
					2'b01:	begin
						mem_be_o = 4'b0010;
					end
					2'b00:	begin
						mem_be_o = 4'b0001;	
					end
					default:	begin
						mem_be_o = 4'b0000;
					end
				endcase				
			end

            default: begin    
			end

			endcase		
		end
	end
			

endmodule