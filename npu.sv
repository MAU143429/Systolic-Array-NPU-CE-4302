`timescale 1ns/1ps

module npu (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic signed [15:0] input_matrix[9:0][9:0],
    output logic        done,
    output logic [7:0]  final_output[9:0][9:0]
);

    // Internal signals
    logic systolic_done, relu_done, norm_done;
    logic signed [15:0] systolic_out[9:0][9:0];
    logic signed [15:0] relu_out[9:0][9:0];
    
    // Systolic Array instance
    systolic_array systolic_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(input_matrix),
        .done(systolic_done),
        .A_result(systolic_out)
    );
    
    // Leaky ReLU instance
    leaky_relu relu_inst (
        .clk(clk),
        .rst(rst),
        .in_matrix(systolic_out),
        .out_matrix(relu_out)
    );
    
    // Normalization instance
    matrix_normalization norm_inst (
        .clk(clk),
        .reset(rst),
        .start(systolic_done), // Start when systolic array finishes
        .matrix_in(relu_out),
        .done(norm_done),
        .matrix_out(final_output)
    );
    
    // Combined done signal
    assign done = norm_done;

endmodule