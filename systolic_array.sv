module systolic_array (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic signed [15:0] A[10][10], 
    output logic        done,
    output logic signed [15:0] A_result[0:9][0:9]
);

    // Internal weights (WS: Weight Stationary)
    logic signed [15:0] weights[10][10];

    // PE interconnection wires - completely separated
    logic signed [15:0] pe_iact_in[10][10];   // Input to each PE
    logic signed [15:0] pe_iact_out[10][10];  // Output from each PE
    logic signed [15:0] pe_psum_in[10][10];   // Psum input to each PE
    logic signed [15:0] pe_psum_out[10][10];  // Psum output from each PE
    logic signed [15:0] pe_weight_in[10][10]; // Weight input to each PE
    logic signed [15:0] pe_weight_out[10][10]; // Weight output from each PE

    // Temporary wires for first column inputs
    logic signed [15:0] first_col_iact[10];
    logic signed [15:0] first_col_weight[10];

    // Cycle counter
    logic [7:0] cycle;

    // FSM states
    typedef enum logic [1:0] {IDLE, LOAD_WEIGHTS, RUN, DONE} state_t;
    state_t state;

    // Buffer for results
    logic signed [15:0] result_buffer[0:9][0:9];

    // Weight initialization
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
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

    // FSM and control logic
    always_ff @(posedge clk or posedge rst) begin
        integer i, j;
        if (rst) begin
            cycle <= 0;
            state <= IDLE;
            done <= 0;
            
            // Initialize first column inputs
            for (i = 0; i < 10; i++) begin
                first_col_iact[i] <= 0;
                first_col_weight[i] <= 0;
            end
            
            // Initialize result buffer
            for (i = 0; i < 10; i++) begin
                for (j = 0; j < 10; j++) begin
                    result_buffer[i][j] <= 0;
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
                    // Load weights into the first column
                    for (i = 0; i < 10; i++) begin
                        first_col_weight[i] <= weights[i][cycle];
                    end
                    
                    cycle <= cycle + 1;
                    if (cycle == 9) begin
                        cycle <= 0;
                        state <= RUN;
                    end
                end

                RUN: begin
                    // Input pattern with delays
                    for (i = 0; i < 10; i++) begin
                        automatic int delay_offset = i;
                        automatic int data_offset = cycle - delay_offset;
                        
                        if (data_offset >= 0 && data_offset < 10) begin
                            first_col_iact[i] <= A[i][9-data_offset]; // Read in reverse order
                        end else begin
                            first_col_iact[i] <= 0; // Delay
                        end
                    end

                    // Capture results only during valid output cycles (12-21)
                    if (cycle >= 12 && cycle <= 21) begin
                        for (j = 0; j < 10; j++) begin
                            result_buffer[cycle-12][j] <= pe_psum_out[9][j];
                        end
                    end

                    cycle <= cycle + 1;
                    if (cycle == 37) begin
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

    // Generate systolic array connections
    genvar i, j;
    generate
        for (i = 0; i < 10; i++) begin : row
            for (j = 0; j < 10; j++) begin : col
                // Connect inputs based on position
                if (j == 0) begin
                    // First column gets inputs from control logic
                    assign pe_iact_in[i][j] = first_col_iact[i];
                    assign pe_weight_in[i][j] = first_col_weight[i];
                end else begin
                    // Other columns get inputs from previous PEs
                    assign pe_iact_in[i][j] = pe_iact_out[i][j-1];
                    assign pe_weight_in[i][j] = pe_weight_out[i][j-1];
                end
                
                // Connect psum inputs: first row gets 0, others get from row above
                assign pe_psum_in[i][j] = (i == 0) ? 16'sd0 : pe_psum_out[i-1][j];
                
                // Instantiate PE
                pe_t pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .iact_in(pe_iact_in[i][j]),
                    .psum_in(pe_psum_in[i][j]),
                    .weight_in(pe_weight_in[i][j]),
                    .iact_out(pe_iact_out[i][j]),
                    .psum_out(pe_psum_out[i][j]),
                    .weight_out(pe_weight_out[i][j])
                );
            end
        end
    endgenerate

    // Direct assignment of final results
    assign A_result = result_buffer;

endmodule