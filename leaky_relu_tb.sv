`timescale 1ns/1ps

module leaky_relu_tb;

    logic clk;
    logic rst;
    logic signed [15:0] in_matrix [9:0][9:0];
    logic signed [15:0] out_matrix [9:0][9:0];

    // Instancia del módulo bajo prueba
    leaky_relu dut (
        .clk(clk),
        .rst(rst),
        .in_matrix(in_matrix),
        .out_matrix(out_matrix)
    );

    // Generador de clock: periodo 10 ns
    always #5 clk = ~clk;

    initial begin
        $display("=== Testbench Leaky ReLU 10x10 ===");
        clk = 0;
        rst = 1;

        // Inicializa matriz de entrada con valores de prueba
        // Mezcla de positivos, negativos, ceros
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                in_matrix[i][j] = (i * 10 + j - 50); // Valores desde -50 hasta +49
            end
        end

        #10;
        rst = 0;

        #10; // Espera 1 ciclo para que se procese

        $display("\nMatriz de entrada (in_matrix):");
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                $write("%5d ", in_matrix[i][j]);
            end
            $write("\n");
        end

        $display("\nMatriz de salida (out_matrix):");
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                $write("%5d ", out_matrix[i][j]);
            end
            $write("\n");
        end

        #10;
        $finish;
    end

endmodule
