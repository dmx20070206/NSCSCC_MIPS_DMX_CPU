`include "defines.v"

module SRAM_CTRL (
    input  wire        clk,
    input  wire        rst,

    // if 阶段的信息
    input  wire [31:0] inst_vaddr,       // 读取指令的地址
    input  wire        inst_ce,          // 指令存储器使能信号
    output wire [31:0] inst_data,        // 获取到的指令

    // mem 阶段的信息
    output wire [31:0] ram_rdata,        // 读取的数据
    input  wire [31:0] ram_vaddr,        // 读（写）地址
    input  wire [31:0] ram_wdata,        // 写入的数据
    input  wire        ram_we,           // 写使能
    input  wire [ 3:0] ram_be,         // 字节选择信号
    input  wire        ram_ce,           // 片选信号

    // 以下信号均为低有效
    // BASERAM
    inout  wire [31:0] base_ram_data,     // BaseRAM数据
    output wire [19:0] base_ram_addr,     // BaseRAM地址
    output wire [ 3:0] base_ram_be_n,     // BaseRAM字节使能
    output wire        base_ram_ce_n,     // BaseRAM片选
    output wire        base_ram_oe_n,     // BaseRAM读使能
    output wire        base_ram_we_n,     // BaseRAM写使能

    // EXTRAM
    inout  wire [31:0] ext_ram_data,      // ExtRAM数据
    output wire [19:0] ext_ram_addr,      // ExtRAM地址
    output wire [ 3:0] ext_ram_be_n,      // ExtRAM字节使能
    output wire        ext_ram_ce_n,      // ExtRAM片选
    output wire        ext_ram_oe_n,      // ExtRAM读使能
    output wire        ext_ram_we_n,      // ExtRAM写使能
    
    // 暂停流水线信号
    output wire        stall_for_Base_relate
);

    wire vaddr_in_base;     // 操作内存的虚拟地址在 base 中
    wire vaddr_in_ext;      // 操作内存的虚拟地址在 ext  中

    assign vaddr_in_base = (ram_vaddr >= 32'h80000000) && (ram_vaddr < 32'h80400000);
    assign vaddr_in_ext  = (ram_vaddr >= 32'h80400000) && (ram_vaddr < 32'h80800000);

    // 处理 base 的数据
    wire [31:0] base_ram_data_o;
    assign base_ram_data   = (vaddr_in_base && ram_we) ? ram_wdata : 32'hzzzzzzzz;
    assign base_ram_data_o = base_ram_data;

    // 处理 base 的地址
    assign base_ram_addr = vaddr_in_base ? ram_vaddr[21:2] : inst_vaddr[21:2];

    // 处理 base 的使能信号
    assign base_ram_be_n = vaddr_in_base ? !ram_be   :  4'b0000;
    assign base_ram_ce_n = vaddr_in_base ?  1'b0     :  1'b0;
    assign base_ram_oe_n = vaddr_in_base ?  ram_we   :  1'b0;
    assign base_ram_we_n = vaddr_in_base ? !ram_we   :  1'b1;

    // 处理 base 导致的暂停信号
    assign stall_for_Base_relate = vaddr_in_base;

    // 处理 ext  的数据
    wire [31:0] ext_ram_data_o;
    assign ext_ram_data   = (vaddr_in_ext && ram_we) ? ram_wdata : 32'hzzzzzzzz;
    assign ext_ram_data_o = ext_ram_data;

    // 处理 ext  的地址
    assign ext_ram_addr = vaddr_in_ext ? ram_vaddr[21:2] : 20'b0;

    // 处理 ext  的使能信号
    assign ext_ram_be_n = vaddr_in_ext ? !ram_be    :  4'b1111;
    assign ext_ram_ce_n = vaddr_in_ext ? !ram_ce    :  1'b1;
    assign ext_ram_oe_n = vaddr_in_ext ?  ram_we    :  1'b1;
    assign ext_ram_we_n = vaddr_in_ext ? !ram_we    :  1'b1;

    // 处理送往 CPU 的信息
    assign ram_rdata = vaddr_in_base ? base_ram_data_o : ext_ram_data_o;
    assign inst_data = vaddr_in_base ? 32'b0           : base_ram_data_o;

endmodule