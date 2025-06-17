module npu_top_module (
    input  logic clk,
    input  logic rst,
    input  logic start_button,
    output logic processing_done,
    output logic vga_hsync,
    output logic vga_vsync,
    output logic sync_blank,
    output logic sync_b,
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue,
    input  logic enter
);

    // Image parameters (changed to 400x400 to match your paintscreen module)
    parameter IMG_WIDTH = 400;
    parameter IMG_HEIGHT = 400;
    parameter TILE_SIZE = 10;
    parameter IMG_SIZE = IMG_WIDTH * IMG_HEIGHT;
    parameter NUM_TILES_X = IMG_WIDTH / TILE_SIZE;
    parameter NUM_TILES_Y = IMG_HEIGHT / TILE_SIZE;
    
    // Clock signals
    logic clk_25;
    
    // Control signals
    logic start_processing;
    logic tile_processed;
    logic [18:0] read_addr;
    logic [18:0] write_addr;
    
    // Signals for the NPU
    logic signed [15:0] current_tile[0:TILE_SIZE-1][0:TILE_SIZE-1];
    logic [7:0] npu_result[0:TILE_SIZE-1][0:TILE_SIZE-1];
    logic npu_done;
    
    // RAM signals
    logic [7:0] ram_data_out;
    logic [7:0] ram_data_in;
    logic ram_wren;
    
    // Tile counters
    logic [5:0] tile_x;  // 0 to 39 (400/10 - 1)
    logic [5:0] tile_y;  // 0 to 39
    
    // Element counters
    logic [3:0] element_x, element_y;
    
    // State machine
    typedef enum {
        IDLE,
        READ_TILE,
        PROCESS_TILE,
        WRITE_TILE,
        DONE
    } state_t;
    
    state_t current_state, next_state;
    
    // Instantiate clock divider
    clkdiv clk_div (
        .clk(clk),
        .clk_25(clk_25)
    );
    
    // Instantiate VGA controller
    vga vga_controller (
        .clk(clk),
        .enter(enter),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .sync_blank(sync_blank),
        .sync_b(sync_b),
        .red(red),
        .green(green),
        .blue(blue),
        .clk_25(clk_25)
    );
    
    // Instantiate RAM
    ram image_ram (
        .address_a(read_addr),
        .address_b(vga_controller.pixel_address),  // VGA reads from address_b
        .clock(clk_25),
        .data_a(8'b0),
        .data_b(ram_data_in),
        .wren_a(1'b0),
        .wren_b(ram_wren),
        .q_a(ram_data_out),
        .q_b()  // VGA reads from q_a
    );
    
    // Instantiate NPU
    npu image_npu (
        .clk(clk_25),  // Use 25MHz clock for processing
        .rst(rst),
        .start(start_processing),
        .input_matrix(current_tile),
        .done(npu_done),
        .final_output(npu_result)
    );
    
    // State register
    always_ff @(posedge clk_25 or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (start_button) begin
                    next_state = READ_TILE;
                end
            end
            
            READ_TILE: begin
                if (element_x == TILE_SIZE-1 && element_y == TILE_SIZE-1) begin
                    next_state = PROCESS_TILE;
                end
            end
            
            PROCESS_TILE: begin
                if (npu_done) begin
                    next_state = WRITE_TILE;
                end
            end
            
            WRITE_TILE: begin
                if (element_x == TILE_SIZE-1 && element_y == TILE_SIZE-1) begin
                    if (tile_x == NUM_TILES_X-1 && tile_y == NUM_TILES_Y-1) begin
                        next_state = DONE;
                    end else begin
                        next_state = READ_TILE;
                    end
                end
            end
            
            DONE: begin
                // Stay here until reset
            end
        endcase
    end
    
    // Counters and address control
    always_ff @(posedge clk_25 or posedge rst) begin
        if (rst) begin
            tile_x <= 0;
            tile_y <= 0;
            element_x <= 0;
            element_y <= 0;
            read_addr <= 0;
            write_addr <= IMG_SIZE;  // Start writing after original image
            processing_done <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    tile_x <= 0;
                    tile_y <= 0;
                    element_x <= 0;
                    element_y <= 0;
                    read_addr <= 0;
                    write_addr <= IMG_SIZE;
                    processing_done <= 0;
                end
                
                READ_TILE: begin
                    // Calculate read address: (tile_y*TILE_SIZE + element_y)*IMG_WIDTH + (tile_x*TILE_SIZE + element_x)
                    read_addr <= (tile_y*TILE_SIZE + element_y)*IMG_WIDTH + (tile_x*TILE_SIZE + element_x);
                    
                    if (element_x == TILE_SIZE-1) begin
                        element_x <= 0;
                        if (element_y == TILE_SIZE-1) begin
                            element_y <= 0;
                        end else begin
                            element_y <= element_y + 1;
                        end
                    end else begin
                        element_x <= element_x + 1;
                    end
                end
                
                PROCESS_TILE: begin
                    // Wait for processing to complete
                    if (npu_done) begin
                        element_x <= 0;
                        element_y <= 0;
                    end
                end
                
                WRITE_TILE: begin
                    // Calculate write address: IMG_SIZE + (tile_y*TILE_SIZE + element_y)*IMG_WIDTH + (tile_x*TILE_SIZE + element_x)
                    write_addr <= IMG_SIZE + (tile_y*TILE_SIZE + element_y)*IMG_WIDTH + (tile_x*TILE_SIZE + element_x);
                    
                    if (element_x == TILE_SIZE-1) begin
                        element_x <= 0;
                        if (element_y == TILE_SIZE-1) begin
                            element_y <= 0;
                            
                            // Move to next tile
                            if (tile_x == NUM_TILES_X-1) begin
                                tile_x <= 0;
                                tile_y <= tile_y + 1;
                            end else begin
                                tile_x <= tile_x + 1;
                            end
                        end else begin
                            element_y <= element_y + 1;
                        end
                    end else begin
                        element_x <= element_x + 1;
                    end
                end
                
                DONE: begin
                    processing_done <= 1;
                end
            endcase
        end
    end
    
    // Read data from RAM and form 10x10 tile
    always_ff @(posedge clk_25) begin
        if (current_state == READ_TILE) begin
            // Convert 8-bit unsigned to 16-bit signed
            current_tile[element_y][element_x] <= {8'b0, ram_data_out};
        end
    end
    
    // Write data to RAM
    assign ram_data_in = npu_result[element_y][element_x];
    assign ram_wren = (current_state == WRITE_TILE);
    
    // Control signals
    assign start_processing = (current_state == PROCESS_TILE);
    
endmodule