`include "defines.v"

module SRAM_CTRL (
    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] inst_vaddr,       
    input  wire        inst_ce,          
    output wire [31:0] inst_data,        

    output wire [31:0] ram_rdata,        
    input  wire [31:0] ram_vaddr,        
    input  wire [31:0] ram_wdata,        
    input  wire        ram_we,             
    input  wire [ 3:0] ram_be,           
    input  wire        ram_ce,            

    inout  wire [31:0] base_ram_data,   // base data
    output wire [19:0] base_ram_addr,   // base address
    output wire [ 3:0] base_ram_be_n,   // base be_n
    output wire        base_ram_ce_n,   // base ce_n
    output wire        base_ram_oe_n,   // base oe_n
    output wire        base_ram_we_n,   // base_we_n

    inout  wire [31:0] ext_ram_data,    // ext data
    output wire [19:0] ext_ram_addr,    // ext address
    output wire [ 3:0] ext_ram_be_n,    // ext be_n
    output wire        ext_ram_ce_n,    // ext ce_n 
    output wire        ext_ram_oe_n,    // ext oe_n
    output wire        ext_ram_we_n,    // ext we_n
    
    output wire        stall_for_Base_relate
);

    wire vaddr_in_base;     // the virtual address of the operating memory is in base
    wire vaddr_in_ext;      // the virtual address of the operating memory is in ext

    assign vaddr_in_base = (ram_vaddr >= 32'h80000000) && (ram_vaddr < 32'h80400000);
    assign vaddr_in_ext  = (ram_vaddr >= 32'h80400000) && (ram_vaddr < 32'h80800000);

    // processing base data
    wire [31:0] base_ram_data_o;
    assign base_ram_data   = (vaddr_in_base && ram_we) ? ram_wdata : 32'hzzzzzzzz;
    assign base_ram_data_o = base_ram_data;

    // processing base address
    assign base_ram_addr = vaddr_in_base ? ram_vaddr[21:2] : inst_vaddr[21:2];

    // processing the base enable_n signal
    assign base_ram_be_n = vaddr_in_base ? !ram_be   :  4'b0000;
    assign base_ram_ce_n = vaddr_in_base ?  1'b0     :  1'b0;
    assign base_ram_oe_n = vaddr_in_base ?  ram_we   :  1'b0;
    assign base_ram_we_n = vaddr_in_base ? !ram_we   :  1'b1;

    // processing pause signals caused by base
    assign stall_for_Base_relate = vaddr_in_base;

    // processing ext data
    wire [31:0] ext_ram_data_o;
    assign ext_ram_data   = (vaddr_in_ext && ram_we) ? ram_wdata : 32'hzzzzzzzz;
    assign ext_ram_data_o = ext_ram_data;

    // processing ext address
    assign ext_ram_addr = vaddr_in_ext ? ram_vaddr[21:2] : 20'b0;

    // processing the ext enable_n signal
    assign ext_ram_be_n = vaddr_in_ext ? !ram_be    :  4'b1111;
    assign ext_ram_ce_n = vaddr_in_ext ? !ram_ce    :  1'b1;
    assign ext_ram_oe_n = vaddr_in_ext ?  ram_we    :  1'b1;
    assign ext_ram_we_n = vaddr_in_ext ? !ram_we    :  1'b1;

    // process the information sent to the CPU
    assign ram_rdata = vaddr_in_base ? base_ram_data_o : ext_ram_data_o;
    assign inst_data = vaddr_in_base ? 32'b0           : base_ram_data_o;

endmodule