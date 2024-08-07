library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use std.env.stop;
library work;
use work.tipos.all;
-- Especificação do estágio de BUSCA - if
-- Estágio de Busca de Instruções - if: neste estágio se encontra o PC(PC_if) (Contador de Programa)
-- o Registrador de Instruções ri_if, o registrador  NPC (NPC_if = PC incrementado de 4), a memória Cache de instruções -
-- imem e um conjunto de informações passadas ao estágio de decodificação-id.
-- Essas informações são passadas por um sinal chamado BID (Buffer para o estágio id). Este buffer é de saída do estágio_if
-- e de entrada no estágio_id.

entity estagio_if_grupo_3 is
    generic(
        imem_init_file: string := "imem.txt" --Nome do arquivo com o conteúdo da memória de programa
    );
    port(
        --Entradas
        clock : in std_logic; -- Base de tempo vinda da bancada de teste
        id_hd_hazard : in std_logic; -- Sinal de controle que carrega 0's na parte do RI do registrador de saída BID

        id_Branch_nop: in std_logic; -- Sinal que determina inserção de NOP- desvio ou pulo
        id_PC_Src : in std_logic; -- Seleção do mux da entrada do PC
        id_Jump_PC : in std_logic_vector(31 downto 0) := x"00000000";-- Endereço do Jump ou desvio realizado

        keep_simulating : in Boolean := True; -- Sinal que indica a continuação da simulação
        -- Saída
        BID : out std_logic_vector(63 downto 0) := x"0000000000000000" -- Reg. de saída if para id
    );
end entity;

architecture behave of estagio_if_grupo_3 is
    component ram is
        generic(
            address_bits	: integer 	:= 32;		 
            size			: integer 	:= 4096;	
            ram_init_file	: string 	:= "imem.txt" 
        );
        port (
            -- Entradas
            clock 	: in  std_logic;								
            write 	: in  std_logic;								
            address : in  std_logic_vector(address_bits-1 downto 0);
            data_in : in  std_logic_vector(address_bits-1 downto 0);
            
            -- Saída
            data_out: out std_logic_vector(address_bits-1 downto 0)
        );
    end component;

    signal pc_if, pc_plus4_if, ri_if, ram_out_imem_if : std_logic_vector(31 downto 0) := x"00000000";

    signal COP_if: instruction_type;

    signal hazard_nop_if: std_logic;

    signal halt_detected: std_logic := '0';

begin
    hazard_nop_if <= id_Branch_nop or id_hd_hazard;
    pc_plus4_if <= pc_if + x"00000004";
    ri_if <= ri_if when halt_detected = '1' else
             ram_out_imem_if when id_Branch_nop = '0' else
             x"00000000";

    COP_if <= ADD when (ri_if(14 downto 12) = "000" and ri_if(6 downto 0) = "0110011") else
              SLT when (ri_if(14 downto 12) = "010" and ri_if(6 downto 0) = "0110011") else
              ADDI when (ri_if(14 downto 12) = "000" and ri_if(6 downto 0) = "0010011") else
              SLTI when (ri_if(14 downto 12) = "010" and ri_if(6 downto 0) = "0010011") else
              SLLI when (ri_if(14 downto 12) = "001" and ri_if(6 downto 0) = "0010011") else
              SRLI when (ri_if(31 downto 25) = "0000000" and ri_if(14 downto 12) = "101" and ri_if(6 downto 0) = "0010011") else
              SRAI when (ri_if(31 downto 25) = "0100000" and ri_if(14 downto 12) = "101" and ri_if(6 downto 0) = "0010011") else
              LW when (ri_if(14 downto 12) = "010" and ri_if(6 downto 0) = "0000011") else
              SW when (ri_if(14 downto 12) = "010" and ri_if(6 downto 0) = "0100011") else
              BEQ when (ri_if(14 downto 12) = "000" and ri_if(6 downto 0) = "1100011") else
              BNE when (ri_if(14 downto 12) = "001" and ri_if(6 downto 0) = "1100011") else
              BLT when (ri_if(14 downto 12) = "100" and ri_if(6 downto 0) = "1100011") else
              HALT when (ri_if = x"0000006F") else
              JAL when ri_if(6 downto 0) = "1101111" else
              JALR when ri_if(6 downto 0) = "1100111" else
              NOP when (ri_if = x"00000000") else
              NOINST;

    MAIN_PROC: process(clock, halt_detected)
    begin
        if (clock'event and clock = '1') and (halt_detected = '0') then
            if (hazard_nop_if = '0' or id_PC_Src = '1') then
                if (id_PC_Src = '1') then
                    pc_if <= id_Jump_PC;
                elsif (id_PC_Src = '0') then
                    pc_if <= pc_plus4_if;
                end if;
            end if;

            if (ri_if = x"0000006F") then
                halt_detected <= '1';
            end if;

	    if(id_hd_hazard = '0') then
	        BID <= pc_if & ri_if;
            end if;
        end if;
    end process;

    KEEP_SIMULATING_PROC: process
    begin
        wait until keep_simulating = False;
        stop;
    end process;

    IMEM : ram
        generic map (
            address_bits => 32, 
            size => 4096,
            ram_init_file => imem_init_file 
        )
        port map(
            clock 	 => clock,								
            write 	 => '0',							
            address  => pc_if,
            data_in  => x"00000000",
            data_out => ram_out_imem_if
        );
end architecture;
