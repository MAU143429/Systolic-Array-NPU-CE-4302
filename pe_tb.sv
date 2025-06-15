`timescale 1ns/1ps

module pe_tb;

    // Señales del PE
    logic signed [15:0] iact_in;
    logic signed [15:0] psum_in;
    logic signed [15:0] weight;
    logic signed [15:0] iact_out;
    logic signed [15:0] psum_out;

    // Instancia del módulo PE
    pe uut (
        .iact_in(iact_in),
        .psum_in(psum_in),
        .weight(weight),
        .iact_out(iact_out),
        .psum_out(psum_out)
    );

    initial begin
        $monitor("t=%0t | iact=%0d, weight=%0d, psum_in=%0d -> psum_out=%0d, iact_out=%0d",
                 $time, iact_in, weight, psum_in, psum_out, iact_out);

        // Caso 1: peso 1
        iact_in = 10; psum_in = 5; weight = 1; #10;
        // Caso 2: peso -1
        iact_in = 20; psum_in = 30; weight = -1; #10;
        // Caso 3: peso 0 (debería pasar el psum intacto)
        iact_in = 100; psum_in = 500; weight = 0; #10;
        // Caso 4: negativo * negativo
        iact_in = -10; psum_in = 100; weight = -1; #10;
        // Caso 5: propagación acumulativa
        iact_in = 3; psum_in = psum_out; weight = 1; #10;

        $finish;
    end

endmodule
