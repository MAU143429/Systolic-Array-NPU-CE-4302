module gcontroller(
	input logic clk_25,
	output logic vga_hsync, vga_vsync, sync_blank, sync_b,
	output logic [9:0] hs, vs
);

	always @(posedge clk_25) begin
		hs++;
		if (hs == 10'd800) begin
			hs = 0;
			vs++;
			if (vs == 10'd525) vs = 0;
		end
	end
									   //Parte    Porch       Parte     Porch        Sincronizacion
										//Activa   Horizontal  Activa    Horizontal   Horizontal
	assign vga_hsync = ~(hs > 10'd640 + 10'd16 & hs < 10'd640 + 10'd16 +    10'd96);
		
		
	                           //Parte    Porch       Parte     Porch     Sincronización
										//Activa   Vertical    Activa    Vertical  Vertical
	assign vga_vsync = ~(vs > 10'd480 + 10'd11 & vs < 10'd480 + 10'd11 +  2);

	
	// Señales de sincronización adicionales
	//assign sync_b = vga_hsync & vga_vsync;
	//assign sync_blank = ~((hs < 10'd640) & (vs < 10'd480));
	
	assign sync_b = 1;
	assign sync_blank = 0;

endmodule