`timescale 1ns/1ps

module npu_tb;

    // Parameters
    parameter CLK_PERIOD = 10;
    
    // Signals
    logic clk;
    logic rst;
    logic start;
    logic done;
    logic signed [15:0] input_matrix[9:0][9:0];
    logic [7:0] final_output[9:0][9:0];
    
    // DUT
    npu dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .input_matrix(input_matrix),
        .done(done),
        .final_output(final_output)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        repeat (1000) begin
            #5 clk = ~clk;
        end
    end
    
    // Display helper functions
    function void display_matrix(string name, logic signed [15:0] matrix[9:0][9:0]);
        $display("=== %s ===", name);
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                $write("%6d ", matrix[i][j]);
            end
            $display();
        end
    endfunction
    
    function void display_normalized_matrix(string name, logic [7:0] matrix[9:0][9:0]);
        $display("=== %s (Normalized 8-bit) ===", name);
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                $write("%4d ", matrix[i][j]);
            end
            $display();
        end
    endfunction
    
    // Test sequence
    initial begin
        // Initialize input matrix
        input_matrix = '{
			 '{ 45, 210,  98, 123,  34,  67, 155,  89, 200,  11},
			 '{233,  54, 128,  76,  99, 177,  32, 145,  66, 201},
			 '{ 87, 199,  22,  43, 110, 255,   0,  78, 164,  33},
			 '{112,  65, 187,  90,  44,  23, 156,  79, 122, 211},
			 '{167,  89, 134,  55,  76,  12,  98, 200,  45,  67},
			 '{ 77, 143,  22, 188, 109,  34, 165,  88, 199, 111},
			 '{154,  76,  43,  20,  87, 222,  33, 145,  66, 178},
			 '{122,  45, 167,  99,  89, 200,  11,  34, 155,  76},
			 '{ 65,  32, 144, 177,  98, 211,  87,  23, 166,  44},
			 '{188,  77, 199,  53, 122,  34, 156,  89, 200,  12}
			};
        
        // Reset sequence
        rst = 1;
        start = 0;
        #(CLK_PERIOD*2);
        rst = 0;
        #(CLK_PERIOD*2);
        
        // Display input matrix
        display_matrix("INPUT MATRIX", input_matrix);
        
        // Start processing
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Wait for completion
        wait(done);
        #(CLK_PERIOD*5);
        
        // Display final output
        display_normalized_matrix("FINAL NORMALIZED OUTPUT", final_output);
        
        $display("\nNPU processing completed successfully!");
        $finish;
    end

    // Debugging: Use $display to show intermediate values at specific times
    initial begin
        // Wait until systolic array completes
        @(posedge dut.systolic_done);
        #10;
        $display("\n=== SYSTOLIC ARRAY OUTPUT (DEBUG) ===");
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                $write("%6d ", dut.systolic_inst.A_result[i][j]);
            end
            $display();
        end
        
        // Wait until ReLU completes
        @(posedge dut.norm_done);
        #10;
        $display("\n=== LEAKY ReLU OUTPUT (DEBUG) ===");
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                $write("%6d ", dut.relu_inst.out_matrix[i][j]);
            end
            $display();
        end
    end

endmodule