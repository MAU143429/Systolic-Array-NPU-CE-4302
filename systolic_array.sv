module systolic_array (
    input  logic         clk,
    input  logic         rst,
    input  logic         start,
    input  logic signed [15:0] A[10][10],
    output logic         done,
    output logic signed [15:0] A_result[0:9][0:9] // C++ output is N x N
);

    // N defined as 10 for convenience in Verilog
    localparam N = 10;

    // Internal weights (WS: Weight Stationary)
    logic signed [15:0] weights[N][N];

    // PE interconnection wires
    // These will now represent the 'a' and 'sum' members within each PE in C++
    logic signed [15:0] pe_iact_in[N][N];
    logic signed [15:0] pe_iact_out[N][N]; // Represents PE.a for the next cycle's left neighbor
    logic signed [15:0] pe_psum_in[N][N];
    logic signed [15:0] pe_psum_out[N][N]; // Represents PE.sum

    // Wire to feed diagonal inputs based on C++ A[i][t-i]
    logic signed [15:0] diagonal_input[N];

    // Cycle counter and FSM state
    logic [7:0] cycle;
    typedef enum logic [1:0] {IDLE, RUN, DONE} state_t;
    state_t state;

    // The C++ `outputAccumulator` is N x N, let's match that.
    logic signed [15:0] result_buffer[20][N];
	 logic signed [15:0] res_buffer [N][N];
	
	 /**
	 
	Gaussiano Suavizado
	
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
	
	*/
    // Weight initialization - matches C++ weights
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
       	weights[0] <= '{ -2, -2, -2, -2, -2, -2, -2, -2, -2, -2 };
			weights[1] <= '{ -2,  0,  0,  0,  1,  1,  0,  0,  0, -2 };
			weights[2] <= '{ -2,  0,  3,  3,  5,  5,  3,  3,  0, -2 };
			weights[3] <= '{ -2,  0,  3,  8, 10, 10,  8,  3,  0, -2 };
			weights[4] <= '{ -2,  1,  5, 10, 16, 16, 10,  5,  1, -2 };
			weights[5] <= '{ -2,  1,  5, 10, 16, 16, 10,  5,  1, -2 };
			weights[6] <= '{ -2,  0,  3,  8, 10, 10,  8,  3,  0, -2 };
			weights[7] <= '{ -2,  0,  3,  3,  5,  5,  3,  3,  0, -2 };
			weights[8] <= '{ -2,  0,  0,  0,  1,  1,  0,  0,  0, -2 };
			weights[9] <= '{ -2, -2, -2, -2, -2, -2, -2, -2, -2, -2 };
        end
    end

    // FSM and control logic - matches C++ timing (3*N-1 cycles)
    always_ff @(posedge clk or posedge rst) begin
        integer i, j;
        if (rst) begin
            cycle <= 0;
            state <= IDLE;
            done <= 0;

            for (i = 0; i < N; i++) begin
                diagonal_input[i] <= 0;
            end

            for (i = 0; i < N; i++) begin
                for (j = 0; j < N; j++) begin
                    result_buffer[i][j] <= 0;
                end
            end

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
								 // Input pattern (mantener igual)
								 for (i = 0; i < N; i++) begin
									  automatic int data_col = cycle - i;
									  if (data_col >= 0 && data_col < N) begin
											diagonal_input[i] <= A[i][data_col];
									  end else begin
											diagonal_input[i] <= 0;
									  end
								 end

								 // Improved output accumulation - matches C++ exactly
								 // Shift all rows down
								 for (i = N*2-1; i > 0; i--) begin  // Buffer más grande para acumulación
									  for (j = 0; j < N; j++) begin
											result_buffer[i][j] <= result_buffer[i-1][j];
									  end
								 end

								 // Update first row with PE outputs
								 for (j = 0; j < N; j++) begin
									  result_buffer[0][j] <= pe_psum_out[N-1][j]; // Last row PEs contain final results
								 end

								 cycle <= cycle + 1;
								 if (cycle == (3*N - 2)) begin  // 29 cycles (0-28)
									  state <= DONE;
									  done <= 1;
								 end
							end

                DONE: begin
							for (int i = 0; i < 10; i++) begin
                            for (int j = 0; j < 10; j++) begin
                                res_buffer[i][j] <= result_buffer[i+7][j];  // Extraer filas 7-16
                            end
                        end
                    done <= 1;
						  state <= IDLE; 
                end
            endcase
        end
    end

    // Generate systolic array connections - matches C++ data flow
    genvar i, j;
    generate
        for (i = 0; i < N; i++) begin : row
            for (j = 0; j < N; j++) begin : col
                // Activation flow (horizontal)
                // C++: if (j > 0) peGrid[i][j].a = peGrid[i][j - 1].a;
                // C++: else if (t - i >= 0 && t - i < N) peGrid[i][j].a = A[i][t - i];
                // C++: else peGrid[i][j].a = 0;
                if (j == 0) begin
                    assign pe_iact_in[i][j] = diagonal_input[i]; // Input from the diagonal source
                end else begin
                    assign pe_iact_in[i][j] = pe_iact_out[i][j-1]; // From the left PE's output 'a'
                end

                // Psum flow (vertical) - top to bottom like C++
                // C++: psum_in = (i > 0) ? peGrid[i - 1][j].sum : 0;
                assign pe_psum_in[i][j] = (i == 0) ? 16'sd0 : pe_psum_out[i-1][j];

                // PE instantiation with fixed weights
                pe_t pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .iact_in(pe_iact_in[i][j]),
                    .psum_in(pe_psum_in[i][j]),
                    .weight_in(weights[i][j]),
                    .iact_out(pe_iact_out[i][j]),
                    .psum_out(pe_psum_out[i][j]),
                    .weight_out() // Not used in weight-stationary
                );
            end
        end
    endgenerate

    assign A_result = res_buffer;

endmodule