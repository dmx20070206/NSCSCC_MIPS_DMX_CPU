`include "defines.v"

module ex_mem(

	input wire					 clk,
	input wire					 rst,

	input wire [            5:0] stall,	

	// signals from the ex phase	
	input wire [            4:0] ex_reg_waddr,
	input wire                   ex_reg_we,
	input wire [           31:0] ex_reg_wdata, 	

	input wire [`AluOpBus - 1:0] ex_alu_op,
	input wire [           31:0] ex_mem_addr,
	input wire [           31:0] ex_reg2_data,
	
	// signals from the mem phase
	output reg [            4:0] mem_reg_waddr,
	output reg                   mem_reg_we,
	output reg [           31:0] mem_reg_wdata,
	
	output reg [`AluOpBus - 1:0] mem_alu_op,
	output reg [           31:0] mem_addr,
	output reg [           31:0] mem_reg2_data
	
	
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			mem_reg_waddr <= 32'b0;
			mem_reg_we    <= `RegWDisable;
		    mem_reg_wdata <= 32'b0;	
		    mem_alu_op    <= `EXE_NOP_OP;
			mem_addr      <= 32'b0;
			mem_reg2_data <= 32'b0;	
		end 
		else begin
			if(stall[3] == `Stop && stall[4] == `NoStop) begin
				mem_reg_waddr <= 32'b0;
				mem_reg_we    <= `RegWDisable;
		    	mem_reg_wdata <= 32'b0;		
		    	mem_alu_op    <= `EXE_NOP_OP;
				mem_addr      <= 32'b0;
				mem_reg2_data <= 32'b0;		  				    
			end 
			else if(stall[3] == `NoStop) begin
				mem_reg_waddr <= ex_reg_waddr;
				mem_reg_we    <= ex_reg_we;
				mem_reg_wdata <= ex_reg_wdata;	
				mem_alu_op    <= ex_alu_op;
				mem_addr      <= ex_mem_addr;
				mem_reg2_data <= ex_reg2_data;	
			end 
			else begin
				mem_reg_waddr <= mem_reg_waddr;
				mem_reg_we    <= mem_reg_we;
				mem_reg_wdata <= mem_reg_wdata;	
				mem_alu_op    <= mem_alu_op;
				mem_addr      <= mem_addr;
				mem_reg2_data <= mem_reg2_data;							
			end  		
		end
	end 

endmodule