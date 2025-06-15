module systolic_array #(
    parameter WIDTH = 16,
    parameter SIZE = 10
)(
    input logic clk,
    input logic reset,
    input logic signed [WIDTH-1:0] weight_matrix[SIZE][SIZE],
    input logic signed [WIDTH-1:0] input_matrix[SIZE][SIZE],
    output logic signed [WIDTH*2+$clog2(SIZE):0] result_matrix[SIZE][SIZE]
);
    // Registros para propagación
    logic signed [WIDTH-1:0] weight_reg[SIZE][SIZE];
    logic signed [WIDTH-1:0] input_reg[SIZE][SIZE];
    logic signed [WIDTH*2+$clog2(SIZE):0] partial_sum[SIZE][SIZE];
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset todos los registros
            for (int i = 0; i < SIZE; i++) begin
                for (int j = 0; j < SIZE; j++) begin
                    weight_reg[i][j] <= '0;
                    input_reg[i][j] <= '0;
                    partial_sum[i][j] <= '0;
                end
            end
        end else begin
            // Propagación de pesos (hacia la derecha)
            for (int i = 0; i < SIZE; i++) begin
                for (int j = 0; j < SIZE; j++) begin
                    if (j == 0) begin
                        weight_reg[i][j] <= weight_matrix[i][j];
                    end else begin
                        weight_reg[i][j] <= weight_reg[i][j-1];
                    end
                end
            end
            
            // Propagación de activaciones (hacia abajo) y cálculo
            for (int i = 0; i < SIZE; i++) begin
                for (int j = 0; j < SIZE; j++) begin
                    if (i == 0 && j == 0) begin
                        // Esquina superior izquierda
                        input_reg[i][j] <= input_matrix[i][j];
                        partial_sum[i][j] <= weight_reg[i][j] * input_reg[i][j];
                    end else if (i == 0) begin
                        // Primera fila
                        input_reg[i][j] <= input_matrix[i][j];
                        partial_sum[i][j] <= partial_sum[i][j-1] + weight_reg[i][j] * input_reg[i][j];
                    end else if (j == 0) begin
                        // Primera columna
                        input_reg[i][j] <= input_reg[i-1][j];
                        partial_sum[i][j] <= weight_reg[i][j] * input_reg[i][j];
                    end else begin
                        // Elementos internos
                        input_reg[i][j] <= input_reg[i-1][j];
                        partial_sum[i][j] <= partial_sum[i][j-1] + weight_reg[i][j] * input_reg[i][j];
                    end
                end
            end
        end
    end
    
    // Asignación de resultados después de completar el pipeline
    always_ff @(posedge clk) begin
        for (int i = 0; i < SIZE; i++) begin
            for (int j = 0; j < SIZE; j++) begin
                if (i == SIZE-1 && j == SIZE-1) begin
                    // Último elemento - resultado final
                    result_matrix[i][j] <= partial_sum[i][j];
                end
                if (i == SIZE-1 && j > 0) begin
                    // Fila inferior (excepto esquina)
                    result_matrix[i][j-1] <= partial_sum[i][j];
                end
                if (j == SIZE-1 && i > 0) begin
                    // Columna derecha (excepto esquina)
                    result_matrix[i-1][j] <= partial_sum[i][j];
                end
                if (i > 0 && j > 0) begin
                    // Elementos internos
                    result_matrix[i-1][j-1] <= partial_sum[i][j];
                end
            end
        end
    end
endmodule