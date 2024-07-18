`include "defines.v"

module id_ex(
	input  wire					   clk,
	input  wire					   rst,
	
	// 从译码阶段传递的信息
	input  wire [ `AluOpBus - 1:0] id_alu_op,
	input  wire [`AluSelBus - 1:0] id_alu_sel,
	input  wire [            31:0] id_reg1_data,
	input  wire [            31:0] id_reg2_data,
	input  wire [            31:0] id_reg_waddr,
	input  wire                    id_reg_we,	
	input  wire [             5:0] stall,

	// 延迟槽 
	input  wire [            31:0] id_link_address,
	input  wire                    id_is_in_delayslot,
	input  wire                    next_inst_in_delayslot_i,		

	input  wire [            31:0] id_inst_data,
	
	// 传递到执行阶段的信息
	output reg  [ `AluOpBus - 1:0] ex_alu_op,
	output reg  [`AluSelBus - 1:0] ex_alu_sel,
	output reg  [            31:0] ex_reg1_data,
	output reg  [            31:0] ex_reg2_data,
	output reg  [             4:0] ex_reg_waddr,
	output reg                     ex_reg_we,

	// 延迟槽
	output reg  [            31:0] ex_link_address,
    output reg                     ex_is_in_delayslot,
	output reg                     is_in_delayslot_o,

	output reg  [            31:0] ex_inst_data
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ex_alu_op          <= `EXE_NOP_OP;
			ex_alu_sel         <= `EXE_RES_NOP;
			ex_reg1_data            <= 32'b0;
			ex_reg2_data            <= 32'b0;
			ex_reg_waddr              <= 32'b0;
			ex_reg_we            <= `RegWDisable;
			ex_link_address    <= 32'b0;
			ex_is_in_delayslot <= 1'b0;
	        is_in_delayslot_o  <= 1'b0;	
	        ex_inst_data            <= 32'b0;
		end 
		else begin		
			if(stall[2] == `Stop && stall[3] == `NoStop) begin
                ex_alu_op          <= `EXE_NOP_OP;
                ex_alu_sel         <= `EXE_RES_NOP;
                ex_reg1_data            <= 32'b0;
                ex_reg2_data            <= 32'b0;
                ex_reg_waddr              <= 32'b0;
                ex_reg_we            <= `RegWDisable;		
                ex_link_address    <= 32'b0;
	            ex_is_in_delayslot <= 1'b0;
	            ex_inst_data            <= 32'b0;	
            end 
			else if(stall[2] == `NoStop) begin		
                ex_alu_op          <= id_alu_op;
                ex_alu_sel         <= id_alu_sel;
                ex_reg1_data            <= id_reg1_data;
                ex_reg2_data            <= id_reg2_data;
                ex_reg_waddr              <= id_reg_waddr;
                ex_reg_we            <= id_reg_we;	
                ex_link_address    <= id_link_address;
			    ex_is_in_delayslot <= id_is_in_delayslot;
	            is_in_delayslot_o  <= next_inst_in_delayslot_i;
	            ex_inst_data            <= id_inst_data;		
            end 
			else begin
                ex_alu_op          <= ex_alu_op;
                ex_alu_sel         <= ex_alu_sel;
                ex_reg1_data            <= ex_reg1_data;
                ex_reg2_data            <= ex_reg2_data;
                ex_reg_waddr              <= ex_reg_waddr;
                ex_reg_we            <= ex_reg_we;	
                ex_link_address    <= ex_link_address;
			    ex_is_in_delayslot <= ex_is_in_delayslot;
	            is_in_delayslot_o  <= is_in_delayslot_o;	
	            ex_inst_data            <= ex_inst_data;
            end
		end
	end
	
endmodule