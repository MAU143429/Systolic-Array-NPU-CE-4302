module ram_top_module (
    input  logic        clk,          // 50 MHz clock
    input  logic        rst,          // Reset signal
    input  logic        start,        // Start button (continuous processing)
    input  logic        step,         // Step button (process one submatrix)
    input  logic        enter,        // Switch to select image source
    output logic        done,         // Processing complete
    output logic        clk_25,       // 25 MHz clock
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

    logic [17:0] rom_addr_npu;
    logic [17:0] pixel_address_rom;
    logic [7:0]  rom_data_npu;
    logic [7:0]  rom_data_vga;

    logic [18:0] ram_addr_write;
    logic [18:0] pixel_address_ram;
    logic [7:0]  ram_data_write;
    logic [7:0]  ram_data_read;
    logic        ram_wren;

    typedef enum {
        IDLE, READ_SUBMATRIX, WAIT_ROM_DATA, STORE_DATA,
        WRITE_RESULT, NEXT_SUBMATRIX, FINISH, WAIT_STEP
    } state_t;
    state_t state;

    logic [5:0] submatrix_x, submatrix_y;
    logic [3:0] load_row, load_col;
    logic [3:0] write_row, write_col;

    logic [7:0] input_matrix[9:0][9:0];

    // Debouncing and edge detection omitted for brevity

    rom image_rom (
        .address_a(rom_addr_npu),
        .address_b(pixel_address_rom),
        .clock(clk),
        .q_a(rom_data_npu),
        .q_b(rom_data_vga)
    );

    ram image_ram (
        .address_a(ram_addr_write),
        .address_b(pixel_address_ram),
        .clock(clk),
        .data_a(ram_data_write),
        .data_b(8'h00),
        .wren_a(ram_wren),
        .wren_b(1'b0),
        .q_a(),
        .q_b(ram_data_read)
    );

    vga vga_controller (
        .clk(clk),
        .enter(enter),
        .clk_25(clk_25),
        .pixel_address_rom(pixel_address_rom),
        .pixel_data_rom(rom_data_vga),
        .pixel_address_ram(pixel_address_ram),
        .pixel_data_ram(ram_data_read),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .sync_blank(sync_blank),
        .sync_b(sync_b),
        .red(red),
        .green(green),
        .blue(blue)
    );

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
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    state <= READ_SUBMATRIX;
                end

                READ_SUBMATRIX: begin
                    rom_addr_npu <= (submatrix_y * 10 + load_row) * 400 + (submatrix_x * 10 + load_col);
                    state <= WAIT_ROM_DATA;
                end

                WAIT_ROM_DATA: begin
                    state <= STORE_DATA;
                end

                STORE_DATA: begin
                    input_matrix[load_row][load_col] <= rom_data_npu;
                    if (load_col == 9) begin
                        load_col <= 0;
                        if (load_row == 9) begin
                            load_row <= 0;
                            state <= WRITE_RESULT;
                        end else begin
                            load_row <= load_row + 1;
                            state <= READ_SUBMATRIX;
                        end
                    end else begin
                        load_col <= load_col + 1;
                        state <= READ_SUBMATRIX;
                    end
                end

                WRITE_RESULT: begin
                    ram_addr_write <= (submatrix_y * 10 + write_row) * 400 + (submatrix_x * 10 + write_col);
                    ram_data_write <= input_matrix[write_row][write_col];
                    ram_wren <= 1;
                    if (write_col == 9) begin
                        write_col <= 0;
                        if (write_row == 9) begin
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
                end

                FINISH: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
