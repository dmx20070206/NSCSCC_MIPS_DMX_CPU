`include "defines.v"

module mem_wb(

	input  wire		   clk,
	input  wire		   rst,
	
	// 来自暂停阶段的信息
    input  wire [ 5:0] stall,

	// 来自访存阶段的信息	
	input  wire [ 4:0] mem_reg_waddr,
	input  wire        mem_reg_we,
	input  wire [31:0] mem_reg_wdata,

	// 送到回写阶段的信息
	output reg  [ 4:0] wb_reg_waddr,
	output reg         wb_reg_we,
	output reg  [31:0] wb_reg_wdata	       
	
);
	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			wb_reg_waddr    <= 5'b0;
			wb_reg_we  <= `RegWDisable;
		    wb_reg_wdata <= 32'b0;	
		end 
		else begin
			if(stall[4] == `Stop && stall[5] == `NoStop) begin
				wb_reg_waddr    <= 5'b0;
				wb_reg_we  <= `RegWDisable;
		    	wb_reg_wdata <= 32'b0;		  	  
			end 
			else if(stall[4] == `NoStop) begin
				wb_reg_waddr    <= mem_reg_waddr;
				wb_reg_we  <= mem_reg_we;
				wb_reg_wdata <= mem_reg_wdata;	
			end 
			else begin
		    	wb_reg_waddr    <= wb_reg_waddr ;
				wb_reg_we  <= wb_reg_we;
				wb_reg_wdata <= wb_reg_wdata;	
			end
		end
	end
			

endmodule