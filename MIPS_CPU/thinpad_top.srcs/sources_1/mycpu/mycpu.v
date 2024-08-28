`include "defines.v"

module mycpu(

	input  wire        clk,
	input  wire		   rst,
 
	input  wire [31:0] inst_data,
	output wire [31:0] inst_vaddr,
	output wire        inst_ce,
	
	input  wire        stop_inst,
	
	input  wire [31:0] ram_rdata,
	output wire [31:0] ram_vaddr,
	output wire [31:0] ram_wdata,

	output wire        ram_we,
	output wire [ 3:0] ram_be,
	output wire        ram_ce
);

	// super, super, super many signals
	wire [`AluSelBus - 1:0] id_alusel_o;	
	wire [`AluSelBus - 1:0] ex_alusel_i;

	wire [ `AluOpBus - 1:0] id_aluop_o;
	wire [ `AluOpBus - 1:0] ex_aluop_i;
	wire [ `AluOpBus - 1:0] ex_aluop_o;
	wire [ `AluOpBus - 1:0] mem_aluop_i;

	wire [            31:0] branch_target_address;
    wire [            31:0] id_link_address_o;
    wire [            31:0] ex_link_address_i;
	wire [            31:0] ram_data_cache_o;
	wire [            31:0] rom_data_icache;
	wire [            31:0] mem_mem_addr_i;
	wire [            31:0] ex_mem_addr_o;
	wire [            31:0] mem_wdata_i;
	wire [            31:0] mem_wdata_o;
	wire [            31:0] mem_reg1_i;
	wire [            31:0] mem_reg2_i;	
	wire [            31:0] wb_wdata_i;
	wire [            31:0] ex_wdata_o;
	wire [            31:0] id_inst_i;
	wire [            31:0] id_reg1_o;
	wire [            31:0] id_reg2_o;
	wire [            31:0] id_inst_o;
	wire [            31:0] ex_reg1_i;
	wire [            31:0] ex_reg2_i;
	wire [            31:0] ex_inst_i;
	wire [            31:0] ex_reg1_o;
	wire [            31:0] ex_reg2_o;
	wire [            31:0] reg1_data;
	wire [            31:0] reg2_data;
	wire [            31:0] id_pc_i;
	wire [            31:0] pc;

	wire [             5:0] stall;

	wire [             4:0] reg1_addr;
	wire [             4:0] reg2_addr;
	wire [             4:0] mem_wd_i;
	wire [             4:0] mem_wd_o;
	wire [             4:0] id_wd_o;
	wire [             4:0] ex_wd_o;
	wire [             4:0] ex_wd_i;
	wire [             4:0] wb_wd_i;

	wire                    next_inst_in_delayslot_o;
	wire                    ex_is_in_delayslot_i;	
	wire                    id_is_in_delayslot_o;
	wire                    stallreq_from_icache;
	wire                    is_in_delayslot_i;
	wire                    is_in_delayslot_o;
	wire                    stallreq_from_id;	
	wire                    stallreq_from_ex;
	wire                    id_branch_flag_o;
	wire                    stall_dcache;
	wire                    mem_wreg_i;
	wire                    mem_wreg_o;
	wire                    id_wreg_o;
	wire                    ex_wreg_i;
	wire                    ex_wreg_o;
	wire                    wb_wreg_i;
 	wire                    reg1_read;
  	wire                    reg2_read;

	//////////////////////////////////////////////////////////////////////////////
	//    pc_reg                                                                //
	//    this Module is used to automatically calculate pc addresses and send  //
	//	  pc addresses to the sram                                              //
	//////////////////////////////////////////////////////////////////////////////
	pc_reg my_pc_reg (
		// input
		.clk                     (clk                  ),
		.rst                     (rst                  ),

		.stall                   (stall                ),
		.branch_flag             (id_branch_flag_o     ),
		.branch_target_address   (branch_target_address),

		// output
		.pc                      (pc                   ),
		.ce                      (inst_ce              )
	);
	assign inst_vaddr = pc;

	//////////////////////////////////////////////////////////////////////////////
	//    ICache                                                                //
	//    This Module is used to store instructions that may be accessed in     //
	//    the future and can be replenished by pausing the pipeline             //
	//////////////////////////////////////////////////////////////////////////////
	ICache my_icache (
		// input
    	.clk        (clk                 ),
    	.rst        (rst                 ),

    	.inst_vaddr (pc                  ),
		.inst_stop  (stop_inst           ),
    	.inst_ce    (inst_ce             ),
    	.inst_i     (inst_data           ),

		// output
    	.inst_data  (rom_data_icache     ),
    	.stall      (stallreq_from_icache)
	);


	//////////////////////////////////////////////////////////////////////////////
	//    if_id                                                                 //
	//    This Module is used to implement the pipeline from the if Module to   //
  	//    the id Module                                                         //
	//////////////////////////////////////////////////////////////////////////////
	if_id my_if2id (
		// input
		.clk     (clk            ),
		.rst     (rst            ),

		.stall   (stall          ),
		.if_pc   (pc             ),
		.if_inst (rom_data_icache),

		// output
		.id_pc   (id_pc_i        ),
		.id_inst (id_inst_i      )      	
	);
	

	
	//////////////////////////////////////////////////////////////////////////////
	//    id                                                                    //
	//    This Module is used to analyze the obtained instructions and pass     //
	//	  the control information to the ex Module, while the Module calculates //
	//    the pc address of the jump (if jump)                                  //
	//////////////////////////////////////////////////////////////////////////////
	id my_id (
		.rst                      (rst                     ),
                
		// send from the Module if
		.pc                       (id_pc_i                 ),
		.inst_data                (id_inst_i               ),

		// load relation
        .ex_alu_op                (ex_aluop_o              ),
        
		// data from regfile
		.reg1_data                (reg1_data               ),
		.reg2_data                (reg2_data               ),
		
		// data conflict
	    .pre_ex_wreg              (ex_wreg_o               ),
		.pre_ex_wdata             (ex_wdata_o              ),
		.pre_ex_wd                (ex_wd_o                 ),
		.pre_mem_wreg             (mem_wreg_o              ),
		.pre_mem_wdata            (mem_wdata_o             ),
		.pre_mem_wd               (mem_wd_o                ),
		
		// send data to regfile
		.reg1_oe                  (reg1_read               ),
		.reg2_oe                  (reg2_read               ), 	  
		.reg1_addr                (reg1_addr               ),
		.reg2_addr                (reg2_addr               ), 
	   
		// send data to the Module ex
		.alu_op                   (id_aluop_o              ),
		.alu_sel                  (id_alusel_o             ),
		.reg1_data_o              (id_reg1_o               ),
		.reg2_data_o              (id_reg2_o               ),
		.reg_waddr                (id_wd_o                 ),
		.reg_we                   (id_wreg_o               ),
		.inst_data_o              (id_inst_o               ),

		// delay slot signal
		.is_in_delayslot_i        (is_in_delayslot_i       ),
		.is_in_delayslot_o        (id_is_in_delayslot_o    ),
		.next_inst_in_delayslot_o (next_inst_in_delayslot_o),	

		// branch and jump
		.branch_flag              (id_branch_flag_o        ),
		.branch_target_address    (branch_target_address   ),       
		.link_addr                (id_link_address_o       ),
		
		// pipeline suspension due to load relation
		.stall_from_id            (stallreq_from_id        )	
	);


	//////////////////////////////////////////////////////////////////////////////
	//    regfile                                                               //
	//    The Module is used to implement 32 registers and read and write 		//
	//	  operations                                                            //
	//////////////////////////////////////////////////////////////////////////////
	regfile my_regfile (
		.clk       (clk       ),
		.rst       (rst       ),

		// write port
		.we	       (wb_wreg_i ),
		.waddr     (wb_wd_i   ),
		.wdata     (wb_wdata_i),

		// read port1
		.reg1_oe   (reg1_read ),
		.reg1_addr (reg1_addr ),
		.reg1_data (reg1_data ),

		// read port2
		.reg2_oe   (reg2_read ),
		.reg2_addr (reg2_addr ),
		.reg2_data (reg2_data )
	);


	//////////////////////////////////////////////////////////////////////////////
	//    id_ex                                                                 //
	//    This Module is used to implement the pipeline from the id Module to   //
  	//    the ex Module                                                         //
	//////////////////////////////////////////////////////////////////////////////
	id_ex my_id2ex (
		// input
		.clk                      (clk                     ),
		.rst                      (rst                     ),
		.stall                    (stall                   ),
		.id_alu_op                (id_aluop_o              ),
		.id_alu_sel               (id_alusel_o             ),
		.id_reg1_data             (id_reg1_o               ),
		.id_reg2_data             (id_reg2_o               ),
		.id_reg_waddr             (id_wd_o                 ),
		.id_reg_we                (id_wreg_o               ),
		.id_inst_data             (id_inst_o               ),
		.id_link_address          (id_link_address_o       ),
		.id_is_in_delayslot       (id_is_in_delayslot_o    ),
		.next_inst_in_delayslot_i (next_inst_in_delayslot_o),
	
		// output
		.ex_alu_op                (ex_aluop_i              ),
		.ex_alu_sel               (ex_alusel_i             ),
		.ex_reg1_data             (ex_reg1_i               ),
		.ex_reg2_data             (ex_reg2_i               ),
		.ex_reg_waddr             (ex_wd_i                 ),
		.ex_reg_we                (ex_wreg_i               ),
		.ex_inst_data             (ex_inst_i               ),
		.ex_link_address          (ex_link_address_i       ),
    	.ex_is_in_delayslot       (ex_is_in_delayslot_i    ),
		.is_in_delayslot_o        (is_in_delayslot_i       )	
	);		
	

	//////////////////////////////////////////////////////////////////////////////
	//    ex                                                                    //
	//    The Module calculates the results of various operation types based on //
	//    the information from the id Module                                    //
	//////////////////////////////////////////////////////////////////////////////
	ex my_ex (
		// input
		.rst               (rst                 ),
		.alu_op_i          (ex_aluop_i          ),
		.alu_sel_i         (ex_alusel_i         ),
		.reg1_data         (ex_reg1_i           ),
		.reg2_data         (ex_reg2_i           ),
		.reg_waddr         (ex_wd_i             ),
		.reg_we            (ex_wreg_i           ),
	  	.inst_data         (ex_inst_i           ),
	  
		// output
		.reg_waddr_o       (ex_wd_o             ),
		.reg_we_o          (ex_wreg_o           ),
		.reg_wdata_o       (ex_wdata_o          ),
		.link_address_i    (ex_link_address_i   ),
		.is_in_delayslot_i (ex_is_in_delayslot_i),	
		.alu_op_o          (ex_aluop_o          ),
		.mem_addr_o        (ex_mem_addr_o       ),
		.reg2_data_o       (ex_reg2_o           ),
		.stall_from_ex     (stallreq_from_ex    )  
	);


	//////////////////////////////////////////////////////////////////////////////
	//    ex_mem                                                                //
	//    This Module is used to implement the pipeline from the ex Module to   //
  	//    the mem Module                                                        //
	//////////////////////////////////////////////////////////////////////////////
  	ex_mem my_ex2mem(
		// input
		.clk          (clk            ),
		.rst          (rst            ),
	  	.stall        (stall          ),
		.ex_reg_waddr (ex_wd_o        ),
		.ex_reg_we    (ex_wreg_o      ),
		.ex_reg_wdata (ex_wdata_o     ),
	   	.ex_alu_op    (ex_aluop_o     ),
		.ex_mem_addr  (ex_mem_addr_o  ),
		.ex_reg2_data (ex_reg2_o      ),
	
		// output
		.mem_reg_waddr (mem_wd_i      ),
		.mem_reg_we    (mem_wreg_i    ),
		.mem_reg_wdata (mem_wdata_i   ),
		.mem_alu_op    (mem_aluop_i   ),
		.mem_addr      (mem_mem_addr_i),
		.mem_reg2_data (mem_reg2_i    )
	);


	//////////////////////////////////////////////////////////////////////////////
	//    mem                                                                   //
	//    this Module can read and write memory operations  				    //
	//////////////////////////////////////////////////////////////////////////////
	mem my_mem(
		// input
		.rst         (rst           ),
		.reg_waddr   (mem_wd_i      ),
		.reg_we      (mem_wreg_i    ),
		.reg_wdata   (mem_wdata_i   ),
	    .alu_op      (mem_aluop_i   ),
		.mem_addr_i  (mem_mem_addr_i),
		.reg2_data   (mem_reg2_i    ),
		.mem_data_i  (ram_rdata     ),		
		
		// output
		.reg_waddr_o (mem_wd_o      ),
		.reg_we_o    (mem_wreg_o    ),
		.reg_wdata_o (mem_wdata_o   ),
        .mem_addr_o  (ram_vaddr     ),
		.mem_we_o    (ram_we        ),
		.mem_be_o    (ram_be        ),
		.mem_data_o  (ram_wdata     ),
		.mem_ce_o    (ram_ce        )   		
	);
	

	//////////////////////////////////////////////////////////////////////////////
	//    dcache                                                                //
	//    This Module is used to store data that may be used recently, either   // 
	//	  by fetching data from it or by replenishing data from the sram  		//
	//////////////////////////////////////////////////////////////////////////////
	// dcache my_dcache(
    // 	 .clk         (clk             ),
    // 	 .rst         (rst             ),
    // 	 .dcache_data (ram_data_cache_o), 
    // 	 .mem_addr    (ram_vaddr       ),    
    // 	 .mem_data    (ram_wdata       ),      
    // 	 .mem_we      (ram_we          ),      
    // 	 .mem_be      (ram_be          ),    
    // 	 .mem_ce      (ram_ce          ),       
    // 	 .stall       (stall_dcache    ),
    // 	 .sram_rdata  (ram_rdata       )
	// );


	//////////////////////////////////////////////////////////////////////////////
	//    mem_wb                                                                //
	//    This Module is used to implement the pipeline from the mem Module to  //
  	//    the wb Module                                                         //
	//////////////////////////////////////////////////////////////////////////////
	mem_wb my_mem2wb(
		// input
		.clk           (clk        ),
		.rst           (rst        ),
        .stall         (stall      ),
		.mem_reg_waddr (mem_wd_o   ),
		.mem_reg_we    (mem_wreg_o ),
		.mem_reg_wdata (mem_wdata_o),

		// output
		.wb_reg_waddr  (wb_wd_i    ),
		.wb_reg_we     (wb_wreg_i  ),
		.wb_reg_wdata  (wb_wdata_i )
	);
	

	//////////////////////////////////////////////////////////////////////////////
	//    ctrl                                                                  //
	//    this Module is used to implement pipeline pause function              //
	//////////////////////////////////////////////////////////////////////////////
	ctrl my_ctrl(
		// input
		.rst                  (rst                 ),	
		.stop_inst            (stop_inst           ),
		.stallreq_from_id     (stallreq_from_id    ),
		.stallreq_from_ex     (stallreq_from_ex    ),
		.stallreq_from_dcache (stall_dcache        ),
		.stallreq_from_icache (stallreq_from_icache),

		// output
		.stall                (stall               )   	
	);

endmodule