module ram_tb;
  reg [18:0] addr;
  reg clk, wren;
  wire [7:0] q;
  
  ram dut (
    .clock(clk),
    .address_a(addr),
    .wren_a(wren),
    .data_a(8'd0),
    .q_a(q),
    .address_b(19'd0),
    .wren_b(1'b0),
    .data_b(8'd0),
    .q_b()
  );

  initial begin
    clk = 0; wren = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    addr = 0;
    #20 addr = 1;
    #20 addr = 2;
    #20 addr = 3;
    #20 $stop;
  end
endmodule
