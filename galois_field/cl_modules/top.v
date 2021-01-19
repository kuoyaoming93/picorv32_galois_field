module top #(
    parameter DATA_WIDTH = 32
) (
    input                           resetn,
    input                           clk,
    input                           op_enable,
    output                          op_finish,

    input                           sum_funct,          // Modo Suma
    input                           exp_funct,          // Modo Exponencial (al cuadrado)
    input                           red_funct,          // Modo Polinomio de reduccion
    input                           carry_option,       // Carry o Carry-Less

    input [$clog2(DATA_WIDTH):0]    in_width,

    input [DATA_WIDTH:0]            polyn_red_in,       // Polinomio primitivo
    input [2*DATA_WIDTH-1:0]        reduc_in,           // Polinomio a reducir

    input [DATA_WIDTH-1:0]          in_a,               // Entrada 1
    input [DATA_WIDTH-1:0]          in_b,               // Entrada 2
    output                          out,                // Salida normal
    output                          out_poly,           // Salida poly
    output                          out_mult,           // Salida para la multiplicacion
    output                          out_carry           // Carry out
);


    wire [2*DATA_WIDTH-1:0]   reduc_in_p;
    wire [DATA_WIDTH-1:0]     out_p;                // Salida normal
    wire [DATA_WIDTH-1:0]     out_poly_p;           // Salida poly
    wire [2*DATA_WIDTH-1:0]   out_mult_p;           // Salida para la multiplicacion

    input_regs #(2*DATA_WIDTH) input0 (
        .clk(clk),
        .resetn(resetn),
        .in_serial(reduc_in),
        .out_parallel(reduc_in_p)
    );

    output_regs #(DATA_WIDTH) output0 (
        .clk(clk),
        .resetn(resetn),
        .in_parallel(out_p),
        .out_serial(out)
    );

    output_regs #(DATA_WIDTH) output1 (
        .clk(clk),
        .resetn(resetn),
        .in_parallel(out_poly_p),
        .out_serial(out_poly)
    );

    output_regs #(2*DATA_WIDTH) output2 (
        .clk(clk),
        .resetn(resetn),
        .in_parallel(out_mult_p),
        .out_serial(out_mult)
    );

    cl_modules #(DATA_WIDTH) dut0(
        .clk(clk),
        .op_enable(op_enable),
        .op_finish(op_finish),

        .sum_funct(sum_funct),
        .exp_funct(exp_funct),
        .red_funct(red_funct),
        .carry_option(carry_option),

        .in_width(in_width),

        .polyn_red_in(polyn_red_in),    // Polinomio primitivo
        .reduc_in(reduc_in_p),      // Polinomio a reducir

        .in_a(in_a),
        .in_b(in_b),
        .out_mult(out_mult_p),
        .out(out_p),
        .out_poly(out_poly_p),
        .out_carry(out_carry)
        
    );

endmodule

