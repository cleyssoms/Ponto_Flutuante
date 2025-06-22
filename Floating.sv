module fpu(
    input  logic [31:0] op_A_in, 
    input  logic [31:0] op_B_in,
    input  logic clk, 
    input  logic reset, 
    output logic [31:0] data_out, 
    output logic [3:0]  status_out
);

    // Definição dos estados da máquina de controle
    typedef enum logic [3:0] { 
        PREPARACAO,         // Estado inicial: preparação dos operandos
        CALC_DIFERENCA,     // Cálculo da diferença entre expoentes
        ALINHAMENTO,        // Alinhamento das mantissas
        OPERACAO,           // Operação aritmética (soma/subtração)
        ANALISE_NORMALIZACAO, // Análise inicial para normalização
        NORMALIZACAO,       // Normalização da mantissa
        VERIFICA_ESTADO,    // Verificação do estado do expoente
        PRE_ARREDONDAMENTO, // Preparação para arredondamento
        ARREDONDAMENTO,     // Aplicação do arredondamento
        POS_ARREDONDAMENTO, // Verificação pós-arredondamento
        SAIDA_FINAL         // Geração da saída final
    } state_t;

    state_t current_state;  // Estado atual da máquina de controle

    // Sinais para manipulação de expoentes
    logic [7:0] expA, expB;      // Expoentes dos operandos
    logic [7:0] exp_result;      // Expoente do resultado
    logic [7:0] exp_dif;         // Diferença entre expoentes
    
    // Sinais para manipulação de mantissas
    logic [23:0] mant_result;    // Mantissa do resultado
    logic [25:0] mantA, mantB;   // Mantissas estendidas (24 bits + 2 guard bits)
    logic [25:0] mantA_shifted;  // Mantissa A após alinhamento
    logic [25:0] mantB_shifted;  // Mantissa B após alinhamento
    logic [26:0] mant_result_temp; // Resultado temporário da operação (27 bits)
    
    // Sinais de controle e status
    logic sinalA, sinalB;        // Sinais dos operandos
    logic sinal_result;          // Sinal do resultado
    logic bit_overflow;          // Flag de overflow
    logic bit_inexact;           // Flag de inexatidão (arredondamento)
    logic bit_underflow;         // Flag de underflow
    logic mantissa_zero_flag;    // Flag indicando resultado zero
    logic [7:0] counter;         // Contador para loops de normalização

    // Extração dos campos dos operandos (combinatorial)
    always_comb begin
        // Bit 31: sinal
        sinalA = op_A_in[31];
        sinalB = op_B_in[31];
        
        // Bits 30-23: expoente (8 bits)
        expA   = op_A_in[30:23];
        expB   = op_B_in[30:23];
        
        // Bits 22-0: mantissa (23 bits)
        // Tratamento de números desnormalizados:
        // - Se expoente = 0, número desnormalizado (bit implícito 0)
        // - Adiciona 2 bits de guarda para arredondamento
        mantA = (expA == 8'd0) ? {1'b0, op_A_in[22:0], 2'b00} : {1'b1, op_A_in[22:0], 2'b00};
        mantB = (expB == 8'd0) ? {1'b0, op_B_in[22:0], 2'b00} : {1'b1, op_B_in[22:0], 2'b00};
    end

    // Máquina de estados principal (sequencial)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            // Reset assíncrono: inicializa todos os registradores
            current_state     <= PREPARACAO;
            {bit_inexact, bit_overflow, bit_underflow} <= 3'b0;
            sinal_result      <= 1'b0;
            status_out        <= 4'b0;
            exp_dif           <= 8'b0;
            exp_result        <= 8'b0;
            mant_result       <= 24'b0;
            mantA_shifted     <= 26'b0;
            mantB_shifted     <= 26'b0;
            mant_result_temp  <= 27'b0;
            data_out          <= 32'b0;
            mantissa_zero_flag <= 1'b0;
            counter           <= 8'b0;
        end else begin
            case (current_state)
                // Estado 0: Preparação inicial
                PREPARACAO: begin
                    // Caso especial: ambos operandos zero
                    if (op_A_in == 32'd0 && op_B_in == 32'd0) begin
                        data_out     <= 32'd0;          // Resultado zero
                        status_out   <= 4'b0001;        // Status EXACT
                    end else begin 
                        // Reset das flags de status
                        bit_overflow  <= 1'b0;
                        bit_inexact   <= 1'b0;
                        bit_underflow <= 1'b0;
                        mantissa_zero_flag <= 1'b0;
                    end
                    current_state <= CALC_DIFERENCA;  // Próximo estado
                end

                // Estado 1: Cálculo da diferença entre expoentes
                CALC_DIFERENCA: begin
                    // Calcula a diferença absoluta entre expoentes
                    if (expA > expB) begin
                        exp_dif <= expA - expB;
                    end else if (expB > expA) begin
                        exp_dif <= expB - expA;
                    end else begin
                        exp_dif <= 8'd0;  // Expoentes iguais
                    end
                    current_state <= ALINHAMENTO;
                end

                // Estado 2: Alinhamento das mantissas
                ALINHAMENTO: begin
                    // Alinha a mantissa do número com menor expoente
                    if (expA > expB) begin
                        // Caso A tenha expoente maior
                        if (exp_dif > 8'd24) begin
                            // Diferença muito grande: mantissa B se torna zero
                            mantB_shifted <= 26'd0;
                            if (mantB != 0) bit_inexact <= 1'b1; // Perda de precisão
                        end else begin
                            // Desloca mantissa B para alinhar
                            mantB_shifted <= mantB >> exp_dif;
                            // Verifica bits perdidos no deslocamento
                            for (int i = 0; i < exp_dif; i++) begin
                                if (mantB[i]) bit_inexact <= 1'b1; // Bit perdido
                            end
                        end
                        mantA_shifted <= mantA;
                        exp_result    <= expA;  // Expoente resultante é o maior
                    end else if (expB > expA) begin
                        // Caso B tenha expoente maior (simétrico)
                        if (exp_dif > 8'd24) begin
                            mantA_shifted <= 26'd0;
                            if (mantA != 0) bit_inexact <= 1'b1;
                        end else begin
                            mantA_shifted <= mantA >> exp_dif;
                            for (int i = 0; i < exp_dif; i++) begin
                                if (mantA[i]) bit_inexact <= 1'b1;
                            end
                        end
                        mantB_shifted <= mantB;
                        exp_result    <= expB;
                    end else begin
                        // Expoentes iguais: mantissas não precisam de alinhamento
                        mantA_shifted <= mantA;
                        mantB_shifted <= mantB;
                        exp_result    <= expA;
                    end
                    current_state <= OPERACAO;
                end

                // Estado 3: Operação aritmética
                OPERACAO: begin
                    // Soma ou subtração dependendo dos sinais
                    if (sinalA == sinalB) begin
                        // Mesmo sinal: soma as mantissas
                        mant_result_temp <= {1'b0, mantA_shifted} + {1'b0, mantB_shifted};
                        sinal_result     <= sinalA;  // Sinal mantido
                    end else begin
                        // Sinais diferentes: subtração
                        if (mantA_shifted >= mantB_shifted) begin
                            mant_result_temp <= {1'b0, mantA_shifted} - {1'b0, mantB_shifted};
                            sinal_result     <= sinalA;
                        end else begin
                            mant_result_temp <= {1'b0, mantB_shifted} - {1'b0, mantA_shifted};
                            sinal_result     <= sinalB;
                        end
                    end
                    current_state <= ANALISE_NORMALIZACAO;
                end

                // Estado 4: Análise inicial para normalização
                ANALISE_NORMALIZACAO: begin
                    // Verifica casos especiais antes da normalização
                    if (mant_result_temp == 27'd0) begin
                        mantissa_zero_flag <= 1'b1;  // Resultado zero
                        current_state <= SAIDA_FINAL;
                    end else if (exp_result >= 8'd255) begin
                        bit_overflow <= 1'b1;         // Overflow de expoente
                        current_state <= SAIDA_FINAL;
                    end else begin
                        counter <= 8'd0;              // Inicializa contador
                        current_state <= NORMALIZACAO; // Inicia normalização
                    end
                end

                // Estado 5: Normalização da mantissa
                NORMALIZACAO: begin
                    // Normaliza o resultado para forma 1.xxxx
                    if (mant_result_temp[26]) begin
                        // Overflow: desloca para direita, incrementa expoente
                        mant_result_temp <= mant_result_temp >> 1;
                        exp_result <= exp_result + 1;
                    end else if (!mant_result_temp[25]) begin
                        // Precisão insuficiente: desloca para esquerda
                        if (exp_result == 8'd0) begin
                            // Underflow: expoente mínimo alcançado
                            bit_underflow <= 1'b1;
                            current_state <= SAIDA_FINAL;
                        end else begin
                            // Desloca mantissa, decrementa expoente
                            mant_result_temp <= mant_result_temp << 1;
                            exp_result <= exp_result - 1;
                            counter <= counter + 1;  // Incrementa contador
                            
                            // Prevenção contra loop infinito
                            if (counter > 8'd24) begin
                                bit_underflow <= 1'b1;
                                current_state <= SAIDA_FINAL;
                            end
                        end
                    end else begin
                        // Mantissa normalizada: prossegue
                        current_state <= VERIFICA_ESTADO;
                    end
                end

                // Estado 6: Verificação do estado do expoente
                VERIFICA_ESTADO: begin
                    // Verifica se após normalização temos underflow
                    if (exp_result == 8'd0) begin
                        bit_underflow <= 1'b1;
                        current_state <= SAIDA_FINAL;
                    end else begin
                        // Extrai mantissa (desconsidera bits de guarda)
                        mant_result <= mant_result_temp[25:2];
                        current_state <= PRE_ARREDONDAMENTO;
                    end
                end

                // Estado 7: Preparação para arredondamento
                PRE_ARREDONDAMENTO: begin
                    // Estado de transição para arredondamento
                    current_state <= ARREDONDAMENTO;
                end

                // Estado 8: Aplicação do arredondamento
                ARREDONDAMENTO: begin
                    // Arredonda para o mais próximo
                    // Verifica bits menos significativos (guard bits)
                    if (mant_result_temp[0] && |mant_result_temp[1:0]) begin
                        bit_inexact <= 1'b1;  // Resultado inexato
                        if (mant_result == 24'hFFFFFF) begin
                            // Overflow na mantissa: ajusta expoente
                            mant_result <= 24'h800000; // Reinicia mantissa
                            exp_result <= exp_result + 1; // Incrementa expoente
                        end else begin
                            mant_result <= mant_result + 1; // Incrementa mantissa
                        end
                    end
                    current_state <= POS_ARREDONDAMENTO;
                end

                // Estado 9: Verificação pós-arredondamento
                POS_ARREDONDAMENTO: begin
                    // Verifica overflow após arredondamento
                    if (exp_result >= 8'd255) begin
                        bit_overflow <= 1'b1;
                    end
                    current_state <= SAIDA_FINAL;
                end

                // Estado 10: Geração da saída final
                SAIDA_FINAL: begin
                    // Formata o resultado final e status
                    if (bit_overflow) begin
                        // Overflow: retorna infinito
                        data_out   <= {sinal_result, 8'hFF, 23'd0};
                        status_out <= 4'b0100; // OVERFLOW
                    end else if (bit_underflow || mantissa_zero_flag) begin
                        // Underflow ou resultado zero
                        data_out   <= 32'd0;  // Retorna zero
                        status_out <= (mantissa_zero_flag && !bit_underflow) ? 
                                      4'b0001 : // EXACT (zero exato)
                                      4'b1000;  // UNDERFLOW
                    end else begin 
                        // Resultado normalizado
                        // Monta formato IEEE 754: sinal + expoente + mantissa (23 bits)
                        data_out <= {sinal_result, exp_result, mant_result[22:0]};
                        status_out <= bit_inexact ? 
                                      4'b0010 : // INEXACT 
                                      4'b0001;  // EXACT
                    end
                    current_state <= PREPARACAO;  // Reinicia ciclo
                end

                default: current_state <= PREPARACAO; // Estado padrão
            endcase
        end
    end
endmodule