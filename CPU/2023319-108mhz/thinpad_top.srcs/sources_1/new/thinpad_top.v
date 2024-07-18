`default_nettype none

module thinpad_top(
    input  wire        clk_50M,           //50MHz ʱ������
    input  wire        clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�

    input  wire        clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input  wire        reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire [ 3:0] touch_btn,         //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire [31:0] dip_sw,            //32λ���뿪�أ�������ON��ʱΪ1
    output wire [15:0] leds,              //16λLED�����ʱ1����
    output wire [ 7:0] dpy0,              //����ܵ�λ�źţ�����С���㣬���1����
    output wire [ 7:0] dpy1,              //����ܸ�λ�źţ�����С���㣬���1����

    // BaseRAM�ź�
    inout  wire [31:0] base_ram_data,     //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire [19:0] base_ram_addr,     //BaseRAM��ַ
    output wire [ 3:0] base_ram_be_n,     //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire        base_ram_ce_n,     //BaseRAMƬѡ������Ч
    output wire        base_ram_oe_n,     //BaseRAM��ʹ�ܣ�����Ч
    output wire        base_ram_we_n,     //BaseRAMдʹ�ܣ�����Ч

    // ExtRAM�ź�
    inout  wire [31:0] ext_ram_data,      //ExtRAM����
    output wire [19:0] ext_ram_addr,      //ExtRAM��ַ
    output wire [ 3:0] ext_ram_be_n,      //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire        ext_ram_ce_n,      //ExtRAMƬѡ������Ч
    output wire        ext_ram_oe_n,      //ExtRAM��ʹ�ܣ�����Ч
    output wire        ext_ram_we_n,      //ExtRAMдʹ�ܣ�����Ч

    // ֱ�������ź�
    output wire        txd,               //ֱ�����ڷ��Ͷ�
    input  wire        rxd,               //ֱ�����ڽ��ն�

    // Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0] flash_a,           //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0] flash_d,           //Flash����
    output wire        flash_rp_n,        //Flash��λ�źţ�����Ч
    output wire        flash_vpen,        //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire        flash_ce_n,        //FlashƬѡ�źţ�����Ч
    output wire        flash_oe_n,        //Flash��ʹ���źţ�����Ч
    output wire        flash_we_n,        //Flashдʹ���źţ�����Ч
    output wire        flash_byte_n,      //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    // ͼ������ź�
    output wire [ 2:0] video_red,         //��ɫ���أ�3λ
    output wire [ 2:0] video_green,       //��ɫ���أ�3λ
    output wire [ 1:0] video_blue,        //��ɫ���أ�2λ
    output wire        video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire        video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire        video_clk,         //����ʱ�����
    output wire        video_de           //��������Ч�źţ���������������
);

    wire locked, clk_10M, clk_20M;
    pll_example clock_gen (
      .clk_in1  (clk_50M),  // �ⲿʱ������

      .clk_out1 (clk_10M),  // ʱ�����1��Ƶ����IP���ý���������
      .clk_out2 (clk_20M),  // ʱ�����2��Ƶ����IP���ý���������

      .reset    (reset_btn),
      .locked   (locked)
    );

    reg reset_of_clk10M;
    always@(posedge clk_10M or negedge locked) begin
        if(~locked) reset_of_clk10M <= 1'b1;
        else        reset_of_clk10M <= 1'b0;
    end

    reg reset_of_clk20M;
    always@(posedge clk_20M or negedge locked) begin
        if(~locked) reset_of_clk20M <= 1'b1;
        else        reset_of_clk20M <= 1'b0;
    end


    wire [31:0]  inst_vaddr ;
    wire         inst_ce;
    wire [31:0]  inst_data ;

    wire [31:0]  ram_rdata;
    wire [31:0]  ram_vaddr;
    wire [31:0]  ram_wdata;

    wire         ram_we;
    wire         ram_ce;
    wire [3:0]   ram_be;

    wire        stall_for_Base_relate;
    wire        stop_inst;
    wire [31:0] sram_rdata;

    mycpu DMX_CPU(
        .clk        (clk_10M),
        .rst        (reset_of_clk10M),

        .inst_vaddr (inst_vaddr),
        .inst_ce    (inst_ce),
        .inst_data  (inst_data),
        .stop_inst  (stop_inst),

        .ram_rdata  (ram_rdata),

        .ram_vaddr  (ram_vaddr),
        .ram_wdata  (ram_wdata),
        .ram_we     (ram_we),
        .ram_be     (ram_be),
        .ram_ce     (ram_ce)
    );

    SRAM_CTRL mySram(
        .clk                   (clk_10M),  
        .rst                   (reset_of_clk10M),
   
        .inst_vaddr            (inst_vaddr),
        .inst_ce               (inst_ce),
        .inst_data             (inst_data),
   
        .ram_rdata             (sram_rdata),
        .ram_vaddr             (ram_vaddr),
        .ram_wdata             (ram_wdata),
        .ram_we                (ram_we),
        .ram_be                (ram_be),
        .ram_ce                (ram_ce),
   
        .base_ram_data         (base_ram_data),
        .base_ram_addr         (base_ram_addr),
        .base_ram_be_n         (base_ram_be_n),
        .base_ram_ce_n         (base_ram_ce_n),
        .base_ram_oe_n         (base_ram_oe_n),
        .base_ram_we_n         (base_ram_we_n),
   
        .ext_ram_data          (ext_ram_data),
        .ext_ram_addr          (ext_ram_addr),
        .ext_ram_be_n          (ext_ram_be_n),
        .ext_ram_ce_n          (ext_ram_ce_n),
        .ext_ram_oe_n          (ext_ram_oe_n),
        .ext_ram_we_n          (ext_ram_we_n),
        
        .stall_for_Base_relate (stall_for_Base_relate)
    );

    wire        stall_for_Uart_relate;
    wire [31:0] CPU_receive_data;
    
    UART_CTRL myUart(
        .clk                   (clk_10M),
        .CPU_send              (ram_wdata),   
        .CPU_receive           (CPU_receive_data),
        .mem_addr              (ram_vaddr),    
        .mem_we                (ram_we),     
        .rxd                   (rxd),
        .txd                   (txd),
        .stall_for_Uart_relate (stall_for_Uart_relate)
    );

    assign stop_inst = stall_for_Base_relate || stall_for_Uart_relate;
    assign ram_rdata = stall_for_Uart_relate ? CPU_receive_data : sram_rdata;
endmodule
