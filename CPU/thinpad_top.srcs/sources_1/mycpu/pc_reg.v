`include "defines.v"

module pc_reg(

	input  wire		   clk,
	input  wire		   rst,
	input  wire [ 5:0] stall,
	

	
	input  wire        branch_flag,
	input  wire [31:0] branch_target_address,
	
	output reg  [31:0] pc,
	output reg         ce 
	
);

	always @ (posedge clk) begin
		if (ce == 1'b0) begin
			pc <= 32'h00000000;
		end 
		else begin
            if (stall[0]==`NoStop) begin
                if (branch_flag == `Branch) begin
                    pc <= branch_target_address;
                end 
				else begin
                    pc <= pc + 4'h4;
                end 
            end 
			else begin
                pc <= pc;
            end 
		end 
	end
	
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= 1'b0;
		end 
		else begin
			ce <= 1'b1;
		end
	end

endmodule