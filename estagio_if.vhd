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

architecture if_arch of estagio_if is
    component mux_2x1_n is
        generic (
            constant BITS: integer := 32
        );
        port(
            D1      : in  std_logic_vector (BITS-1 downto 0);
            D0      : in  std_logic_vector (BITS-1 downto 0);
            SEL     : in  std_logic;
            MUX_OUT : out std_logic_vector (BITS-1 downto 0)
        );
    end component;

    component mux_3x1_n is
        generic (
            constant BITS: integer := 32
        );
        port(
            D2      : in  std_logic_vector (BITS-1 downto 0);
            D1      : in  std_logic_vector (BITS-1 downto 0);
            D0      : in  std_logic_vector (BITS-1 downto 0);
            SEL     : in  std_logic_vector (1 downto 0);
            MUX_OUT : out std_logic_vector (BITS-1 downto 0)
        );
    end component;

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

    component registrador_n is
        generic (
            constant N: integer := 8 
        );
        port (
            clock  : in  std_logic;
            clear  : in  std_logic;
            enable : in  std_logic;
            D      : in  std_logic_vector (N-1 downto 0);
            Q      : out std_logic_vector (N-1 downto 0) 
        );
    end component;

    component adder is
        port(
            a, b: in std_logic_vector(31 downto 0);
            y: out std_logic_vector(31 downto 0)
        );
    end component;

    signal pc, pc_plus4, mux_pc, mux_ri_if, ram_out : std_logic_vector(31 downto 0) := x"00000000";

    signal hazard_nop: std_logic;

begin
    hazard_nop <= id_Branch_nop or id_hd_hazard;


    PC_SOURCE_MUX: mux_2x1_n
        generic map (BITS => 32)
        port map(
            D0 => pc_plus4,
            D1 => id_Jump_Pc,
            SEL => id_PC_Src,
            MUX_OUT => mux_pc
        );

    PC_REG: registrador_n
        generic map (
            N => 32
        )
        port map (
            clock  => clock,
            clear  => '0',
            enable => "not"(hazard_nop),
            D      => mux_pc,
            Q      => pc
        );

    MUX_RI: mux_2x1_n
        generic map (BITS => 32)
        port map(
            D0 => ram_out,
            D1 => "00000000000000000000000000000000",
            SEL => hazard_nop,
            MUX_OUT => mux_ri_if
        );

    IMEM : ram
        generic map (
            address_bits => 32, 
            size => 4096,
            ram_init_file => "imem.txt" 
        )
        port map(
            clock 	 => clock,								
            write 	 => '0',							
            address  => pc,
            data_in  => "00000000000000000000000000000000",
            data_out => ram_out
        );
    

    PLUS4: adder
        port map (
            a => pc,
            b => "00000000000000000000000000000100",
            y => pc_plus4
        );
    
    BID <= pc & mux_ri_if;
end architecture if_arch;