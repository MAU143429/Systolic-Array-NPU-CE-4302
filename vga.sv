module vga (
    input logic clk, enter,
    output logic vga_hsync, vga_vsync, sync_blank, sync_b,
    output logic [7:0] red, green, blue,
    output logic clk_25
);
    // Señales internas
    logic [9:0] hs, vs;
    logic [18:0] pixel_address;  // 19 bits para direccionar 460x460x2 imágenes
    logic [7:0] pixel_data;
	 logic [18:0] wr_address = 19'b0;
    logic [7:0] wr_data = 8'b0;
    logic wren = 1'b0;
    
    // Instancias
    clkdiv div(.clk(clk), .clk_25(clk_25));
    
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
        .pixel_data(pixel_data),
        .r(red),
        .g(green),
        .b(blue),
        .pixel_address(pixel_address)
    );
    
    // Instancia de la RAM generada por el IP
     ram ram_inst (
        .address_a(pixel_address),
        .address_b(19'b0),       // No usado
        .clock(clk_25),
        .data_a(8'b0),           // No usado
        .data_b(8'b0),           // No usado
        .wren_a(1'b0),           // Siempre lectura
        .wren_b(1'b0),           // Deshabilitado
        .q_a(pixel_data),       // Salida a VGA
        .q_b()                  // No usado
    );

endmodule