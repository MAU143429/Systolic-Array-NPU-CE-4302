module npu_top_module (
    input  logic        clk,          // 50 MHz clock
    input  logic        rst,          // Reset signal
    input  logic        start,        // Start processing
    input  logic        enter,        // Input for paintscreen module
    output logic        done,         // Processing complete
	 output logic        clk_25,       // 25 Mhz clock
    output logic [7:0]  red,      // VGA red output
    output logic [7:0]  green,    // VGA green output
    output logic [7:0]  blue,     // VGA blue output
    output logic        vga_hsync,    // VGA horizontal sync
    output logic        vga_vsync,    // VGA vertical sync
    output logic        sync_blank,   // VGA blank signal
    output logic        sync_b        // VGA sync signal
);
    
    // RAM signals
    logic [18:0] ram_addr_read;
    logic [18:0] ram_addr_write;
    logic [7:0]  ram_data_read;
    logic [7:0]  ram_data_write;
    logic        ram_wren;
    
    // VGA signals
    logic [18:0] vga_pixel_address;
    logic [7:0]  vga_pixel_data;
    
    // NPU signals
    logic npu_start;
    logic npu_done;
    logic signed [15:0] input_matrix[9:0][9:0];
    logic [7:0] output_matrix[9:0][9:0];
    
    // FSM signals
    typedef enum {
        IDLE,
        READ_SUBMATRIX,
        PROCESS_NPU,
        WRITE_RESULT,
		  READ_SUBMATRIX_WAIT,
		  WRITE_RESULT_WAIT,
        FINISH
    } state_t;
    state_t state;
    
    // Position counters
    logic [5:0] submatrix_x;  // 0-39 (400/10)
    logic [5:0] submatrix_y;  // 0-39 (400/10)
    
    // Submatrix loading counter
    logic [3:0] load_row;
    logic [3:0] load_col;
    
    // Submatrix writing counter
    logic [3:0] write_row;
    logic [3:0] write_col;
    
    // Clock divider
    clkdiv clk_divider (
        .clk(clk),
        .clk_25(clk_25)
    );
    
    // Dual-port RAM
    ram image_ram (
        .address_a(ram_addr_read),
        .address_b(vga_pixel_address),
        .clock(clk_25),
        .data_a(ram_data_write),
        .data_b(8'h00),  // Not writing from port B
        .wren_a(ram_wren),
        .wren_b(1'b0),   // Never write from port B
        .q_a(ram_data_read),
        .q_b(vga_pixel_data)
    );
    
    // NPU instance
    npu image_npu (
        .clk(clk_25),
        .rst(rst),
        .start(npu_start),
        .input_matrix(input_matrix),
        .done(npu_done),
        .final_output(output_matrix)
    );
    
    // VGA controller
    vga vga_controller (
        .clk(clk),
        .enter(enter),
        .clk_25(clk_25),
        .pixel_data(vga_pixel_data),
        .pixel_address(vga_pixel_address),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .sync_blank(sync_blank),
        .sync_b(sync_b),
        .red(red),
        .green(green),
        .blue(blue)
    );
    
    // FSM for image processing
    always_ff @(posedge clk_25 or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            submatrix_x <= 0;
            submatrix_y <= 0;
            load_row <= 0;
            load_col <= 0;
            write_row <= 0;
            write_col <= 0;
            ram_wren <= 0;
            npu_start <= 0;
            done <= 0;
            
            // Initialize input matrix
            for (int i = 0; i < 10; i++) begin
                for (int j = 0; j < 10; j++) begin
                    input_matrix[i][j] <= 0;
                end
            end
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= READ_SUBMATRIX;
                        submatrix_x <= 0;
                        submatrix_y <= 0;
                        load_row <= 0;
                        load_col <= 0;
                        done <= 0;
                    end
                end
                
                READ_SUBMATRIX: begin
                    // Calculate address in original image
                    ram_addr_read <= (submatrix_y * 10 + load_row) * 400 + (submatrix_x * 10) + load_col;
                    
                    // Wait one cycle for RAM read latency
                    state <= READ_SUBMATRIX_WAIT;
                end
                
                READ_SUBMATRIX_WAIT: begin
                    // Store the read value in the input matrix
                    input_matrix[load_row][load_col] <= {8'h00, ram_data_read};
                    
                    // Move to next column
                    if (load_col == 9) begin
                        load_col <= 0;
                        // Move to next row
                        if (load_row == 9) begin
                            load_row <= 0;
                            state <= PROCESS_NPU;
                            npu_start <= 1;
                        end else begin
                            load_row <= load_row + 1;
                            state <= READ_SUBMATRIX;
                        end
                    end else begin
                        load_col <= load_col + 1;
                        state <= READ_SUBMATRIX;
                    end
                end
                
                PROCESS_NPU: begin
                    npu_start <= 0;
                    if (npu_done) begin
                        state <= WRITE_RESULT;
                        write_row <= 0;
                        write_col <= 0;
                    end
                end
                
                WRITE_RESULT: begin
                    // Calculate address in output area (160000 + offset)
                    ram_addr_write <= 160000 + (submatrix_y * 10 + write_row) * 400 + (submatrix_x * 10) + write_col;
                    ram_data_write <= output_matrix[write_row][write_col];
                    ram_wren <= 1;
                    
                    // Wait one cycle for RAM write
                    state <= WRITE_RESULT_WAIT;
                end
                
                WRITE_RESULT_WAIT: begin
                    ram_wren <= 0;
                    
                    // Move to next column
                    if (write_col == 9) begin
                        write_col <= 0;
                        // Move to next row
                        if (write_row == 9) begin
                            write_row <= 0;
                            // Move to next submatrix
                            if (submatrix_x == 39) begin
                                submatrix_x <= 0;
                                if (submatrix_y == 39) begin
                                    state <= FINISH;
                                end else begin
                                    submatrix_y <= submatrix_y + 1;
                                    state <= READ_SUBMATRIX;
                                end
                            end else begin
                                submatrix_x <= submatrix_x + 1;
                                state <= READ_SUBMATRIX;
                            end
                        end else begin
                            write_row <= write_row + 1;
                            state <= WRITE_RESULT;
                        end
                    end else begin
                        write_col <= write_col + 1;
                        state <= WRITE_RESULT;
                    end
                end
                
                FINISH: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule