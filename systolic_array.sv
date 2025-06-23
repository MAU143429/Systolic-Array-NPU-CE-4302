module systolic_array (
    input  logic         clk,
    input  logic         rst,
    input  logic         start,
    input  logic signed [15:0] A[10][10],
    output logic         done,
    output logic signed [15:0] A_result[0:9][0:9] 
);

    
    localparam N = 10;

    
    logic signed [15:0] weights[N][N];


    logic signed [15:0] pe_iact_in[N][N];
    logic signed [15:0] pe_iact_out[N][N]; 
    logic signed [15:0] pe_psum_in[N][N];
    logic signed [15:0] pe_psum_out[N][N]; 


    logic signed [15:0] diagonal_input[N];


    logic [7:0] cycle;
    typedef enum logic [1:0] {IDLE, RUN, DONE} state_t;
    state_t state;


    logic signed [15:0] result_buffer[20][N];
	 logic signed [15:0] res_buffer [N][N];
	

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
		//FSM
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
								
								 for (i = 0; i < N; i++) begin
									  automatic int data_col = cycle - i;
									  if (data_col >= 0 && data_col < N) begin
											diagonal_input[i] <= A[i][data_col];
									  end else begin
											diagonal_input[i] <= 0;
									  end
								 end

								 
								 for (i = N*2-1; i > 0; i--) begin  
									  for (j = 0; j < N; j++) begin
											result_buffer[i][j] <= result_buffer[i-1][j];
									  end
								 end

								 
								 for (j = 0; j < N; j++) begin
									  result_buffer[0][j] <= pe_psum_out[N-1][j];
								 end

								 cycle <= cycle + 1;
								 if (cycle == (3*N - 2)) begin  
									  state <= DONE;
									  done <= 1;
								 end
							end

                DONE: begin
							for (int i = 0; i < 10; i++) begin
                            for (int j = 0; j < 10; j++) begin
                                res_buffer[i][j] <= result_buffer[i+7][j]; 
                            end
                        end
                    done <= 1;
						  state <= IDLE; 
                end
            endcase
        end
    end

    genvar i, j;
    generate
        for (i = 0; i < N; i++) begin : row
            for (j = 0; j < N; j++) begin : col
    
                if (j == 0) begin
                    assign pe_iact_in[i][j] = diagonal_input[i]; 
                end else begin
                    assign pe_iact_in[i][j] = pe_iact_out[i][j-1]; 
                end


                assign pe_psum_in[i][j] = (i == 0) ? 16'sd0 : pe_psum_out[i-1][j];

                pe_t pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .iact_in(pe_iact_in[i][j]),
                    .psum_in(pe_psum_in[i][j]),
                    .weight_in(weights[i][j]),
                    .iact_out(pe_iact_out[i][j]),
                    .psum_out(pe_psum_out[i][j]),
                    .weight_out() 
                );
            end
        end
    endgenerate

    assign A_result = res_buffer;

endmodule