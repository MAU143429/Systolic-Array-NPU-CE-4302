module vga (
    input logic clk,
    input logic ok_button,
    output logic vga_hsync, vga_vsync, sync_blank, sync_b,
    output logic [7:0] red, green, blue,
    output logic clk_25
);

    logic [9:0] hs;
    logic [9:0] vs;
    logic [7:0] pixel_data;  // Datos de los píxeles (escala de grises)

    // Señales para la RAM
    logic [18:0] pixel_address;  // Cambiado a 19 bits para la RAM de megafunción
    logic [7:0] unused_data_b;
    logic [7:0] unused_q_b;
    
    // Divisor de reloj
    clkdiv div(clk, clk_25);
    
    // Controlador gráfico VGA
    gcontroller controller(
        .clk(clk_25),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .blank(sync_blank),
        .sync(sync_b),
        .hcount(hs),
        .vcount(vs)
    );

    // Instanciación de la RAM de megafunción
    ram ram_inst (
        // Puerto A (usado para lectura de píxeles)
        .address_a(pixel_address),  // Dirección de 19 bits
        .address_b(19'b0),          // Puerto B no usado
        .clock(clk_25),             // Reloj de la RAM
        .data_a(8'b0),              // No escribimos en este puerto
        .data_b(8'b0),              // No escribimos en este puerto
        .wren_a(1'b0),              // Deshabilitar escritura en puerto A
        .wren_b(1'b0),              // Deshabilitar escritura en puerto B
        .q_a(pixel_data),           // Datos del píxel leídos
        .q_b(unused_q_b)            // Salida del puerto B no usada
    );

    // Módulo para pintar la pantalla
    paintscreen painter(
        .clk(clk),
        .ok_button(ok_button),
        .hs(hs),
        .vs(vs),
        .pixel_data(pixel_data),
        .red(red),
        .green(green),
        .blue(blue),
        .pixel_address(pixel_address[17:0])  // Usamos solo 18 bits para la dirección
    );

endmodule