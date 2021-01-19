module cl_rca_mult #(
    parameter DATA_WIDTH = 32
) (
    input carry_option,
    input [DATA_WIDTH-1:0] a,
    input [DATA_WIDTH-1:0] b,
    output [2*DATA_WIDTH-1:0] out
    );

    wire [DATA_WIDTH-1:0]   partial_products [0:DATA_WIDTH-1];
    wire [DATA_WIDTH-1:0]   partial_sum [0:DATA_WIDTH-1];
    wire [DATA_WIDTH-1:0]   carry;
    wire [DATA_WIDTH-1:0]   partial_result;

    /* Creo las multiplicaciones parciales */
    genvar i;
    generate
		for (i = 0; i < DATA_WIDTH; i = i + 1) begin
            partial_mult #(DATA_WIDTH) pmult0 (
                .a(a),
                .b(b[i]),
                .out(partial_products[i])
            );
		end
	endgenerate

    assign carry[0] = 1'b0;
    assign partial_sum[0] = partial_products[0];

    /* Creo los N adders de N bits de ancho */
    genvar j;
    generate
        for (j = 0; j < DATA_WIDTH-1; j = j + 1) begin
            cl_rca_adder #(DATA_WIDTH) adder0(
                .carry_option(carry_option),
                .a({carry[j],partial_sum[j][1 +: DATA_WIDTH-1]}),
                .b(partial_products[j+1]),
                .sum(partial_sum[j+1]),
                .co(carry[j+1])
            );
            assign partial_result[j+1] = partial_sum[j+1][0];
        end
    endgenerate

    
    assign out = {carry[DATA_WIDTH-1],partial_sum[DATA_WIDTH-1][DATA_WIDTH-1:1],partial_result};
    assign partial_result[0] = partial_products[0][0];

endmodule