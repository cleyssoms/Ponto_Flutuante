

# Implementação Unidade de Ponto Flutuante (FPU)


## 🧮 Cálculo de X e Y

Matrícula: 23111400-0

Somatório dos dígitos: 2 + 3 + 1 + 1 + 1 + 4 + 0 + 0 + 0 = 12

Mod: 12 % 4 = 0

X = 8 - 0 = 8 bits de expoente

Y = 31 – 8 = 23 bits (mantissa)


## 📌 Objetivo

Desenvolver e testar uma Unidade de Ponto Flutuante (FPU) capaz de realizar a soma e subtração de números no formato IEEE 754 de 32 bits, implementando todas as etapas do processamento: desde a preparação dos operandos até o arredondamento e verificação de status como overflow, underflow e inexatidão.

---

## ⚙️ Estrutura do Módulo `fpu`

### 🧠 Estados da Máquina de Controle

A máquina de estados da FPU percorre os seguintes estágios:

| Estado                 | Descrição                                                              |
| ---------------------- | ---------------------------------------------------------------------- |
| `PREPARACAO`           | Extrai sinais, expoentes e mantissas. Lida com casos triviais de zero. |
| `CALC_DIFERENCA`       | Calcula a diferença entre os expoentes.                                |
| `ALINHAMENTO`          | Alinha a mantissa do operando com menor expoente.                      |
| `OPERACAO`             | Realiza a soma ou subtração das mantissas.                             |
| `ANALISE_NORMALIZACAO` | Verifica se o resultado é zero ou overflow.                            |
| `NORMALIZACAO`         | Ajusta o número resultante para a forma normalizada 1.xxxxx.           |
| `VERIFICA_ESTADO`      | Valida o expoente final após normalização.                             |
| `PRE_ARREDONDAMENTO`   | Transição para o arredondamento.                                       |
| `ARREDONDAMENTO`       | Aplica arredondamento para o mais próximo, se necessário.              |
| `POS_ARREDONDAMENTO`   | Verifica se houve overflow após arredondamento.                        |
| `SAIDA_FINAL`          | Formata e entrega o resultado final e status.                          |

### 🧮 Campos IEEE 754

* **Sinal (bit 31):** 0 (positivo), 1 (negativo)
* **Expoente (bits 30–23):** Excesso-127 (biased)
* **Mantissa (bits 22–0):** 23 bits + 1 implícito para números normalizados
* **Mantissas internas:** ampliadas para 26 bits com 2 bits de guarda

---

## 🧪 Casos de Teste (`Floating_tb`)

O testbench simula operações diversas, exibindo os resultados e status:

 -------------------------------------------------------------
 Teste | Operando A      | Operando B      | Resultado       | Status
 ------|-----------------|-----------------|-----------------|----
 1     | 3f800000 | 40000000 | 40400000 | 0001
 2     | 00000000 | 00000000 | 00000000 | 0001
 3     | 40a00000 | c0400000 | 40000000 | 0001
 4     | 7f7fffff | 7f7fffff | 7f800000 | 0100
 5     | 00000001 | 00000001 | 00000000 | 1000
 6     | 3f800000 | 322bcc77 | 3f800000 | 0010
 7     | c0200000 | bfc00000 | c0800000 | 0001
 8     | 3fc00000 | bf800000 | 3f000000 | 0001
 9     | 00000001 | 00000001 | 00000000 | 1000
---

![image](https://github.com/user-attachments/assets/ab841319-11ed-4cfe-a6b3-46ad732ffd8b)

Para executar a simulação inicie o Questa ou ModelSim e entre na pasta 'sim', depois execute o comando `do sim.do` no terminal

## 🧾 Códigos de `status_out`

* `0001` – Resultado exato (`EXACT`)
* `0010` – Resultado inexato devido a arredondamento (`INEXACT`)
* `0100` – Overflow: resultado não representável, retorna infinito (`OVERFLOW`)
* `1000` – Underflow: valor muito pequeno, tratado como zero (`UNDERFLOW`)

---

## 🔢 Faixa de Representação IEEE 754 (32 bits)

* **Menor valor positivo:**
  `+1.17549435 × 10^(-38)`
  Representação: `0 00000001 000...0`

* **Maior valor positivo:**
  `+3.40282347 × 10^(38)`
  Representação: `0 11111110 111...1`

(Falta imagem do espectro de representação, será adiconado em breve)
