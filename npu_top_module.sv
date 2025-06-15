module npu_top_module (
    input  logic clk,
    input  logic rst,
    input  logic start_button
);

    logic start, done;
    logic signed [15:0] A[10][10];
    logic signed [15:0] A_mac[10][10];
	 logic signed [15:0] A_leaky[10][10];
	 logic signed [15:0] A_normalized[10][10];

    // Cargar matrices desde la RAM
	 
	 
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 10; i++)
                for (int j = 0; j < 10; j++)
                    A[i][j] <= i + j;  // ejemplo simple
        end
    end
	 
	 
	assign start = start_button;
  
	 
	 // Instancia del arreglo sistólico 
	 /**
    systolic_array systolic_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .done(done),
        .A_result(A_mac)
    );*/
	 
	 
	 
	 // Instancia de Leaky ReLU para matriz A 
	 /**
    leaky_relu dut (
        .clk(clk),
        .rst(rst),
        .in_matrix(A_result),
        .out_matrix(out_matrix)
    );**
	 
	 
	 // Instancia de Normalizacion para matriz A 
	 
	 
	 
	 
	 
	 
	 // Cargar Matriz A resultante en RAM (Nueva posicion)
	 
	 
	
	 
	 
	 

endmodule
