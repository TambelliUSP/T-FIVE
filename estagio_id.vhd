library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
library work;
use work.tipos.all;
-- Especificação do estágio de DECODIFICAÇÃO E LEITURA - id
-- Estágio que contém a Unidade de Controle, Banco de Registradores, 
-- Unidade de detecção de conflitos (Hazard Unit), cuja função é decodificar a 
-- instrução vinda do estágio ID e, a partir disso, resgatar os valores corretos
-- do Banco de Registradores, repassar parte da instrução para a Unidade de 
-- Controle gerar os sinais corretos a serem usados no restante do circuito e 
-- detectar possíveis conflitos de dado. Ademais, a principal diferença quando 
-- comparado ao livro texto é que os saltos, incondicionais e condicionais, 
-- devem ser realizados neste estágio para o T-Five-Pipe.


entity estagio_id is
    port (
        clock             : in  std_logic;-- Base de tempo vinda da bancada de teste
        --Entradas vindas de IF
        BID               : in std_logic_vector(95 downto 0) := x"000000000000000000000000";
        --Entradas vindas de EX
        rd_ex             : in std_logic_vector(4 downto 0); -- Registrador destino da instrução, sendo usado para a lógica da hazard unit
        result_src_ex     : in std_logic_vector(1 downto 0); -- Chave do MUX para selecionar qual dado será escrito no banco de registradores (AluResult, ReadData ou PcPlus4);
        --Entradas vindas de WB
        rd_wb             : in std_logic_vector(4 downto 0); -- Registrador destino, onde será escrito o resultado
        reg_write         : in std_logic; -- Sinal de controle para permitir escrita no banco de registradores
        result            : in std_logic_vector(31 downto 0); -- Resultado da operação designada pela instrução, a ser escrito no banco de registradores
        
        keep_simulating   : in Boolean := True; -- Sinal que indica fim da simulação

        --Saídas para IF
        pc_src            : out  std_logic_vector(1 downto 0); -- chave seletora do MUX de entrada do PC
        pc_write          : out  std_logic; -- habilita atualização do PC
        if_id_write       : out  std_logic; -- habilita a escrita no buffer entre IF e ID
        hd_hazard_flush   : out  std_logic; -- carrega zeros na parte do RI do BID
        branch_nop        : out  std_logic; -- vem da UC, pra inserir NOP quando há desvio
        jump_pc           : out  std_logic_vector(31 downto 0) := x"00000000"; -- endereço do desvio
        --Saidas para EX
        ex_flush          : out  std_logic; -- vem da UC para esvaziar o estado de execução, no caso de exceções acontecerem
        bex               : out  std_logic_vector(183 downto 0) -- Buffer de saída do estágio de ID para o estágio de EX
        );
end entity;