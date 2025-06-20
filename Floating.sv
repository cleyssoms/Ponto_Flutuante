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
        
        // Tratar números desnormalizados (expoente zero) como zero
        // Adicionar bit implícito para números normalizados
        logic [23:0] mantissaA = (expA == 0) ? 24'b0 : {1'b1, fracA};
        logic [23:0] mantissaB = (expB == 0) ? 24'b0 : {1'b1, fracB};
    end
end
endmodule