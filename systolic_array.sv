module systolic_array (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic signed [15:0] A[10][10], 
    output logic        done,
    output logic signed [15:0] A_result[0:9][0:9]  // Changed to 10x10 output
);

    // Interno: pesos constantes (WS: Weight Stationary)
    logic signed [15:0] weights[10][10];

    // Conexiones entre PEs
    logic signed [15:0] iact_wire[10][11];   // Activaciones: izquierda a derecha
    logic signed [15:0] psum_wire[11][10];    // Sumas parciales: arriba a abajo
    logic signed [15:0] weight_wire[10][11];  // Pesos: izquierda a derecha

    // Contador de ciclos para controlar el flujo
    logic [7:0] cycle;

    // FSM
    typedef enum logic [1:0] {IDLE, LOAD_WEIGHTS, RUN, DONE} state_t;
    state_t state;

    // Buffer para almacenar resultados intermedios
    logic signed [15:0] result_buffer[0:37][0:9];

    // Inicialización y actualización de pesos
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Inicialización con los pesos piramidales que especificaste
            weights[0]  <= '{ 1,  2,  3,  4,  5,  5,  4,  3,  2,  1};
            weights[1]  <= '{ 2,  4,  6,  8, 10, 10,  8,  6,  4,  2};
            weights[2]  <= '{ 3,  6,  9, 12, 15, 15, 12,  9,  6,  3};
            weights[3]  <= '{ 4,  8, 12, 16, 20, 20, 16, 12,  8,  4};
            weights[4]  <= '{ 5, 10, 15, 20, 25, 25, 20, 15, 10,  5};
            weights[5]  <= '{ 5, 10, 15, 20, 25, 25, 20, 15, 10,  5};
            weights[6]  <= '{ 4,  8, 12, 16, 20, 20, 16, 12,  8,  4};
            weights[7]  <= '{ 3,  6,  9, 12, 15, 15, 12,  9,  6,  3};
            weights[8]  <= '{ 2,  4,  6,  8, 10, 10,  8,  6,  4,  2};
            weights[9]  <= '{ 1,  2,  3,  4,  5,  5,  4,  3,  2,  1};
        end
    end

    // FSM y control de entrada
    always_ff @(posedge clk or posedge rst) begin
        integer i, j;
        if (rst) begin
            cycle <= 0;
            state <= IDLE;
            done <= 0;
            
            // Inicializar conexiones
            for (i = 0; i < 10; i++) begin
                for (j = 0; j < 11; j++) begin
                    iact_wire[i][j] <= 0;
                    if (j < 10) weight_wire[i][j] <= 0;
                end
            end
            
            for (i = 0; i < 11; i++) begin
                for (j = 0; j < 10; j++) begin
                    psum_wire[i][j] <= 0;
                end
            end
            
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        cycle <= 0;
                        state <= LOAD_WEIGHTS;
                    end
                end
                
                LOAD_WEIGHTS: begin
                    // Cargar pesos en los registros de desplazamiento
                    for (i = 0; i < 10; i++) begin
                        weight_wire[i][0] <= weights[i][cycle];
                    end
                    
                    cycle <= cycle + 1;
                    if (cycle == 9) begin
                        cycle <= 0;
                        state <= RUN;
                    end
                end

                RUN: begin
                    // Patrón de inyección con delays
                    for (i = 0; i < 10; i++) begin
                        automatic int delay_offset = i;
                        automatic int data_offset = cycle - delay_offset;
                        
                        if (data_offset >= 0 && data_offset < 10) begin
                            iact_wire[i][0] <= A[i][9-data_offset]; // Leemos en orden inverso
                        end else begin
                            iact_wire[i][0] <= 0; // Delay
                        end
                    end
                    
                    // Desplazar pesos continuamente
                    for (i = 0; i < 10; i++) begin
                        for (j = 1; j < 10; j++) begin
                            weight_wire[i][j] <= weight_wire[i][j-1];
                        end
                    end

                    cycle <= cycle + 1;
                    if (cycle == 37) begin  // 10 datos + 9 delays = 19 ciclos + margen
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
                pe_t pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .iact_in(iact_wire[i][j]),
                    .psum_in(i == 0 ? 16'sd0 : psum_wire[i][j]),
                    .weight_in(weight_wire[i][j]),
                    .iact_out(iact_wire[i][j+1]),
                    .psum_out(psum_wire[i+1][j]),
                    .weight_out(weight_wire[i][j+1])
                );
            end
        end
    endgenerate

    // Captura de resultados en buffer temporal
    always_ff @(posedge clk) begin
        if (state == RUN) begin
            for (int j = 0; j < 10; j++) begin
                result_buffer[cycle][j] <= psum_wire[10][j];
            end
        end
    end

    // Extraer solo ciclos 12-21 (10 ciclos) para la salida final
    always_comb begin
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                A_result[i][j] = result_buffer[i+12][j];
            end
        end
    end

endmodule