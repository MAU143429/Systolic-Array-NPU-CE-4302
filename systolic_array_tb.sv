module systolic_array_tb;

    parameter WIDTH = 8;
    parameter SIZE = 10;
    
    logic clk;
    logic reset;
    logic [WIDTH-1:0] weight_matrix[SIZE][SIZE];
    logic [WIDTH-1:0] input_matrix[SIZE][SIZE];
    logic [WIDTH*2+$clog2(SIZE):0] result_matrix[SIZE][SIZE];
    /**
    // Instantiate DUT
    systolic_array #(WIDTH, SIZE) dut (
        .clk(clk),
        .reset(reset),
        .weight_matrix(weight_matrix),
        .input_matrix(input_matrix),
        .result_matrix(result_matrix)
    );*/
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test procedure
    initial begin
        // Initialize matrices
        reset = 1;
        
        // Weight matrix: 5 rows of 1, 5 rows of -1
        for (int i = 0; i < SIZE; i++) begin
            for (int j = 0; j < SIZE; j++) begin
                weight_matrix[i][j] = (i < 5) ? 8'd1 : -8'd1;
            end
        end
        
        // Input matrix: incremental values
        for (int i = 0; i < SIZE; i++) begin
            for (int j = 0; j < SIZE; j++) begin
                input_matrix[i][j] = 10*i + j*10;
            end
        end
        
        // Reset and start
        #10 reset = 0;
        
        // Wait for computation to complete
        #(20*SIZE);
        
        // Check results
        $display("=== TESTBENCH SYSTOLIC ARRAY ===");
        $display("# Verificando resultados...");
        
        for (int i = 0; i < SIZE; i++) begin
            for (int j = 0; j < SIZE; j++) begin
                if (result_matrix[i][j] != -250) begin
                    $display("ERROR en [%0d][%0d]: esperado = -250, obtenido = %0d", 
                            i, j, result_matrix[i][j]);
                end
            end
        end
        
        // Display final result
        $display("\n# Matriz de resultados (10x10):");
        for (int i = 0; i < SIZE; i++) begin
            for (int j = 0; j < SIZE; j++) begin
                $write("%6d ", result_matrix[i][j]);
            end
            $write("\n");
        end
        
        $display("\n# Verificación completada");
        $finish;
    end
    
endmodule