`default_nettype none

module thinpad_top(
    input  wire        clk_50M,           //50MHz 时钟输入
    input  wire        clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input  wire        clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input  wire        reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire [ 3:0] touch_btn,         //BTN1~BTN4，按钮开关，按下时为1
    input  wire [31:0] dip_sw,            //32位拨码开关，拨到“ON”时为1
    output wire [15:0] leds,              //16位LED，输出时1点亮
    output wire [ 7:0] dpy0,              //数码管低位信号，包括小数点，输出1点亮
    output wire [ 7:0] dpy1,              //数码管高位信号，包括小数点，输出1点亮

    // BaseRAM信号
    inout  wire [31:0] base_ram_data,     //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire [19:0] base_ram_addr,     //BaseRAM地址
    output wire [ 3:0] base_ram_be_n,     //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire        base_ram_ce_n,     //BaseRAM片选，低有效
    output wire        base_ram_oe_n,     //BaseRAM读使能，低有效
    output wire        base_ram_we_n,     //BaseRAM写使能，低有效

    // ExtRAM信号
    inout  wire [31:0] ext_ram_data,      //ExtRAM数据
    output wire [19:0] ext_ram_addr,      //ExtRAM地址
    output wire [ 3:0] ext_ram_be_n,      //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire        ext_ram_ce_n,      //ExtRAM片选，低有效
    output wire        ext_ram_oe_n,      //ExtRAM读使能，低有效
    output wire        ext_ram_we_n,      //ExtRAM写使能，低有效

    // 直连串口信号
    output wire        txd,               //直连串口发送端
    input  wire        rxd,               //直连串口接收端

    // Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0] flash_a,           //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0] flash_d,           //Flash数据
    output wire        flash_rp_n,        //Flash复位信号，低有效
    output wire        flash_vpen,        //Flash写保护信号，低电平时不能擦除、烧写
    output wire        flash_ce_n,        //Flash片选信号，低有效
    output wire        flash_oe_n,        //Flash读使能信号，低有效
    output wire        flash_we_n,        //Flash写使能信号，低有效
    output wire        flash_byte_n,      //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    // 图像输出信号
    output wire [ 2:0] video_red,         //红色像素，3位
    output wire [ 2:0] video_green,       //绿色像素，3位
    output wire [ 1:0] video_blue,        //蓝色像素，2位
    output wire        video_hsync,       //行同步（水平同步）信号
    output wire        video_vsync,       //场同步（垂直同步）信号
    output wire        video_clk,         //像素时钟输出
    output wire        video_de           //行数据有效信号，用于区分消隐区
);

    wire locked, clk_10M, clk_20M;
    pll_example clock_gen (
      .clk_in1  (clk_50M),  // 外部时钟输入

      .clk_out1 (clk_10M),  // 时钟输出1，频率在IP配置界面中设置
      .clk_out2 (clk_20M),  // 时钟输出2，频率在IP配置界面中设置

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
