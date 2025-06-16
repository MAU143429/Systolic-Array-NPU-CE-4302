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

    // Generación de reloj
    initial begin
        clk = 0;
        repeat (1000) begin
            #5 clk = ~clk;
        end
    end

    // Simulación
    initial begin
        integer i, j, errors;
        
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
        
        // Mostrar resultados (solo 10x10)
        $display("\n=== MATRIZ DE RESULTADOS (10x10) ===");
        $display("Extraídos de los ciclos 12-21:");
        for (i = 0; i < SIZE; i++) begin
            $write("Fila %2d: ", i);
            for (j = 0; j < SIZE; j++) begin
                $write("%6d ", A_result[i][j]);
            end
            $display();
        end
        
        // Verificación básica
        errors = 0;
        for (i = 0; i < SIZE; i++) begin
            for (j = 0; j < SIZE; j++) begin
                if (A_result[i][j] === 'x) begin
                    $display("Error: Resultado no válido en [%0d][%0d]", i, j);
                    errors++;
                end
            end
        end
        
        if (errors == 0) begin
            $display("\nTEST PASADO: Todos los resultados son válidos");
        end else begin
            $display("\nTEST FALLADO: %0d errores encontrados", errors);
        end
        
        $finish;
    end

endmodule