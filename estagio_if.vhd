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

entity estagio_if is
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

architecture behave of estagio_if is
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
    HAZARD_NOP_PROC: process(id_Branch_nop, id_hd_hazard)
    begin
        hazard_nop_if <= id_Branch_nop or id_hd_hazard;
    end process;

    PC_PLUS4_PROC: process(pc_if)
    begin
        pc_plus4_if <= pc_if + x"00000004";
    end process;

    RI_IF_PROC: process(id_Branch_nop, ram_out_imem_if, halt_detected)
    begin
        if (halt_detected = '0') then
            if (id_Branch_nop = '0') then
                ri_if <= ram_out_imem_if;
            else
                ri_if <= x"00000000";
            end if;
        end if;
    end process;

    COP_IF_PROC: process(ri_if)
    begin
        if (ri_if(14 downto 12) = "000" and ri_if(6 downto 0) = "0110011") then
            COP_if <= ADD;
        elsif (ri_if(14 downto 12) = "010" and ri_if(6 downto 0) = "0110011") then
            COP_if <= SLT;
        elsif (ri_if(14 downto 12) = "000" and ri_if(6 downto 0) = "0010011") then
            COP_if <= ADDI;
        elsif (ri_if(14 downto 12) = "010" and ri_if(6 downto 0) = "0010011") then
            COP_if <= SLTI;
        elsif (ri_if(14 downto 12) = "001" and ri_if(6 downto 0) = "0010011") then
            COP_if <= SLLI;
        elsif (ri_if(31 downto 25) = "0000000" and ri_if(14 downto 12) = "101" and ri_if(6 downto 0) = "0010011") then
            COP_if <= SRLI;
        elsif (ri_if(31 downto 25) = "0100000" and ri_if(14 downto 12) = "101" and ri_if(6 downto 0) = "0010011") then
            COP_if <= SRAI;
        elsif (ri_if(14 downto 12) = "010" and ri_if(6 downto 0) = "0000011") then
            COP_if <= LW;
        elsif (ri_if(14 downto 12) = "010" and ri_if(6 downto 0) = "0100011") then
            COP_if <= SW;
        elsif (ri_if(14 downto 12) = "000" and ri_if(6 downto 0) = "1100011") then
            COP_if <= BEQ;
        elsif (ri_if(14 downto 12) = "001" and ri_if(6 downto 0) = "0000000") then
            COP_if <= BNE;
        elsif (ri_if(14 downto 12) = "100" and ri_if(6 downto 0) = "0000000") then
            COP_if <= BLT;
        elsif (ri_if = x"0000006F") then
            COP_if <= HALT;
        elsif (ri_if(14 downto 12) = "000" and ri_if(6 downto 0) = "1101111") then
            COP_if <= JAL;
        elsif (ri_if(14 downto 12) = "000" and ri_if(6 downto 0) = "1100111") then
            COP_if <= JALR;
        elsif (ri_if = x"00000000") then
            COP_if <= NOP;
        else
            COP_if <= NOINST;
        end if;
    end process;

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

            BID <= pc_if & ri_if;
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
            ram_init_file => "imem.txt" 
        )
        port map(
            clock 	 => clock,								
            write 	 => '0',							
            address  => pc_if,
            data_in  => x"00000000",
            data_out => ram_out_imem_if
        );
end architecture;