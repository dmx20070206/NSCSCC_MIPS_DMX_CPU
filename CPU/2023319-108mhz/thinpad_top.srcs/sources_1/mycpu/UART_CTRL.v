module UART_CTRL(
    input  wire        clk,

    // 和 CPU 交换的信息
    input  wire [31:0] CPU_send,    // CPU 发送的数据
    output reg  [31:0] CPU_receive, // CPU 接收的数据

    input  wire [31:0] mem_addr,    // CPU 操作内存的地址 
    input  wire        mem_we,      // CPU 内存写使能

    // 串口接口
    input  wire        rxd,
    output wire        txd,

    // 暂停流水线信号
    output wire        stall_for_Uart_relate
);

    parameter CheckSerialState = 32'hBFD003FC;
    parameter CheckSerialData  = 32'hBFD003F8;

    wire        RxD_data_ready;     // 接收数据完成时，置为1
    reg         RxD_clear;          // 为1时将清除接收标志

    wire        TxD_busy;           // 是否正在发送数据
    reg         TxD_start;          // 是否可以发送数据

    reg  [ 7:0] TxD_data;
    wire [ 7:0] RxD_data;

    wire cpu_request_state;     // CPU <-- state
    wire cpu_request_data;      // CPU <-- data
    wire cpu_send_data;         // CPU --> data

    assign cpu_request_state = !mem_we && (mem_addr == CheckSerialState);
    assign cpu_request_data  = !mem_we && (mem_addr == CheckSerialData );
    assign cpu_send_data     =  mem_we && (mem_addr == CheckSerialData );
    
    // 实例化串口模块，波特率9600
    async_receiver    #(.ClkFrequency(40000000),.Baud(9600))    // 接收模块
                        myUartReceiver(
                       .clk            (clk),
                       .RxD            (rxd),
                       .RxD_data_ready (RxD_data_ready),
                       .RxD_clear      (RxD_clear),
                       .RxD_data       (RxD_data)
                    );

    async_transmitter #(.ClkFrequency(40000000),.Baud(9600))     // 发送模块
                        myUartTransmitter(
                        .clk           (clk),
                        .TxD           (txd),
                        .TxD_busy      (TxD_busy),
                        .TxD_start     (TxD_start),
                        .TxD_data      (TxD_data)
                    );

    // 发送模块的处理
    always @(*)begin

        // CPU 想获取串口的状态信息
        if(cpu_request_state) begin
            CPU_receive  = {30'b0, {RxD_data_ready, !TxD_busy}};
            TxD_start    = 1'b0;
            TxD_data     = 8'h00;
        end

        // CPU 想获取串口输出的数据
        else if(cpu_request_data) begin               
            CPU_receive  = {24'b0, RxD_data};
            TxD_start    = 1'b0;
            TxD_data     = 8'b0;
        end

        // CPU 想发送数据到串口（前提是发送端不忙碌）
        else if(cpu_send_data && !TxD_busy) begin
            CPU_receive = 32'b0;
            TxD_start   = 1'b1;
            TxD_data    = CPU_send[7:0];
        end

        // 其他情况
        else begin
            CPU_receive = 32'b0;
            TxD_start = 1'b0;
            TxD_data = 8'b0;
        end
    end

    // 接收模块的处理
    always @(*) begin

        // 接收数据完毕 + CPU 读取串口数据（CPU 获取数据 + 内存不需要写）
        if (RxD_data_ready && !mem_we && (mem_addr == CheckSerialData)) begin
            RxD_clear = 1'b1;
        end
        else begin
            RxD_clear = 1'b0;
        end
    end

    // 暂停信号
    assign stall_for_Uart_relate = (mem_addr == CheckSerialData || mem_addr == CheckSerialState);

endmodule