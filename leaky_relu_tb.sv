`timescale 1ns/1ps

module leaky_relu_tb;

    parameter WIDTH = 16;
    parameter SIZE = 10;

    logic clk;
    logic rst;
    logic signed [WIDTH-1:0] A [SIZE][SIZE];
    logic signed [WIDTH-1:0] A_result [SIZE][SIZE];

    // DUT
    leaky_relu dut (
        .clk(clk),
        .rst(rst),
        .in_matrix(A),
        .out_matrix(A_result)
    );

   localparam logic signed [WIDTH-1:0] expected_result[SIZE][SIZE] = '{
    '{  -188,    132,   2338,   5173,   7482,   7482,   5173,   2338,    132,   -188},
    '{  -276,    -55,   1941,   4101,   6811,   6811,   4101,   1941,    -55,   -276},
    '{  -194,     -6,   2092,   4652,   7220,   7220,   4652,   2092,     -6,   -194},
    '{  -178,    -35,   1293,   3553,   5650,   5650,   3553,   1293,    -35,   -178},
    '{  -247,    -15,   2128,   3583,   5647,   5647,   3583,   2128,    -15,   -247},
    '{  -173,    -12,   1603,   3183,   5150,   5150,   3183,   1603,    -12,   -173},
    '{  -184,    -10,   1619,   3384,   5599,   5599,   3384,   1619,    -10,   -184},
    '{  -228,    -43,   1443,   3373,   5419,   5419,   3373,   1443,    -43,   -228},
    '{  -198,    -34,   1741,   3606,   5854,   5854,   3606,   1741,    -34,   -198},
    '{  -250,    -22,   2179,   4729,   7441,   7441,   4729,   2179,    -22,   -250}
	};
	    // Clock
    initial begin
        clk = 0;
        repeat (1000) begin
            #5 clk = ~clk;
        end
    end
	 
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
		  rst = 1;
		  
		 A[0] = '{ -1888,    132,   2338,   5173,   7482,   7482,   5173,   2338,    132,  -1888};
       A[1] = '{ -2766,   -556,   1941,   4101,   6811,   6811,   4101,   1941,   -556,  -2766};
       A[2] = '{ -1940,    -68,   2092,   4652,   7220,   7220,   4652,   2092,    -68,  -1940};
       A[3] = '{ -1786,   -359,   1293,   3553,   5650,   5650,   3553,   1293,   -359,  -1786};
       A[4] = '{ -2470,   -156,   2128,   3583,   5647,   5647,   3583,   2128,   -156,  -2470};
       A[5] = '{ -1736,   -127,   1603,   3183,   5150,   5150,   3183,   1603,   -127,  -1736};
       A[6] = '{ -1848,   -109,   1619,   3384,   5599,   5599,   3384,   1619,   -109,  -1848};
       A[7] = '{ -2288,   -438,   1443,   3373,   5419,   5419,   3373,   1443,   -438,  -2288};
       A[8] = '{ -1980,   -342,   1741,   3606,   5854,   5854,   3606,   1741,   -342,  -1980};
       A[9] = '{ -2500,   -222,   2179,   4729,   7441,   7441,   4729,   2179,   -222,  -2500};
		 
		  // Reset y carga inicial de pesos
        #20;
        rst = 0;
        #20
		  
		  // Mostrar matrices
        print_matrix("MATRIZ DE ENTRADA", A);
		  
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
		  
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 