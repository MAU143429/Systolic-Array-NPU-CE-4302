module systolic_array_tb2;

    parameter WIDTH = 16;
    parameter SIZE = 10;

    logic clk;
    logic rst;
    logic start;
    logic done;
    logic signed [WIDTH-1:0] A[SIZE][SIZE];
    logic signed [WIDTH-1:0] A_result[SIZE][SIZE];

    systolic_array dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .done(done),
        .A_result(A_result)
    );

    // Expected result matrix
    localparam logic signed [WIDTH-1:0] expected_result[SIZE][SIZE] = '{
        '{189,   189,  189,   189, 189, 189,  189,  189, 189,  189},
        '{-378,   -378,  -378,   -378, -378, -378,  -378,  -378, -378,  -378},
        '{333,   333,  333,   333, 333, 333,  333,  333, 333,  333},
        '{-11,   -11,  -11,   -11, -11, -11,  -11,  -11, -11,  -11},
        '{-167,   -167,  -167,   -167, -167, -167,  -167,  -167, -167,  -167},
        '{-142,   -142,  -142,   -142, -142, -142,  -142,  -142, -142,  -142},
        '{96,   96,  96,   96, 96, 96,  96,  96, 96,  96},
        '{123,   123,  123,   123, 123, 123,  123,  123, 123,  123},
        '{38,   38,  38,   38, 38, 38,  38, 38, 38,  38},
        '{-150,   -150,  -150,   -150, -150, -150,  -150,  -150, -150,  -150}
    };

    // Generación de reloj
    initial begin
        clk = 0;
        repeat (1000) begin
            #5 clk = ~clk;
        end
    end

    // Simulación
    initial begin
        integer i, j, errors = 0;
        
        // Inicialización
        rst = 1;
        start = 0;
        
        // Matriz de entrada específica
        A[0] = '{  123,  45,  89, 200,  34,  67, 155, 210,  11,  98};
        A[1] = '{   76, 233,  54, 128,  99, 177,  32, 145,  66, 201};
        A[2] = '{   43,  87, 199,  22, 110, 255,   0,  78, 164,  33};
        A[3] = '{   90, 112,  65, 187,  44,  23, 156,  79, 122, 211};
        A[4] = '{   55, 167,  89, 134,  76,  12,  98, 200,  45,  67};
        A[5] = '{  188,  77, 143,  22, 109,  34, 165,  88, 199, 111};
        A[6] = '{   20, 154,  76,  43,  87, 222,  33, 145,  66, 178};
        A[7] = '{   99, 122,  45, 167,  89, 200,  11,  34, 155,  76};
        A[8] = '{  177,  65,  32, 144,  98, 211,  87,  23, 166,  44};
        A[9] = '{   53, 188,  77, 199, 122,  34, 156,  89, 200,  12};
        
        // Reset
        #20;
        rst = 0;
        #20;
        
        // Mostrar matriz de entrada
        $display("=== MATRIZ DE ENTRADA ===");
        for (i = 0; i < SIZE; i++) begin
            for (j = 0; j < SIZE; j++) begin
                $write("%4d ", A[i][j]);
            end
            $display();
        end
        
        // Mostrar matriz de pesos esperada
        $display("\n=== MATRIZ DE PESOS (5 filas de 1, 5 filas de -1) ===");
        for (i = 0; i < SIZE; i++) begin
            for (j = 0; j < SIZE; j++) begin
                $write("%4d ", (i < 5) ? 1 : -1);
            end
            $display();
        end
        
        // Iniciar procesamiento
        start = 1;
        #10;
        start = 0;
        
        // Esperar finalización
        wait(done);
        #50;
        
        // Mostrar resultados
        $display("\n=== MATRIZ DE RESULTADOS (10x10) ===");
        $display("      Col: 0     1     2     3     4     5     6     7     8     9");
        $display("     ------------------------------------------------------------");
        for (i = 0; i < SIZE; i++) begin
            $write("Fila %1d: ", i);
            for (j = 0; j < SIZE; j++) begin
                $write("%6d ", A_result[i][j]);
            end
            $display();
        end
        
        // Verificación detallada contra valores esperados
        $display("\n=== VERIFICACIÓN DE RESULTADOS ===");
        for (i = 0; i < SIZE; i++) begin
            for (j = 0; j < SIZE; j++) begin
                if (A_result[i][j] !== expected_result[i][j]) begin
                    $display("ERROR en [%0d][%0d]: Esperado %6d, Obtenido %6d", 
                            i, j, expected_result[i][j], A_result[i][j]);
                    errors++;
                end
            end
        end
        
        // Resumen final
        $display("\n=== RESUMEN DE VERIFICACIÓN ===");
        if (errors == 0) begin
            $display("¡PRUEBA EXITOSA! Todos los resultados coinciden con los valores esperados");
        end else begin
            $display("PRUEBA FALLIDA: Se encontraron %0d errores", errors);
        end
        
        $finish;
    end

endmodule