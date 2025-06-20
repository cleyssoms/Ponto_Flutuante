`timescale 1ns / 1ps

module fpu_tb;

// Parâmetros de simulação
localparam CLK_PERIOD = 10; // 10 ns = 100 KHz

// Sinais de teste
logic clk;
logic rst_n;
logic [31:0] Op_A_in;
logic [31:0] Op_B_in;
logic [31:0] data_out;
logic [3:0] status_out;

// Instância da FPU
fpu dut (
    .clk(clk),
    .rst_n(rst_n),
    .Op_A_in(Op_A_in),
    .Op_B_in(Op_B_in),
    .data_out(data_out),
    .status_out(status_out)
);

// Gerador de clock
initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Procedimento principal de teste
initial begin
    // Inicializar e resetar
    rst_n = 1'b0;
    Op_A_in = 0;
    Op_B_in = 0;
    #(CLK_PERIOD*2);
    rst_n = 1'b1;
    #(CLK_PERIOD);
    
    $display("===================== TESTE FPU =====================");
    
    // Teste 1: Adição simples (1.0 + 2.0 = 3.0)
    Op_A_in = 32'h3f800000; // 1.0
    Op_B_in = 32'h40000000; // 2.0
    
    // Teste 2: Subtração simples (5.0 - 3.0 = 2.0)
    Op_A_in = 32'h40a00000; // 5.0
    Op_B_in = 32'h40400000; // 3.0
    
    // Teste 3: Adição com números negativos (-1.5 + -2.5 = -4.0)
    Op_A_in = 32'hbfc00000; // -1.5
    Op_B_in = 32'hc0200000; // -2.5
    
    // Teste 4: Subtração com números negativos (-3.0 - (-1.5) = -1.5)
    Op_A_in = 32'hc0400000; // -3.0
    Op_B_in = 32'hbfc00000; // -1.5
    
    // Teste 5: Overflow (1e30 * 1e30 = infinito)
    Op_A_in = 32'h7e000000; // ~1e30
    Op_B_in = 32'h7e000000; // ~1e30
    
    // Teste 6: Underflow (1e-30 * 1e-30 = 0)
    Op_A_in = 32'h00000001; // ~1e-45
    Op_B_in = 32'h00000001; // ~1e-45
    
    // Teste 7: Resultado exato (0.5 + 0.25 = 0.75)
    Op_A_in = 32'h3f000000; // 0.5
    Op_B_in = 32'h3e800000; // 0.25
    
    // Teste 8: Arredondamento (1.0 + 2^-24 = 1.000000119)
    Op_A_in = 32'h3f800000; // 1.0
    Op_B_in = 32'h33000000; // 2^-24 ≈ 5.96e-8
    
    // Teste 9: Subtração igual (3.0 - 3.0 = 0.0)
    Op_A_in = 32'h40400000; // 3.0
    Op_B_in = 32'h40400000; // 3.0
    
    // Teste 10: Adição de valores com expoentes diferentes (1e10 + 1 = 1e10)
    Op_A_in = 32'h501502f9; // 1e10
    Op_B_in = 32'h3f800000; // 1.0
    
    $display("================ FIM DOS TESTES ================");
    $stop;
end

endmodule