module clkdiv(
	input logic clk,
	output logic clk_25
);
	
	reg [15:0] cnt;
	
	always @(posedge clk)
		{clk_25, cnt} <= cnt + 16'h8000;
		
endmodule