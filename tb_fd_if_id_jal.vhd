library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
library std;
use std.textio.all;

library work;
use work.tipos.all;

entity tb_fd_if_id_jal is
    generic(
        imem_init_file: string := "imem.txt";
        dmem_init_file: string := "dmem.txt"
    );
end entity;

architecture tb_fd_if_id_jal_arch of tb_fd_if_id_jal is	

    component estagio_if
        generic(
		imem_init_file: string := "imem.txt"
        );
        port(
			--Entradas
			clock			: in 	std_logic;	-- Base de tempo vinda da bancada de teste
        	id_hd_hazard	: in 	std_logic;	-- Sinal de controle que carrega 0's na parte do RI do registrador de saída do if_stage
			id_Branch_nop	: in 	std_logic;	-- Sinal que indica inser4çao de NP devido a desviou pulo
			id_PC_Src		: in 	std_logic;	-- Seleçao do mux da entrada do PC
			id_Jump_PC		: in 	std_logic_vector(31 downto 0) := x"00000000";			-- Endereço do Jump ou desvio realizado
			keep_simulating	: in	Boolean := True;
			
			-- Saída
        	BID				: out 	std_logic_vector(63 downto 0) := x"0000000000000000"	--Registrador de saída do if_stage-if_id
        );
    end component;

    component estagio_id
        port(
			-- Entradas
			clock				: in 	std_logic; 						-- Base de tempo vindo da bancada de teste
			BID					: in 	std_logic_vector(063 downto 0);	-- Informaçoes vindas estágio Busca
			MemRead_ex			: in	std_logic;						-- Sinal de leitura de memória no estagio ex
			rd_ex				: in	std_logic_vector(004 downto 0);	-- Endereço de destino noa regs. no estágio ex
			ula_ex				: in 	std_logic_vector(031 downto 0);	-- Saída da ULA no estágio Ex
			MemRead_mem			: in	std_logic;						-- Sinal de leitura na memória no estágio mem
			rd_mem				: in	std_logic_vector(004 downto 0);	-- Endere'co de escrita nos regs. no est'agio mem
			ula_mem				: in 	std_logic_vector(031 downto 0);	-- Saída da ULA no estágio Mem 
			NPC_mem				: in	std_logic_vector(031 downto 0); -- Valor do NPC no estagio mem
        	RegWrite_wb			: in 	std_logic; 						-- Sinal de escrita no RegFile vindo de wb
        	writedata_wb		: in 	std_logic_vector(031 downto 0);	-- Valor a ser escrito no RegFile vindo de wb
        	rd_wb				: in 	std_logic_vector(004 downto 0);	-- Endereço do registrador escrito
        	ex_fw_A_Branch		: in 	std_logic_vector(001 downto 0);	-- Seleçao de Branch forwardA vindo de forward
        	ex_fw_B_Branch		: in 	std_logic_vector(001 downto 0);	-- Seleçao de Branch forwardB vindo de forward
		
			-- Saídas
			id_Jump_PC			: out	std_logic_vector(031 downto 0) := x"00000000";		-- Endereço destino do JUmp ou Desvio
			id_PC_src			: out	std_logic := '0';				-- Seleciona a entrado do PC
			id_hd_hazard		: out	std_logic := '0';				-- Sinal que preserva o if_id e nao incrementa o PC
			id_Branch_nop		: out	std_logic := '0';				-- Sinaliza a inserçao de um NOP devido ao Branch. limpa o if_id.ri
			rs1_id_ex			: out	std_logic_vector(004 downto 0);	-- Endereço rs1 no estágio id
			rs2_id_ex			: out	std_logic_vector(004 downto 0);	-- Endereço rs2 no estágio id
			BEX					: out 	std_logic_vector(151 downto 0) := (others => '0'); 	-- Saída do ID para o EX
			COP_id				: out	instruction_type  := NOP;							-- Instrucao no estagio id
			COP_ex				: out 	instruction_type := NOP								-- Instruçao no estágio id passada para EX
        );
    end component;

	-- Período do relógio do Pipeline
	constant clock_period: time := 10 ns; 
	
	-- Sinais internos para conexao das portas do estágio IF
	signal		clock			: std_logic := '1';	-- Base de tempo vinda da bancada de teste
    signal    	id_hd_hazard	: std_logic;		-- Sinal de controle que carrega 0's na parte do RI do registrador de saída do if_stage
	signal		id_PC_Src		: std_logic;		-- Seleçao do mux da entrada do PC
	signal		id_Jump_PC		: std_logic_vector(31 downto 0) := x"00000000";		-- Endereço do Jump ou desvio realizado
	signal		BID				: std_logic_vector(63 downto 0) := x"0000000000000000";--Registrador de saída do if_stage-if_id clock 
	signal		Keep_simulating	: boolean := true;	-- Continue a simulaçao
	
	
	-- Sinais internos para conexao das portas do estágio ID
	--Entradas
	signal	MemRead_ex		: std_logic;						-- Sinal de leitura de memória no estagio ex
	--signal	RegWrite_ex		: std_logic;						-- Sinal de escrita nos regs. no estágio ex
	signal	rd_ex			: std_logic_vector(004 downto 0);	-- Endereço de destino nos regs. no estágio ex
	signal	ula_ex			: std_logic_vector(031 downto 0);	-- Saída da ULA no estágio Ex
	signal	MemRead_mem		: std_logic;						-- Sinal de leitura na memória no estágio mem
	signal	ula_mem			: std_logic_vector(031 downto 0);	-- Saída da ULA no estágio Mem 
    signal  RegWrite_wb		: std_logic; 						-- Sinal de escrita no RegFile vindo de wb
    signal  writedata_wb	: std_logic_vector(031 downto 0);	-- Valor a ser escrito no RegFile vindo de wb
    signal  rd_wb			: std_logic_vector(004 downto 0);	-- Endereço do registrador escrito
    signal  ex_fw_A_Branch	: std_logic_vector(001 downto 0);	-- Seleçao de Branch forwardA vindo de forward
    signal  ex_fw_B_Branch	: std_logic_vector(001 downto 0);	-- Seleçao de Branch forwardB vindo de forward 
	signal	rd_mem			: std_logic_vector(04 downto 0); 
	signal	NPC_mem			: std_logic_vector(31 downto 0);
	signal	id_Branch_nop	: std_logic; 
	signal	rs1_id_ex		: std_logic_vector(04 downto 0);
	signal	rs2_id_ex		: std_logic_vector(04 downto 0);
	signal	COP_id			: instruction_type;
	 
			-- Saídas
	signal	BEX				: std_logic_vector(151 downto 0) := (others => '0'); 	-- Saída do ID para o EX
	signal	COP_ex			: instruction_type := NOP;						  		-- Instruçao no estágio id passada para EX
	
	--	Mostrando a alocaç±ao dos sinais no buffer de saída  id - BEX

alias MemToReg 	is BEX(151 downto 150);
alias RegWrite 	is BEX(149);
alias Memwrite 	is BEX(148);
alias Memread  	is BEX(147);
alias AluSrc   	is BEX(146);
alias Aluop		is BEX(145 downto 143);
alias reg_rd	is BEX(142 downto 138);
alias reg_rs2	is BEX(137 downto 133);
alias reg_rs1	is BEX(132 downto 128);
alias PC_id		is BEX(127 downto 096);
alias Imed		is BEX(095 downto 064);
alias RB		is BEX(063 downto 032);
alias RA		is BEX(031 downto 000);	  

-- Sinais para escrever log em arquivos	
constant 	C_FILE_NAME 	:string  	:= "DataOut.txt";
signal 		eof           	:std_logic 	:= '0';
file 		fptr			: text;

signal start : std_logic := '1';
	
begin
	
    fetch : estagio_if 
        generic map(
            imem_init_file => "imem_tb_if_id_jal.txt"
        )
        port map(
			--Entradas
			clock			=> clock,			-- Base de tempo vinda da bancada de teste
        	id_hd_hazard	=> id_hd_hazard,	-- Sinal de controle que carrega 0's na parte do RI do registrador de saída do if_stage
			id_Branch_nop	=> id_Branch_nop,	-- Sinal que indica inser4çao de NP devido a desviou pulo
			id_PC_Src		=> id_PC_Src,		-- Seleçao do mux da entrada do PC
			id_Jump_PC		=> id_Jump_PC,		-- Endereço do Jump ou desvio realizado
			keep_simulating	=> keep_simulating,	-- Continue a simulaçao
			
			-- Saída
        	BID				=> BID				--Registrador de saída do if_stage-if_id
        );

    decode : estagio_id 
        port map(
            -- Entradas
		clock				=> clock,			-- Base de tempo vindo da bancada de teste
		BID					=> BID,				-- Informaçoes vindas estágio Busca
		MemRead_ex			=> MemRead_ex,		-- Sinal de leitura de memória no estagio ex
		rd_ex				=> rd_ex,			-- Endereço de destino noa regs. no estágio ex
		ula_ex				=> ula_ex,			-- Saída da ULA no estágio Ex
		MemRead_mem			=> MemRead_mem,		-- Sinal de leitura na memória no estágio mem
		rd_mem				=> rd_mem,			-- Endereco de escrita nos regs. no estagio mem
		ula_mem				=> ula_mem,			-- Saída da ULA no estágio Mem 
		NPC_mem				=> NPC_mem, 		-- Valor do NPC no estagio mem
        RegWrite_wb			=> RegWrite_wb, 	-- Sinal de escrita no RegFile vindo de wb
        writedata_wb		=> writedata_wb,	-- Valor a ser escrito no RegFile vindo de wb
        rd_wb				=> rd_wb,			-- Endereço do registrador escrito
        ex_fw_A_Branch		=> ex_fw_A_Branch,	-- Seleçao de Branch forwardA vindo de forward
        ex_fw_B_Branch		=> ex_fw_B_Branch,	-- Seleçao de Branch forwardB vindo de forward
		
		-- Saídas
		id_Jump_PC			=> id_Jump_PC, 		-- Endereço destino do JUmp ou Desvio
		id_PC_src			=> id_PC_src,		-- Seleciona a entrado do PC
		id_hd_hazard		=> id_hd_hazard,	-- Sinal que preserva o if_id e nao incrementa o PC
		id_Branch_nop		=> id_Branch_nop,	-- Sinaliza a inserçao de um NOP devido ao Branch. limpa o if_id.ri
		rs1_id_ex			=> rs1_id_ex,		-- Endereço rs1 no estágio id
		rs2_id_ex			=> rs2_id_ex,		-- Endereço rs2 no estágio id
		BEX					=> BEX, 			-- Saída do ID para o EX
		COP_id				=> COP_id,			-- Instrucao no estagio id
		COP_ex				=> COP_ex			-- Instruçao no estágio id passada para EX
        );


	clock <= not clock after clock_period / 2;

    process(clock) 
		variable count: integer := 0; 
		variable simulation_count: integer := 0; 
		variable fstatus       :file_open_status;
		variable file_line     :line;
    begin
		if(rising_edge(clock)) then
			case count is
			when 0=> --IF: jal x0, 4 // ID: nop
									MemRead_ex 		<= '0';
									rd_ex			<= "00000";
									--RegWrite_ex 	<= '0';
									ULA_ex 			<= x"00000000";
									--rs1_id_ex		<= "00000";
									--rs2_id_ex		<= "00000";
									MemRead_mem 	<= '0';
									rd_mem			<= "00000";
									ula_mem 		<= x"00000000";
									NPC_mem			<= x"00000000";
									RegWrite_wb 	<= '0';
									writedata_wb 	<= x"00000000";
									rd_wb			<= "00000";
									ex_fw_A_Branch 	<= "00";
									ex_fw_B_Branch 	<= "00";
									assert (BID(31 downto 0) = "0x00000000") severity error
			when 1=> --IF: jal x0, -4 // ID: jal x0, 4 
									assert (BID = "0x000000000040006F") severity error
			when 2=> --IF: jal x0, -4 // ID: NOP
									assert (BID(31 downto 0) = "0x00000000") severity error
			when 3=> --IF: nop // ID: jal x0, -4
									assert (BID = "0x00000004ffdff06f") severity error	
					when others => null;
			
			end case;
			if (count = 3) then
				count := 0;
			else
				count := count + 1;
			end if;
			simulation_count := simulation_count + 1;
			if (simulation_count = 8) then
				keep_simulating <= false;
			end if;
		end if;
		eof       <= '1';
	end process;
end architecture;
