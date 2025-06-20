module fpu (
    input logic clk,         // Clock de 100 KHz
    input logic rst_n,       // Reset assíncrono ativo baixo
    input logic [31:0] Op_A_in,
    input logic [31:0] Op_B_in,
    output logic [31:0] data_out,
    output logic [3:0] status_out // [EXACT, OVERFLOW, UNDERFLOW, INEXACT]
);

// Definições dos índices para status_out
localparam INEXACT  = 0;
localparam UNDERFLOW = 1;
localparam OVERFLOW  = 2;
localparam EXACT    = 3;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset: saídas zeradas
        data_out <= 0;
        status_out <= 0;
    end else begin
        // Extrair sinal, expoente e fração de cada operando
        logic signA, signB;
        logic [7:0] expA, expB;
        logic [22:0] fracA, fracB;
        signA = Op_A_in[31];
        expA = Op_A_in[30:23];
        fracA = Op_A_in[22:0];
        signB = Op_B_in[31];
        expB = Op_B_in[30:23];
        fracB = Op_B_in[22:0];
        
       // Determinar maior expoente e diferença entre expoentes
        logic [7:0] max_exp = (expA >= expB) ? expA : expB;
        logic [7:0] exp_diff = (expA >= expB) ? (expA - expB) : (expB - expA);
        
        // Alinhar mantissas com base na diferença de expoentes
        logic [23:0] aligned_A, aligned_B;
        logic sticky; // Indica perda de precisão durante deslocamento
        
        if (expA >= expB) begin
            aligned_A = mantissaA;
            // Deslocar mantissa menor e calcular sticky bit
            aligned_B = mantissaB >> exp_diff;
            sticky = (exp_diff > 0) ? |(mantissaB << (24 - exp_diff)) : 1'b0;
        end else begin
            aligned_A = mantissaA >> exp_diff;
            aligned_B = mantissaB;
            sticky = (exp_diff > 0) ? |(mantissaA << (24 - exp_diff)) : 1'b0;
        end

        logic [24:0] sum; // Resultado com bit extra para carry
        logic sign_res;
        logic [23:0] mantissa_res;
        logic [7:0] exp_res;
        
        if (signA == signB) begin
            // Adição para sinais iguais
            sum = {1'b0, aligned_A} + {1'b0, aligned_B};
            sign_res = signA;
            
            // Tratar carry (resultado maior que 24 bits)
            if (sum[24]) begin
                mantissa_res = sum[24:1]; // Desloca resultado
                exp_res = max_exp + 1;    // Ajusta expoente
                sticky |= sum[0];         // Atualiza sticky com bit perdido
            end else begin
                mantissa_res = sum[23:0];
                exp_res = max_exp;
            end
        end else begin
            // Subtração para sinais diferentes
            if (aligned_A >= aligned_B) begin
                sum = {1'b0, aligned_A} - {1'b0, aligned_B};
                sign_res = signA;
            end else begin
                sum = {1'b0, aligned_B} - {1'b0, aligned_A};
                sign_res = signB;
            end
            
            // Normalização: encontrar primeiro '1' significativo
            logic [4:0] leading_zeros = 0;
            for (int i = 23; i >= 0; i--) begin
                if (sum[i]) begin
                    leading_zeros = 23 - i; // Calcula zeros à esquerda
                    break;
                end
            end
            
            // Ajustar mantissa e expoente
            if (sum == 0) begin
                // Resultado zero
                mantissa_res = 0;
                exp_res = 0;
            end else begin
                mantissa_res = sum[23:0] << leading_zeros;
                exp_res = max_exp - leading_zeros;
            end
        end
        
    end
end
endmodule