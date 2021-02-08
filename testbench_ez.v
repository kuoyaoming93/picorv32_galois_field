// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

`timescale 1 ns / 1 ps
`define DEBUG

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
		repeat (300) @(posedge clk);
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

	parameter [6:0] OPCODE_R = 7'b0110011;
	parameter [6:0] FUNCT7_R = 7'b0000001;
	parameter [6:0] FUNCT7_G = 7'b0000100;


	initial begin

		// MULT
		reg1 = 12'h743;
		reg2 = 12'h7fe;
		memory[3] = {reg1,8'b0,5'd1,7'b0010011};    			//      li      	x1,h743
		memory[4] = {reg2,8'b0,5'd2,7'b0010011};    			//      li      	x2,h7fe
		memory[5] = {FUNCT7_R,5'd2,5'd1,3'd1,5'd4,OPCODE_R};	// 		MULH		= 743*7FE = 3A097A
		memory[6] = {FUNCT7_R,5'd2,5'd1,3'd0,5'd4,OPCODE_R};	// 		MUL			= 743*7FE = 3A097A
		memory[7] = {FUNCT7_R,5'd4,5'd4,3'd1,5'd5,OPCODE_R};	// 		MULH		= 3A097A * 3A097A = D284BA1CE24
		memory[8] = {FUNCT7_R,5'd4,5'd4,3'd0,5'd5,OPCODE_R};	// 		MUL			= 3A097A * 3A097A = D284BA1CE24

		// GL MULT
		reg1 = 12'b1110;
		reg2 = 12'b1111;
		memory[9] = {reg1,8'b0,5'd1,7'b0010011};    			//      li      x1,b1010
		memory[10] = {reg2,8'b0,5'd2,7'b0010011};    			//      li      x2,b1110
		memory[11] = {FUNCT7_G,5'd2,5'd1,3'd2,5'd3,OPCODE_R};	// 		CLMULH
		memory[12] = {FUNCT7_G,5'd2,5'd1,3'd0,5'd4,OPCODE_R};	// 		CLMUL

		// GL WIDTH
		reg1 = 12'd4;
		reg2 = 12'b10011;
		memory[13] = {reg1,8'b0,5'd1,7'b0010011};    			//      li      	x1,d31
		memory[14] = {reg2,8'b0,5'd2,7'b0010011};    			//      li      	x2,b11001
		memory[15] = {FUNCT7_G,5'd2,5'd1,3'd4,5'd3,OPCODE_R};	// 		GLWIDTH

		memory[16] = {FUNCT7_G,5'd4,5'd3,3'd1,5'd5,OPCODE_R};	// 		Polynomial reduction
	

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
