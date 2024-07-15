---------------------------------------------------------------------------------------------------
-----------MODULO ESTAGIO DE MEMORIA---------------------------------------------------------------
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all; 

library work;
use work.tipos.all;	

-- O est�gio de mem�ria � respons�vel por implementar os acessos a mem�ria de dados nas 
-- instru�oes de load e Store.
-- Nas demais instru�oes este est�gio nao realiza nenhuma opera�ao e passa simplesmente 
-- os dados recebidos para o est�gio wb de forma a viabilizar
-- o armazenamento das informa�oes nos registradores do Banco de registradores.
-- Os sinais de entrada e sa�da deste est�gio encontram-se definidos na declara�ao da 
-- entidade estagio_mem.

entity estagio_mem_grupo_3 is
    generic (
        dmem_init_file: string := "dmem.txt"          --Nome do arquivo conteúdo da memoria de programa
    );
    port(
		-- Entradas
		clock		: in std_logic;						 	-- Base de tempo
        BMEM		: in std_logic_vector(115 downto 0); 	-- Informa�oes vindas do est�gio ex
		COP_mem		: in instruction_type;					-- Mnem�nico sendo processada no est�gio mem
		
		-- Sa�das
        BWB			: out std_logic_vector(103 downto 0) := (others => '0');-- Informa�oes para o wb
		COP_wb 		: out instruction_type := NOP;			-- Mnem�nico a ser processada pelo est�gio wb
		RegWrite_mem: out std_logic;						-- Escrita em regs no est�gio mem
		MemRead_mem	: out std_logic;						-- Leitura da mem�ria no est�gio mem 
		MemWrite_mem: out std_logic;						-- Escrita na memoria de dados no est�gio mem
		rd_mem		: out std_logic_vector(004 downto 0);	-- Destino nos regs. no estagio mem
		ula_mem		: out std_logic_vector(031 downto 0);	-- ULA no est�go mem para o est�gio mem
		NPC_mem		: out std_logic_vector(031 downto 0);	-- Valor do NPC no estagio mem
		Memval_mem	: out std_Logic_vector(031 downto 0)	-- Saida da mem�ria no est�gio mem
    );
end entity;

architecture behave of estagio_mem_grupo_3 is
    component data_ram is	 -- Esta � a mem�ria de dados -dmem
        generic(
            address_bits		: integer 	:= 32;		  -- Bits de end. da mem�ria de dados
            size				: integer 	:= 4099;	  -- Tamanho da mem�ria de dados em Bytes
            data_ram_init_file	: string 	:= "dmem.txt" -- Arquivo da mem�ria de dados
        );
        port (
            -- Entradas
            clock 		: in  std_logic;							    -- Base de tempo bancada de teste
            write 		: in  std_logic;								-- Sinal de escrita na mem�ria
            address 	: in  std_logic_vector(address_bits-1 downto 0);-- Entrada de endere�o da mem�ria
            data_in 	: in  std_logic_vector(address_bits-1 downto 0);-- Entrada de dados da mem�ria
            
            -- Sa�da
            data_out 	: out std_logic_vector(address_bits-1 downto 0)	-- Sa�da de dados da mem�ria
        );
    end component;

    -- Alias para sinais vindos do BMEM
    alias MemToReg_mem is BMEM(115 downto 114);
    alias RegWrite_mem_bmem is BMEM(113);
    alias MemWrite_mem_bmem is BMEM(112);
    alias MemRead_mem_bmem is BMEM(111);
    alias NPC_mem_bmem is BMEM(110 downto 079);
    alias ULA_mem_bmem is BMEM(078 downto 047);
    alias dado_arma_mem is BMEM(046 downto 015);
    alias rs1_mem is BMEM(014 downto 010);
    alias rs2_mem is BMEM(009 downto 005);
    alias rd_mem_bmem is BMEM(004 downto 000);

    -- Alias para sinais atribuidos no BWB
    --alias BMEM(103 downto 102) <= MemToReg_wb;
    --alias BMEM(101) <= RegWrite_wb;
    --alias BMEM(100 downto 069) <= NPC_wb;
    --alias BMEM(068 downto 037) <= ULA_wb;
    --alias BMEM(036 downto 005) <= dado_lido_wb;
    --alias BMEM(004 downto 000) <= rd_wb;

    signal dmem_out_mem: std_logic_vector(31 downto 0) := x"00000000";
begin
    DMEM: data_ram 
    generic map (
        address_bits		=> 32,
        size				=> 4099,
        data_ram_init_file	=> dmem_init_file
    )
    port map (
        -- Entradas
        clock 		=> clock,
        write 		=> MemWrite_mem_bmem,
        address 	=> ULA_mem_bmem,
        data_in 	=> dado_arma_mem,
        
        -- Sa�da
        data_out 	=> dmem_out_mem
    );

    process(clock)
    begin
        if(clock'event and clock='1') then
            BWB <= MemToReg_mem & RegWrite_mem_bmem & NPC_mem_bmem & ULA_mem_bmem & dmem_out_mem & rd_mem_bmem;
            COP_wb <= COP_mem;
        end if;
    end process;

    RegWrite_mem <= RegWrite_mem_bmem;
    MemRead_mem	 <= MemRead_mem_bmem;
    MemWrite_mem <= MemWrite_mem_bmem;		
    rd_mem		<= rd_mem_bmem;
    ula_mem		<= ULA_mem_bmem;
    NPC_mem		<= NPC_mem_bmem;
    Memval_mem	<= dmem_out_mem;
end architecture;