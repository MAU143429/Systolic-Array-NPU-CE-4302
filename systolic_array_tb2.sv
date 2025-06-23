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

    // Expected result matrix for pyramid weights
    localparam logic signed [WIDTH-1:0] expected_result[SIZE][SIZE] = '{
		 '{ -1888,   132,  2338,  5173,  7482,  7482,  5173,  2338,   132, -1888},
		 '{ -2766,  -556,  1941,  4101,  6811,  6811,  4101,  1941,  -556, -2766},
		 '{ -1940,   -68,  2092,  4652,  7220,  7220,  4652,  2092,   -68, -1940},
		 '{ -1786,  -359,  1293,  3553,  5650,  5650,  3553,  1293,  -359, -1786},
		 '{ -2470,  -156,  2128,  3583,  5647,  5647,  3583,  2128,  -156, -2470},
		 '{ -1736,  -127,  1603,  3183,  5150,  5150,  3183,  1603,  -127, -1736},
		 '{ -1848,  -109,  1619,  3384,  5599,  5599,  3384,  1619,  -109, -1848},
		 '{ -2288,  -438,  1443,  3373,  5419,  5419,  3373,  1443,  -438, -2288},
		 '{ -1980,  -342,  1741,  3606,  5854,  5854,  3606,  1741,  -342, -1980},
		 '{ -2500,  -222,  2179,  4729,  7441,  7441,  4729,  2179,  -222, -2500}
	 };

    // Generación de reloj
    initial begin
        clk = 0;
        repeat (1000) begin
            #5 clk = ~clk;
        end
    end

    // Tarea para imprimir matrices
    task print_matrix(input string name, input logic signed [WIDTH-1:0] matrix[SIZE][SIZE]);
        $display("=== %s ===", name);
        $display("      Col: 0     1     2     3     4     5     6     7     8     9");
        $display("     ------------------------------------------------------------");
        for (int i = 0; i < SIZE; i++) begin
            $write("Fila %1d: ", i);
            for (int j = 0; j < SIZE; j++) begin
                $write("%6d ", matrix[i][j]);
            end
            $display();
        end
    endtask

    // Simulación
    initial begin
        integer i, j, errors = 0;
        
        // Inicialización
        rst = 1;
        start = 0;
        
        // Matriz de entrada específica (la misma que antes)
        A[0] = '{   45,  210,   98,  123,   34,   67,  155,   89,  200,   11};
        A[1] = '{  233,   54,  128,   76,   99,  177,   32,  145,   66,  201};
        A[2] = '{   87,  199,   22,   43,  110,  255,    0,   78,  164,   33};
        A[3] = '{  112,   65,  187,   90,   44,   23,  156,   79,  122,  211};
        A[4] = '{  167,   89,  134,   55,   76,   12,   98,  200,   45,   67};
        A[5] = '{   77,  143,   22,  188,  109,   34,  165,   88,  199,  111};
        A[6] = '{  154,   76,   43,   20,   87,  222,   33,  145,   66,  178};
        A[7] = '{  122,   45,  167,   99,   89,  200,   11,   34,  155,   76};
        A[8] = '{   65,   32,  144,  177,   98,  211,   87,   23,  166,   44};
        A[9] = '{  188,   77,  199,   53,  122,   34,  156,   89,  200,   12};
        
  
        // Reset y carga inicial de pesos
        #20;
        rst = 0;
        #20;
        
        // Mostrar matrices
        print_matrix("MATRIZ DE ENTRADA", A);
        
        
        // Iniciar procesamiento
        start = 1;
        #10;
        start = 0;
        
        // Esperar finalización
        wait(done);
        #50;
        
        // Mostrar resultados
        print_matrix("MATRIZ DE RESULTADOS", A_result);
        
        // Verificación detallada contra valores esperados
        $display("\n=== VERIFICACIÓN DE RESULTADOS ===");
        for (i = 0; i < SIZE; i++) begin
            for (j = 0; j < SIZE; j++) begin
                if (A_result[i][j] !== expected_result[i][j]) begin
                    $display("ERROR en [%0d][%0d]: Esperado %6d, Obtenido %6d", 
                            i, j, expected_result[i][j], A_result[i][j]);
                    errors++;
                end
					 else begin
						$display("OK: en [%0d][%0d]: Esperado %6d, Obtenido %6d", 
                            i, j, expected_result[i][j], A_result[i][j]);
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