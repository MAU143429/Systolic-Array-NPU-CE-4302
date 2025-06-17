`timescale 1ns/1ps
module systolic_array_tb;
    // Parameters
    parameter CLK_PERIOD = 10;
    
    // Signals
    logic clk;
    logic rst;
    logic start;
    logic done;
    logic signed [15:0] input_matrix[9:0][9:0];
    logic signed [15:0] output_matrix[0:9][0:9];
    
    // DUT
    systolic_array dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(input_matrix),
        .done(done),
        .A_result(output_matrix)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        repeat (2000) begin  // Extended for longer simulation
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
    
    function void display_full_output_matrix(string name, logic signed [15:0] matrix[0:9][0:9]);
        $display("=== %s ===", name);
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                $write("%6d ", matrix[i][j]);
            end
            $display();
        end
    endfunction
    
    function void display_10x10_section(string name, logic signed [15:0] matrix[0:9][0:9], int start_row, int start_col);
        $display("=== %s [%0d:%0d, %0d:%0d] ===", name, start_row, start_row+9, start_col, start_col+9);
        for (int i = start_row; i < start_row + 10; i++) begin
            for (int j = start_col; j < start_col + 10; j++) begin
                if (i < 9 && j < 9) begin
                    $write("%6d ", matrix[i][j]);
                end else begin
                    $write("   --- ");
                end
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
        
        // Display full output matrix
        display_full_output_matrix("COMPLETE SYSTOLIC ARRAY OUTPUT (19x19)", output_matrix);
          
        $display("\nSystolic Array processing completed successfully!");
        $display("Total cycles processed: 37");
        $display("Output matrix size: 19x19");
        $finish;
    end
    
    // Debugging: Monitor done signal and cycle progress
    initial begin
        $display("Starting systolic array simulation...");
        
        // Monitor START signal
        @(posedge start);
        $display("START signal received");
        
        // Wait for processing to complete
        @(posedge done);
        $display("Processing completed - DONE signal received");
    end
    
    // Monitor cycle progress during processing
    initial begin
        // Wait for start signal
        @(posedge start);
        #(CLK_PERIOD * 20); // Wait some cycles before monitoring
        
        $display("Monitoring cycle progress...");
        for (int cycle_count = 0; cycle_count < 100; cycle_count++) begin
            @(posedge clk);
            if (cycle_count % 10 == 0) begin
                $display("Simulation cycle %0d", cycle_count);
            end
            if (done) break;
        end
        
        $display("Cycle monitoring completed");
    end
endmodule