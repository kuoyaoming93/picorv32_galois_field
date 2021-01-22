ICARUS_SUFFIX =
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
COMPRESSED_ISA = C



test_ez: testbench_ez.vvp
	$(VVP) -N $<

test_ez_vcd: testbench_ez.vvp
	$(VVP) -N $< +vcd

testbench_ez.vvp: testbench_ez.v picorv/picorv32.v galois_field/picorv32_pcpi_galois.v galois_field/cl_modules/cl_modules.v galois_field/cl_modules/cl_rca_adder.v galois_field/cl_modules/cl_half_adder.v galois_field/cl_modules/cl_full_adder.v galois_field/cl_modules/partial_mult.v galois_field/cl_modules/bit_order_inversion.v
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

clean:
	rm -vrf testbench_ez.vvp testbench.vcd 

.PHONY: test_ez test_ez_vcd  clean
