module systolic_array (
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic signed [15:0] A[10][10],
    output logic done,
    output logic signed [15:0] A_result[0:9][0:9],
	 output logic signed [15:0] weights_out[10][10]
);

    // Pesos fijos por PE (manual o luego parametrizable)
    logic signed [15:0] weights[10][10];

    // Wires para propagación horizontal (iact) y vertical (psum)
    logic signed [15:0] iact_wire[10][11];  // de cada PE a la derecha
    logic signed [15:0] psum_wire[11][10];  // de cada PE hacia abajo
	 
	 logic signed [15:0] temp_result[0:18][0:9];


    // Ciclo para control de flujo
    logic [5:0] cycle;
    typedef enum logic [1:0] {IDLE, RUN, DONE} state_t;
    state_t state;


	// Inicialización de pesos: filas 0–4 con 1, filas 5–9 con -1
	always_ff @(posedge clk or posedge rst) begin
		 if (rst) begin
			  for (int i = 0; i < 10; i++) begin
					for (int j = 0; j < 10; j++) begin
						 if (i < 5)
							  weights[i][j] <= 16'sd1;
						 else
							  weights[i][j] <= -16'sd1;
					end
			  end
		 end
	end


	 assign weights_out = weights;


    // Inyección de A en la primera columna
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle <= 0;
            state <= IDLE;
            done  <= 0;
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
                    for (int i = 0; i < 10; i++) begin
                        if ((cycle >= i) && (cycle - i < 10))
                            iact_wire[i][0] <= A[i][cycle - i];
                        else
                            iact_wire[i][0] <= 0;
                    end

                    cycle <= cycle + 1;
                    if (cycle == 28)
                        state <= DONE;
                end
                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

   genvar i, j;
	generate
		 for (i = 0; i < 10; i++) begin : row
			  for (j = 0; j < 10; j++) begin : col
					pe pe_inst (
						 .iact_in (iact_wire[i][j]),
						 .psum_in (i == 0 ? 16'sd0 : psum_wire[i][j]),
						 .weight  (weights[i][j]),
						 .iact_out(iact_wire[i][j+1]),
						 .psum_out(psum_wire[i+1][j])
					);
			  end
		 end
	endgenerate
	
	
	
	// Captura diagonal
	always_ff @(posedge clk) begin
		 if (state == RUN && cycle >= 9 && cycle <= 28) begin
			  int sum_idx;
			  sum_idx = cycle - 9;
			  for (int i = 0; i < 10; i++) begin
					int j;
					j = sum_idx - i;
					if (j >= 0 && j < 10)
						 temp_result[sum_idx][j] <= psum_wire[10][j];
			  end
		 end
	end


	// Reorganización final a salida limpia
	always_ff @(posedge clk) begin
		 if (state == DONE) begin
			  for (int i = 0; i < 10; i++) begin
					for (int j = 0; j < 10; j++) begin
						 A_result[i][j] <= temp_result[i + j][j];
					end
			  end
		 end
	end



endmodule
