`include "defines.v"

module SRAM_CTRL (
    input  wire        clk,
    input  wire        rst,

    // if �׶ε���Ϣ
    input  wire [31:0] inst_vaddr,       // ��ȡָ��ĵ�ַ
    input  wire        inst_ce,          // ָ��洢��ʹ���ź�
    output wire [31:0] inst_data,        // ��ȡ����ָ��

    // mem �׶ε���Ϣ
    output wire [31:0] ram_rdata,        // ��ȡ������
    input  wire [31:0] ram_vaddr,        // ����д����ַ
    input  wire [31:0] ram_wdata,        // д�������
    input  wire        ram_we,           // дʹ��
    input  wire [ 3:0] ram_be,         // �ֽ�ѡ���ź�
    input  wire        ram_ce,           // Ƭѡ�ź�

    // �����źž�Ϊ����Ч
    // BASERAM
    inout  wire [31:0] base_ram_data,     // BaseRAM����
    output wire [19:0] base_ram_addr,     // BaseRAM��ַ
    output wire [ 3:0] base_ram_be_n,     // BaseRAM�ֽ�ʹ��
    output wire        base_ram_ce_n,     // BaseRAMƬѡ
    output wire        base_ram_oe_n,     // BaseRAM��ʹ��
    output wire        base_ram_we_n,     // BaseRAMдʹ��

    // EXTRAM
    inout  wire [31:0] ext_ram_data,      // ExtRAM����
    output wire [19:0] ext_ram_addr,      // ExtRAM��ַ
    output wire [ 3:0] ext_ram_be_n,      // ExtRAM�ֽ�ʹ��
    output wire        ext_ram_ce_n,      // ExtRAMƬѡ
    output wire        ext_ram_oe_n,      // ExtRAM��ʹ��
    output wire        ext_ram_we_n,      // ExtRAMдʹ��
    
    // ��ͣ��ˮ���ź�
    output wire        stall_for_Base_relate
);

    wire vaddr_in_base;     // �����ڴ�������ַ�� base ��
    wire vaddr_in_ext;      // �����ڴ�������ַ�� ext  ��

    assign vaddr_in_base = (ram_vaddr >= 32'h80000000) && (ram_vaddr < 32'h80400000);
    assign vaddr_in_ext  = (ram_vaddr >= 32'h80400000) && (ram_vaddr < 32'h80800000);

    // ���� base ������
    wire [31:0] base_ram_data_o;
    assign base_ram_data   = (vaddr_in_base && ram_we) ? ram_wdata : 32'hzzzzzzzz;
    assign base_ram_data_o = base_ram_data;

    // ���� base �ĵ�ַ
    assign base_ram_addr = vaddr_in_base ? ram_vaddr[21:2] : inst_vaddr[21:2];

    // ���� base ��ʹ���ź�
    assign base_ram_be_n = vaddr_in_base ? !ram_be   :  4'b0000;
    assign base_ram_ce_n = vaddr_in_base ?  1'b0     :  1'b0;
    assign base_ram_oe_n = vaddr_in_base ?  ram_we   :  1'b0;
    assign base_ram_we_n = vaddr_in_base ? !ram_we   :  1'b1;

    // ���� base ���µ���ͣ�ź�
    assign stall_for_Base_relate = vaddr_in_base;

    // ���� ext  ������
    wire [31:0] ext_ram_data_o;
    assign ext_ram_data   = (vaddr_in_ext && ram_we) ? ram_wdata : 32'hzzzzzzzz;
    assign ext_ram_data_o = ext_ram_data;

    // ���� ext  �ĵ�ַ
    assign ext_ram_addr = vaddr_in_ext ? ram_vaddr[21:2] : 20'b0;

    // ���� ext  ��ʹ���ź�
    assign ext_ram_be_n = vaddr_in_ext ? !ram_be    :  4'b1111;
    assign ext_ram_ce_n = vaddr_in_ext ? !ram_ce    :  1'b1;
    assign ext_ram_oe_n = vaddr_in_ext ?  ram_we    :  1'b1;
    assign ext_ram_we_n = vaddr_in_ext ? !ram_we    :  1'b1;

    // �������� CPU ����Ϣ
    assign ram_rdata = vaddr_in_base ? base_ram_data_o : ext_ram_data_o;
    assign inst_data = vaddr_in_base ? 32'b0           : base_ram_data_o;

endmodule