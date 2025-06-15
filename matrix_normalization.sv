// matrix_normalization.sv
module matrix_normalization #(
    parameter WIDTH_IN = 16,
    parameter WIDTH_OUT = 8,
    parameter SIZE = 10
) (
    input clk,
    input reset,
    input start,
    input signed [WIDTH_IN-1:0] matrix_in [0:SIZE-1][0:SIZE-1],
    output logic done,
    output logic [WIDTH_OUT-1:0] matrix_out [0:SIZE-1][0:SIZE-1]
);

    // Registros para almacenar valores máximos y mínimos
    logic signed [WIDTH_IN-1:0] max_val;
    logic signed [WIDTH_IN-1:0] min_val;
    
    // Variables para cálculo
    logic signed [31:0] range;
    logic signed [63:0] scaled_value; // Para cálculos intermedios
    
    // Contadores
    integer row, col;
    
    // Máquina de estados
    typedef enum {IDLE, FIND_MIN_MAX, CALC_RANGE, NORMALIZE, DONE} state_t;
    state_t state;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            row <= 0;
            col <= 0;
            max_val <= matrix_in[0][0];
            min_val <= matrix_in[0][0];
            range <= 0;
            
            // Inicializar salidas a 0
            for (int i = 0; i < SIZE; i++) begin
                for (int j = 0; j < SIZE; j++) begin
                    matrix_out[i][j] <= 0;
                end
            end
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= FIND_MIN_MAX;
                        row <= 0;
                        col <= 0;
                        max_val <= matrix_in[0][0];
                        min_val <= matrix_in[0][0];
                    end
                end
                
                FIND_MIN_MAX: begin
                    // Actualizar máx y mín
                    if (matrix_in[row][col] > max_val) max_val <= matrix_in[row][col];
                    if (matrix_in[row][col] < min_val) min_val <= matrix_in[row][col];
                    
                    // Avanzar en la matriz
                    if (col == SIZE-1) begin
                        col <= 0;
                        if (row == SIZE-1) begin
                            state <= CALC_RANGE;
                        end else begin
                            row <= row + 1;
                        end
                    end else begin
                        col <= col + 1;
                    end
                end
                
                CALC_RANGE: begin
                    range <= max_val - min_val;
                    row <= 0;
                    col <= 0;
                    state <= NORMALIZE;
                end
                
                NORMALIZE: begin
                    if (range != 0) begin
                        // Cálculo: ((val - min) * 255) / range
                        scaled_value = (matrix_in[row][col] - min_val) * 255;
                        matrix_out[row][col] <= scaled_value / range;
                    end else begin
                        // Todos los valores iguales
                        matrix_out[row][col] <= 8'd128;
                    end
                    
                    // Avanzar en la matriz
                    if (col == SIZE-1) begin
                        col <= 0;
                        if (row == SIZE-1) begin
                            state <= DONE;
                        end else begin
                            row <= row + 1;
                        end
                    end else begin
                        col <= col + 1;
                    end
                end
                
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule