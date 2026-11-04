// regfile_tb.sv — self-checking testbench for the register file
//   * shadow model (a plain array) predicts every read
//   * random reads/writes, with extra pressure on x0 and same-address read/write
//   * immediate assertion: x0 must always read 0
`timescale 1ns/1ps
module regfile_tb;

  logic        clk = 0, rst_n = 0;
  logic [4:0]  rs1_addr, rs2_addr, rd_addr;
  logic [31:0] rs1_data, rs2_data, rd_data;
  logic        we;

  regfile dut (.*);

  always #5 clk = ~clk;

  logic [31:0] model [32];
  int errors = 0;
  int checks = 0;
  int x0_write_attempts = 0, same_cycle_rw = 0;

  task automatic check_reads();
    checks += 2;
    if (rs1_data !== model[rs1_addr]) begin
      errors = errors + 1;
      if (errors <= 10) $display("ERROR t=%0t rs1 x%0d: got %h exp %h", $time, rs1_addr, rs1_data, model[rs1_addr]);
    end
    if (rs2_data !== model[rs2_addr]) begin
      errors = errors + 1;
      if (errors <= 10) $display("ERROR t=%0t rs2 x%0d: got %h exp %h", $time, rs2_addr, rs2_data, model[rs2_addr]);
    end
  endtask

  // x0 invariant. Sampled at posedge: the TB changes addresses at negedge, so sampling
  // there would race the combinational read (a classic testbench bug, not a DUT bug).
  always @(posedge clk) if (rst_n) begin
    assert (!(rs1_addr == 0 && rs1_data != 0)) else begin errors = errors + 1; $display("ASSERT FAIL: x0 read nonzero on rs1"); end
    assert (!(rs2_addr == 0 && rs2_data != 0)) else begin errors = errors + 1; $display("ASSERT FAIL: x0 read nonzero on rs2"); end
  end

  initial begin
    foreach (model[i]) model[i] = 0;
    we = 0; rd_addr = 0; rd_data = 0; rs1_addr = 0; rs2_addr = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;

    // after reset everything reads 0
    for (int r = 0; r < 32; r++) begin
      @(negedge clk); rs1_addr = 5'(r); rs2_addr = 5'(31 - r); #1; check_reads();
    end

    repeat (20000) begin
      @(negedge clk);
      we       = ($urandom_range(0, 3) != 0);
      rd_addr  = ($urandom_range(0, 7) == 0) ? 5'd0 : 5'($urandom);   // ~12% target x0
      rd_data  = $urandom;
      rs1_addr = ($urandom_range(0, 3) == 0) ? rd_addr : 5'($urandom); // often read what we're writing
      rs2_addr = 5'($urandom);
      if (we && rd_addr == 0) x0_write_attempts = x0_write_attempts + 1;
      if (we && rs1_addr == rd_addr && rd_addr != 0) same_cycle_rw = same_cycle_rw + 1;
      #1; check_reads();          // before the edge: old value expected
      @(posedge clk);
      if (we && rd_addr != 0) model[rd_addr] = rd_data;
      #1; check_reads();          // after the edge: new value expected
    end

    $display("--------------------------------------------");
    $display("REGFILE: %0d checks, %0d errors", checks, errors);
    $display("  x0 write attempts: %0d, same-cycle read/write: %0d", x0_write_attempts, same_cycle_rw);
    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED");
    $display("--------------------------------------------");
    $finish;
  end

endmodule
