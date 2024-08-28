`include "defines.v"
// SLT, SRAV, BLEZ
// ori lui addu bne lw sw andi or xor addiu beq lb sb sll
// and andi lui or ori xor xori sll srl addu addiu beq bgtz bne j jal jr lb sb lw sw
// and xori srl bgtz j jal jr 
module id(

	input  wire					   rst,

	// signals received from the if phase
	input  wire [            31:0] pc,
	input  wire [            31:0] inst_data,
	
	// processing Load correlation
	input  wire [ `AluOpBus - 1:0] ex_alu_op,
	
    // regfile returns information
	input  wire [            31:0] reg1_data,
	input  wire [            31:0] reg2_data,

    // data forwarding
    // ex phase data forwarding
	input  wire					   pre_ex_wreg,
	input  wire [            31:0] pre_ex_wdata,
	input  wire [             4:0] pre_ex_wd,
	
	// mem phase data forwarding
	input  wire					   pre_mem_wreg,
	input  wire [            31:0] pre_mem_wdata,
	input  wire [             4:0] pre_mem_wd,
	
    // delay slot
    input  wire                    is_in_delayslot_i,

	// signals sent to regfile
	output reg                     reg1_oe,
	output reg                     reg2_oe,     
	output reg  [             4:0] reg1_addr,
	output reg  [             4:0] reg2_addr, 	      
	
	// signals sent to ex
	output reg  [ `AluOpBus - 1:0] alu_op,
	output reg  [`AluSelBus - 1:0] alu_sel,
	output reg  [            31:0] reg1_data_o,
	output reg  [            31:0] reg2_data_o,
	output reg  [             4:0] reg_waddr,
	output reg                     reg_we,
	
	// delay slot
	output reg                     next_inst_in_delayslot_o,
	
	output reg                     branch_flag,
	output reg  [            31:0] branch_target_address,       
	output reg  [            31:0] link_addr,
	output reg                     is_in_delayslot_o,

	output wire [            31:0] inst_data_o,
	
	output wire                    stall_from_id         
);

	wire [ 5:0] inst_31_26 = inst_data[31:26];
	wire [ 4:0] inst_25_21 = inst_data[25:21];
	wire [ 4:0] inst_20_16 = inst_data[20:16];
	wire [ 4:0] inst_15_11 = inst_data[15:11];
	wire [ 4:0] inst_10_6  = inst_data[10: 6];
	wire [ 5:0] inst_5_0   = inst_data[ 5: 0];	

  	reg [31:0] imm;
  	reg        instvalid;
  
  	// delay slot
  	wire [31:0] pc_plus_8;
  	wire [31:0] pc_plus_4;
  	wire [31:0] imm_Bbranch;  
  
  	assign pc_plus_8 = pc + 4'h8;
  	assign pc_plus_4 = pc + 4'h4;
  	assign imm_Bbranch = {{14{inst_data[15]}}, inst_data[15:0], 2'b00};
  
    assign inst_data_o = inst_data;
 
    // processing load correlation
    reg  stallreq_for_reg1_loadrelate;
    reg  stallreq_for_reg2_loadrelate;
    wire pre_inst_is_load;

  	// pipeline pause
    assign stall_from_id = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
    assign pre_inst_is_load = (ex_alu_op == `EXE_LW_OP) || (ex_alu_op == `EXE_LB_OP);
      
    
	always @ (*) begin	
		if (rst == `RstEnable) begin
			alu_op                   = `EXE_NOP_OP;
			alu_sel                  = `EXE_RES_NOP;
			reg_waddr                = 5'b0;
			reg_we                   = `RegWDisable;
			instvalid                = 1'b1;
			reg1_oe                  = 1'b0;
			reg2_oe                  = 1'b0;
			reg1_addr                = 5'b0;
			reg2_addr                = 5'b0;
			imm                      = 32'h0;		
			link_addr                = 32'b0;
			branch_target_address    = 32'b0;
			branch_flag              = `NotBranch;
			next_inst_in_delayslot_o = 1'b0;	
	  	end 
	  	else begin
			alu_op                   = `EXE_NOP_OP;
			alu_sel                  = `EXE_RES_NOP;
			reg_waddr                = inst_15_11;
			reg_we                   = `RegWDisable;
			instvalid                = 1'b0;	   
			reg1_oe                  = 1'b0;
			reg2_oe                  = 1'b0;
			reg1_addr                = inst_25_21;
			reg2_addr                = inst_20_16;		
			imm                      = 32'b0;			
			link_addr                = 32'b0;
            branch_target_address    = 32'b0;
            branch_flag              = `NotBranch;			
			next_inst_in_delayslot_o = 1'b0; 

		  	case (inst_31_26)

		  	`EXE_SPECIAL_INST:	begin
		    	case (inst_10_6)
		    		5'b00000: begin
		    			case (inst_5_0)

						// one of three special instructions
						`EXE_SRAV: begin
                        	reg_we    = `RegWEnable;
							alu_op    = `EXE_SRAV_OP;
							alu_sel   = `EXE_RES_SHIFT;
							reg1_oe   = 1'b1;
							reg2_oe   = 1'b1;
							instvalid = 1'b1;
						end

						// one of three special instructions
						`EXE_SLT: begin
							reg_we    = `RegWEnable;
							alu_op    = `EXE_SLT_OP;
							alu_sel   = `EXE_RES_ARITHMETIC;
							reg1_oe   = 1'b1;
							reg2_oe   = 1'b1;
							instvalid = 1'b1;
						end

						`EXE_SLTU: begin
							reg_we    = `RegWEnable;
							alu_op    = `EXE_SLTU_OP;
							alu_sel   = `EXE_RES_ARITHMETIC;
							reg1_oe   = 1'b1;
							reg2_oe   = 1'b1;
							instvalid = 1'b1;
						end

		    			`EXE_ADDU: begin
							reg_we    = `RegWEnable;		
							alu_op    = `EXE_ADDU_OP;
		  					alu_sel   = `EXE_RES_ARITHMETIC;		
							reg1_oe   = 1'b1;	
							reg2_oe   = 1'b1;
		  					instvalid = 1'b1;	
						end

						`EXE_OR:	begin
		    				reg_we    = `RegWEnable;		
							alu_op    = `EXE_OR_OP;
		  					alu_sel   = `EXE_RES_LOGIC; 	
							reg1_oe   = 1'b1;	
							reg2_oe   = 1'b1;
		  					instvalid = 1'b1;	
						end  

		    			`EXE_AND:	begin
		    				reg_we    = `RegWEnable;		
							alu_op    = `EXE_AND_OP;
		  					alu_sel   = `EXE_RES_LOGIC;	 
							reg1_oe   = 1'b1;	
							reg2_oe   = 1'b1;	
		  					instvalid = 1'b1;	
						end  	

		    			`EXE_XOR:	begin
		    				reg_we    = `RegWEnable;		
							alu_op    = `EXE_XOR_OP;
		  					alu_sel   = `EXE_RES_LOGIC;		
							reg1_oe   = 1'b1;	
							reg2_oe   = 1'b1;	
		  					instvalid = 1'b1;	
						end  

		  				`EXE_JR: begin
							reg_we                   = `RegWDisable;		
							alu_op                   = `EXE_JR_OP;
		  					alu_sel                  = `EXE_RES_JUMP_BRANCH;   
							reg1_oe                  = 1'b1;	
							reg2_oe                  = 1'b0;
		  					link_addr                = 32'b0;	  						
			            	branch_target_address    = reg1_data_o;
			                branch_flag              = `Branch;			           
			                next_inst_in_delayslot_o = 1'b1;
			                instvalid                = 1'b1;	
						end

						default:	begin
						end
						
						endcase
					end

					default: begin
					end
				endcase	
			end

		  	`EXE_ORI:			begin
		  		reg_we    = `RegWEnable;		
				alu_op    = `EXE_OR_OP;
		  		alu_sel   = `EXE_RES_LOGIC; 
				reg1_oe   = 1'b1;	
				reg2_oe   = 1'b0;	  	
				imm       = {16'h0, inst_data[15:0]};		
				reg_waddr = inst_20_16;
				instvalid = 1'b1;	
		  	end 	

		  	`EXE_LUI:			begin
		  		reg_we    = `RegWEnable;		
				alu_op    = `EXE_OR_OP;
		  		alu_sel   = `EXE_RES_LOGIC; 
				reg1_oe   = 1'b1;	
				reg2_oe   = 1'b0;	  	
				imm       = {inst_data[15:0], 16'h0};		
				reg_waddr = inst_20_16;		  	
				instvalid = 1'b1;	
			end	

			`EXE_ANDI:			begin
		  		reg_we    = `RegWEnable;		
				alu_op    = `EXE_AND_OP;
		  		alu_sel   = `EXE_RES_LOGIC;	
				reg1_oe   = 1'b1;	
				reg2_oe   = 1'b0;	  	
				imm       = {16'h0, inst_data[15:0]};		
				reg_waddr = inst_20_16;		  	
				instvalid = 1'b1;	
			end	 	

		  	`EXE_XORI:			begin
		  		reg_we    = `RegWEnable;		
				alu_op    = `EXE_XORI_OP;
		  		alu_sel   = `EXE_RES_LOGIC;	
				reg1_oe   = 1'b1;	
				reg2_oe   = 1'b0;	  	
				imm       = {16'b0, inst_data[15:0]};		
				reg_waddr = inst_20_16;		  	
				instvalid = 1'b1;	
			end	

			`EXE_ADDIU:			begin
		  		reg_we    = `RegWEnable;		
				alu_op    = `EXE_ADDIU_OP;
		  		alu_sel   = `EXE_RES_ARITHMETIC; 
				reg1_oe   = 1'b1;	
				reg2_oe   = 1'b0;	  	
				imm       = {{16{inst_data[15]}}, inst_data[15:0]};		
				reg_waddr = inst_20_16;		  	
				instvalid = 1'b1;	
			end

			`EXE_J:			begin
		  		reg_we                   = `RegWDisable;		
				alu_op                   = `EXE_J_OP;
		  		alu_sel                  = `EXE_RES_JUMP_BRANCH; 
				reg1_oe                  = 1'b0;	
				reg2_oe                  = 1'b0;
		  		link_addr                = 32'b0;
			    branch_target_address    = {pc_plus_4[31:28], inst_data[25:0], 2'b00};
			    branch_flag              = `Branch;
			    next_inst_in_delayslot_o = 1'b1;		  	
			    instvalid                = 1'b1;	
			end

			`EXE_JAL:			begin
		  		reg_we                   = `RegWEnable;		
				alu_op                   = `EXE_JAL_OP;
		  		alu_sel                  = `EXE_RES_JUMP_BRANCH; 
				reg1_oe                  = 1'b0;	
				reg2_oe                  = 1'b0;
		  		reg_waddr                = 5'b11111;	
		  		link_addr                = pc_plus_8 ;
			    branch_target_address    = {pc_plus_4[31:28], inst_data[25:0], 2'b00};
			    branch_flag              = `Branch;
			    next_inst_in_delayslot_o = 1'b1;		  	
			    instvalid                = 1'b1;	
			end

			`EXE_BEQ:			begin
		  		reg_we    = `RegWDisable;		
				alu_op    = `EXE_BEQ_OP;
		  		alu_sel   = `EXE_RES_JUMP_BRANCH; 
				reg1_oe   = 1'b1;	
				reg2_oe   = 1'b1;
		  		instvalid = 1'b1;	
		  		if(reg1_data_o == reg2_data_o) begin
			    	branch_target_address    = pc_plus_4 + imm_Bbranch;
			    	branch_flag              = `Branch;
			    	next_inst_in_delayslot_o = 1'b1;		  	
			    end 
				else begin
			        branch_target_address    = 32'b0;
			        branch_flag              = `NotBranch;	
			        next_inst_in_delayslot_o = 1'b0; 
			    end
			end

			`EXE_BGTZ:			begin
		  		reg_we    = `RegWDisable;		
				alu_op    = `EXE_BGTZ_OP;
		  		alu_sel   = `EXE_RES_JUMP_BRANCH; 
				reg1_oe   = 1'b1;	
				reg2_oe   = 1'b0;
		  		instvalid = 1'b1;	
		  		if((reg1_data_o[31] == 1'b0) && (reg1_data_o != 32'b0)) begin
			    	branch_target_address    = pc_plus_4 + imm_Bbranch;
			    	branch_flag              = `Branch;
			    	next_inst_in_delayslot_o = 1'b1;		  	
			    end 
				else begin
			        branch_target_address    = 32'b0;
			        branch_flag              = `NotBranch;	
			        next_inst_in_delayslot_o = 1'b0; 
			    end
			end

			`EXE_SPECIAL2_INST:		begin
				case (inst_5_0)
					`EXE_MUL:		begin
						reg_we    = `RegWEnable;		
						alu_op    = `EXE_MUL_OP;
		  				alu_sel   = `EXE_RES_MUL; 
						reg1_oe   = 1'b1;	
						reg2_oe   = 1'b1;	
		  				instvalid = 1'b1;	  			
					end

					default: begin
					end
				endcase 
			end			

			`EXE_BNE:			begin
		  		reg_we    = `RegWDisable;		
				alu_op    = `EXE_BNE_OP;
		  		alu_sel   = `EXE_RES_JUMP_BRANCH; 
				reg1_oe   = 1'b1;	
				reg2_oe   = 1'b1;
		  		instvalid = 1'b1;	
		  		if(reg1_data_o != reg2_data_o) begin
			    	branch_target_address    = pc_plus_4 + imm_Bbranch;
			    	branch_flag              = `Branch;
			    	next_inst_in_delayslot_o = 1'b1;		  	
			    end 
				else begin
			        branch_target_address    = 32'b0;
			        branch_flag              = `NotBranch;	
			        next_inst_in_delayslot_o = 1'b0; 
			    end
			end	

			// one of three special instructions
			`EXE_BLEZ: begin
				reg_we    = `RegWDisable;
				alu_op    = `EXE_BLEZ_OP;
				alu_sel   = `EXE_RES_JUMP_BRANCH;
				reg1_oe   = 1'b1;
				reg2_oe   = 1'b0;
				instvalid = 1'b1;
				if(reg1_data_o[31] || reg1_data_o == 32'b0) begin
					branch_target_address    = pc_plus_4 + imm_Bbranch;
			    	branch_flag              = `Branch;
			    	next_inst_in_delayslot_o = 1'b1;
				end
				else begin
					branch_target_address    = 32'b0;
			        branch_flag              = `NotBranch;	
			        next_inst_in_delayslot_o = 1'b0; 
				end
			end

			`EXE_LW: begin
		  		reg_we    = `RegWEnable;		
				alu_op    = `EXE_LW_OP;
		  		alu_sel   = `EXE_RES_LOAD_STORE; 
				reg1_oe   = 1'b1;	
				reg2_oe   = 1'b0;	  	
				reg_waddr = inst_20_16; 
				instvalid = 1'b1;	
			end

            `EXE_SW: begin
            	reg_we    = `RegWDisable;		
				alu_op    = `EXE_SW_OP;
            	reg1_oe   = 1'b1;	
				reg2_oe   = 1'b1; 
				instvalid = 1'b1;	
            	alu_sel   = `EXE_RES_LOAD_STORE; 
            end		

            `EXE_LB: begin
		  		reg_we    = `RegWEnable;		
				alu_op    = `EXE_LB_OP;
		  		alu_sel   = `EXE_RES_LOAD_STORE; 
				reg1_oe   = 1'b1;	
				reg2_oe   = 1'b0;	  	
				reg_waddr = inst_20_16; 
				instvalid = 1'b1;	
			end
			
			`EXE_SB:			begin
		  		reg_we    = `RegWDisable;
				alu_op    = `EXE_SB_OP;
		  		reg1_oe   = 1'b1;	
				reg2_oe   = 1'b1; 
				instvalid = 1'b1;	
		  		alu_sel   = `EXE_RES_LOAD_STORE; 
			end			

		    default: begin
		    end

			endcase	  
			
			// SLL/SRL ָ
			if(inst_data[31:21] == 11'b0) begin
				if(inst_5_0 == `EXE_SLL) begin
					reg_we    = `RegWEnable;		
					alu_op    = `EXE_SLL_OP;
					alu_sel   = `EXE_RES_SHIFT; 
					reg1_oe   = 1'b0;	
					reg2_oe   = 1'b1;	  	
					imm[4:0]  = inst_10_6;		
					reg_waddr = inst_15_11;
					instvalid = 1'b1;	
				end
				else if(inst_5_0 == `EXE_SRL) begin
					reg_we    = `RegWEnable;
					alu_op    = `EXE_SRL_OP;
					alu_sel   = `EXE_RES_SHIFT; 
					reg1_oe   = 1'b0;
					reg2_oe   = 1'b1;
					imm[4:0]  = inst_10_6;		
					reg_waddr = inst_15_11;
					instvalid = 1'b1;	
				end
			end
		end 
	end 

	always @ (*) begin
		stallreq_for_reg1_loadrelate = `NoStop;
		if(rst == `RstEnable) begin
			reg1_data_o = 32'b0;
		end 
		else if(pre_inst_is_load == 1'b1 && pre_ex_wd == reg1_addr && reg1_oe == 1'b1 ) begin
		  	stallreq_for_reg1_loadrelate = `Stop;	
        end 
		else if((reg1_oe == 1'b1) && (pre_ex_wreg == 1'b1) && (pre_ex_wd == reg1_addr)) begin
        	reg1_data_o = pre_ex_wdata; 
      	end 
		else if((reg1_oe == 1'b1) && (pre_mem_wreg == 1'b1) && (pre_mem_wd == reg1_addr)) begin
     		reg1_data_o = pre_mem_wdata; 	
	  	end 
		else if(reg1_oe == 1'b1) begin
	  		reg1_data_o = reg1_data;
	  	end 
		else if(reg1_oe == 1'b0) begin
	  		reg1_data_o = imm;
	  	end else begin
	    	reg1_data_o = 32'b0;
	  	end
	end
	
	always @ (*) begin
		stallreq_for_reg2_loadrelate = `NoStop;
		if(rst == `RstEnable) begin
			reg2_data_o = 32'b0;
		end 
		else if(pre_inst_is_load == 1'b1 && pre_ex_wd == reg2_addr && reg2_oe == 1'b1 ) begin
		  	stallreq_for_reg2_loadrelate = `Stop;	
		end 
		else if((reg2_oe == 1'b1) && (pre_ex_wreg == 1'b1) && (pre_ex_wd == reg2_addr)) begin
			reg2_data_o = pre_ex_wdata; 
		end 
		else if((reg2_oe == 1'b1) && (pre_mem_wreg == 1'b1) && (pre_mem_wd == reg2_addr)) begin
			reg2_data_o = pre_mem_wdata;		
	  	end
		else if(reg2_oe == 1'b1) begin
	  		reg2_data_o = reg2_data;
	  	end 
		else if(reg2_oe == 1'b0) begin
	  		reg2_data_o = imm;
	  	end 
		else begin
	    	reg2_data_o = 32'b0;
	  	end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			is_in_delayslot_o = 1'b0;
		end 
		else begin
		  	is_in_delayslot_o = is_in_delayslot_i;		
	  end
	end

	

endmodule
