`timescale 1ns/1ps

module mac_tb;

    // Señales signed
    logic signed [15:0] matriz_value;
    logic signed [15:0] pe_weight;
    logic signed [15:0] partial_result;
    logic signed [15:0] mac_result;

    // Instanciar el DUT
    mac uut (
        .matriz_value(matriz_value),
        .pe_weight(pe_weight),
        .partial_result(partial_result),
        .mac_result(mac_result)
    );

    initial begin
        $monitor("t=%0t | matriz=%0d, weight=%0d, partial=%0d -> mac=%0d",
                  $time, matriz_value, pe_weight, partial_result, mac_result);

        // Pruebas positivas y negativas
        matriz_value = 16'd10;  pe_weight = 16'sd1;   partial_result = 16'sd5;    #10;
        matriz_value = 16'd20;  pe_weight = -16'sd1;  partial_result = 16'sd15;   #10;
        matriz_value = 16'd50;  pe_weight = 16'sd0;   partial_result = 16'sd100;  #10;
        matriz_value = -16'd25; pe_weight = 16'sd1;   partial_result = 16'sd200;  #10;
        matriz_value = -16'd50; pe_weight = -16'sd1;  partial_result = 16'sd300;  #10;

        #20;
        $finish;
    end

endmodule
