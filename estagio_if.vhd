library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
library work;
use work.tipos.all;
-- Especificação do estágio de BUSCA - if
-- Estágio de Busca de Instruções - if: neste estágio se encontra o PC(PC_if) (Contador de Programa)
-- o Registrador de Instruções ri_if, o registrador  NPC (NPC_if = PC incrementado de 4), a memória Cache de instruções -
-- imem e um conjunto de informações passadas ao estágio de decodificação-id.
-- Essas informações são passadas por um sinal chamado BID (Buffer para o estágio id). Este buffer é de saída do estágio_if
-- e de entrada no estágio_id.

entity estagio_if is
    generic (
        imem_init_file: string := "imem.txt"          --Nome do arquivo conteúdo da memoria de programa
    );
    port (   
        clock             : in  std_logic;-- Base de tempo vinda da bancada de teste
        --Entradas vindas do ID
        jump_pc           : in  std_logic_vector(31 downto 0) := x"00000000"; -- endereço do desvio
        pc_src            : in  std_logic_vector(1 downto 0); -- chave seletora do MUX de entrada do PC
        pc_write          : in  std_logic; -- habilita atualização do PC
        if_id_write       : in  std_logic; -- habilita a escrita no buffer entre IF e ID
        hd_hazard_flush   : in  std_logic; -- carrega zeros na parte do RI do BID
        branch_nop        : in  std_logic; -- determina a inserção de NOP, desvio ou pulo

        keep_simulating   : in Boolean := True; -- Sinal que indica fim da simulação
    -- Saída para o ID
        BID               : out std_logic_vector(95 downto 0) := x"000000000000000000000000"
        );
end entity;