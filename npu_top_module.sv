module npu_top_module (
    input  logic        clk,          // 50 MHz clock
    input  logic        rst,          // Reset signal
    input  logic        start,        // Start button (continuous processing)
    input  logic        step,         // Step button (process one submatrix)
    input  logic        enter,        // Switch to select image source
    output logic        done,         // Processing complete
    output logic        clk_25,       // 25 MHz clock
    output logic [9:0]  leds,         // LED indicators for current submatrix
    output logic [7:0]  red,          // VGA red output
    output logic [7:0]  green,        // VGA green output
    output logic [7:0]  blue,         // VGA blue output
    output logic        vga_hsync,    // VGA horizontal sync
    output logic        vga_vsync,    // VGA vertical sync
    output logic        sync_blank,   // VGA blank signal
    output logic        sync_b        // VGA sync signal
);

    // Clock divider
    clkdiv clk_divider (
        .clk(clk),
        .clk_25(clk_25)
    );
    
    // Performance Counters
    logic [13:0] memory_access_control;
    logic [31:0] arithmetic_operation_control;

    // ROM signals (dual-port)
    logic [17:0] rom_addr_npu;      // Puerto A: Para leer submatrices (NPU)
    logic [17:0] pixel_address_rom; // Puerto B: Para VGA
    logic [7:0]  rom_data_npu;      // Datos para NPU
    logic [7:0]  rom_data_vga;      // Datos para VGA

    // RAM signals (processed image)
    logic [18:0] ram_addr_write;    // Dirección escritura
    logic [18:0] pixel_address_ram; // Dirección lectura (VGA)
    logic [7:0]  ram_data_write;    // Datos escritura
    logic [7:0]  ram_data_read;     // Datos lectura
    logic        ram_wren;          // Write enable

    // NPU signals
    logic npu_start;
    logic npu_done;
    logic signed [15:0] input_matrix[9:0][9:0];
    logic [7:0] output_matrix[9:0][9:0];

    // Control signals
    logic [5:0] submatrix_x;        // 0-39 (400/10)
    logic [5:0] submatrix_y;        // 0-39 (400/10)
    logic [3:0] load_row, load_col; // Current row/col within submatrix
    logic [3:0] write_row, write_col;
	 
	 

    // FSM states
    typedef enum {
        IDLE,
        READ_SUBMATRIX,
        STORE_DATA,
        PROCESS_NPU,
        WRITE_RESULT,
        NEXT_SUBMATRIX,
        FINISH,
        WAIT_STEP
    } state_t;
    state_t state;
	 
	 assign leds = state;

    // Debouncing signals
    logic start_db, step_db;
    logic [19:0] debounce_counter_start, debounce_counter_step;
    logic start_prev, step_prev;
    
    // Debouncer for start button (10ms debounce time at 50MHz clock)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            start_prev <= 0;
            debounce_counter_start <= 0;
            start_db <= 0;
        end else begin
            start_prev <= start;
            
            if (start != start_prev) begin
                debounce_counter_start <= 0;
            end else if (debounce_counter_start < 20'd500000) begin // 10ms at 50MHz
                debounce_counter_start <= debounce_counter_start + 1;
            end else begin
                start_db <= start_prev;
            end
        end
    end
    
    // Debouncer for step button (10ms debounce time at 50MHz clock)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            step_prev <= 0;
            debounce_counter_step <= 0;
            step_db <= 0;
        end else begin
            step_prev <= step;
            
            if (step != step_prev) begin
                debounce_counter_step <= 0;
            end else if (debounce_counter_step < 20'd500000) begin // 10ms at 50MHz
                debounce_counter_step <= debounce_counter_step + 1;
            end else begin
                step_db <= step_prev;
            end
        end
    end
    
    // Edge detection for buttons
    logic start_rising, step_rising;
    assign start_rising = ~start_prev & start_db; // Detect rising edge of debounced start
    assign step_rising = ~step_prev & step_db;    // Detect rising edge of debounced step

    // Processing mode (1 = continuous, 0 = step)
    logic processing_mode;
    
    // LED indicators for current submatrix
    assign led_x = submatrix_x[4:0];
    assign led_y = submatrix_y[4:0];

    // Instantiate ROM (original image) - Dual port
    rom image_rom (
        .address_a(rom_addr_npu),      // Puerto A: NPU
        .address_b(pixel_address_rom), // Puerto B: VGA
        .clock(clk),
        .q_a(rom_data_npu),           // Datos para NPU
        .q_b(rom_data_vga)            // Datos para VGA
    );

    // Instantiate RAM (processed image)
    ram image_ram (
        .address_a(ram_addr_write),
        .address_b(pixel_address_ram),
        .clock(clk),
        .data_a(ram_data_write),
        .data_b(8'h00),               // No usamos escritura en puerto B
        .wren_a(ram_wren),
        .wren_b(1'b0),
        .q_a(),                       // No usado
        .q_b(ram_data_read)
    );

    // Instantiate NPU
    npu image_npu (
        .clk(clk),
        .rst(rst),
        .start(npu_start),
        .input_matrix(input_matrix),
        .done(npu_done),
        .final_output(output_matrix)
    );

    // VGA controller
    vga vga_controller (
        .clk(clk),
        .enter(enter),                // Selects image source
        .clk_25(clk_25),
        .pixel_address_rom(pixel_address_rom), // Address for ROM (port B)
        .pixel_data_rom(rom_data_vga), // Data from ROM
        .pixel_address_ram(pixel_address_ram), // Address for RAM
        .pixel_data_ram(ram_data_read), // Data from RAM
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .sync_blank(sync_blank),
        .sync_b(sync_b),
        .red(red),
        .green(green),
        .blue(blue)
    );

    // FSM for image processing
    always_ff @(posedge clk or posedge rst) begin
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
            processing_mode <= 0;
            memory_access_control <= 0;
            arithmetic_operation_control <= 0;
            
            // Initialize input matrix
            for (int i = 0; i < 10; i++) begin
                for (int j = 0; j < 10; j++) begin
                    input_matrix[i][j] <= 0;
                end
            end
        end else begin
            case (state)
                IDLE: begin
                    if (start_rising) begin
                        // Continuous processing mode
                        state <= READ_SUBMATRIX;
                        submatrix_x <= 0;
                        submatrix_y <= 0;
                        load_row <= 0;
                        load_col <= 0;
                        done <= 0;
                        processing_mode <= 1;
                    end else if (step_rising) begin
                        // Step mode - process first submatrix
                        state <= READ_SUBMATRIX;
                        submatrix_x <= 0;
                        submatrix_y <= 0;
                        load_row <= 0;
                        load_col <= 0;
                        done <= 0;
                        processing_mode <= 0;
                    end
                end
                
                READ_SUBMATRIX: begin
                    // Calculate address for current pixel in 400x400 image
                    rom_addr_npu <= (submatrix_y * 10 + load_row) * 400 + (submatrix_x * 10 + load_col);
                    memory_access_control <= memory_access_control + 1;
                    state <= STORE_DATA;
                end
                
                STORE_DATA: begin
                    // Store pixel data in input matrix (convert to 16-bit signed)
                    input_matrix[load_row][load_col] <= {8'h00, rom_data_npu};
                    
                    // Move to next pixel in submatrix
                    if (load_col == 9) begin
                        load_col <= 0;
                        if (load_row == 9) begin
                            // Entire submatrix loaded
                            load_row <= 0;
                            state <= PROCESS_NPU;
                            npu_start <= 1;  // Start NPU processing
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
                    npu_start <= 0;  // Clear start signal after one cycle
                    arithmetic_operation_control <= arithmetic_operation_control + 2150; // Estimate max arithmetic operations 
                    if (npu_done) begin
                        // Processing complete, prepare to write results
                        write_row <= 0;
                        write_col <= 0;
                        state <= WRITE_RESULT;
                    end
                end
                
                WRITE_RESULT: begin
                    // Calculate address in RAM for current pixel
                    ram_addr_write <= (submatrix_y * 10 + write_row) * 400 + (submatrix_x * 10 + write_col);
                    ram_data_write <= output_matrix[write_row][write_col];
                    ram_wren <= 1;
                    memory_access_control <= memory_access_control + 1;
                    
                    // Move to next pixel in submatrix
                    if (write_col == 9) begin
                        write_col <= 0;
                        if (write_row == 9) begin
                            // Entire submatrix written
                            write_row <= 0;
                            ram_wren <= 0;
                            state <= NEXT_SUBMATRIX;
                        end else begin
                            write_row <= write_row + 1;
                        end
                    end else begin
                        write_col <= write_col + 1;
                    end
                end
                
                NEXT_SUBMATRIX: begin
                    // Move to next 10x10 submatrix
                    if (submatrix_x == 39) begin
                        submatrix_x <= 0;
                        if (submatrix_y == 39) begin
                            // Entire image processed
                            state <= FINISH;
                        end else begin
                            submatrix_y <= submatrix_y + 1;
                            if (processing_mode) begin
                                // Continuous mode - process next submatrix
                                state <= READ_SUBMATRIX;
                            end else begin
                                // Step mode - wait for next step
                                state <= WAIT_STEP;
                            end
                        end
                    end else begin
                        submatrix_x <= submatrix_x + 1;
                        if (processing_mode) begin
                            // Continuous mode - process next submatrix
                            state <= READ_SUBMATRIX;
                        end else begin
                            // Step mode - wait for next step
                            state <= WAIT_STEP;
                        end
                    end
                end
                
                WAIT_STEP: begin
                    ram_wren <= 0;
                    // Wait for step button press in step mode
                    if (step_rising && !processing_mode) begin
                        state <= READ_SUBMATRIX;
                    end
                    // Allow switching to continuous mode
                    if (start_rising) begin
                        processing_mode <= 1;
                        state <= READ_SUBMATRIX;
                    end
                end
                
                FINISH: begin
                    done <= 1;
                    processing_mode <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule