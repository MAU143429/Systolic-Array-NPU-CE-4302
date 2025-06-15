`timescale 1ns/1ps

module systolic_array_tb;

    logic clk;
    logic rst;
    logic start;
    logic signed [15:0] A[10][10];
    logic done;
    logic signed [15:0] A_result[0:9][0:9];
	 logic signed [15:0] weights_out[10][10];
    integer errores;

    // DUT
    systolic_array dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .done(done),
        .A_result(A_result),
		  .weights_out(weights_out)
    );

    // Clock de 10ns
    always #5 clk = ~clk;

    // Matriz esperada (copiada de tu imagen)
    typedef logic signed [15:0] fila_t [0:9];
    fila_t expected[0:9] = '{
        '{1500, 1890, 2320, 2790, 3300, 3150, 2960, 2730, 2460, 2150},
        '{1590, 1960, 2360, 2790, 3250, 3060, 2840, 2590, 2310, 2000},
        '{1620, 1960, 2320, 2700, 3100, 2880, 2640, 2380, 2100, 1800},
        '{1590, 1890, 2200, 2520, 2850, 2610, 2360, 2100, 1830, 1550},
        '{1500, 1750, 2000, 2250, 2500, 2250, 2000, 1750, 1500, 1250},
        '{ 750,  840,  920,  990, 1050, 1000,  900,  760,  630,  400},
        '{ -60, -140, -240, -360, -500, -560, -560, -540, -500, -400},
        '{-930, -1190, -1480, -1800, -2150, -2070, -1960, -1820, -1650, -1450},
        '{-1860, -2310, -2880, -3330, -3900, -3690, -3440, -3150, -2820, -2450},
        '{-2850, -3500, -4200, -4950, -5750, -5400, -5000, -4550, -4050, -3500}
    };

    initial begin
        $display("=== TESTBENCH SYSTOLIC ARRAY ===");
        clk = 0;
        rst = 1;
        start = 0;

        #10;
        rst = 0;
		  
		  // Mostrar matriz de pesos
			$display("\nMatriz de pesos (10x10):");
			for (int i = 0; i < 10; i++) begin
				 for (int j = 0; j < 10; j++) begin
					  $write("%6d ", weights_out[i][j]);
				 end
				 $write("\n");
			end


        // === Cargar matriz A (10x10)
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                A[i][j] = i * 10 + j * 10;
            end
        end

        // Mostrar matriz A
        $display("\nMatriz A (10x10):");
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                $write("%6d ", A[i][j]);
            end
            $write("\n");
        end

        // Iniciar
        #10; start = 1;
        #10; start = 0;

        // Esperar a done
        wait(done == 1);
        #50;

        // Mostrar salida ordenada
        $display("\nResultado A_result (10x10):");
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                $write("%6d ", A_result[i][j]);
            end
            $write("\n");
        end

        // Verificar contra matriz esperada
        $display("\nVerificación de resultados:");
        errores = 0;
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                if (A_result[i][j] !== expected[i][j]) begin
                    $display("  ERROR en [%0d][%0d]: esperado = %0d, obtenido = %0d",
                             i, j, expected[i][j], A_result[i][j]);
                    errores++;
                end
            end
        end

        if (errores == 0)
            $display("\n RESULTADO CORRECTO: Todos los valores coinciden.");
        else
            $display("\n RESULTADO INCORRECTO: Se detectaron %0d errores.", errores);

        #10;
        $finish;
    end

endmodule
