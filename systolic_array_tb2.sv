module systolic_array_tb2;

    parameter WIDTH = 16;  // 16 bits para soportar valores grandes
    parameter SIZE = 10;   // Matriz 10x10
    
    logic clk;
    logic reset;
    logic signed [WIDTH-1:0] weight_matrix[0:SIZE-1][0:SIZE-1];
    logic signed [WIDTH-1:0] input_matrix[0:SIZE-1][0:SIZE-1];
    logic signed [WIDTH*2+$clog2(SIZE):0] result_matrix[0:SIZE-1][0:SIZE-1];
    
    // Instanciación del systolic array corregido
    systolic_array #(WIDTH, SIZE) dut (
        .clk(clk),
        .reset(reset),
        .weight_matrix(weight_matrix),
        .input_matrix(input_matrix),
        .result_matrix(result_matrix)
    );
    
    // Generación de reloj (100 MHz)
    initial begin
        clk = 0;
        repeat (1000) begin // Número finito de ciclos
        #5 clk = ~clk;
		end
    end
    
    // Inicialización y control de la simulación
    initial begin
        integer i, j;
        
        // ----- 1. Inicializar matrices -----
        reset = 1;
        
        // Matriz de pesos: 5 filas de 1, 5 filas de -1
        for (i = 0; i < SIZE; i=i+1) begin
            for (j = 0; j < SIZE; j=j+1) begin
                weight_matrix[i][j] = (i < 5) ? 16'sd1 : -16'sd1;
            end
        end
        
        // Matriz de entrada: valores de 0 a 180 en pasos de 10
        for (i = 0; i < SIZE; i=i+1) begin
            for (j = 0; j < SIZE; j=j+1) begin
                input_matrix[i][j] = 10*i + j*10;
            end
        end
        
        // ----- 2. Mostrar matrices de entrada -----
        $display("\n=== MATRIZ DE PESOS (10x10) ===");
        for (i = 0; i < SIZE; i=i+1) begin
            for (j = 0; j < SIZE; j=j+1) begin
                $write("%4d ", $signed(weight_matrix[i][j]));
            end
            $write("\n");
        end
        
        $display("\n=== MATRIZ DE ENTRADA (10x10) ===");
        for (i = 0; i < SIZE; i=i+1) begin
            for (j = 0; j < SIZE; j=j+1) begin
                $write("%4d ", $signed(input_matrix[i][j]));
            end
            $write("\n");
        end
        
        // ----- 3. Iniciar simulación -----
        #10 reset = 0;  // Desactivar reset después de 10ns
        $display("\nIniciando cálculo...");
        
        // Esperar suficiente tiempo para que los datos fluyan por todo el array
        // (Se necesitan 2*SIZE-1 ciclos para llenar el pipeline)
        #(20*SIZE*10);  // 2000ns para SIZE=10
        
        // ----- 4. Mostrar resultados -----
        $display("\n=== MATRIZ DE RESULTADOS (10x10) ===");
        for (i = 0; i < SIZE; i=i+1) begin
            for (j = 0; j < SIZE; j=j+1) begin
                $write("%8d ", $signed(result_matrix[i][j]));
            end
            $write("\n");
        end
        
        // ----- 5. Verificación automática -----
        $display("\n=== VERIFICACIÓN DE RESULTADOS ===");
        begin
            integer errors = 0;
            for (i = 0; i < SIZE; i=i+1) begin
                for (j = 0; j < SIZE; j=j+1) begin
                    if (result_matrix[i][j] != -250) begin
                        $display("  ERROR en [%0d][%0d]: esperado = -250, obtenido = %0d", 
                                i, j, $signed(result_matrix[i][j]));
                        errors = errors + 1;
                    end
                end
            end
            
            if (errors == 0) begin
                $display("  ¡Todos los resultados son correctos! (Todos = -250)");
            end else begin
                $display("  Se encontraron %0d errores", errors);
            end
        end
        
        // Finalizar simulación
        $finish;
    end
    
    // Monitor para observar cambios en los resultados
    initial begin
        $monitor("Tiempo = %0t ns: Resultado[0][0] = %0d", $time, $signed(result_matrix[0][0]));
    end
    
endmodule