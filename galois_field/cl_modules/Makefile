RTL_SOURCES = cl_half_adder.v cl_full_adder.v cl_rca_adder.v partial_mult.v bit_order_inversion.v cl_modules.v testmod/cl_rca_mult.v testmod/red_test.v testmod/cl_add.v

ICARUS_SUFFIX =
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)

all: testbench.vvp
	$(VVP) -N $< +vcd

testbench.vvp: testbench.v $(RTL_SOURCES)
	$(IVERILOG) -o $@  $^
	chmod -x $@


clean:
	rm -rf testbench.vvp testbench.vcd


.PHONY: test clean
