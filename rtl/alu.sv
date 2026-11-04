// alu.sv — combinational RV32I ALU
`timescale 1ns/1ps
module alu
  import rv32i_pkg::*;
(
  input  alu_op_t     op,
  input  logic [31:0] a,
  input  logic [31:0] b,
  output logic [31:0] y,
  output logic        zero   // handy for BEQ/BNE
);

  logic [4:0] shamt;
  assign shamt = b[4:0];   // RV32I shifts only use the low 5 bits

  always_comb begin
    case (op)
      ALU_ADD:  y = a + b;
      ALU_SUB:  y = a - b;
      ALU_SLL:  y = a << shamt;
      ALU_SLT:  y = {31'b0, $signed(a) < $signed(b)};
      ALU_SLTU: y = {31'b0, a < b};
      ALU_XOR:  y = a ^ b;
      ALU_SRL:  y = a >> shamt;
      ALU_SRA:  y = $unsigned($signed(a) >>> shamt);
      ALU_OR:   y = a | b;
      ALU_AND:  y = a & b;
      default:  y = 32'b0;
    endcase
  end

  assign zero = (y == 32'b0);

endmodule
