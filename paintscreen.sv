module paintscreen (
    input logic clk_25, 
    input logic enter,
    input logic [9:0] hs, vs,
    input logic [7:0] pixel_data_rom,  // Datos de la ROM
    input logic [7:0] pixel_data_ram,  // Datos de la RAM
    output logic [7:0] r, g, b,
    output logic [18:0] pixel_address_rom,  // Dirección para ROM
    output logic [18:0] pixel_address_ram   // Dirección para RAM
);

    parameter IMG_WIDTH = 400;
    parameter IMG_HEIGHT = 400;
    parameter H_START = 120;  // Posición horizontal inicial
    parameter V_START = 40;   // Posición vertical inicial
    logic [9:0] rel_x, rel_y;
    logic [7:0] pixel_data_selected;
    
    always_ff @(posedge clk_25) begin
        if (hs >= H_START && hs < H_START + IMG_WIDTH &&
            vs >= V_START && vs < V_START + IMG_HEIGHT) begin
            
            rel_x = hs - H_START;
            rel_y = vs - V_START;
            
            // Direcciones independientes (mismo cálculo, pero salidas separadas)
            pixel_address_rom <= (rel_y * IMG_WIDTH) + rel_x;  // ROM
            pixel_address_ram <= (rel_y * IMG_WIDTH) + rel_x;  // RAM
            
            // Selección de datos basada en 'enter'
            pixel_data_selected = (enter) ? pixel_data_ram : pixel_data_rom;
            
            // Salida en escala de grises
            {r, g, b} <= {pixel_data_selected, pixel_data_selected, pixel_data_selected};
        end else begin
            // Fuera del área de la imagen: negro y direcciones a 0
            {r, g, b} <= 24'h000000;
            pixel_address_rom <= 19'b0;
            pixel_address_ram <= 19'b0;
        end
    end
endmodule