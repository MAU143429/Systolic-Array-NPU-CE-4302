`timescale 1ns/1ps
module systolic_array_tb3;
    // Parámetros
    parameter CLK_PERIOD = 10;
    parameter MATRIX_SIZE = 10;
    
    // Señales
    logic clk;
    logic rst;
    logic start;
    logic done;
    logic signed [15:0] input_matrix_1[MATRIX_SIZE-1:0][MATRIX_SIZE-1:0];
    logic signed [15:0] input_matrix_2[MATRIX_SIZE-1:0][MATRIX_SIZE-1:0];
    logic signed [15:0] current_matrix[MATRIX_SIZE-1:0][MATRIX_SIZE-1:0];
    logic signed [15:0] output_matrix_1[MATRIX_SIZE-1:0][MATRIX_SIZE-1:0];
    logic signed [15:0] output_matrix_2[MATRIX_SIZE-1:0][MATRIX_SIZE-1:0];
    
    // DUT
    systolic_array dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(current_matrix),
        .done(done),
        .A_result(output_matrix_1) // Solo usamos uno para captura temporal
    );
    
    // Generación de reloj
    initial begin
        clk = 0;
          repeat (1000) begin // Número finito de ciclos
        #5 clk = ~clk;
        end
    end
    
    // Función para mostrar matrices
    function void display_matrix(string name, logic signed [15:0] matrix[MATRIX_SIZE-1:0][MATRIX_SIZE-1:0]);
        $display("=== %s ===", name);
        for (int i = 0; i < MATRIX_SIZE; i++) begin
            for (int j = 0; j < MATRIX_SIZE; j++) begin
                $write("%6d ", matrix[i][j]);
            end
            $display();
        end
    endfunction
    
    // Secuencia de prueba principal
    initial begin
        // Inicializar matrices de entrada
        input_matrix_1 = '{
            '{ 45, 210,  98, 123,  34,  67, 155,  89, 200,  11},
            '{233,  54, 128,  76,  99, 177,  32, 145,  66, 201},
            '{ 87, 199,  22,  43, 110, 255,   0,  78, 164,  33},
            '{112,  65, 187,  90,  44,  23, 156,  79, 122, 211},
            '{167,  89, 134,  55,  76,  12,  98, 200,  45,  67},
            '{ 77, 143,  22, 188, 109,  34, 165,  88, 199, 111},
            '{154,  76,  43,  20,  87, 222,  33, 145,  66, 178},
            '{122,  45, 167,  99,  89, 200,  11,  34, 155,  76},
            '{ 65,  32, 144, 177,  98, 211,  87,  23, 166,  44},
            '{188,  77, 199,  53, 122,  34, 156,  89, 200,  12}
        };
        
        input_matrix_2 = '{
            '{100, 200, 100, 200, 100, 200, 100, 200, 100, 200},
            '{200, 100, 200, 100, 200, 100, 200, 100, 200, 100},
            '{100, 200, 100, 200, 100, 200, 100, 200, 100, 200},
            '{200, 100, 200, 100, 200, 100, 200, 100, 200, 100},
            '{100, 200, 100, 200, 100, 200, 100, 200, 100, 200},
            '{200, 100, 200, 100, 200, 100, 200, 100, 200, 100},
            '{100, 200, 100, 200, 100, 200, 100, 200, 100, 200},
            '{200, 100, 200, 100, 200, 100, 200, 100, 200, 100},
            '{100, 200, 100, 200, 100, 200, 100, 200, 100, 200},
            '{200, 100, 200, 100, 200, 100, 200, 100, 200, 100}
        };
        
        // Secuencia de reset
        rst = 1;
        start = 0;
        #(CLK_PERIOD*2);
        rst = 0;
        #(CLK_PERIOD*2);
        
        // Mostrar matrices de entrada
        display_matrix("MATRIZ DE ENTRADA 1", input_matrix_1);
        display_matrix("MATRIZ DE ENTRADA 2", input_matrix_2);
        
        // =================================================
        // Procesar primera matriz
        // =================================================
        $display("\nIniciando procesamiento de Matriz 1");
        
        // Cargar primera matriz
        for (int i = 0; i < MATRIX_SIZE; i++) begin
            for (int j = 0; j < MATRIX_SIZE; j++) begin
                current_matrix[i][j] = input_matrix_1[i][j];
            end
        end
        
        // Iniciar procesamiento
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Esperar completación
        wait(done);
        #(CLK_PERIOD*5);
        
        // Mostrar resultados primera matriz
        display_matrix("RESULTADO MATRIZ 1", output_matrix_1);
        
        // =================================================
        // Procesar segunda matriz
        // =================================================
        $display("\nIniciando procesamiento de Matriz 2");
        
        // Reset para segundo procesamiento
        rst = 1;
        #(CLK_PERIOD*2);
        rst = 0;
        #(CLK_PERIOD*2);
        
        // Cargar segunda matriz
        for (int i = 0; i < MATRIX_SIZE; i++) begin
            for (int j = 0; j < MATRIX_SIZE; j++) begin
                current_matrix[i][j] = input_matrix_2[i][j];
            end
        end
        
        // Iniciar procesamiento
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Esperar completación
        wait(done);
        #(CLK_PERIOD*5);
        
        // Mostrar resultados segunda matriz
        display_matrix("RESULTADO MATRIZ 2", output_matrix_1);
        
        // =================================================
        // Finalizar simulación
        // =================================================
        $display("\nProcesamiento completado para ambas matrices");
        $finish;
    end
endmodule