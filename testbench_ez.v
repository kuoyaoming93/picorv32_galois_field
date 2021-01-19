// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

`timescale 1 ns / 1 ps

module testbench;
	reg clk = 1;
	reg resetn = 0;
	wire trap;

	always #5 clk = ~clk;

	initial begin
		if ($test$plusargs("vcd")) begin
			$dumpfile("testbench.vcd");
			$dumpvars(0, testbench);
		end
		repeat (100) @(posedge clk);
		resetn <= 1;
		repeat (1000) @(posedge clk);
		$finish;
	end

	wire mem_valid;
	wire mem_instr;
	reg mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	reg  [31:0] mem_rdata;

	always @(posedge clk) begin
		if (mem_valid && mem_ready) begin
			if (mem_instr)
				$display("ifetch 0x%08x: 0x%08x", mem_addr, mem_rdata);
			else if (mem_wstrb)
				$display("write  0x%08x: 0x%08x (wstrb=%b)", mem_addr, mem_wdata, mem_wstrb);
			else
				$display("read   0x%08x: 0x%08x", mem_addr, mem_rdata);
		end
	end


    // Pico Co-Processor Interface (PCPI)
	wire        pcpi_valid;
	wire [31:0] pcpi_insn;
	wire [31:0] pcpi_rs1;
	wire [31:0] pcpi_rs2;
	wire        pcpi_wr;
	wire [31:0] pcpi_rd;
	wire        pcpi_wait;
	wire        pcpi_ready;

	picorv32 #(
        .ENABLE_PCPI(1)
	) uut (
		.clk         (clk        ),
		.resetn      (resetn     ),
		.trap        (trap       ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  ),

        // Pico Co-Processor Interface (PCPI)
	    .pcpi_valid  (pcpi_valid ),
	    .pcpi_insn   (pcpi_insn  ),
	    .pcpi_rs1    (pcpi_rs1   ),
	    .pcpi_rs2    (pcpi_rs2   ),
	    .pcpi_wr     (pcpi_wr    ),
	    .pcpi_rd     (pcpi_rd    ),
	    .pcpi_wait   (pcpi_wait  ),
	    .pcpi_ready  (pcpi_ready )
	);

    picorv32_pcpi_galois #(
        .DATA_WIDTH(32)
    ) gf_uut (
        .clk         (clk        ),
		.resetn      (resetn     ),
        // Pico Co-Processor Interface (PCPI)
	    .pcpi_valid  (pcpi_valid ),
	    .pcpi_insn   (pcpi_insn  ),
	    .pcpi_rs1    (pcpi_rs1   ),
	    .pcpi_rs2    (pcpi_rs2   ),
	    .pcpi_wr     (pcpi_wr    ),
	    .pcpi_rd     (pcpi_rd    ),
	    .pcpi_wait   (pcpi_wait  ),
	    .pcpi_ready  (pcpi_ready )
    );





	reg [31:0] memory [0:255];
	
	reg [11:0] reg1, reg2;

	initial begin
		//memory[0] = 32'h 3fc00093; //       li      x1,1020
		//memory[1] = 32'h 0000a023; //       sw      x0,0(x1)
		//memory[2] = 32'h 0000a103; // loop: lw      x2,0(x1)
		//memory[3] = 32'h 00110113; //       addi    x2,x2,1
		//memory[4] = 32'h 0020a023; //       sw      x2,0(x1)
		//memory[5] = 32'h ff5ff06f; //       j       <loop>
		//memory[0] = 32'h 3fc00093; //       li      x1,1020}

		reg1 = 12'd31;
		reg2 = 12'd1020;

		memory[0] = {reg1,8'b0,5'd1,7'b0010011}; //       li      x1,31
		memory[1] = {reg2,8'b0,5'd2,7'b0010011}; //       li      x2,1020
        memory[2] = 32'h 0020c023;
	end

	always @(posedge clk) begin
		mem_ready <= 0;
		if (mem_valid && !mem_ready) begin
			if (mem_addr < 1024) begin
				mem_ready <= 1;
				mem_rdata <= memory[mem_addr >> 2];
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
			end
			/* add memory-mapped IO here */
		end
	end
endmodule
