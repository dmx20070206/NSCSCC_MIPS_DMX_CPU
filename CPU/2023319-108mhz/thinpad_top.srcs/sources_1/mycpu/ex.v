`include "defines.v"

module ex(

	input  wire				       rst,
	
	//送到执行阶段的信息
	input  wire [ `AluOpBus - 1:0] alu_op_i,
	input  wire [`AluSelBus - 1:0] alu_sel_i,
	input  wire [            31:0] reg1_data,
	input  wire [            31:0] reg2_data,
	input  wire [             4:0] reg_waddr,
	input  wire                    reg_we,

    // 延迟槽
    input  wire [            31:0] link_address_i,
	input  wire                    is_in_delayslot_i,	

	// 当前指令
	input  wire [            31:0] inst_data,
	
	output reg  [             4:0] reg_waddr_o,
	output reg                     reg_we_o,
	output reg  [            31:0] reg_wdata_o,

	//访存
	output wire [ `AluOpBus - 1:0] alu_op_o,
	output wire [            31:0] mem_addr_o,
	output wire [            31:0] reg2_data_o,
	
	output reg					   stall_from_ex 
);

	// 根据 alu_op 决定的运算大类
	reg  [31:0] alu_result_logic;
	reg  [31:0] alu_result_shift;
	reg  [31:0] alu_result_arithmeticres;

	wire signed [63:0] mulres;	
	wire        [31:0] result_sum;

	wire [31:0] opdata1_mult;
	wire [31:0] opdata2_mult;
	
	// 判断两个计算数的大小
	wire   reg1_lt_reg2;
	assign reg1_lt_reg2 = $signed(reg1_data) < $signed(reg2_data) ? 1'b1 : 1'b0;

	// 加法计算
	assign result_sum = reg1_data + reg2_data;		
	
	// 乘法计算
	assign mulres = $signed(reg1_data) * $signed(reg2_data);

	// 送到访存的信息
    assign alu_op_o = alu_op_i;
    assign mem_addr_o = reg1_data + {{16{inst_data[15]}}, inst_data[15:0]};
    assign reg2_data_o = reg2_data;
	
	// 逻辑运算部分
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
	
	// 移位运算部分
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
	
	// 算数运算部分
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
                default: begin
					alu_result_arithmeticres = 32'b0;
				end
			endcase
		end
	end
																			
	// 根据 alu_sel 决定输出的运算结果
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