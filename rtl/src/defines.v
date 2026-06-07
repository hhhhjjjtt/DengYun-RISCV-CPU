`ifndef DEFINES_V
`define DEFINES_V

// ----Address & Data----
`define AddrBus                         31:0
`define DataBus                         31:0
`define ZeroAddr                        32'b0
`define ZeroWord                        32'b0
`define ZeroHalfWord                    16'b0

`define ByteSize                        8
`define HalfWordSize                    16
`define WordSize                        32

`define InstAddrBus                     31:0
`define DataAddrBus                     31:0

`define ROM_base                        32'h0
`define RAM_base                        32'h2000
`define Periph_base                     32'h4000

// ----Register Address & Data----
`define RegsNum                         32
`define RegsAddrBus                     4:0
`define Reg0Addr                        5'b0

// ----ROM----
`define InstAddrDepth                   4096

// ----RAM----
`define DataAddrDepth                   4096

// ----Enable/Disable----
`define Enable                          1
`define Disable                         0

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
`define U_OPCODE_LUI                    7'b0110111

`define U_OPCODE_AUIPC                  7'b0010111

`define I_OPCODE_OP_IMM                 7'b0010011
`define funct3_addi                     3'b000
`define funct3_slti                     3'b010
`define funct3_sltiu                    3'b011
`define funct3_xori                     3'b100
`define funct3_ori                      3'b110
`define funct3_andi                     3'b111
`define funct3_slli                     3'b001
`define funct3_srli_srai                3'b101

`define R_OPCODE                        7'b0110011
`define funct3_add_sub                  3'b000
`define funct3_sll                      3'b001
`define funct3_slt                      3'b010
`define funct3_sltu                     3'b011
`define funct3_xor                      3'b100
`define funct3_srl_sra                  3'b101
`define funct3_or                       3'b110
`define funct3_and                      3'b111

// ----M Instructions----
`define funct3_mul                      3'b000
`define funct3_mulh                     3'b001
`define funct3_mulhsu                   3'b010
`define funct3_mulhu                    3'b011
`define funct3_div                      3'b100
`define funct3_divu                     3'b101
`define funct3_rem                      3'b110
`define funct3_remu                     3'b111
`define funct7_mul_div                  7'b0000001

// ----Control Transfer Operation----
`define J_OPCODE_JAL                    7'b1101111

`define J_OPCODE_JALR                   7'b1100111

`define B_OPCODE                        7'b1100011
`define funct3_beq                      3'b000
`define funct3_bne                      3'b001
`define funct3_blt                      3'b100
`define funct3_bge                      3'b101
`define funct3_bltu                     3'b110
`define funct3_bgeu                     3'b111

// ----Memory Access Operation----
`define I_OPCODE_LOAD                   7'b0000011
`define funct3_lb                       3'b000
`define funct3_lh                       3'b001
`define funct3_lw                       3'b010
`define funct3_lbu                      3'b100
`define funct3_lhu                      3'b101

`define S_OPCODE_STORE                  7'b0100011
`define funct3_sb                       3'b000
`define funct3_sh                       3'b001
`define funct3_sw                       3'b010

// ----System----
`define OPCODE_SYSTEM                   7'b1110011
`define funct3_csrrw                    3'b001
`define funct3_csrrs                    3'b010
`define funct3_csrrc                    3'b011
`define funct3_csrrwi                   3'b101
`define funct3_csrrsi                   3'b110
`define funct3_csrrci                   3'b111


// ----EX Control----

// input A      
`define ALU_src_A_rs1                   1'b0
`define ALU_src_A_pc                    1'b1

// input B      
`define ALU_src_B_rs2                   2'b00
`define ALU_src_B_imm                   2'b01
`define ALU_src_B_4                     2'b10

// writeback source     
`define WB_src_ALU                      1'b0
`define WB_src_MEM                      1'b1

// ALU ops
`define ALU_op_add                      5'b00000
`define ALU_op_sub                      5'b00001
`define ALU_op_slt                      5'b00010
`define ALU_op_sltu                     5'b00011
`define ALU_op_xor                      5'b00100
`define ALU_op_or                       5'b00101
`define ALU_op_and                      5'b00110
`define ALU_op_sll                      5'b00111
`define ALU_op_srl                      5'b01000
`define ALU_op_sra                      5'b01001
`define ALU_op_lui                      5'b01010
`define ALU_op_mul                      5'b01011
`define ALU_op_mulh                     5'b01100
`define ALU_op_mulhsu                   5'b01101
`define ALU_op_mulhu                    5'b01110
`define ALU_op_div                      5'b01111
`define ALU_op_divu                     5'b10000
`define ALU_op_rem                      5'b10001
`define ALU_op_remu                     5'b10010

// Branch Conditions
`define Branch_none                     3'b000         // no jump
`define Branch_jump                     3'b001         // unconditional jump to pc+imm
`define Branch_reg_jump                 3'b010         // unconditional jump to reg+imm
`define Branch_jump_eq                  3'b100         // conditioanl jump equal
`define Branch_jump_ne                  3'b101         // conditional jump not equal
`define Branch_jump_l                   3'b110         // conditional jump less than
`define Branch_jump_ge                  3'b111         // conditional jump greater than

// rd write source
`define MemtoReg_src_ALU                1'b0           // write to rd from ALU
`define MemtoReg_src_Mem                1'b1           // write to rd from data RAM

// memory operation length & type
`define MemOpTypeBus                    2:0
`define Mem_op_byte                     3'b000         // 1 byte, signed
`define Mem_op_half                     3'b001         // 2 bytes, signed
`define Mem_op_word                     3'b010         // 4 bytes
`define Mem_op_ubyte                    3'b100         // 1 byte, unsigned
`define Mem_op_uhalf                    3'b101         // 2 bytes, unsigned

// memory write strobe
`define StrbBus                         3:0

// ----Trap Cause----
`define TrapCauseBus                    1:0
`define trap_none                       2'b00
`define trap_ecall                      2'b01
`define trap_ebreak                     2'b10
`define trap_mret                       2'b11

// ----SYSTEM funct12----
`define funct12_ecall                   12'h000
`define funct12_ebreak                  12'h001
`define funct12_mret                    12'h302

// ----mstatus bit masks----
`define MSTATUS_MIE                     32'h00000008   // bit 3
`define MSTATUS_MPIE                    32'h00000080   // bit 7
`define MSTATUS_MPP                     32'h00001800   // bits 12:11
`define MSTATUS_CLEAR                   32'h00001888   // MIE | MPIE | MPP

// ----CSR Address----
`define CSRAddrBus                      11:0

`define CSR_CYCLE                       12'hC00
`define CSR_CYCLEH                      12'hC80
`define CSR_MSTATUS                     12'h300
`define CSR_MIE                         12'h304
`define CSR_MTVEC                       12'h305
`define CSR_MSCRATCH                    12'h340
`define CSR_MEPC                        12'h341
`define CSR_MCAUSE                      12'h342

`endif