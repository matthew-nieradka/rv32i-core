// regfile.sv — 32 x 32-bit register file, 2 async read ports, 1 sync write port.
`timescale 1ns/1ps
// x0 is hardwired to zero: writes to it are ignored and reads always return 0.
module regfile (
  input  logic        clk,
  input  logic        rst_n,
  // read ports
  input  logic [4:0]  rs1_addr,
  input  logic [4:0]  rs2_addr,
  output logic [31:0] rs1_data,
  output logic [31:0] rs2_data,
  // write port
  input  logic        we,
  input  logic [4:0]  rd_addr,
  input  logic [31:0] rd_data
);

  logic [31:0] regs [1:31];   // no storage for x0

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 1; i < 32; i++) regs[i] <= 32'b0;
    end else if (we && rd_addr != 5'd0) begin
      regs[rd_addr] <= rd_data;
    end
  end

  // Note: a read in the same cycle as a write to the same register returns the OLD
  // value. When you build the pipeline, you will either add write-first bypass here
  // or forward in the pipeline. Write a test for whichever you choose.
  assign rs1_data = (rs1_addr == 5'd0) ? 32'b0 : regs[rs1_addr];
  assign rs2_data = (rs2_addr == 5'd0) ? 32'b0 : regs[rs2_addr];

endmodule
