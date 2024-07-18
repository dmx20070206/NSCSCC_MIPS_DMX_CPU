module UART_CTRL(
    input  wire        clk,

    // �� CPU ��������Ϣ
    input  wire [31:0] CPU_send,    // CPU ���͵�����
    output reg  [31:0] CPU_receive, // CPU ���յ�����

    input  wire [31:0] mem_addr,    // CPU �����ڴ�ĵ�ַ 
    input  wire        mem_we,      // CPU �ڴ�дʹ��

    // ���ڽӿ�
    input  wire        rxd,
    output wire        txd,

    // ��ͣ��ˮ���ź�
    output wire        stall_for_Uart_relate
);

    parameter CheckSerialState = 32'hBFD003FC;
    parameter CheckSerialData  = 32'hBFD003F8;

    wire        RxD_data_ready;     // �����������ʱ����Ϊ1
    reg         RxD_clear;          // Ϊ1ʱ��������ձ�־

    wire        TxD_busy;           // �Ƿ����ڷ�������
    reg         TxD_start;          // �Ƿ���Է�������

    reg  [ 7:0] TxD_data;
    wire [ 7:0] RxD_data;

    wire cpu_request_state;     // CPU <-- state
    wire cpu_request_data;      // CPU <-- data
    wire cpu_send_data;         // CPU --> data

    assign cpu_request_state = !mem_we && (mem_addr == CheckSerialState);
    assign cpu_request_data  = !mem_we && (mem_addr == CheckSerialData );
    assign cpu_send_data     =  mem_we && (mem_addr == CheckSerialData );
    
    // ʵ��������ģ�飬������9600
    async_receiver    #(.ClkFrequency(40000000),.Baud(9600))    // ����ģ��
                        myUartReceiver(
                       .clk            (clk),
                       .RxD            (rxd),
                       .RxD_data_ready (RxD_data_ready),
                       .RxD_clear      (RxD_clear),
                       .RxD_data       (RxD_data)
                    );

    async_transmitter #(.ClkFrequency(40000000),.Baud(9600))     // ����ģ��
                        myUartTransmitter(
                        .clk           (clk),
                        .TxD           (txd),
                        .TxD_busy      (TxD_busy),
                        .TxD_start     (TxD_start),
                        .TxD_data      (TxD_data)
                    );

    // ����ģ��Ĵ���
    always @(*)begin

        // CPU ���ȡ���ڵ�״̬��Ϣ
        if(cpu_request_state) begin
            CPU_receive  = {30'b0, {RxD_data_ready, !TxD_busy}};
            TxD_start    = 1'b0;
            TxD_data     = 8'h00;
        end

        // CPU ���ȡ�������������
        else if(cpu_request_data) begin               
            CPU_receive  = {24'b0, RxD_data};
            TxD_start    = 1'b0;
            TxD_data     = 8'b0;
        end

        // CPU �뷢�����ݵ����ڣ�ǰ���Ƿ��Ͷ˲�æµ��
        else if(cpu_send_data && !TxD_busy) begin
            CPU_receive = 32'b0;
            TxD_start   = 1'b1;
            TxD_data    = CPU_send[7:0];
        end

        // �������
        else begin
            CPU_receive = 32'b0;
            TxD_start = 1'b0;
            TxD_data = 8'b0;
        end
    end

    // ����ģ��Ĵ���
    always @(*) begin

        // ����������� + CPU ��ȡ�������ݣ�CPU ��ȡ���� + �ڴ治��Ҫд��
        if (RxD_data_ready && !mem_we && (mem_addr == CheckSerialData)) begin
            RxD_clear = 1'b1;
        end
        else begin
            RxD_clear = 1'b0;
        end
    end

    // ��ͣ�ź�
    assign stall_for_Uart_relate = (mem_addr == CheckSerialData || mem_addr == CheckSerialState);

endmodule