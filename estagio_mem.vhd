library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
library work;
use work.tipos.all;
-- Especificação do estágio de ACESSO À MEMÓRIA - mem
-- Estágio com a memória de dados do circuito, 
-- sendo útil, apenas, para instruções que necessitam 
-- de acesso à memória.


entity estagio_mem is
    generic (
        dmem_init_file: string := "dmem.txt"          --Nome do arquivo conteúdo da memoria de programa
    );
    port (
        clock             : in  std_logic;-- Base de tempo vinda da bancada de teste
        --Entrada vindas de MEM
        bmem              : in std_logic_vector(104 downto 0); -- Buffer de saída do estágio EX para o estágio MEM

        keep_simulating   : in Boolean := True; -- Sinal que indica fim da simulação

        --Saída para WB
        bwb           : out std_logic_vector(103 downto 0); -- Buffer de saída do estágio MEM para o estágio WB
        reg_write_mem : out std_logic; -- Sinal de controle para permitir escrita no banco de registradores no estágio de Write Back
        rd            : out std_logic_vector(4 downto 0); -- Registrador destino da instrução
        alu_result    : out std_logic_vector(31 downto 0) -- Resultado da operação realizada na ULA para esta instrução
        );
end entity;