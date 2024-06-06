library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
library work;
use work.tipos.all;
-- Especificação do estágio de EXECUÇÃO - ex
-- Onde se tem a Unidade Lógico Aritmética (ULA) e 
-- a unidade de antecipação de valores (Forwarding Unit),
-- responsável por realizar as operações aritméticas do 
-- processador, tanto de instruções aritméticas, quanto 
-- de instruções Load/Store nas quais é preciso calcular 
-- o endereço efetivo, da memória, a ser operacionalizado, 
-- além de realizar os devidos encaminhamentos de dados 
-- para outros ciclos do pipeline.


entity estagio_ex is
    port (
        -- Entradas vindas de ID
        ex_flush          : in std_logic; -- vem da UC para esvaziar o estado de execução, no caso de exceções acontecerem
        bex               : in std_logic_vector(183 downto 0); -- Buffer de saída do estágio de ID para o estágio de EX
        -- Entradas vindas de MEM
        alu_result        : in std_logic_vector(31 downto 0); -- Resultado da operação realizada na ULA para esta instrução
        reg_write_mem     : in std_logic; -- Sinal de controle para permitir escrita no banco de registradores no estágio de Write Back
        rd_mem            : in std_logic_vector(4 downto 0); -- Registrador destino da instrução
        -- Entradas vindas WB
        reg_write_wb      : in std_logic; -- Sinal de controle para permitir escrita no banco de registradores no estágio de Write Back
        result            : in std_logic_vector(31 downto 0); -- Registrador destino da instrução
        rd_wb             : in std_logic_vector(4 downto 0); -- Saída do MUX presente no estágio de WB, a qual representa o dado a ser armazenado no banco de registradores pela instrução em questão

        keep_simulating   : in Boolean := True; -- Sinal que indica fim da simulação

    -- Saída
        bmem              : out std_logic_vector(104 downto 0); -- Buffer de saída do estágio EX para o estágio MEM
        rd_ex             : out std_logic_vector(4 downto 0); -- Registrador destino da instrução
        result_src_ex     : out std_logic_vector(1 downto 0) -- Chave do MUX para selecionar qual dado será escrito no banco de registradores (AluResult, ReadData ou PcPlus4);
        );
end entity;