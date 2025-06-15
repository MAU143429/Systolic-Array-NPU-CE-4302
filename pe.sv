module pe (
    input  logic signed [15:0] iact_in,      // valor desde la izquierda
    input  logic signed [15:0] psum_in,      // valor desde arriba
    input  logic signed [15:0] weight,       // peso fijo del PE
    output logic signed [15:0] iact_out,     // reenviado hacia la derecha
    output logic signed [15:0] psum_out      // salida hacia abajo
);

    logic signed [15:0] mac_result;

    // Instanciar MAC
    mac mac_unit (
        .matriz_value(iact_in),
        .pe_weight(weight),
        .partial_result(psum_in),
        .mac_result(mac_result)
    );

    // Propagar señales de salida
    assign iact_out = iact_in;
    assign psum_out = mac_result;

endmodule
