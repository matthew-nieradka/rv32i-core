# make alu      -> run ALU testbench (Icarus)
# make regfile  -> run register-file testbench (Icarus)
# make all      -> run both
# make SIM=verilator alu   -> same with Verilator 5+
# make SIM=xsim all        -> same with the Vivado simulator (run from a Vivado-sourced shell)
SIM ?= icarus
PKG := rtl/rv32i_pkg.sv

all: alu regfile

alu:     ; $(MAKE) run TOP=alu_tb     SRCS="$(PKG) rtl/alu.sv tb/alu_tb.sv"
regfile: ; $(MAKE) run TOP=regfile_tb SRCS="$(PKG) rtl/regfile.sv tb/regfile_tb.sv"

ifeq ($(SIM),xsim)
run:
	mkdir -p build/$(TOP)
	cd build/$(TOP) && xvlog -sv $(addprefix ../../,$(SRCS)) && xelab -debug typical $(TOP) -s $(TOP)_sim && xsim $(TOP)_sim -R
else ifeq ($(SIM),verilator)
run:
	mkdir -p build/$(TOP)
	verilator --binary --timing -Wno-fatal -j 0 --top-module $(TOP) $(SRCS) -o $(TOP) --Mdir build/$(TOP)
	./build/$(TOP)/$(TOP)
else
run:
	mkdir -p build
	iverilog -g2012 -s $(TOP) -o build/$(TOP).vvp $(SRCS)
	vvp -n build/$(TOP).vvp
endif

clean: ; rm -rf build

.PHONY: all alu regfile run clean
