module leaky_relu (
    input  logic clk,
    input  logic rst,
    input  logic signed [15:0] in_matrix [9:0][9:0],
    output logic signed [15:0] out_matrix [9:0][9:0]
);

    // alpha = 0.1
    // La multiplicación se implementa como (x * 13) >> 7 ≈ 0.1015625 
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 10; i++) begin
                for (int j = 0; j < 10; j++) begin
                    out_matrix[i][j] <= 0;
                end
            end
        end else begin
            for (int i = 0; i < 10; i++) begin
                for (int j = 0; j < 10; j++) begin
                    if (in_matrix[i][j] < 0)
                        out_matrix[i][j] <= (in_matrix[i][j] * 13) >>> 7; // aproxima 0.1015625
                    else
                        out_matrix[i][j] <= in_matrix[i][j];
                end
            end
        end
    end

endmodule
