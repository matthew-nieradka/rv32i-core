# RV32I Core — Design + Verification

A RISC-V RV32I CPU in SystemVerilog, built verification-first: every block gets a
self-checking testbench before it's integrated.

## Status
| Block | RTL | Testbench | Result |
|---|---|---|---|
| ALU (10 ops) | done | self-checking, 22k checks, 60 coverage bins | 0 errors, 100% bins |
| Register file (32x32, x0 hardwired) | done | shadow model + x0 assertion, 80k checks | 0 errors |
| Immediate generator | todo | | |
| Decoder / control | todo | | |
| Single-cycle datapath | todo | | |
| 5-stage pipeline | todo | | |

## Run it
Needs Icarus Verilog 12+ or Verilator 5+ (on Windows use WSL: `sudo apt install iverilog verilator gtkwave make`).

```
make all                 # Icarus
make SIM=verilator all   # Verilator
```

## How the testbenches work
- **Reference model** written a different way from the RTL (e.g. SUB as `a + ~b + 1`,
  SRA via 64-bit sign extension), so one misunderstanding can't hide in both.
- **Directed corners first** (0, 1, -1, INT_MIN, INT_MAX, 31) for every op, then
  **biased random** that picks edge values far more often than pure random.
- **Functional coverage**: per-op bins (a==b, opposite signs, zero operand,
  shift by 0, shift by 31, zero result). Holes get printed by name.
- **Bug injection**: break the RTL on purpose (e.g. make SRA logical) and confirm
  the testbench fails. A testbench that never fails proves nothing.

## Bug log
Log every bug you find from here on. Keep it honest — interviewers ask about it.

| # | Where | Symptom | Root cause | How it was caught |
|---|---|---|---|---|
| 1 | | | | |

## Notes on the starter testbenches
- `regfile_tb` checks the x0 assertion at posedge. The stimulus changes addresses at negedge,
  so checking there would race the combinational read and fail on correct RTL.
- Counters use `x = x + 1` instead of `x++`. Under Verilator 5.020, `x++` inside these
  conditionals miscounted and reported thousands of false errors.

## Next up
1. `imm_gen.sv` — I/S/B/U/J immediates. Test: for random 32-bit instructions, compare against a reference written straight from the spec tables.
2. `decoder.sv` — opcode/funct3/funct7 → control signals + `alu_op_t`.
3. Single-cycle top + instruction/data memory loaded with `$readmemh`.
4. Reference ISS in Python, then compare retired-instruction traces (pc, rd, value) against the RTL.
