------------------------------------------------------------------------------------------------------------
------------MODULO ESTAGIO WRITE-BACK-----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all; 
use std.env.stop;

library work;
use work.tipos.all;	

-- Especifica�ao do est�gio WRITE-BACK - wb: Declara�ao de entidade
-- Este est�gio  seleciona a informa�ao que deve ser gravada nos registradores, 
-- cuja grava�ao ser� executada no est�gio id
-- Os sinais de entrada e sa�da deste est�gio encontram-es definidos nos coment�rios 
-- da declara�ao de entidade estagio_wb.


entity estagio_wb_grupo_3 is
    port(
		-- Entradas
        BWB				: in std_logic_vector(103 downto 0); -- Informa�oes vindas do estagi mem
		COP_wb			: in instruction_type := NOP;		 -- Mnem�nico da instru�ao no estagio wb
		
		-- Sa�das
        writedata_wb	: out std_logic_vector(31 downto 0); -- Valor a ser escrito emregistradores
        rd_wb			: out std_logic_vector(04 downto 0); -- Endere�o do registrador a ser escrito
		RegWrite_wb		: out std_logic						 -- Sinal de escrita nos registradores
    );
end entity;

architecture behave of estagio_wb_grupo_3 is
    -- Alias para sinais atribuidos no BWB
    alias MemToReg_wb is BWB(103 downto 102);
    alias RegWrite_wb_bwb is BWB(101);
    alias NPC_wb is BWB(100 downto 069);
    alias ULA_wb is BWB(068 downto 037);
    alias Memval_wb is BWB(036 downto 005);
    alias rd_wb_bwb is BWB(004 downto 000);

    signal halt_detected: std_logic := '0';
begin
    writedata_wb <= ULA_wb when MemToReg_wb="00" else
                    Memval_wb when MemToReg_wb="01" else
                    NPC_wb when MemToReg_wb="10" else
                    x"00000000"; -- Erro
    
    RegWrite_wb <= RegWrite_wb_bwb;
    rd_wb <= rd_wb_bwb;

    halt_detected <=    '1' when COP_wb=HALT else
                        '0';

    HALT_DETECTED_PROC: process
    begin
        wait until halt_detected='1';
        stop;
    end process;
end architecture;