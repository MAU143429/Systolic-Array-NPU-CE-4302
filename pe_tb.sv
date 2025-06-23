`timescale 1ns/1ps

module pe_tb;

    // Señales del DUT
    logic signed [15:0] iact_in;
    logic signed [15:0] psum_in;
    logic signed [15:0] weight;
    logic signed [15:0] iact_out;
    logic signed [15:0] psum_out;

    // Contador de test cases
    integer test_num = 0;

    // Instancia del módulo PE
    pe dut (
        .iact_in(iact_in),
        .psum_in(psum_in),
        .weight(weight),
        .iact_out(iact_out),
        .psum_out(psum_out)
    );

    // Función para mostrar resultados en formato tabular
    function void display_results(input string test_case);
        $display("------------------------------------------------------------");
        $display("Test Case %0d: %s", test_num, test_case);
        $display("------------------------------------------------------------");
        $display("| Inputs          | Outputs                  |");
        $display("| iact  | weight  | psum_in | psum_out |");
        $display("| %-6d| %-8d| %-8d| %-9d|", 
                iact_in, weight, psum_in, psum_out);
        $display("------------------------------------------------------------");
        $display("");
        test_num = test_num + 1;
    endfunction

    initial begin
        // Inicialización
        iact_in = 0;
        psum_in = 0;
        weight = 0;
            
        // Caso 1: peso positivo
        iact_in = 10; psum_in = 5; weight = 1; #10;
        display_results("Peso positivo (1)");
        
        // Caso 2: peso negativo
        iact_in = 20; psum_in = 30; weight = -1; #10;
        display_results("Peso negativo (-1)");
        
        // Caso 3: peso cero
        iact_in = 100; psum_in = 500; weight = 0; #10;
        display_results("Peso cero (0)");
        
        // Caso 4: activación negativa
        iact_in = -10; psum_in = 100; weight = -1; #10;
        display_results("Activación negativa (-10)");
        
        // Caso 5: propagación acumulativa
        iact_in = 3; psum_in = psum_out; weight = 1; #10;
        display_results("Propagación acumulativa");
        
        // Caso 6: valores grandes
        iact_in = 32767; psum_in = 0; weight = 1; #10;
        display_results("Valor máximo positivo (32767)");
        
        // Caso 7: valores límite negativos
        iact_in = -32768; psum_in = 0; weight = -1; #10;
        display_results("Valor mínimo negativo (-32768)");

        $finish;
    end

    // Generación de archivo VCD para visualización
    initial begin
        $dumpfile("pe_tb.vcd");
        $dumpvars(0, pe_tb);
    end

endmodule