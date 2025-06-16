module paintscreen (
    input logic clk,
	 input logic ok_button,
    input logic [9:0] hs, vs,          // Coordenadas horizontales y verticales
    input logic [7:0] pixel_data,      // Datos de los píxeles en escala de grises desde la ROM
    output logic [7:0] r, g, b,        // Salida RGB
    output logic [17:0] pixel_address  // Dirección de los píxeles de la ROM
);

	logic flag_red;

	initial begin
		flag_red = 0;    
	end	
    always @(posedge clk) begin
			
		  if (ok_button) begin 
		    flag_red = 1;
		  end
	 
			
        // Verificar si las coordenadas están dentro del área de la imagen
        if ((hs >= 120) && (hs <= 520) && (vs >= 40) && (vs <= 440) && !flag_red) begin
            // Calcular la dirección de la ROM basada en las coordenadas
            // El mapeo es: dirección = (vs - 40) * 400 + (hs - 120)
            pixel_address = ((vs - 40) * 400) + (hs - 120);
            
            // Asignar el valor del píxel en escala de grises a los canales RGB
            r = pixel_data;  // Los 8 bits de escala de grises se asignan a los 3 canales
            g = pixel_data;
            b = pixel_data;
        end else if ((hs >= 220) && (hs <= 420) && (vs >= 140) && (vs <= 340) && flag_red) begin
            // Calcular la dirección de la ROM basada en las coordenadas
            // El mapeo es: dirección = (vs - 40) * 400 + (hs - 120)
            pixel_address = ((vs - 140) * 200) + (hs - 220);
            
            // Asignar el valor del píxel en escala de grises a los canales RGB
            r = pixel_data;  // Los 8 bits de escala de grises se asignan a los 3 canales
            g = pixel_data;
            b = pixel_data;
        end else begin
				
				// Fuera del área activa de la imagen, dejar la pantalla negra
            r = 8'b00000000;
            g = 8'b00000000;
            b = 8'b00000000;
		  
		  end
		
		  
		  
    end

endmodule