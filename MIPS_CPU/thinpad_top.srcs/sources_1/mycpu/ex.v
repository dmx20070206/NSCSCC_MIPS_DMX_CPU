`include "defines.v"

module ex(

	input  wire				       rst,
	
	// signals sent to the ex phase
	input  wire [ `AluOpBus - 1:0] alu_op_i,
	input  wire [`AluSelBus - 1:0] alu_sel_i,
	input  wire [            31:0] reg1_data,
	input  wire [            31:0] reg2_data,
	input  wire [             4:0] reg_waddr,
	input  wire                    reg_we,

    // delay slot
    input  wire [            31:0] link_address_i,
	input  wire                    is_in_delayslot_i,	

	// current inst
	input  wire [            31:0] inst_data,
	
	output reg  [             4:0] reg_waddr_o,
	output reg                     reg_we_o,
	output reg  [            31:0] reg_wdata_o,

	output wire [ `AluOpBus - 1:0] alu_op_o,
	output wire [            31:0] mem_addr_o,
	output wire [            31:0] reg2_data_o,
	
	output reg					   stall_from_ex 
);

	// class of operations determined by alu_op
	reg  [31:0] alu_result_logic;
	reg  [31:0] alu_result_shift;
	reg  [31:0] alu_result_arithmeticres;

	wire signed [63:0] mulres;	
	wire        [31:0] result_sum;

	wire [31:0] opdata1_mult;
	wire [31:0] opdata2_mult;
	
	// determine the size of two calculated numbers
	wire   reg1_lt_reg2;
	assign reg1_lt_reg2 = $signed(reg1_data) < $signed(reg2_data) ? 1'b1 : 1'b0;
	wire   reg1_lt_reg2_u;
	assign reg1_lt_reg2_u = $unsigned(reg1_data) < $unsigned(reg2_data) ? 1'b1 : 1'b0;

	// addition calculation
	assign result_sum = reg1_data + reg2_data;		
	
	// multiplication calculation
	assign mulres = $signed(reg1_data) * $signed(reg2_data);

	// send access to the stored information
    assign alu_op_o = alu_op_i;
    assign mem_addr_o = reg1_data + {{16{inst_data[15]}}, inst_data[15:0]};
    assign reg2_data_o = reg2_data;
	
	// logic operation part
	always @ (*) begin
		if(rst == `RstEnable) begin
			alu_result_logic = 32'b0;
		end 
		else begin
			case (alu_op_i)
				`EXE_OR_OP: begin
					alu_result_logic = reg1_data | reg2_data;
				end
				`EXE_AND_OP: begin
					alu_result_logic = reg1_data & reg2_data;
				end
				`EXE_XOR_OP, `EXE_XORI_OP: begin
					alu_result_logic = reg1_data ^ reg2_data;
				end
				default: begin
					alu_result_logic = 32'b0;
				end
			endcase
		end
	end 
	
	// shift operation part
	always @ (*) begin
		if(rst == `RstEnable) begin
			alu_result_shift = 32'b0;
		end 
		else begin
			case (alu_op_i)
				`EXE_SLL_OP: begin
					alu_result_shift = reg2_data << reg1_data[4:0] ;
				end
				`EXE_SRL_OP: begin
					alu_result_shift = reg2_data >> reg1_data[4:0];
				end
				`EXE_SRA_OP, `EXE_SRAV_OP: begin
					alu_result_shift = ($signed(reg2_data)) >>> reg1_data[4:0];
				end
				default: begin
					alu_result_shift = 32'b0;
				end
			endcase
		end
	end
	
	// arithmeticres operation part
    always @ (*) begin
        if(rst == `RstEnable) begin
            alu_result_arithmeticres <= 32'b0;
        end 
		else begin
            case (alu_op_i)
                `EXE_ADDU_OP, `EXE_ADDIU_OP : begin
					alu_result_arithmeticres = result_sum; 
                end
				`EXE_SLT_OP: begin
                	alu_result_arithmeticres = reg1_lt_reg2;
            	end
				`EXE_SLTU_OP: begin
					alu_result_arithmeticres = reg1_lt_reg2_u;
				end
                default: begin
					alu_result_arithmeticres = 32'b0;
				end
			endcase
		end
	end
																			
	// the output result is determined according to alu_sel
    always @ (*) begin
        reg_waddr_o     = reg_waddr;	 	 	
	    reg_we_o   = reg_we;
        stall_from_ex = `NoStop;
        case (alu_sel_i) 
            `EXE_RES_LOGIC: begin
                reg_wdata_o = alu_result_logic;
            end
            `EXE_RES_SHIFT:	begin
	 			reg_wdata_o = alu_result_shift;
	    	end	
            `EXE_RES_ARITHMETIC: begin
	 			reg_wdata_o = alu_result_arithmeticres;
	 	    end
	 	    `EXE_RES_MUL: begin
	 			reg_wdata_o = mulres[31:0];
	       	end	 
	 	    `EXE_RES_JUMP_BRANCH: begin
	 			reg_wdata_o = link_address_i;
	 	    end	
            default: begin
                reg_wdata_o = 32'b0;
            end
    	endcase
    end	

endmodule
