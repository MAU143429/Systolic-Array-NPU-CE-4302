module mac (
    input  logic signed [15:0] matriz_value,   // valor de la imagen (con signo)
    input  logic signed [15:0] pe_weight,      // peso fijo del PE (-1, 0, 1)
    input  logic signed [15:0] partial_result, // acumulado desde PE superior
    output logic signed [15:0] mac_result      // salida del MAC
);

    logic signed [15:0] mult_result; // resultado de la multiplicación (signed)

    always_comb begin
        mult_result = matriz_value * pe_weight;
        mac_result  = mult_result[15:0] + partial_result; // suma con signo
    end

endmodule
