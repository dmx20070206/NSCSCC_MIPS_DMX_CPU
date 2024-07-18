module dcache(
    input  wire        clk,
    input  wire        rst,

    // from cpu
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_data,
    input  wire        mem_we,
    input  wire [ 3:0] mem_be,
    input  wire        mem_ce,
    input  wire        inst_stop,

    output reg  [31:0] ram_rdata_o,
    output reg         stall,

    // from sram
    input  wire [31:0] ram_rdata_i 
);

    parameter Cache_Num    = 32;
    parameter Tag          = 16;
    parameter Cache_Index  = 5;
    parameter Block_Offset = 2;

    reg [     31:0] cache_mem   [0:Cache_Num - 1];
    reg [Tag - 1:0] cache_tag   [0:Cache_Num - 1];
    reg [      3:0] cache_valid [0:Cache_Num - 1];

    //状态机
    parameter IDLE       = 0;
    parameter READ_SRAM  = 1;
    parameter WRITE_SRAM = 2;

    reg [1:0] state, next_state;

    always@(posedge clk)begin
        if(rst) begin
            state <= IDLE;
        end 
        else begin
            state <= next_state;
        end
    end

    //处理串口
    wire uart_req = (mem_ce & ((mem_addr == 32'hbfd003f8)|(mem_addr == 32'hbfd003fc))) ? 1'b1 : 1'b0;

    //read
    //hit(单独指读命中，写命中没有意义)
    wire [Tag-1:0] ram_tag_i = mem_addr[22:7];//ram tag
    wire [Cache_Index-1:0]  ram_cache_i = mem_addr[6:2];//ram cache block addr


    wire hit = 1'b0;
    reg[31:0]cache_wb;
    reg cache_wb_vaild;


    reg finish_read;
    reg finish_write;

    integer i;
    reg[63:0] wb_data_r;
    always@(*)begin
        if(rst)begin
            for(i=0 ; i < 32 ; i=i+1)begin
                        cache_mem[i] = 32'b0;
                        cache_tag[i] = 16'b0;
                        cache_valid[i] = 4'b0;
                    end  
            finish_read = 1'b0;
            finish_write = 1'b0;
            ram_rdata_o = 32'b0;       //读取的数据
        end else begin
            case(state)
            IDLE:begin
                finish_read = 1'b0;
                finish_write = 1'b0;
                //处理读cache
                if(hit&&!uart_req)begin
                    ram_rdata_o = cache_mem[ram_cache_i];
                end else if(uart_req)begin
                    ram_rdata_o = ram_rdata_i;                
                end else begin
                    ram_rdata_o = 32'b0;
                end
                //处理写cache

            end
            READ_SRAM: begin      
                //读sram 
                ram_rdata_o = ram_rdata_i;       //读取的数据 
                finish_read = 1'b1;         
                //写入cache
     //           if(!uart_req)begin         
                cache_mem[ram_cache_i] = ram_rdata_i;
                cache_valid[ram_cache_i] = mem_be;
                cache_tag[ram_cache_i] = ram_tag_i;//cache tag
      //          end else begin end
            end
            WRITE_SRAM:begin    
                //写SRAM
                ram_rdata_o = 32'b0;           
                finish_write = 1'b1;   
                //写cache
       //         if(!uart_req)begin
                    if(cache_valid[ram_cache_i] != mem_be&&cache_valid[ram_cache_i]!=4'b0) begin
                        cache_valid[ram_cache_i] = mem_be;
                        case(mem_be)
                            4'b1111:begin 
                                cache_mem[ram_cache_i] =  mem_data;
                            end
                            4'b0001:begin
                                cache_mem[ram_cache_i][7:0] = mem_data[7:0];
                            end
                            4'b0010:begin
                                cache_mem[ram_cache_i][15:8] = mem_data[15:8];
                            end
                            4'b0100:begin
                                cache_mem[ram_cache_i][23:16] = mem_data[23:16];
                            end
                            4'b1000:begin
                                cache_mem[ram_cache_i][31:24] = mem_data[31:24];
                            end
                            default:begin
                                cache_mem[ram_cache_i] = mem_data;
                            end
                        endcase
                    end 
                    else begin
                        cache_mem[ram_cache_i] = mem_data;
                        cache_valid[ram_cache_i] = mem_be;
                    end
                    cache_tag[ram_cache_i] = ram_tag_i;//cache tag
            end
            default:begin end
            endcase
        end
    end

    always@(*)begin
        if(rst)begin
            stall = 1'b0;
            next_state=IDLE;
        end else begin
            case(state)
                IDLE:begin
                    if(~mem_we&&(hit!=1'b1)&&mem_ce&&!uart_req)begin//读，未命中
                        next_state=READ_SRAM;
                        stall = 1'b1;
                    end else if(mem_we&&mem_ce&&!uart_req) begin//写
                        next_state=WRITE_SRAM;
                        stall = 1'b1;
                    end else begin
                        next_state=IDLE;
                        stall = 1'b0;
                    end
                end
                READ_SRAM:begin
                    if(finish_read)begin
                        next_state=IDLE;
                        stall = 1'b0;
                        end
                    else begin
                        next_state=READ_SRAM;  
                     end 
                 end
                WRITE_SRAM:begin
                    if(finish_write)begin
                        next_state=IDLE;
                        stall = 1'b0;
                        end
                    else begin
                        next_state=WRITE_SRAM;
                    end
                 end
                default:next_state=IDLE;
            endcase
        end
    end
endmodule