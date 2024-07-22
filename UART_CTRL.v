module UART_CTRL(
    input  wire        clk,

    // information exchanged with the CPU
    input  wire [31:0] CPU_send,    // CPU send data
    output reg  [31:0] CPU_receive, // CPU receive data

    input  wire [31:0] mem_addr,    // CPU operating memory address
    input  wire        mem_we,      // CPU memory write is enabled

    // serial interface
    input  wire        rxd,
    output wire        txd,

    // pause pipeline signal
    output wire        stall_for_Uart_relate
);

    parameter CheckSerialState = 32'hBFD003FC;
    parameter CheckSerialData  = 32'hBFD003F8;

    wire        RxD_data_ready;     // set to 1 when receiving data is complete
    reg         RxD_clear;          // a value of 1 clears the receive flag

    wire        TxD_busy;           // whether data is being sent
    reg         TxD_start;          // whether data can be sent

    reg  [ 7:0] TxD_data;
    wire [ 7:0] RxD_data;

    wire cpu_request_state;     // CPU <-- state
    wire cpu_request_data;      // CPU <-- data
    wire cpu_send_data;         // CPU --> data

    assign cpu_request_state = !mem_we && (mem_addr == CheckSerialState);
    assign cpu_request_data  = !mem_we && (mem_addr == CheckSerialData );
    assign cpu_send_data     =  mem_we && (mem_addr == CheckSerialData );
    
    // instantiate the serial port module, baud rate 9600
    async_receiver    #(.ClkFrequency(55000000),.Baud(9600))    // receiving module
                        myUartReceiver(
                       .clk            (clk),
                       .RxD            (rxd),
                       .RxD_data_ready (RxD_data_ready),
                       .RxD_clear      (RxD_clear),
                       .RxD_data       (RxD_data)
                    );

    async_transmitter #(.ClkFrequency(55000000),.Baud(9600))     // transmitter module
                        myUartTransmitter(
                        .clk           (clk),
                        .TxD           (txd),
                        .TxD_busy      (TxD_busy),
                        .TxD_start     (TxD_start),
                        .TxD_data      (TxD_data)
                    );

    // processing of the sending module
    always @(*)begin

        // CPU wants to obtain the status of the serial port
        if(cpu_request_state) begin
            CPU_receive  = {30'b0, {RxD_data_ready, !TxD_busy}};
            TxD_start    = 1'b0;
            TxD_data     = 8'h00;
        end

        // CPU wants to obtain the data output from the serial port
        else if(cpu_request_data) begin               
            CPU_receive  = {24'b0, RxD_data};
            TxD_start    = 1'b0;
            TxD_data     = 8'b0;
        end

        // CPU wants to send data to the serial port (if the sending end is not busy)
        else if(cpu_send_data && !TxD_busy) begin
            CPU_receive = 32'b0;
            TxD_start   = 1'b1;
            TxD_data    = CPU_send[7:0];
        end

        // other conditions
        else begin
            CPU_receive = 32'b0;
            TxD_start = 1'b0;
            TxD_data = 8'b0;
        end
    end

    // Receiving module processing
    always @(*) begin

        // Data received is complete + CPU reads serial port data (CPU gets data + memory does not need to write)
        if (RxD_data_ready && !mem_we && (mem_addr == CheckSerialData)) begin
            RxD_clear = 1'b1;
        end
        else begin
            RxD_clear = 1'b0;
        end
    end

    // pause signal
    assign stall_for_Uart_relate = (mem_addr == CheckSerialData || mem_addr == CheckSerialState);

endmodule