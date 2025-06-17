module vga (
    input logic clk, enter, clk_25,
	 input logic [7:0] pixel_data_rom, pixel_data_ram,
	 output logic [18:0] pixel_address_rom,pixel_address_ram,
    output logic vga_hsync, vga_vsync, sync_blank, sync_b,
    output logic [7:0] red, green, blue
);
    // Señales internas
    logic [9:0] hs, vs;
	 
	  gcontroller controller(
	  .clk_25(clk_25),
	  .vga_hsync(vga_hsync),
	  .vga_vsync(vga_vsync),
	  .sync_blank(sync_blank),
	  .sync_b(sync_b),
	  .hs(hs),
	  .vs(vs)
    );
	 
    paintscreen painter(
        .clk_25(clk_25),
        .enter(enter),
        .hs(hs),
        .vs(vs),
        .pixel_data_rom(pixel_data_rom),  // Conexión directa desde la ROM
        .pixel_data_ram(pixel_data_ram),  // Conexión directa desde la RAM
        .r(red),
        .g(green),
        .b(blue),
        .pixel_address_ram(pixel_address_ram),
		  .pixel_address_rom(pixel_address_rom)
    );
    
endmodule



