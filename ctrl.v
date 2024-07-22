`include "defines.v"

module ctrl(
	input wire					rst,

	// pause signals from all stages
    input wire                  stop_inst,
	input wire                  stallreq_from_id,
	input wire                  stallreq_from_ex,
	input wire                  stallreq_from_dcache,
	input wire                  stallreq_from_icache,

	// final pause signal sent to each Module
	// stall[0]  stall[1]  stall[2]  stall[3]  stall[4]  stall[5]
    // pc        if        id        ex        mem       wb       phase stopped or not
	output reg [5:0]            stall       
	
);

	// set the stall signal according to the source of the pause signal
	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
		end
		else if(stallreq_from_icache == `Stop) begin
			stall <= 6'b111111;				
		end 
		else if(stallreq_from_dcache == `Stop)begin
			stall <= 6'b111111;
		end 
		else if(stallreq_from_ex == `Stop) begin
			stall <= 6'b001111;
		end 
		else if(stallreq_from_id == `Stop) begin
			stall <= 6'b000111;			
		end 
		else if(stop_inst == `Stop) begin
			stall <= 6'b000111;			
		end 
		else begin
			stall <= 6'b000000;
		end
	end
			

endmodule