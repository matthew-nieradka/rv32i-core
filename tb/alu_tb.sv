// alu_tb.sv — self-checking testbench for the ALU
//   * reference model written a different way than the RTL (so the same bug can't hide in both)
//   * directed corner cases, then constrained-random stimulus
//   * hand-rolled functional coverage (swap for covergroups once your simulator supports them)
`timescale 1ns/1ps
module alu_tb;
  import rv32i_pkg::*;

  alu_op_t     op;
  logic [31:0] a, b, y;
  logic        zero;

  alu dut (.op(op), .a(a), .b(b), .y(y), .zero(zero));

  // ---------------- reference model ----------------
  function automatic logic [31:0] ref_alu(alu_op_t f_op, logic [31:0] fa, logic [31:0] fb);
    logic [63:0] sext;
    case (f_op)
      ALU_ADD:  return fa + fb;
      ALU_SUB:  return fa + (~fb + 32'd1);                 // two's complement, not "-"
      ALU_SLL:  return fa << fb[4:0];
      ALU_SRL:  return fa >> fb[4:0];
      ALU_SRA:  begin
                  sext = {{32{fa[31]}}, fa};               // sign-extend to 64 then logical shift
                  sext = sext >> fb[4:0];
                  return sext[31:0];
                end
      ALU_SLT:  // signed compare via sign bits
                if (fa[31] != fb[31]) return {31'b0, fa[31]};
                else                  return {31'b0, fa < fb};
      ALU_SLTU: return {31'b0, fa < fb};
      ALU_XOR:  return fa ^ fb;
      ALU_OR:   return fa | fb;
      ALU_AND:  return fa & fb;
      default:  return 32'b0;
    endcase
  endfunction

  // ---------------- coverage ----------------
  localparam int NOPS  = 10;
  localparam int NBINS = 6;   // per-op corner bins
  alu_op_t ops [NOPS];
  initial begin   // (filled element-by-element so Icarus is happy too)
    ops[0] = ALU_ADD;  ops[1] = ALU_SUB;  ops[2] = ALU_SLL; ops[3] = ALU_SRL; ops[4] = ALU_SRA;
    ops[5] = ALU_SLT;  ops[6] = ALU_SLTU; ops[7] = ALU_XOR; ops[8] = ALU_OR;  ops[9] = ALU_AND;
  end
  int hits [NOPS][NBINS];
  initial foreach (hits[i, j]) hits[i][j] = 0;
  // bins: 0 a==b | 1 a,b opposite signs | 2 a==0 or b==0 | 3 b[4:0]==0 | 4 b[4:0]==31 | 5 result==0

  function automatic int op_index(alu_op_t o);
    for (int i = 0; i < NOPS; i++) if (ops[i] == o) return i;
    return -1;
  endfunction

  task automatic sample();
    int i;
    i = op_index(op);
    if (a == b)               hits[i][0] = hits[i][0] + 1;
    if (a[31] != b[31])       hits[i][1] = hits[i][1] + 1;
    if (a == 0 || b == 0)     hits[i][2] = hits[i][2] + 1;
    if (b[4:0] == 5'd0)       hits[i][3] = hits[i][3] + 1;
    if (b[4:0] == 5'd31)      hits[i][4] = hits[i][4] + 1;
    if (y == 0)               hits[i][5] = hits[i][5] + 1;
  endtask

  // ---------------- check ----------------
  int errors = 0, checks = 0;

  task automatic drive_and_check(alu_op_t t_op, logic [31:0] ta, logic [31:0] tb);
    logic [31:0] exp;
    op = t_op; a = ta; b = tb;
    #1;
    exp = ref_alu(t_op, ta, tb);
    checks = checks + 1;
    sample();
    if (y !== exp || zero !== (exp == 0)) begin
      errors = errors + 1;
      if (errors <= 10)
        $display("ERROR op=%s a=%h b=%h : got y=%h zero=%b, expected %h",
                 t_op.name(), ta, tb, y, zero, exp);
    end
  endtask

  // biased random: hit interesting values far more often than pure random would
  function automatic logic [31:0] rand_operand();
    case ($urandom_range(0, 7))
      0: return 32'h0000_0000;
      1: return 32'hFFFF_FFFF;
      2: return 32'h8000_0000;
      3: return 32'h7FFF_FFFF;
      4: return 32'h0000_0001;
      5: return $urandom_range(0, 31);
      default: return $urandom;
    endcase
  endfunction

  initial begin
    logic [31:0] corners [6];
    int covered, total;
    corners[0] = 32'h0;         corners[1] = 32'h1;         corners[2] = 32'hFFFF_FFFF;
    corners[3] = 32'h8000_0000; corners[4] = 32'h7FFF_FFFF; corners[5] = 32'h1F;
    #0;  // let the ops[] initial block run first

    // 1) directed: every op x every pair of corner values
    foreach (ops[k])
      foreach (corners[i])
        foreach (corners[j])
          drive_and_check(ops[k], corners[i], corners[j]);

    // 2) random
    repeat (20000) begin
      drive_and_check(ops[$urandom_range(0, NOPS-1)], rand_operand(), rand_operand());
      if ($urandom_range(0, 9) == 0) begin   // force a == b sometimes
        a = rand_operand();
        drive_and_check(ops[$urandom_range(0, NOPS-1)], a, a);
      end
    end

    // 3) report
    covered = 0; total = NOPS * NBINS;
    foreach (hits[i, j]) if (hits[i][j] > 0) covered++;
    $display("--------------------------------------------");
    $display("ALU: %0d checks, %0d errors", checks, errors);
    $display("Coverage: %0d / %0d bins hit (%0d%%)", covered, total, covered * 100 / total);
    foreach (hits[i, j]) if (hits[i][j] == 0) begin
      op = alu_op_t'(ops[i]);
      $display("  HOLE: op=%s bin=%0d never hit", op.name(), j);
    end
    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED");
    $display("--------------------------------------------");
    $finish;
  end

endmodule
