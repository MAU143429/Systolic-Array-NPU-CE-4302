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
        '{ 1750,  1750,  1750,  1750,  1750,  1750,  1750,  1750,  1750,  1750},
        '{ 3500,  3500,  3500,  3500,  3500,  3500,  3500,  3500,  3500,  3500},
        '{ 5250,  5250,  5250,  5250,  5250,  5250,  5250,  5250,  5250,  5250},
        '{ 7000,  7000,  7000,  7000,  7000,  7000,  7000,  7000,  7000,  7000},
        '{ 8750,  8750,  8750,  8750,  8750,  8750,  8750,  8750,  8750,  8750},
        '{ 8750,  8750,  8750,  8750,  8750,  8750,  8750,  8750,  8750,  8750},
        '{ 7000,  7000,  7000,  7000,  7000,  7000,  7000,  7000,  7000,  7000},
        '{ 5250,  5250,  5250,  5250,  5250,  5250,  5250,  5250,  5250,  5250},
        '{ 3500,  3500,  3500,  3500,  3500,  3500,  3500,  3500,  3500,  3500},
        '{ 1750,  1750,  1750,  1750,  1750,  1750,  1750,  1750,  1750,  1750}
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