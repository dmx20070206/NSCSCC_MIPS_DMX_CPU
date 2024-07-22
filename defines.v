// rst
`define RstEnable 1'b1
`define RstDisable 1'b0

// stop
`define Stop 1'b1
`define NoStop 1'b0

// branch
`define Branch 1'b1
`define NotBranch 1'b0

// chip
`define ChipEnable 1'b1
`define ChipDisable 1'b0

// regfile
`define RegWDisable 1'b0
`define RegWEnable 1'b1
`define RegRDisable 1'b0
`define RegREnable 1'b1


//  -----------------------------------------
// |       instruction operation code        |
//  -----------------------------------------

// logic instruction
`define EXE_ORI   6'b001101
`define EXE_LUI   6'b001111
`define EXE_AND   6'b100100
`define EXE_ANDI  6'b001100
`define EXE_OR    6'b100101
`define EXE_XOR   6'b100110
`define EXE_XORI  6'b001110

// shift instruction
`define EXE_SLL   6'b000000
`define EXE_SRL   6'b000010
`define EXE_SRAV  6'b000111

// arithmeticres instruction
`define EXE_ADDU  6'b100001
`define EXE_SUB   6'b100010
`define EXE_ADDIU 6'b001001
`define EXE_MUL   6'b000010
`define EXE_SLT   6'b101010

// branch instruction
`define EXE_BNE   6'b000101
`define EXE_BEQ   6'b000100
`define EXE_J     6'b000010
`define EXE_JAL   6'b000011
`define EXE_JR    6'b001000
`define EXE_BLEZ  6'b000110
`define EXE_BGTZ  6'b000111
 
// load instruction
`define EXE_LW    6'b100011
`define EXE_SW    6'b101011
`define EXE_LB    6'b100000
`define EXE_SB    6'b101000

// nop instruction
`define EXE_NOP   6'b000000

// special instruction
`define EXE_REGIMM_INST   6'b000001
`define EXE_SPECIAL_INST  6'b000000
`define EXE_SPECIAL2_INST 6'b011100

//  -----------------------------------------
// |                  ALU_OP                 |
//  -----------------------------------------

`define AluOpBus 8

// logical operation
`define EXE_OR_OP    8'h01
`define EXE_ORI_OP   8'h02
`define EXE_LUI_OP   8'h03
`define EXE_AND_OP   8'h04
`define EXE_XOR_OP   8'h05
`define EXE_XORI_OP  8'h06
`define EXE_ANDI_OP  8'h07

// shift operation
`define EXE_SLL_OP   8'h08
`define EXE_SRAV_OP  8'h09
`define EXE_SRL_OP   8'h0A
`define EXE_SRA_OP   8'h0B

// arithmeticres operation
`define EXE_ADDU_OP  8'h0C
`define EXE_SLT_OP   8'h0D
`define EXE_ADDIU_OP 8'h0E
`define EXE_SUB_OP   8'h0F
`define EXE_MUL_OP   8'h10

// branch operation
`define EXE_BNE_OP   8'h11
`define EXE_BLEZ_OP  8'h12
`define EXE_BEQ_OP   8'h13
`define EXE_J_OP     8'h14
`define EXE_JAL_OP   8'h15
`define EXE_JR_OP    8'h16
`define EXE_BGTZ_OP  8'h17
`define EXE_BGEZ_OP  8'h18

// load operation
`define EXE_LW_OP    8'h19
`define EXE_SW_OP    8'h1A
`define EXE_LB_OP    8'h1B
`define EXE_SB_OP    8'h1C

// nop operation
`define EXE_NOP_OP   8'h1D

//  -----------------------------------------
// |                 ALU_SEL                 |
//  -----------------------------------------

`define AluSelBus 3

`define EXE_RES_LOGIC       3'b001
`define EXE_RES_SHIFT       3'b010
`define EXE_RES_ARITHMETIC  3'b100	
`define EXE_RES_MUL         3'b101
`define EXE_RES_JUMP_BRANCH 3'b110
`define EXE_RES_LOAD_STORE  3'b111

`define EXE_RES_NOP         3'b000