`include "defines.v"

module regfile(

	input  wire		   clk,
	input  wire		   rst,
	
	// write port
	input  wire		   we,
	input  wire [31:0] waddr,
	input  wire [31:0] wdata,
	
	// read port1
	input  wire		   reg1_oe,
	input  wire [31:0] reg1_addr,
	output reg  [31:0] reg1_data,
	
	// read port2
	input  wire		   reg2_oe,
	input  wire [31:0] reg2_addr,
	output reg  [31:0] reg2_data
	
);

	reg [31:0]  regs[0:31];
	
	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if ((we == `RegWEnable) && (waddr != 5'h0)) begin
				regs[waddr] <= wdata;
			end 
			else if(waddr == 5'h0) begin
			    regs[waddr] <= 32'b0;
		    end
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			reg1_data = 32'b0;
	  	end 
		else if(reg1_addr == 5'h0) begin
	  		reg1_data = 32'b0;
	  	end 
		else if((reg1_addr == waddr) && (we == `RegWEnable) && (reg1_oe == `RegREnable)) begin
	  	  	reg1_data = wdata;
	  	end 
		else if(reg1_oe == `RegREnable) begin
	      	reg1_data = regs[reg1_addr];
	  	end 
		else begin
	      	reg1_data = 32'b0;
	  	end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			reg2_data = 32'b0;
	  	end 
		else if(reg2_addr == 5'h0) begin
	  		reg2_data = 32'b0;
	  	end 
		else if((reg2_addr == waddr) && (we == `RegWEnable) && (reg2_oe == `RegREnable)) begin
	  	  	reg2_data = wdata;
	  	end 
		else if(reg2_oe == `RegREnable) begin
	      	reg2_data = regs[reg2_addr];
	  	end 
		else begin
			reg2_data = 32'b0;
		end
	end

endmodule