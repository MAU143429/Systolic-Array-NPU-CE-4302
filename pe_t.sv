module pe_t (
    input  logic        clk,
    input  logic        rst,
    input  logic signed [15:0] iact_in,    // Activación de entrada
    input  logic signed [15:0] psum_in,    // Suma parcial de entrada
    input  logic signed [15:0] weight_in,  // Peso de entrada
    output logic signed [15:0] iact_out,   // Activación de salida
    output logic signed [15:0] psum_out,   // Suma parcial de salida
    output logic signed [15:0] weight_out  // Peso de salida
);

    // Registros internos
    logic signed [15:0] weight_reg;   // Registro para peso estacionario
    logic signed [31:0] product;      // Resultado de multiplicación
    logic signed [31:0] psum_acc;     // Acumulador de suma parcial

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            weight_reg <= '0;
            product    <= '0;
            psum_acc   <= '0;
        end else begin
            // Registro de peso (solo se carga en el primer ciclo)
            weight_reg <= weight_in;
            
            // Multiplicación activación x peso
            product <= iact_in * weight_reg;
            
            // Acumulación de suma parcial
            psum_acc <= psum_in + product;
        end
    end

    // Asignación de salidas
    assign iact_out   = iact_in;     // Pasa la activación sin modificar
    assign psum_out   = psum_acc;    // Suma parcial acumulada
    assign weight_out = weight_reg;  // Peso registrado

endmodule