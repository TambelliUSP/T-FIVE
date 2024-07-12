----------------------------------------------------------------------------------------------------
-------------MODULO ESTAGIO DE EXECU�AO-------------------------------------------------------------
----------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

library work;
use work.tipos.all;

-- Especifica�ao do estagio Executa - ex: declara�ao de entidade
-- Neste est�gio sao executadas as instru�oes do tipo RR e calculado os endere�os 
-- das instru�oes de load e store.
-- O m�dulo que implementa a antecipa�ao de valores (Forwarding) � feita neste est�gio 
-- num m�dulo separado dentro do est�gio ex.
-- A unidade l�gica e aritm�tica - ULA - fica neste est�gio.
-- Os multiplexadores de estrada da ULA que selecionam os valores corretos dependendo 
-- da antecipa�ao ficam neste est�gio.
-- A defini�ao do sinais de entrada e sa�da do est�gio EX encontram-se na declara�ao 
-- da entidade est�gio_ex e sao passados pelo registrador BEX

entity estagio_ex is
    port(
		-- Entradas
		clock				: in 	std_logic;					  		-- Rel�gio do Sistema
      	BEX					: in 	std_logic_vector (151 downto 0);  	-- Dados vindos do id
		COP_ex				: in 	instruction_type;				  	-- Mnem�nico no est�gio ex
		ula_mem				: in 	std_logic_vector (031 downto 0);	-- ULA no est�gio de Mem�ria
		rs1_id_ex			: in	std_logic_vector (004 downto 0);    -- rs1 no est�gio id para o ex
		rs2_id_ex			: in	std_logic_vector (004 downto 0);    -- rs2 no est�gio id para o ex
		MemRead_mem			: in 	std_logic;					  		-- Leitura na mem�ria no  mem
		RegWrite_mem		: in 	std_logic;					  		-- Escrita nos regs. no  mem
		rd_mem				: in 	std_logic_vector (004 downto 0);	-- Destino nos regs. mem
		RegWrite_wb			: in	Std_logic;							-- Escrita nos regs no estagio wb
		rd_wb				: in	std_logic_vector (004 downto 0);	-- Destino no rges no est�gio wb
		writedata_wb		: in 	std_logic_vector (031 downto 0);	-- Dado a ser escrito no regs.
		Memval_mem			: in	std_logic_vector (031 downto 0);	-- Sa�da da mem�ria no mem
		
		-- Sa�das
		MemRead_ex			: out	std_logic;							-- Leitura da mem�ria no ex 
		rd_ex				: out	std_logic_vector (004 downto 0);	-- Destino dos regs no ex
		ULA_ex				: out	std_logic_vector (031 downto 0);	-- ULA no est�gio ex
		ex_fw_A_Branch		: out 	std_logic_vector (001 downto 0);	-- Dado comparado em A no id 
																		-- em desvios com forward
        ex_fw_B_Branch		: out 	std_logic_vector (001 downto 0);	-- Dado comparado em B no id 
																		-- em desvios com forward
        BMEM				: out 	std_logic_vector (115 downto 0) := (others => '0'); -- dados para mem
		COP_mem				: out 	instruction_type := NOP			  	-- Mnem�nico no est�gio mem
		
		);
end entity;

architecture behave of estagio_ex is
    component alu is
        port(
            -- Entradas
            in_a		: in 	std_logic_vector(31 downto 0);
            in_b		: in 	std_logic_vector(31 downto 0);
            ALUOp		: in 	std_logic_vector(02 downto 0);
            
            -- Sa�das
            ULA			: out 	std_logic_vector(31 downto 0);
            zero		: out 	std_logic
        );
    end component;

    -- Alias para sinais vindos do BEX
    alias RA_ex is BEX(31 downto 0);
    alias RB_ex is BEX(63 downto 32);
    alias Imed_ex is BEX(95 downto 64);
    alias PC_ex_Plus4 is BEX(127 downto 96);
    alias rs1_ex is BEX(132 downto 128);
    alias rs2_ex is BEX(137 downto 133);
    alias rd_ex_bex is BEX(142 downto 138);
    alias Aluop_ex is BEX(145 downto 143);
    alias AluSrc_ex is BEX(146);
    alias Memread_ex_bex is BEX(147);
    alias Memwrite_ex is BEX(148);
    alias RegWrite_ex is BEX(149);
    alias MemtoReg_ex is BEX(151 downto 150);

    -- Alias para sinais a serem redirecionados para o BMEM
    --alias BMEM(115 downto 114) <= MemToReg_mem;
    --alias BMEM(113) <= RegWrite_mem;
    --alias BMEM(112) <= MemWrite_mem;
    --alias BMEM(111) <= MemRead_mem;
    --alias BMEM(110 downto 079) <= NPC_mem;
    --alias BMEM(078 downto 047) <= ULA_mem;
    --alias BMEM(046 downto 015) <= dado_arma_mem;
    --alias BMEM(014 downto 010) <= rs1_mem;
    --alias BMEM(009 downto 005) <= rs2_mem;
    --alias BMEM(004 downto 000) <= rd_mem;

    signal dado_arma_ex, ULA_out_ex: std_logic_vector(31 downto 0) := x"00000000";

    signal forwarding_operator_A, forwarding_operator_B, alu_operator_B: std_logic_vector(31 downto 0) := x"00000000";
    signal forward_A, forward_B: std_logic_vector(1 downto 0) := "00";

    signal BMEM_int: std_logic_vector(115 downto 0) := (others => '0');
    signal MemToReg_mem: std_logic_vector(1 downto 0) := "00";
begin
    -- Forwarding Unit -> Alu operators
    forward_A <=    "11" when (RegWrite_mem='1') and (rd_mem/="00000") and (rd_mem=rs1_ex) and (MemRead_mem='1') else
                    "10" when (RegWrite_mem='1') and (rd_mem/="00000") and (rd_mem=rs1_ex) else
                    "01" when (RegWrite_wb='1') and (rd_wb/="00000") and (rd_wb=rs1_ex) else
                    "00"; -- Caso padrão usa valor do registrador vindo do estagio anterior

    forward_B <=    "11" when (RegWrite_mem='1') and (rd_mem/="00000") and (rd_mem=rs2_ex) and (MemRead_mem='1') else
                    "10" when (RegWrite_mem='1') and (rd_mem/="00000") and (rd_mem=rs2_ex) else
                    "01" when (RegWrite_wb='1') and (rd_wb/="00000") and (rd_wb=rs2_ex) else
                    "00"; -- Caso padrão usa valor do registrador vindo do estagio anterior

    -- Forwarding Unit -> Branch Operators
    ex_fw_A_Branch <=   "10" when (RegWrite_ex='1') and (rd_ex_bex/="00000") and (rs1_id_ex=rd_ex_bex) else
                        "11" when (RegWrite_mem='1') and (rd_mem/="00000") and (rs1_id_ex=rd_mem) and (MemToReg_mem="10") else
                        "01" when (RegWrite_mem='1') and (rd_mem/="00000") and (rs1_id_ex=rd_mem) else
                        "00"; -- Caso padrão em que não é preciso fazer encaminhamento para branch
    ex_fw_B_Branch <=   "10" when (RegWrite_ex='1') and (rd_ex_bex/="00000") and (rs2_id_ex=rd_ex_bex) else
                        "11" when (RegWrite_mem='1') and (rd_mem/="00000") and (rs2_id_ex=rd_mem) and (MemToReg_mem="10") else
                        "01" when (RegWrite_mem='1') and (rd_mem/="00000") and (rs2_id_ex=rd_mem) else
                        "00"; -- Caso padrão em que não é preciso fazer encaminhamento para branch

    MAIN_PROC: process(clock)
		begin
			if(clock'event and clock='1') then
                BMEM_int <= MemtoReg_ex & RegWrite_ex & Memwrite_ex & Memread_ex_bex & PC_ex_Plus4 & ULA_out_ex & dado_arma_ex & rs1_ex & rs2_ex & rd_ex_bex;
				COP_MEM <= COP_EX;
			end if;
		end process;

    forwarding_operator_A <=    RA_ex when forward_A = "00" else
                                ula_mem when forward_A = "10" else
                                writedata_wb when forward_A = "01" else
                                Memval_mem;
    
    forwarding_operator_B <=    RB_ex when forward_B = "00" else
                                ula_mem when forward_B = "10" else
                                writedata_wb when forward_B = "01" else
                                Memval_mem;

    dado_arma_ex <= forwarding_operator_B;

    alu_operator_B <=   forwarding_operator_B when AluSrc_ex = '0' else
                        Imed_ex;
                    
    ULA: alu
        port map (
            in_a		=> forwarding_operator_A,
            in_b		=> alu_operator_B,
            ALUOp		=> Aluop_ex,
            ULA			=> ULA_out_ex,
            zero		=> open
        );

    BMEM <= BMEM_int;
    MemToReg_mem <= BMEM_int(115 downto 114);
    MemRead_ex <= Memread_ex_bex;
    rd_ex <= rd_ex_bex;
    ULA_ex <= ULA_out_ex;
end architecture;