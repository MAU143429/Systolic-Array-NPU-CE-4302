// tb_matrix_normalization_example.sv
`timescale 1ns/1ps

module matrix_normalization_tb;

    parameter WIDTH_IN = 16;
    parameter WIDTH_OUT = 8;
    parameter SIZE = 10;
    
    // Señales de prueba
    logic clk;
    logic reset;
    logic start;
    logic signed [WIDTH_IN-1:0] matrix_in [0:SIZE-1][0:SIZE-1];
    logic done;
    logic [WIDTH_OUT-1:0] matrix_out [0:SIZE-1][0:SIZE-1];
    
    // Instancia del módulo
    matrix_normalization dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .matrix_in(matrix_in),
        .done(done),
        .matrix_out(matrix_out)
    );
    
    // Generación de reloj
    always #5 clk = ~clk;
    
    // Valores esperados (deberías reemplazarlos con tus cálculos)
    logic [WIDTH_OUT-1:0] expected [0:SIZE-1][0:SIZE-1] = '{
        '{136, 162, 190, 221, 255, 245, 232, 217, 199, 179},
        '{142, 166, 193, 221, 251, 239, 224, 208, 189, 169},
        '{144, 166, 190, 215, 241, 227, 211, 194, 176, 156},
        '{142, 162, 182, 203, 225, 209, 193, 176, 158, 139},
        '{136, 153, 169, 185, 202, 185, 169, 153, 136, 120},
        '{87 , 93 , 98 , 102, 106, 97 , 87 , 79 , 71 , 64},
        '{37 , 36 , 36 , 35 , 34 , 34 , 34 , 34 , 34 , 34},
        '{31 , 30 , 28 , 25 , 23 , 24 , 24 , 25 , 26 , 28},
        '{25 , 22 , 19 , 15 , 12 , 13 , 15 , 17 , 19 , 21},
        '{19 , 14 , 10 , 5  , 0  , 2  , 4  , 7  , 11 , 14}
    };
    
    integer i, j;
    integer errors = 0;
    
    initial begin
        // Inicializar matriz de entrada con los valores proporcionados
        matrix_in = '{
            '{1500,  1890,  2320,  2790,  3300,  3150,  2960,  2730,  2460,  2150},
            '{1590,  1960,  2360,  2790,  3250,  3060,  2840,  2590,  2310,  2000},
            '{1620,  1960,  2320,  2700,  3100,  2880,  2640,  2380,  2100,  1800},
            '{1590,  1890,  2200,  2520,  2850,  2610,  2360,  2100,  1830,  1550},
            '{1500,  1750,  2000,  2250,  2500,  2250,  2000,  1750,  1500,  1250},
            '{ 750,   840,   920,   990,  1050,   900,   760,   630,   510,   400},
            '{  -6,   -14,   -24,   -36,   -50,   -54,   -56,   -56,   -54,   -50},
            '{ -93,  -119,  -148,  -180,  -215,  -207,  -196,  -182,  -165,  -145},
            '{-186,  -231,  -280,  -333,  -390,  -369,  -344,  -315,  -282,  -245},
            '{-285,  -350,  -420,  -495,  -575,  -540,  -500,  -455,  -405,  -350}
        };
        
        // Inicialización
        clk = 0;
        reset = 1;
        start = 0;
        #20 reset = 0;
        
        // Iniciar normalización
        start = 1;
        #10 start = 0;
        
        // Esperar a que termine
        wait(done);
        #100;
        
        // Verificar resultados
        $display("=== Resultados de Normalización ===");
        $display("Entrada (16-bit signed) -> Salida (8-bit unsigned) [Esperado]");
        
        for (i = 0; i < SIZE; i = i + 1) begin
            for (j = 0; j < SIZE; j = j + 1) begin
                $write("[%4d] -> %3d [%3d]", matrix_in[i][j], matrix_out[i][j], expected[i][j]);
                
                if (matrix_out[i][j] !== expected[i][j]) begin
                    $display("  ERROR");
                    errors = errors + 1;
                end else begin
                    $display("  OK");
                end
            end
        end
        
        // Resumen de pruebas
        $display("\n=== Resumen de Verificación ===");
        if (errors == 0) begin
            $display("¡Todas las pruebas pasaron correctamente!");
        end else begin
            $display("Pruebas fallidas: %0d errores encontrados", errors);
        end
        
        $finish;
    end

endmodule