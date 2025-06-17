module paintscreen (
    input logic clk_25, 
    input logic enter, 	
    input logic [9:0] hs, vs,
    input logic [7:0] pixel_data,
    output logic [7:0] r, g, b,
    output logic [18:0] pixel_address
);

    parameter IMG_WIDTH = 400;
    parameter IMG_HEIGHT = 400;
    parameter IMG1_START = 0;          
    parameter IMG2_START = 160000;     
    parameter H_START = 120;           
    parameter V_START = 40;            
	 logic [9:0] rel_x, rel_y;
    
    always_ff @(posedge clk_25) begin
	 
        if (hs >= H_START && hs < H_START + IMG_WIDTH &&
            vs >= V_START && vs < V_START + IMG_HEIGHT) begin
            
            rel_x = hs - H_START;
            rel_y = vs - V_START;
            
            if (enter == 1'b0) begin
               
                pixel_address <= IMG1_START + (rel_y * IMG_WIDTH) + rel_x;
            end else begin
                
                pixel_address <= IMG2_START + (rel_y * IMG_WIDTH) + rel_x;
            end
           
            {r, g, b} <= {pixel_data, pixel_data, pixel_data};
        end else begin
          
            {r, g, b} <= 24'h000000;
            pixel_address <= 19'b0;  
        end
    end
endmodule