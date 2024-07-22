`include "defines.v"

module ICache(
    input  wire        clk,
    input  wire        rst,

    // the information entered in the if phase
    input  wire [31:0] inst_vaddr,
    input  wire        inst_ce,
    output reg  [31:0] inst_data,
    output reg         stall,

    // connect to Sram Controller
    input  wire        inst_stop,
    input  wire [31:0] inst_i
);

    //////////////////////////////////////////////////////////////////////////////////////////
    //                                                                                      //
    //    The iCache provides the following functions:                                      //
    //    1 Attempt to read an instruction                                                  //
    //    2 Fetch instruction when hit                                                      //
    //    3 Pause the pipeline when missed, take the instruction from ram and write it      //
    //    4 Direct mapping is used                                                          //
    //                                                                                      //
    //////////////////////////////////////////////////////////////////////////////////////////

    // parameters
    parameter Cache_Num     = 32;
    parameter Cache_Tag     = 15;
    parameter Cache_Index   = 5;
    parameter Cache_Address = 2;

    //////////////////////////////////////////////////////////////////////
    //           A two-dimensional array manages icache data            //
    //////////////////////////////////////////////////////////////////////
    reg [           31:0] cache_inst  [0:Cache_Num - 1];
    reg [Cache_Tag - 1:0] cache_tag   [0:Cache_Num - 1];
    reg                   cache_valid [0:Cache_Num - 1];            

    parameter STATE_IDLE   = 2'b00;
    parameter STATE_MISS   = 2'b01;

    reg [1:0] curState;
    reg [1:0] nextState;

    //////////////////////////////////////////////////////////////////////
    //               State transition of a state machinen               //
    //////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            curState <= STATE_IDLE;
        end 
        else begin
            curState <= nextState;
        end
    end
    
    // split the inst addr
    //  ---------- ------------------------------ ------------------- ------
    // |          |             tag              |       index       |      |
    // |31      22|21                           7|6                 2|1    0|
    //  ---------- ------------------------------ ------------------- ------
    wire [  Cache_Tag - 1:0] inst_tag;
    wire [Cache_Index - 1:0] inst_index;
    assign inst_tag   = inst_vaddr [21:7];
    assign inst_index = inst_vaddr [ 6:2];
    
    // hit flag
    wire   hit;
    assign hit =   (curState                == STATE_IDLE)    // idle state
                && (cache_valid[inst_index] == 1'b1      )    // valid data
                && (cache_tag  [inst_index] == inst_tag  );   // same tag
                
    // whether to complete the missing instructions from the sram
    reg finish_read;

    ////////////////////////////////////////////////////////////////////////////////////
    // the transformation logic between states and the realization of icache function //
    ////////////////////////////////////////////////////////////////////////////////////
    always @(*) begin
        if (rst == `RstEnable) begin
            finish_read = 1'b0;
            inst_data   = 32'b0;
            stall       = 1'b0;
        end
        else begin
            // default value
            finish_read = 1'b0;
            inst_data   = 32'b0;
            stall       = 1'b0;
            case (curState)
                STATE_IDLE: begin
                    if (inst_stop) begin
                        // nothing happen
                    end
                    // hit condition
                    else if (hit) begin
                        inst_data = cache_inst[inst_index];
                    end
                    // not hit condition
                    else begin
                        nextState = STATE_MISS;
                        stall     = 1'b1;
                    end
                end
                STATE_MISS: begin
                    if (inst_stop) begin
                        // nothing happen
                    end
                    else begin
                        if (finish_read) begin
                            nextState = STATE_IDLE;
                        end
                        else begin
                            inst_data = inst_i;
                            finish_read = 1'b1;
                        end
                    end
                end
                default: begin
                end
            endcase
        end
    end

    //////////////////////////////////////////////////////////////////////
    //                assign a value to the icache data                 //
    //////////////////////////////////////////////////////////////////////
    integer i;
    always@(posedge clk)begin
        if(rst == `RstEnable) begin
            for (i = 0; i < 32; i = i + 1) begin
                cache_inst [i] <= 32'b0;
                cache_tag  [i] <= 15'b0;
                cache_valid[i] <= 1'b0;
            end  
        end 
        else begin
            case(curState)
                STATE_MISS: begin
                    cache_inst [inst_index] <= inst_i;
                    cache_valid[inst_index] <= 1'b1;
                    cache_tag  [inst_index] <= inst_tag;
                end
            endcase
        end 
    end

endmodule