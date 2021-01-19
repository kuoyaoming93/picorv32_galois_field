module cl_modules #(
    parameter DATA_WIDTH = 32
) (
    input                           clk,
    input                           op_enable,
    output reg                      op_finish,

    input                           sum_funct,          // Modo Suma
    input                           exp_funct,          // Modo Exponencial (al cuadrado)
    input                           red_funct,          // Modo Polinomio de reduccion
    input                           carry_option,       // Carry o Carry-Less

    input [$clog2(DATA_WIDTH):0]    in_width,

    input [DATA_WIDTH:0]            polyn_red_in,       // Polinomio primitivo
    input [2*DATA_WIDTH-1:0]        reduc_in,           // Polinomio a reducir

    input [DATA_WIDTH-1:0]          in_a,               // Entrada 1
    input [DATA_WIDTH-1:0]          in_b,               // Entrada 2
    output reg [DATA_WIDTH-1:0]     out,                // Salida normal
    output reg [DATA_WIDTH-1:0]     out_poly,           // Salida poly
    output reg [2*DATA_WIDTH-1:0]   out_mult,           // Salida para la multiplicacion
    output reg                      out_carry           // Carry out
);

    reg [$clog2(DATA_WIDTH):0] count, count_d1, count_d2, count_d3;

    always @(posedge clk) begin
        if(!op_enable) begin
            count       <= 0;
            count_d1    <= 0;
            count_d2    <= 0;
            count_d3    <= 0;
        end
        else begin
            if(count < DATA_WIDTH) begin
                count       <= count + 1;
                
            end
            else begin 
            end
            count_d1    <= count;
            count_d2    <= count_d1;
            count_d3    <= count_d2;
        end
    end

    //////////////////////////////////////////////////////////
    // Generacion de los operandos
    //////////////////////////////////////////////////////////

    wire [DATA_WIDTH:0]         polyn_red_op [0:DATA_WIDTH];
    wire [DATA_WIDTH:0]         polyn_red_op_out;
    wire [2*DATA_WIDTH-1:0]     reduc_op [0:DATA_WIDTH];
    wire [2*DATA_WIDTH-1:0]     reduc_op_out;

    /* Creo N conexiones, customizando para operar con cualquier grado de polinomio primitivo */
    genvar i;
    generate
        for (i = 0; i <= DATA_WIDTH; i = i + 1) begin
            assign polyn_red_op[i] =    (i > 1) ? {polyn_red_in[i:0],{DATA_WIDTH-i{1'b0}}} : 'b0;
            assign reduc_op[i] =        (i > 1) ? {reduc_in[(2*i)-1:0],{(2*(DATA_WIDTH-i)){1'b0}}} : 'b0;
        end
    endgenerate

    assign polyn_red_op_out = polyn_red_op[in_width];
    assign reduc_op_out = reduc_op[in_width];

    
    // Registro las salidas para esta etapa
    reg [DATA_WIDTH:0]         poly_red_reg;
    reg [2*DATA_WIDTH-1:0]     reduc_reg;

    always @(posedge clk) begin
        if(!op_enable) begin
            poly_red_reg    <= 0;
            reduc_reg       <= 0;
        end else begin
            poly_red_reg    <= polyn_red_op_out;
            reduc_reg       <= reduc_op_out;
        end
    end

    //////////////////////////////////////////////////////////
    // Inversion de las entradas - Para reducir el polinomio
    //////////////////////////////////////////////////////////

    wire [2*DATA_WIDTH-1:0]     reduc_in_n;         // Polinomio a reducir invertido
    wire [DATA_WIDTH:0]         polyn_red_in_n;     // Polinomio primitivo invertido

    bit_order_inversion #(2*DATA_WIDTH) bit_inv_reduc(
        .a(reduc_reg),
        .a_n(reduc_in_n)
    );
    bit_order_inversion #(DATA_WIDTH+1) bit_inv_polym(
        .a(poly_red_reg),
        .a_n(polyn_red_in_n)
    );

    // Registro las salidas para esta etapa
    reg [DATA_WIDTH:0]         poly_red_inv_reg;
    reg [2*DATA_WIDTH-1:0]     reduc_inv_reg;

    always @(posedge clk) begin
        if(!op_enable) begin
            poly_red_inv_reg    <= 0;
            reduc_inv_reg       <= 0;
        end else begin
            poly_red_inv_reg    <= polyn_red_in_n;
            reduc_inv_reg       <= reduc_in_n;
        end
    end

    //////////////////////////////////////////////////////////
    // Modulo de multiplicaciones parciales
    //////////////////////////////////////////////////////////

    wire [DATA_WIDTH-1:0]   in_partial_mult_a;
    wire                    in_partial_mult_b;
    wire [DATA_WIDTH-1:0]   partial_products;
    reg [DATA_WIDTH-1:0]    partial_products_reg;
    reg [DATA_WIDTH-1:0]    pp_prev;

    always @(posedge clk) begin
        if(!count) begin
            partial_products_reg    <= 0;
            pp_prev                 <= 0;
        end
        else begin
            partial_products_reg    <= partial_products;
            pp_prev                 <= partial_products_reg;
        end
    end

    wire [DATA_WIDTH-1:0] exp_mux;

    assign exp_mux = exp_funct ? in_a : in_b;
    assign in_partial_mult_a = in_a;
    assign in_partial_mult_b = count ? exp_mux[count-1] : 0;

    partial_mult #(DATA_WIDTH) pmult0 (
        .a(in_partial_mult_a),
        .b(in_partial_mult_b),
        .out(partial_products)
    );
    
    //////////////////////////////////////////////////////////
    // Modulo de sumas parciales
    //////////////////////////////////////////////////////////

    // Module connections
    wire [DATA_WIDTH:0]     in_adder_a;
    wire [DATA_WIDTH:0]     in_adder_b;
    wire [DATA_WIDTH:0]     out_adder_sum;
    wire                    out_adder_carry;
    wire                    bit_selector;

    // Registers
    reg [DATA_WIDTH:0]      out_adder_reg;
    reg [DATA_WIDTH-1:0]    partial_result;
    reg                     out_carry_reg;
    reg [DATA_WIDTH:0]      partial_sum;
    reg                     partial_carry;

    always @(posedge clk) begin
        if (!op_enable) begin
            out_adder_reg       <= 0;
            out_carry_reg       <= 0;
            partial_result      <= 0;
            partial_sum         <= 0;
            partial_carry       <= 0;
        end else begin
            out_adder_reg               <= out_adder_sum;
            out_carry_reg               <= out_adder_carry;
            partial_result[count_d2]    <= out_adder_sum[0];
            
            if (count_d2 == 1)
                partial_result[0]       <= pp_prev[0];
            if (count_d2 == in_width-1) begin
                partial_sum             <= out_adder_sum;
                partial_carry           <= out_adder_carry;
            end
        end
    end

    wire [DATA_WIDTH-2:0] adder_mux; 
    assign adder_mux = (count_d2 ==1) ? pp_prev[DATA_WIDTH-1:1] : out_adder_reg[DATA_WIDTH-1:1];
    
    assign in_adder_a = red_funct ? ((count_d1==1) ? (reduc_inv_reg[0 +: (DATA_WIDTH+1)]) : ({reduc_inv_reg[DATA_WIDTH-1+count_d1],out_adder_reg[1 +: DATA_WIDTH]})) : (sum_funct ? in_a : {out_carry_reg,adder_mux});
    assign bit_selector = (count_d1 == 1) ? (reduc_inv_reg[0]) : (out_adder_reg[1]);
    assign in_adder_b = red_funct ? (bit_selector ? poly_red_inv_reg : 0) : (sum_funct ? in_b : partial_products_reg);

    cl_rca_adder #(DATA_WIDTH) adder0(
        .carry_option(carry_option),
        .a(in_adder_a[DATA_WIDTH-1:0]),
        .b(in_adder_b[DATA_WIDTH-1:0]),
        .sum(out_adder_sum[DATA_WIDTH-1:0]),
        .co(out_adder_carry)
    );
    assign out_adder_sum[DATA_WIDTH] = in_adder_a[DATA_WIDTH] ^ in_adder_b[DATA_WIDTH];

    //////////////////////////////////////////////////////////
    // Selecciono la salida correcta
    //////////////////////////////////////////////////////////

    wire [2*DATA_WIDTH-1:0] mult_mux_out;
    wire [2*DATA_WIDTH-1:0] mult_out [0:DATA_WIDTH];
    wire [DATA_WIDTH-1:0] poly_mux_out;
    wire [DATA_WIDTH-1:0] poly_out [0:DATA_WIDTH];

    reg [DATA_WIDTH-1:0]  poly_mux_out_reg;

    generate
        for (i = 0; i <= DATA_WIDTH; i = i + 1) begin           
            assign mult_out[i] = (i > 1) ? {partial_carry,{DATA_WIDTH-i{1'b0}},partial_sum[DATA_WIDTH-1:1],partial_result[i-1:0]} : 'b0;
            assign poly_out[i] = (i > 1) ? {partial_sum[i:1],{DATA_WIDTH-i{1'b0}}} : 'b0;
        end
    endgenerate
    
    assign mult_mux_out = mult_out[in_width];
    assign poly_mux_out = poly_out[in_width];

    always @(posedge clk) begin
        if (!op_enable) begin
            poly_mux_out_reg    <= 0;
        end else begin
            poly_mux_out_reg    <= poly_mux_out;
        end
    end

    //////////////////////////////////////////////////////////
    // Inversion de las salidas - Para reducir el polinomio
    //////////////////////////////////////////////////////////

    wire [DATA_WIDTH-1:0]   poly_result;       // Salida del polinomio de reduccion

    bit_order_inversion #(DATA_WIDTH) bit_inv_poly_out(
        .a(poly_mux_out_reg),
        .a_n(poly_result)
    );

    //////////////////////////////////////////////////////////
    // Salidas
    //////////////////////////////////////////////////////////

    always @(posedge clk) begin
        if (!op_enable) begin
            op_finish   <= 0;

            out         <= 0;
            out_carry   <= 0;
            out_poly    <= 0;
            out_mult    <= 0;
        end else begin
            out_mult    <= mult_mux_out;
            out_poly    <= poly_result;

            if(sum_funct) begin
                out         <= out_adder_sum;
                out_carry   <= out_adder_carry;
                op_finish   <= 1;
            end

            if(count_d2 >= in_width && !red_funct) begin
                op_finish <= 1;
            end

            if(count_d3 >= in_width && red_funct) begin
                op_finish <= 1;
            end
        end
    end


endmodule