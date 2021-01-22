module picorv32_pcpi_galois #(
	parameter DATA_WIDTH = 32
) (
	input clk, resetn,

	input             pcpi_valid,
	input      [31:0] pcpi_insn,
	input      [31:0] pcpi_rs1,
	input      [31:0] pcpi_rs2,
	output reg        pcpi_wr,
	output reg [31:0] pcpi_rd,
	output reg        pcpi_wait,
	output reg        pcpi_ready
);

	parameter [6:0] OPCODE_R 	= 7'b0110011;
	parameter [6:0] FUNCT7_R 	= 7'b0000100;
	parameter [6:0] FUNCT7_RH 	= 7'b0000101;

	parameter [6:0] OPCODE_S	= 7'b0100011;
	parameter [2:0] FUNCT3_S 	= 3'b100;
	

	reg 	instr_glwidth, instr_gladd, instr_glmul, instr_glred, instr_mul;
	wire	instr_op = 	|{instr_gladd, instr_glmul, instr_glred, instr_mul};
	wire 	instr_any = |{instr_glwidth, instr_op};

	reg 	width_flag;
	reg 	width_finish;
	wire	alu_finish = |{width_finish, op_finish};


	/******************************************************************************************
	*********************************** Module instantiation **********************************
	******************************************************************************************/
	reg 							op_enable;
	wire 							op_finish;
	reg 							sum_funct, exp_funct, red_funct, carry_option;
	reg  [$clog2(DATA_WIDTH):0] 	in_width; 
	reg  [DATA_WIDTH:0]         	polyn_red_in;
	reg  [2*DATA_WIDTH-1:0]        	reduc_in;
	reg  [DATA_WIDTH-1:0]          	in_a, in_b;
	wire [DATA_WIDTH-1:0]     		out;                // Salida normal
    wire [DATA_WIDTH-1:0]     		out_poly;           // Salida poly
    wire [2*DATA_WIDTH-1:0]   		out_mult;           // Salida para la multiplicacion
    wire                     		out_carry;          // Carry out

	cl_modules #(
        .DATA_WIDTH(32)
    ) gf_alu (
		.clk			(clk			),
		.op_enable 		(op_enable		),
      	.op_finish		(op_finish		),
		.sum_funct 		(sum_funct		),          	// Modo Suma
    	.exp_funct		(exp_funct		),          	// Modo Exponencial (al cuadrado)
    	.red_funct		(red_funct		),          	// Modo Polinomio de reduccion
    	.carry_option	(carry_option	),       		// Carry o Carry-Less
		.in_width		(in_width		),

		.polyn_red_in	(polyn_red_in	),       		// Polinomio primitivo
    	.reduc_in 		(reduc_in		),          	// Polinomio a reducir
		.in_a			(in_a 			),              // Entrada 1
    	.in_b 			(in_b 			),              // Entrada 2
    	.out 			(out 			),              // Salida normal
    	.out_poly       (out_poly 		),           	// Salida poly
    	.out_mult 		(out_mult 		),           	// Salida para la multiplicacion
    	.out_carry     	(out_carry		)      			// Carry out
	);

	always @(posedge clk) begin
		sum_funct 		<= 0;
		exp_funct 		<= 0;
		red_funct 		<= 0;
		carry_option 	<= 0;
		in_a 			<= 0;
		in_b 			<= 0;

		if(instr_op) begin
			carry_option 	<= pcpi_insn[14];
			red_funct 		<= pcpi_insn[13];
			sum_funct 		<= pcpi_insn[12];

			in_a			<= pcpi_rs1;
			in_b 			<= pcpi_rs2;
		end
	end

	/******************************************************************************************
	*************************************** PCPI Signals **************************************
	******************************************************************************************/
	always @(posedge clk) begin
		instr_glwidth 	<= 0;
		instr_glmul		<= 0;
		instr_gladd		<= 0;
		instr_glred		<= 0;
		instr_mul		<= 0;
		
		pcpi_wait		<= 0;
		pcpi_wr 		<= 0;
		pcpi_ready 		<= 0;
		pcpi_rd 		<= 0;

		if (resetn && pcpi_valid && pcpi_insn[6:0] == OPCODE_S && pcpi_insn[14:12] == FUNCT3_S) begin
			instr_glwidth <= 1;
		end

		if (resetn && pcpi_valid && pcpi_insn[6:0] == OPCODE_R && pcpi_insn[31:25] == FUNCT7_R) begin
			case (pcpi_insn[14:12])
				3'b000: instr_glmul <= 1;
				3'b001: instr_gladd <= 1;
				3'b010: instr_glred <= 1;
				3'b100: instr_mul 	<= 1;
			endcase
		end

		if(op_finish && pcpi_valid) begin
			pcpi_wr <= 1;
			case (pcpi_insn[14:12])
				3'b000: pcpi_rd <= out_mult[(DATA_WIDTH/2)-1:0];
				3'b001: pcpi_rd <= out;
				3'b010: pcpi_rd <= out_poly;
				3'b100: pcpi_rd <= out_mult[(DATA_WIDTH/2)-1:0];
			endcase
		end

		op_enable 	<= instr_op && pcpi_valid;
		pcpi_wait 	<= instr_any;
		pcpi_ready  <= alu_finish && pcpi_valid;
	end


	/******************************************************************************************
	***************************************** GL WIDTH ****************************************
	******************************************************************************************/
	always @(posedge clk) begin
		if(!resetn) begin
			in_width 		<= DATA_WIDTH;
			polyn_red_in 	<= 0;
			width_finish	<= 0;
		end
		if(instr_glwidth && pcpi_valid) begin
			in_width 		<= pcpi_rs1;
			polyn_red_in	<= (pcpi_rs1==DATA_WIDTH) ? {1'b1,pcpi_rs2} : {1'b0,pcpi_rs2};
			width_finish	<= 1;
		end else begin
			width_finish	<= 0;
		end
	end

	/******************************************************************************************
	************************************** GL Operations **************************************
	******************************************************************************************/
	always @(posedge clk) begin
		if(!resetn)
			reduc_in <= 0;			
		else if(op_finish && instr_glmul) begin
			reduc_in <= out_mult;
		end
	end

endmodule 