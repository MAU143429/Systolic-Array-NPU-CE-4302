module clkdiv(
    input  logic clk,      // 50 MHz
    output logic clk_25    // 25 MHz
);
    always @(posedge clk) begin
        clk_25 <= ~clk_25; // Alterna en cada flanco (divide por 2)
    end
endmodule