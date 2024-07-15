library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
library work;
use work.tipos.all;
-- Especificação do estágio de ESCREVE DE VOLTA - wb
-- Responsável por armazenar no Banco de Registradores 
-- alguma informação, seja o resultado de operação, valor 
-- de endereço de retorno para instruções de desvio.


entity estagio_wb_grupo_3 is
    port (
        --Entradas
        bwb  : in std_logic_vector(103 downto 0); -- Buffer de saída do estágio MEM para o estágio WB

    -- Saída
        reg_write         : out  std_logic; -- Sinal de controle para permitir escrita no banco de registradores no estágio de Write Back
        rd                : out  std_logic_vector(4 downto 0); -- Registrador destino da instrução
        mux_result        : out  std_logic_vector(31 downto 0) -- Resultado da operação designada pela instrução, a ser escrito no banco de registradores
        );
end entity;