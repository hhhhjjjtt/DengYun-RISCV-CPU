`define ZeroWord                        32'b0

// ----Address & Data----
`define AddrBus                         31:0
`define DataBus                         31:0
`define ZeroAddr                        32'b0
`define ZeroWord                        32'b0
`define ZeroHalfWord                    16'b0
`define ZeroCtrlBundle                  17'b0

`define ByteSize                        8
`define HalfWordSize                    16
`define WordSize                        32

`define InstAddrBus                     31:0
`define DataAddrBus                     31:0

`define RAM_base                        32'h2000

// ----Register Address & Data----
`define RegsNum                         32
`define RegsAddrBus                     4:0
`define Reg0Addr                        5'b0

// ----ROM----
`define InstAddrDepth                   4096

// ----RAM----
`define DataAddrDepth                   4096

// ----Enable----
`define WriteEnable                     1
`define WriteDisable                    0
`define ReadEnable                      1
`define ReadDisable                     0
`define CycleEnable                     1
`define CycleDisable                    0
`define StrobeEnable                    1
`define StrobeDisable                   0

// ----Pipeline Control----
`define CtrlTypeBus                     1:0
`define ctrl_none                       2'b00
`define ctrl_stall                      2'b01
`define ctrl_flush                      2'b10

// ----Jump Flag----
`define JumpDisable                     0
`define JumpEnable                      1

// ----Pipeline Stall Flag----
`define StallDisable                    0
`define StallEnable                     1

// ----NOP----
`define NOP                             32'h13

// ----Immediate----
`define ImmDataBus                      31:0

// ----Integer Operation----
`define U_OPCODE_LUI            7'b0110111

`define U_OPCODE_AUIPC          7'b0010111

`define I_OPCODE_OP_IMM         7'b0010011
`define funct3_addi             3'b000
`define funct3_slti             3'b010
`define funct3_sltiu            3'b011
`define funct3_xori             3'b100
`define funct3_ori              3'b110
`define funct3_andi             3'b111
`define funct3_slli             3'b001
`define funct3_srli_srai        3'b101
`define funct7_digit6_srli      1'b0
`define funct7_digit6_srai      1'b1

`define R_OPCODE                7'b0110011
`define funct3_add_sub          3'b000
`define funct7_digit6_add       1'b0
`define funct7_digit6_sub       1'b1
`define funct3_sll              3'b001
`define funct3_slt              3'b010
`define funct3_sltu             3'b011
`define funct3_xor              3'b100
`define funct3_srl_sra          3'b101
`define funct7_digit6_srl       1'b0
`define funct7_digit6_sra       1'b1
`define funct3_or               3'b110
`define funct3_and              3'b111

// ----Control Transfer Operation----
`define J_OPCODE_JAL            7'b1101111

`define J_OPCODE_JALR           7'b1100111

`define B_OPCODE                7'b1100011
`define funct3_beq              3'b000
`define funct3_bne              3'b001
`define funct3_blt              3'b100
`define funct3_bge              3'b101
`define funct3_bltu             3'b110
`define funct3_bgeu             3'b111

// ----Memory Access Operation----
`define I_OPCODE_LOAD           7'b0000011
`define funct3_lb               3'b000
`define funct3_lh               3'b001
`define funct3_lw               3'b010
`define funct3_lbu              3'b100
`define funct3_lhu              3'b101

`define S_OPCODE_STORE          7'b0100011
`define funct3_sb               3'b000
`define funct3_sh               3'b001
`define funct3_sw               3'b010

// ----Control Bundle----
`define CtrlBundleBus           16:0

// input A
`define cb_ALU_src_A_rs1        1'b0
`define cb_ALU_src_A_pc         1'b1

// input B 
`define cb_ALU_src_B_rs2        2'b00
`define cb_ALU_src_B_imm        2'b01
`define cb_ALU_src_B_4          2'b10

// writeback source
`define WB_src_ALU              1'b0
`define WB_src_MEM              1'b1

// ALU ops
`define cb_ALU_op_add           4'b0000
`define cb_ALU_op_sub           4'b0001
`define cb_ALU_op_slt           4'b0010
`define cb_ALU_op_sltu          4'b0011
`define cb_ALU_op_xor           4'b0100
`define cb_ALU_op_or            4'b0101
`define cb_ALU_op_and           4'b0110
`define cb_ALU_op_sll           4'b0111
`define cb_ALU_op_srl           4'b1000
`define cb_ALU_op_sra           4'b1001
`define cb_ALU_op_lui           4'b1010

// Branch Conditions
`define cb_Branch_none          3'b000      // no jump
`define cb_Branch_jump          3'b001      // unconditional jump to pc+imm
`define cb_Branch_reg_jump      3'b010      // unconditional jump to reg+imm
`define cb_Branch_jump_eq       3'b100      // conditioanl jump equal
`define cb_Branch_jump_ne       3'b101      // conditional jump not equal
`define cb_Branch_jump_l        3'b110      // conditional jump less than
`define cb_Branch_jump_ge       3'b111      // conditional jump greater than

// rd write source
`define cb_MemtoReg_src_ALU     1'b0        // write to rd from ALU
`define cb_MemtoReg_src_Mem     1'b1        // write to rd from data RAM

// memory operation length & type
`define MemOpTypeBus            2:0
`define cb_Mem_op_byte          3'b000      // 1 byte, signed
`define cb_Mem_op_half          3'b001      // 2 bytes, signed
`define cb_Mem_op_word          3'b010      // 4 bytes
`define cb_Mem_op_ubyte         3'b100      // 1 byte, unsigned
`define cb_Mem_op_uhalf         3'b101      // 2 bytes, unsigned

// memory write strobe
`define StrbBus                 3:0
