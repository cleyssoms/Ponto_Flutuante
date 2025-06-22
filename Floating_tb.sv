`timescale 1ns/1ns

module Floating_tb();
    logic clk;
    logic reset;
    logic [31:0] op_A_in, op_B_in;
    logic [31:0] data_out;
    logic [3:0] status_out;
    
    // Instância da FPU
    fpu dut (
        .op_A_in(op_A_in),
        .op_B_in(op_B_in),
        .clk(clk),
        .reset(reset),
        .data_out(data_out),
        .status_out(status_out)
    );
    
    // Gerador de clock (100 KHz)
    always #5000 clk = ~clk;  // Período de 10 μs (5 ns semiperíodo)
    
    // Casos de teste
    initial begin
        // Inicializações
        clk = 0;
        reset = 0;
        op_A_in = 0;
        op_B_in = 0;
        
        // Reset
        #10 reset = 0;
        #100 reset = 1;
        
        // Header da tabela
        $display("-------------------------------------------------------------");
        $display("Teste | Operando A      | Operando B      | Resultado       | Status");
        $display("-------------------------------------------------------------");
        
        // Caso 1: 1.0 + 2.0 = 3.0
        op_A_in = 32'h3F800000; // 1.0
        op_B_in = 32'h40000000; // 2.0
        #200000; // Aguarda processamento (20 ciclos)
        $display("1     | %h | %h | %h | %b", op_A_in, op_B_in, data_out, status_out);
        
        // Caso 2: 0.0 + 0.0 = 0.0
        op_A_in = 32'h00000000;
        op_B_in = 32'h00000000;
        #200000;
        $display("2     | %h | %h | %h | %b", op_A_in, op_B_in, data_out, status_out);
        
        // Caso 3: 5.0 - 3.0 = 2.0
        op_A_in = 32'h40A00000; // 5.0
        op_B_in = 32'hC0400000; // -3.0
        #200000;
        $display("3     | %h | %h | %h | %b", op_A_in, op_B_in, data_out, status_out);
        
        // Caso 4: Overflow
        op_A_in = 32'h7F7FFFFF; // Max float
        op_B_in = 32'h7F7FFFFF;
        #200000;
        $display("4     | %h | %h | %h | %b", op_A_in, op_B_in, data_out, status_out);
        
        // Caso 5: Underflow
        op_A_in = 32'h00000001; // Menor denormal
        op_B_in = 32'h00000001;
        #200000;
        $display("5     | %h | %h | %h | %b", op_A_in, op_B_in, data_out, status_out);
        
        // Caso 6: Arredondamento
        op_A_in = 32'h3F800000; // 1.0
        op_B_in = 32'h322BCC77; // ~1e-8
        #200000;
        $display("6     | %h | %h | %h | %b", op_A_in, op_B_in, data_out, status_out);
        
        // Caso 7: Soma negativa
        op_A_in = 32'hC0200000; // -2.5
        op_B_in = 32'hBFC00000; // -1.5
        #200000;
        $display("7     | %h | %h | %h | %b", op_A_in, op_B_in, data_out, status_out);
        
        // Caso 8: Subtração
        op_A_in = 32'h3FC00000; // 1.5
        op_B_in = 32'hBF800000; // -1.0
        #200000;
        $display("8     | %h | %h | %h | %b", op_A_in, op_B_in, data_out, status_out);
        
        // Caso 9: Desnormalizados
        op_A_in = 32'h00000001; 
        op_B_in = 32'h00000001;
        #200000;
        $display("9     | %h | %h | %h | %b", op_A_in, op_B_in, data_out, status_out);
        
        // Caso 10: 0.5 + 0.5 = 1.0
        op_A_in = 32'h3F000000; // 0.5
        op_B_in = 32'h3F000000; // 0.5
        #200000;
        $display("10    | %h | %h | %h | %b", op_A_in, op_B_in, data_out, status_out);
        
        // Finalização
        $display("-------------------------------------------------------------");
        #100 $finish;
    end
endmodule