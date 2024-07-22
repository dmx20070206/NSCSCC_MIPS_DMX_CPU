`include "defines.v"

module if_id(

	input  wire		   clk,
	input  wire		   rst,
	input  wire [ 5:0] stall,

	input  wire [31:0] if_pc,
	input  wire [31:0] if_inst,
	output reg  [31:0] id_pc,
	output reg  [31:0] id_inst  
	
);
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			id_pc   <= 32'b0;
			id_inst <= 32'b0;
	    end 
		else begin
	        if(stall[1]==`Stop && stall[2]==`NoStop) begin
	           id_pc   <= 32'b0;
			   id_inst <= 32'b0;
	        end 
		    else if(stall[1]==`NoStop) begin
		       id_pc   <= if_pc;
		       id_inst <= if_inst;
		    end 
		    else begin
		       id_pc   <= id_pc;
		       id_inst <= id_inst;
		   end
	   end
	end

endmodule