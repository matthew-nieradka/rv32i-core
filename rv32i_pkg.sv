// rv32i_pkg.sv — shared definitions for the RV32I core
`timescale 1ns/1ps
package rv32i_pkg;

  // ALU operations. The low bits line up with funct3 so the decoder stays simple;
  // bit 3 picks the "alternate" op (SUB vs ADD, SRA vs SRL), like funct7[5].
  typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,
    ALU_SLL  = 4'b0001,
    ALU_SLT  = 4'b0010,
    ALU_SLTU = 4'b0011,
    ALU_XOR  = 4'b0100,
    ALU_SRL  = 4'b0101,
    ALU_OR   = 4'b0110,
    ALU_AND  = 4'b0111,
    ALU_SUB  = 4'b1000,
    ALU_SRA  = 4'b1101
  } alu_op_t;

  // Major opcodes (instr[6:0]) you will need in the decoder
  localparam logic [6:0] OP_LUI    = 7'b0110111;
  localparam logic [6:0] OP_AUIPC  = 7'b0010111;
  localparam logic [6:0] OP_JAL    = 7'b1101111;
  localparam logic [6:0] OP_JALR   = 7'b1100111;
  localparam logic [6:0] OP_BRANCH = 7'b1100011;
  localparam logic [6:0] OP_LOAD   = 7'b0000011;
  localparam logic [6:0] OP_STORE  = 7'b0100011;
  localparam logic [6:0] OP_IMM    = 7'b0010011;
  localparam logic [6:0] OP_REG    = 7'b0110011;
  localparam logic [6:0] OP_FENCE  = 7'b0001111;
  localparam logic [6:0] OP_SYSTEM = 7'b1110011;

endpackage
