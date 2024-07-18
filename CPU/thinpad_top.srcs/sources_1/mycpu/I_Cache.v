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
    parameter CacheNum     = 32;
    parameter CacheTag     = 15;
    parameter CacheIndex   = 5;
    parameter CacheAddress = 2;

    //  ------- ----------------------------- --------------------------------
    // | valid |             tag             |              inst              |
    // |   1   |              15             |               32               |  x 32
    //  ------- ----------------------------- --------------------------------

    //////////////////////////////////////////////////////////////////////
    //           A two-dimensional array manages icache data            //
    //////////////////////////////////////////////////////////////////////
    reg [          31:0] cache_inst   [0:CacheNum - 1];
    reg [CacheTag - 1:0] cache_tag    [0:CacheNum - 1];
    reg                  cache_valid  [0:CacheNum - 1];            

    parameter STATE_HIT    = 1'b0;
    parameter STATE_NOT_HIT = 1'b1;

    reg [1:0] curState;
    reg [1:0] nextState;

    //////////////////////////////////////////////////////////////////////
    //               State transition of a state machinen               //
    //////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            curState <= STATE_HIT;
        end 
        else begin
            curState <= nextState;
        end
    end
    
    wire [  CacheTag - 1:0] ram_tag_i;
    wire [CacheIndex - 1:0] ram_cache_i;
    assign ram_tag_i   = inst_vaddr [21:7];
    assign ram_cache_i = inst_vaddr [ 6:2];
    
    // hit flag
    wire   hit;
    assign hit =   (curState                 == STATE_HIT) 
                && (cache_valid[ram_cache_i] == 1'b1     )    // valid data
                && (cache_tag  [ram_cache_i] == ram_tag_i);   // same tag

    // whether to complete the missing instructions from the sram
    reg finish_read;

    ////////////////////////////////////////////////////////////////////////////////////
    // the transformation logic between states and the realization of icache function //
    ////////////////////////////////////////////////////////////////////////////////////
    always @(*)begin
        if(rst == `RstEnable) begin
            finish_read = 1'b0;
            inst_data   = 32'b0;
            stall       = 1'b0;     
        end 
        else begin
            // default value
            finish_read = 1'b0;
            inst_data   = 32'b0;
            stall       = 1'b0;
            case(curState)
            
                // STATE1 HIT
                STATE_HIT: begin
                    // if icache hit
                    if(~inst_stop && hit) begin
                        inst_data = cache_inst[ram_cache_i];
                    end
                    // if icache not hit
                    else if(~inst_stop && ~hit) begin
                        nextState = STATE_NOT_HIT;
                        stall     = 1'b1;
                    end
                end

                // STATE2 NOTHIT
                STATE_NOT_HIT: begin
                    // if aready get inst from base ram
                    if (finish_read) begin
                        nextState = STATE_HIT;
                    end
                    else begin
                        inst_data   = inst_i;
                        finish_read = 1'b1;   
                    end
                end

                // invalid state
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
                STATE_NOT_HIT: begin
                    cache_inst [ram_cache_i] <= inst_i;
                    cache_valid[ram_cache_i] <= 1'b1;
                    cache_tag  [ram_cache_i] <= ram_tag_i;
                end
                default: begin 
                end
            endcase
        end 
    end

endmodule