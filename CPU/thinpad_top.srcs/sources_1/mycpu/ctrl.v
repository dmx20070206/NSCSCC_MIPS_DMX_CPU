`include "defines.v"

module ctrl(
	input wire					rst,

	// 来自各个阶段的暂停信号
    input wire                  stop_inst,
	input wire                  stallreq_from_id,
	input wire                  stallreq_from_ex,
	input wire                  stallreq_from_dcache,
	input wire                  stallreq_from_icache,

	// 向各个模块发送的暂停信号
	// stall[0]  stall[1]  stall[2]  stall[3]  stall[4]  stall[5]
    //   PC地址      取指      译码       执行      访存      回写  阶段是否停止
	output reg [5:0]            stall       
	
);

	// 根据暂停信号的来源设置 stall 信号
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