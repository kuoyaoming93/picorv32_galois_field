ICARUS_SUFFIX =
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
COMPRESSED_ISA = #C
PYTHON = python3

RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX = /opt/riscv32
TOOLCHAIN_PREFIX = $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)i/bin/riscv32-unknown-elf-

VERILOG_SOURCES = picorv/picorv32.v galois_field/picorv32_pcpi_galois.v galois_field/cl_modules/cl_modules.v \
					galois_field/cl_modules/cl_rca_adder.v galois_field/cl_modules/cl_half_adder.v \
					galois_field/cl_modules/cl_full_adder.v galois_field/cl_modules/partial_mult.v \
					galois_field/cl_modules/bit_order_inversion.v

TEST_OBJS = #$(addsuffix .o,$(basename $(wildcard tests/*.S)))
FIRMWARE_OBJS = firmware/start.o firmware/galois.o firmware/print.o firmware/irq.o

test: testbench.vvp firmware/firmware.hex
	$(VVP) -N $<

test_ez: testbench_ez.vvp
	$(VVP) -N $<

test_ez_vcd: testbench_ez.vvp
	$(VVP) -N $< +vcd

testbench.vvp: testbench.v $(VERILOG_SOURCES)
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

testbench_ez.vvp: testbench_ez.v 
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^ $(VERILOG_SOURCES)
	chmod -x $@

firmware/firmware.hex: firmware/firmware.bin picorv/firmware/makehex.py
	$(PYTHON) picorv/firmware/makehex.py $< 32768 > $@

firmware/firmware.bin: firmware/firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

firmware/firmware.elf: $(FIRMWARE_OBJS) $(TEST_OBJS) picorv/firmware/sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,-T,picorv/firmware/sections.lds,-Map,firmware/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(TEST_OBJS) -lgcc
	chmod -x $@

firmware/start.o: firmware/start.S
	$(TOOLCHAIN_PREFIX)gcc -c -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -o $@ $<

firmware/%.o: firmware/%.c
	$(TOOLCHAIN_PREFIX)gcc -c -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib -o $@ $<

clean:
	rm -vrf testbench_ez.vvp testbench.vcd 
	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) \
		firmware/firmware.elf firmware/firmware.bin firmware/firmware.hex firmware/firmware.map \
		testbench.vvp \
		testbench.vcd 

.PHONY: test test_ez test_ez_vcd  clean


# riscv32-unknown-elf-gcc -g ./firmware/galois.c -o tst 
# riscv32-unknown-elf-objdump -drwC tst > obj