module systolic_array (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic signed [15:0] A[10][10],  
    output logic        done,
    output logic signed [15:0] A_result[0:18][0:9]  // 19x10 resultado final
);

    // Interno: pesos constantes (WS: Weight Stationary)
    logic signed [15:0] weights[10][10];

    // Interno: conexiones entre PEs
    logic signed [15:0] iact_wire[10][11];   // de cada PE a la derecha
    logic signed [15:0] psum_wire[11][10];   // de cada PE hacia abajo

    // Contador de ciclos para manejar el flujo
    logic [5:0] cycle;

    // FSM
    typedef enum logic [1:0] {IDLE, RUN, DONE} state_t;
    state_t state;

    // Inicialización de pesos
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 10; i++) begin
                for (int j = 0; j < 10; j++) begin
                    weights[i][j] <= (i < 5) ? 16'sd1 : -16'sd1; // pesos constantes por fila
                end
            end
        end
    end

    // FSM y control de entrada
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle <= 0;
            state <= IDLE;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        cycle <= 0;
                        state <= RUN;
                    end
                end

                RUN: begin
                    // Inyectar datos en la primera columna (entrada izquierda)
                    for (int i = 0; i < 10; i++) begin
                        int j = cycle - i;
                        if (j >= 0 && j < 10)
                            iact_wire[i][0] <= A[i][j];
                        else
                            iact_wire[i][0] <= 0;
                    end

                    cycle <= cycle + 1;
                    if (cycle == 29) begin  // ciclo 29 es el último donde sale dato útil
                        state <= DONE;
                        done <= 1;
                    end
                end

                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

    // Instanciación de los PEs
    genvar i, j;
    generate
        for (i = 0; i < 10; i++) begin : row
            for (j = 0; j < 10; j++) begin : col
                pe pe_inst (
                    .iact_in (j == 0 ? iact_wire[i][j] : iact_wire[i][j]),
                    .psum_in (i == 0 ? 16'sd0 : psum_wire[i][j]),
                    .weight  (weights[i][j]),
                    .iact_out(iact_wire[i][j+1]),
                    .psum_out(psum_wire[i+1][j])
                );
            end
        end
    endgenerate

    // Captura de resultados válidos en A_result[0..18][0..9]
    always_ff @(posedge clk) begin
        if (cycle >= 10 && cycle <= 28) begin
            for (int j = 0; j < 10; j++) begin
                A_result[cycle - 10][j] <= psum_wire[10][j];
            end
        end
    end

endmodule
