`include "defines.v"

module ctrl(
	input wire					rst,

	// ���Ը����׶ε���ͣ�ź�
    input wire                  stop_inst,
	input wire                  stallreq_from_id,
	input wire                  stallreq_from_ex,
	input wire                  stallreq_from_dcache,
	input wire                  stallreq_from_icache,

	// �����ģ�鷢�͵���ͣ�ź�
	// stall[0]  stall[1]  stall[2]  stall[3]  stall[4]  stall[5]
    //   PC��ַ      ȡָ      ����       ִ��      �ô�      ��д  �׶��Ƿ�ֹͣ
	output reg [5:0]            stall       
	
);

	// ������ͣ�źŵ���Դ���� stall �ź�
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