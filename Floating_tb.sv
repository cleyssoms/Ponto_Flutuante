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

// Tarefa para converter float para inteiro
function automatic real float_to_real(input logic [31:0] float_val);
    logic sign;
    logic [7:0] exponent;
    logic [22:0] mantissa;
    real value;
    
    sign = float_val[31];
    exponent = float_val[30:23];
    mantissa = float_val[22:0];
    
    if (exponent == 8'hFF) begin
        if (mantissa == 0) begin
            return sign ? -$itor(1.0/0.0) : $itor(1.0/0.0); // Infinito
        end else begin
            return $itor(0.0/0.0); // NaN
        end
    end else if (exponent == 0) begin
        value = $bitstoreal({sign, 8'b0, mantissa}) * 2.0**-126;
    end else begin
        value = $bitstoreal({sign, exponent, mantissa});
    end
    return value;
endfunction

// Tarefa para imprimir resultado
task print_result(input real a, input real b, input string op);
    real expected, result_val;
    string status_str;
    
    // Aguardar estabilização
    @(posedge clk);
    @(negedge clk);
    
    // Converter resultado para real
    result_val = float_to_real(data_out);
    
    // Determinar operação esperada
    if (op == "add") expected = a + b;
    else if (op == "sub") expected = a - b;
    else expected = 0;
    
    // Decodificar status
    case (1'b1)
        status_out[0]: status_str = "INEXACT";
        status_out[1]: status_str = "UNDERFLOW";
        status_out[2]: status_str = "OVERFLOW";
        status_out[3]: status_str = "EXACT";
        default: status_str = "UNKNOWN";
    endcase
    
    // Imprimir resultados
    $display("A = %e (0x%h)  B = %e (0x%h)", a, Op_A_in, b, Op_B_in);
    $display("Operação: %s  Resultado: %e (0x%h)", op, result_val, data_out);
    $display("Status: %s (0b%b)  Esperado: %e", status_str, status_out, expected);
    $display("----------------------------------------------------------------");
endtask

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
    print_result(1.0, 2.0, "add");
    
    // Teste 2: Subtração simples (5.0 - 3.0 = 2.0)
    Op_A_in = 32'h40a00000; // 5.0
    Op_B_in = 32'h40400000; // 3.0
    print_result(5.0, 3.0, "sub");
    
    // Teste 3: Adição com números negativos (-1.5 + -2.5 = -4.0)
    Op_A_in = 32'hbfc00000; // -1.5
    Op_B_in = 32'hc0200000; // -2.5
    print_result(-1.5, -2.5, "add");
    
    // Teste 4: Subtração com números negativos (-3.0 - (-1.5) = -1.5)
    Op_A_in = 32'hc0400000; // -3.0
    Op_B_in = 32'hbfc00000; // -1.5
    print_result(-3.0, -1.5, "sub");
    
    // Teste 5: Overflow (1e30 * 1e30 = infinito)
    Op_A_in = 32'h7e000000; // ~1e30
    Op_B_in = 32'h7e000000; // ~1e30
    print_result(1e30, 1e30, "add");
    
    // Teste 6: Underflow (1e-30 * 1e-30 = 0)
    Op_A_in = 32'h00000001; // ~1e-45
    Op_B_in = 32'h00000001; // ~1e-45
    print_result(1e-45, 1e-45, "add");
    
    // Teste 7: Resultado exato (0.5 + 0.25 = 0.75)
    Op_A_in = 32'h3f000000; // 0.5
    Op_B_in = 32'h3e800000; // 0.25
    print_result(0.5, 0.25, "add");
    
    // Teste 8: Arredondamento (1.0 + 2^-24 = 1.000000119)
    Op_A_in = 32'h3f800000; // 1.0
    Op_B_in = 32'h33000000; // 2^-24 ≈ 5.96e-8
    print_result(1.0, 5.96e-8, "add");
    
    // Teste 9: Subtração igual (3.0 - 3.0 = 0.0)
    Op_A_in = 32'h40400000; // 3.0
    Op_B_in = 32'h40400000; // 3.0
    print_result(3.0, 3.0, "sub");
    
    // Teste 10: Adição de valores com expoentes diferentes (1e10 + 1 = 1e10)
    Op_A_in = 32'h501502f9; // 1e10
    Op_B_in = 32'h3f800000; // 1.0
    print_result(1e10, 1.0, "add");
    
    $display("================ FIM DOS TESTES ================");
    $finish;
end

endmodule