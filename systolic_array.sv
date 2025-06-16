module systolic_array (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic signed [15:0] A[10][10],  
    output logic        done,
    output logic signed [15:0] A_result[0:37][0:9]  // 19x10 resultado final
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

    // Inicialización de pesos (5 filas de 1, 5 filas de -1)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 10; i++) begin
                for (int j = 0; j < 10; j++) begin
                    weights[i][j] <= (i < 5) ? 16'sd1 : -16'sd1;
                end
            end
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
                    if (cycle == 37) begin  // 10 datos + 9 delays = 19 ciclos
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

    // Captura de resultados en matriz 19x10
    always_ff @(posedge clk) begin
        integer i, j;
        if (state == RUN) begin
            // Capturamos todos los ciclos de RUN (0-28)
            for (j = 0; j < 10; j++) begin
                A_result[cycle][j] <= psum_wire[10][j];
            end
        end
    end

endmodule

module pe_t (
    input  logic        clk,
    input  logic        rst,
    input  logic signed [15:0] iact_in,    // Activación de entrada
    input  logic signed [15:0] psum_in,    // Suma parcial de entrada
    input  logic signed [15:0] weight_in,  // Peso de entrada
    output logic signed [15:0] iact_out,   // Activación de salida
    output logic signed [15:0] psum_out,   // Suma parcial de salida
    output logic signed [15:0] weight_out  // Peso de salida
);

    // Registros internos
    logic signed [15:0] weight_reg;   // Registro para peso estacionario
    logic signed [31:0] product;      // Resultado de multiplicación
    logic signed [31:0] psum_acc;     // Acumulador de suma parcial

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            weight_reg <= '0;
            product    <= '0;
            psum_acc   <= '0;
        end else begin
            // Registro de peso (solo se carga en el primer ciclo)
            weight_reg <= weight_in;
            
            // Multiplicación activación x peso
            product <= iact_in * weight_reg;
            
            // Acumulación de suma parcial
            psum_acc <= psum_in + product;
        end
    end

    // Asignación de salidas
    assign iact_out   = iact_in;     // Pasa la activación sin modificar
    assign psum_out   = psum_acc;    // Suma parcial acumulada
    assign weight_out = weight_reg;  // Peso registrado

endmodule