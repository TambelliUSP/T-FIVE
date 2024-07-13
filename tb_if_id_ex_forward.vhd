library ieee;  

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

library work;
use work.tipos.all;

entity fd_if_id_ex_forward is
    generic(
        imem_init_file: string := "imem.txt";-- Arquivo que contem o programa a ser executado
        dmem_init_file: string := "dmem.txt" -- Arquivo que alimenta a mem�ria de dados neces�rios ao programa em execu�ao
    );
end entity;

architecture fd_arch of fd_if_id_ex_forward is

    component estagio_if
        generic(
            imem_init_file: string := "imem.txt"
        );
        port(
            --Entradas
			clock			: in 	std_logic;	-- Base de tempo vinda da bancada de teste
        	id_hd_hazard	: in 	std_logic;	-- Sinal de controle que carrega 0's na parte do RI do registrador de sa�da do if_stage
			id_Branch_nop	: in 	std_logic;	-- Sinal que indica inser4�ao de NP devido a desviou pulo
			id_PC_Src		: in 	std_logic;	-- Sele�ao do mux da entrada do PC
			id_Jump_PC		: in 	std_logic_vector(31 downto 0) := x"00000000";			-- Endere�o do Jump ou desvio realizado
			keep_simulating	: in	Boolean := True;
			
			-- Sa�da
        	BID				: out 	std_logic_vector(63 downto 0) := x"0000000000000000"	--Registrador de sa�da do if_stage-if_id
        );
    end component;

    component estagio_id
        port(
			-- Entradas
			clock				: in 	std_logic; 						-- Base de tempo vindo da bancada de teste
			BID					: in 	std_logic_vector(063 downto 0);	-- Informa�oes vindas est�gio Busca
			MemRead_ex			: in	std_logic;						-- Sinal de leitura de mem�ria no estagio ex
			rd_ex				: in	std_logic_vector(004 downto 0);	-- Endere�o de destino noa regs. no est�gio ex
			ula_ex				: in 	std_logic_vector(031 downto 0);	-- Sa�da da ULA no est�gio Ex
			MemRead_mem			: in	std_logic;						-- Sinal de leitura na mem�ria no est�gio mem
			rd_mem				: in	std_logic_vector(004 downto 0);	-- Endere'co de escrita nos regs. no est'agio mem
			ula_mem				: in 	std_logic_vector(031 downto 0);	-- Sa�da da ULA no est�gio Mem 
			NPC_mem				: in	std_logic_vector(031 downto 0); -- Valor do NPC no estagio mem
        	RegWrite_wb			: in 	std_logic; 						-- Sinal de escrita no RegFile vindo de wb
        	writedata_wb		: in 	std_logic_vector(031 downto 0);	-- Valor a ser escrito no RegFile vindo de wb
        	rd_wb				: in 	std_logic_vector(004 downto 0);	-- Endere�o do registrador escrito
        	ex_fw_A_Branch		: in 	std_logic_vector(001 downto 0);	-- Sele�ao de Branch forwardA vindo de forward
        	ex_fw_B_Branch		: in 	std_logic_vector(001 downto 0);	-- Sele�ao de Branch forwardB vindo de forward
		
		-- Sa�das
			id_Jump_PC			: out	std_logic_vector(031 downto 0) := x"00000000";		-- Endere�o destino do JUmp ou Desvio
			id_PC_src			: out	std_logic := '0';				-- Seleciona a entrado do PC
			id_hd_hazard		: out	std_logic := '0';				-- Sinal que preserva o if_id e nao incrementa o PC
			id_Branch_nop		: out	std_logic := '0';				-- Sinaliza a inser�ao de um NOP devido ao Branch. limpa o if_id.ri
			rs1_id_ex			: out	std_logic_vector(004 downto 0);	-- Endere�o rs1 no est�gio id
			rs2_id_ex			: out	std_logic_vector(004 downto 0);	-- Endere�o rs2 no est�gio id
			BEX					: out 	std_logic_vector(151 downto 0) := (others => '0'); 	-- Sa�da do ID para o EX
			COP_id				: out	instruction_type  := NOP;							-- Instrucao no estagio id
			COP_ex				: out 	instruction_type := NOP								-- Instru�ao no est�gio id passada para EX
		);
    end component;
	
	component estagio_ex
		port (
			-- Entradas
			clock				: in 	std_logic;					  		-- Rel�gio do Sistema
      		BEX					: in 	std_logic_vector (151 downto 0);  	-- Dados vindos do est�gio Decode
			COP_ex				: in 	instruction_type;				  	-- Mnem�nico da instru�ao vinda do est�gio id: instru�ao no est�gio ex
			ula_mem				: in 	std_logic_vector (031 downto 0);	-- Sa�da da ULA no est�gio de Mem�ria
			rs1_id_ex			: in	std_logic_vector (004 downto 0);    -- Endere�o rs1 no est�gio id sendo passado para o est�gio ex
			rs2_id_ex			: in	std_logic_vector (004 downto 0);    -- Endere�o rs2 no est�gio id sendo passado para o est�gio ex
			MemRead_mem			: in 	std_logic;					  		-- Sinal de leitura na mem�ria no est�gio mem
			RegWrite_mem		: in 	std_logic;					  		-- Sinal de escrita nos regs. no est�gio mem
			rd_mem				: in 	std_logic_vector (004 downto 0);		-- Endere�o de destino nos regs. no est�gio mem
			RegWrite_wb			: in	Std_logic;							-- Sinal de escrita nos regs no estagio wb
			rd_wb				: in	std_logic_vector (004 downto 0);	-- endere�o de destino no rges no est�gio wb
			writedata_wb		: in 	std_logic_vector (031 downto 0);	-- Dado a ser escrito no registrador destino
			Memval_mem			: in	std_logic_vector (031 downto 0);	-- Valor da sa�da da mem�ria no est�gio mem
		
			-- Sa�das
			MemRead_ex			: out	std_logic;							-- Sinal de leitura da mem�ria no estagio ex 
			rd_ex				: out	std_logic_vector (004 downto 0);	-- Endere�o de destino dos regs no est�gio ex
			ULA_ex				: out	std_logic_vector (031 downto 0);	-- Sa�da da ULA no est�gio ex
			ex_fw_A_Branch		: out 	std_logic_vector (001 downto 0);	-- Sele�ao do dado a ser comparado em A no id em desvios com forward
        	ex_fw_B_Branch		: out 	std_logic_vector (001 downto 0);	-- Sele�ao do dado a ser comparado em B no id em desvios com forward
        	BMEM				: out 	std_logic_vector (115 downto 0) := (others => '0'); -- dados de sa�da para o est�gio de Mem�ria
			COP_mem				: out 	instruction_type := NOP			  	-- Mnem�nico da instru�ao no est�gio mem
		);
	end component;

    --Sinais internos para conexao das portas de if
	signal		clock			: std_logic := '1';	-- Base de tempo vinda da bancada de teste
    signal    	id_hd_hazard	: std_logic;		-- Sinal de controle que carrega 0's na parte do RI do registrador de sa�da do if_stage
	signal		id_Branch_nop	: std_logic;		-- Sinal que indica inser4�ao de NP devido a desviou pulo
	signal		id_PC_Src		: std_logic;		-- Sele�ao do mux da entrada do PC
	signal		id_Jump_PC		: std_logic_vector(31 downto 0) := x"00000000";		-- Endere�o do Jump ou desvio realizado
	signal		BID				: std_logic_vector(63 downto 0) := x"0000000000000000";--Registrador de sa�da do if_stage-if_id clock 
	signal		Keep_simulating	: boolean := true;	-- Continue a simula�ao
	
	-- Sinais internos para conexao das portas do est�gio ID
	--Entradas
	signal	MemRead_ex		: std_logic;						-- Sinal de leitura de mem�ria no estagio ex
	signal	rd_ex			: std_logic_vector(004 downto 0);	-- Endere�o de destino nos regs. no est�gio ex
	signal	ula_ex			: std_logic_vector(031 downto 0);	-- Sa�da da ULA no est�gio Ex
	signal	MemRead_mem		: std_logic;						-- Sinal de leitura na mem�ria no est�gio mem
	signal	ula_mem			: std_logic_vector(031 downto 0);	-- Sa�da da ULA no est�gio Mem 
    signal  RegWrite_wb		: std_logic; 						-- Sinal de escrita no RegFile vindo de wb
    signal  writedata_wb	: std_logic_vector(031 downto 0);	-- Valor a ser escrito no RegFile vindo de wb
    signal  rd_wb			: std_logic_vector(004 downto 0);	-- Endere�o do registrador escrito
    signal  ex_fw_A_Branch	: std_logic_vector(001 downto 0);	-- Sele�ao de Branch forwardA vindo de forward
    signal  ex_fw_B_Branch	: std_logic_vector(001 downto 0);	-- Sele�ao de Branch forwardB vindo de forward 
	signal	rd_mem			: std_logic_vector(04 downto 0); 
	signal	NPC_mem			: std_logic_vector(31 downto 0);
	signal	rs1_id_ex		: std_logic_vector(04 downto 0);
	signal	rs2_id_ex		: std_logic_vector(04 downto 0);
	signal	COP_id			: instruction_type;
	-- Sa�das
	signal	BEX				: std_logic_vector(151 downto 0) := (others => '0'); 	-- Sa�da do ID para o EX
	signal	COP_ex			: instruction_type := NOP;						  		-- Instru�ao no est�gio id passada para EX
     
	
	-- Per�odo do rel�gio do Pipeline
	constant clock_period		: time := 10 ns;

    --buffers entre os est�gios da pipeline
	signal BMEM				: std_logic_vector(115 downto 0) := (others => '0');
	
	--Apelidos para os sinais do buffer BMEM
	alias MemToReg_ex		is  BMEM(115 downto 114);
	alias RegWrite_ex		is  BMEM(113);
	alias MemWrite_ex		is  BMEM(112);
	alias MemRead_bmem_ex	is  BMEM(111);
	alias NPC_ex			is  BMEM(110 downto 079);
	alias ULA_bmem_ex		is  BMEM(078 downto 47);
	alias dado_arma_ex		is  BMEM(046 downto 15);
	alias rs1_ex			is  BMEM(014 downto 10);
	alias rs2_ex			is  BMEM(009 downto 05);
	alias rd_bmem_ex		is  BMEM(004 downto 00);
 

    --sinais que conectam sa�da dos est�gios aos buffers 
	signal wb_write_data	: std_logic_vector(031 downto 0);
    signal wb_write_rd		: std_logic_vector(004 downto 0); 
	signal wb_RegWrite		: std_logic;
	signal RegWrite_mem		: std_logic; 
	signal Memval_mem		: std_logic_vector(31 downto 0);
	signal COP_mem			: instruction_type;
	
	

begin
    fetch : estagio_if 
        generic map(
            imem_init_file => "imem_tb_if_id_ex_forward.txt"
        )
        port map(
            --Entradas
			clock			=> clock,			-- Base de tempo vinda da bancada de teste
        	id_hd_hazard	=> id_hd_hazard,	-- Sinal de controle que carrega 0's na parte do RI do registrador de sa�da do if_stage
			id_Branch_nop	=> id_Branch_nop,	-- Sinal que indica inser4�ao de NP devido a desviou pulo
			id_PC_Src		=> id_PC_Src,		-- Sele�ao do mux da entrada do PC
			id_Jump_PC		=> id_Jump_PC,		-- Endere�o do Jump ou desvio realizado
			keep_simulating	=> keep_simulating,	-- Continue a simula�ao
			
			-- Sa�da
        	BID				=> 	BID 			--Registrador de sa�da do if_stage-if_id
        );

    decode : estagio_id 
		port map(
			-- Entradas
            clock				=> clock,			-- Base de tempo vindo da bancada de teste
			BID					=> BID,				-- Informa�oes vindas est�gio Busca
			MemRead_ex			=> MemRead_ex,		-- Sinal de leitura de mem�ria no estagio ex
			rd_ex				=> rd_ex,			-- Endere�o de destino noa regs. no est�gio ex
			ula_ex				=> ula_ex,			-- Sa�da da ULA no est�gio Ex
			MemRead_mem			=> MemRead_mem,		-- Sinal de leitura na mem�ria no est�gio mem
			rd_mem				=> rd_mem,			-- Endereco de escrita nos regs. no estagio mem
			ula_mem				=> ula_mem,			-- Sa�da da ULA no est�gio Mem 
			NPC_mem				=> NPC_mem, 		-- Valor do NPC no estagio mem
        	RegWrite_wb			=> RegWrite_wb, 	-- Sinal de escrita no RegFile vindo de wb
        	writedata_wb		=> writedata_wb,	-- Valor a ser escrito no RegFile vindo de wb
        	rd_wb				=> rd_wb,			-- Endere�o do registrador escrito
        	ex_fw_A_Branch		=> ex_fw_A_Branch,	-- Sele�ao de Branch forwardA vindo de forward
        	ex_fw_B_Branch		=> ex_fw_B_Branch,	-- Sele�ao de Branch forwardB vindo de forward
		
			-- Sa�das
			id_Jump_PC			=> id_Jump_PC, 		-- Endere�o destino do JUmp ou Desvio
			id_PC_src			=> id_PC_src,		-- Seleciona a entrado do PC
			id_hd_hazard		=> id_hd_hazard,	-- Sinal que preserva o if_id e nao incrementa o PC
			id_Branch_nop		=> id_Branch_nop,	-- Sinaliza a inser�ao de um NOP devido ao Branch. limpa o if_id.ri
			rs1_id_ex			=> rs1_id_ex,		-- Endere�o rs1 no est�gio id
			rs2_id_ex			=> rs2_id_ex,		-- Endere�o rs2 no est�gio id
			BEX					=> BEX, 			-- Sa�da do ID para o EX
			COP_id				=> COP_id,			-- Instrucao no estagio id
			COP_ex				=> COP_ex			-- Instru�ao no est�gio id passada para EX
        );
		
		
	executa: estagio_ex
		port map(
		   	-- Entradas
		clock				=> clock,			-- Rel�gio do Sistema
      	BEX					=> BEX, 			-- Dados vindos do est�gio Decode
		COP_ex				=> COP_ex,			-- Mnem�nico da instru�ao vinda do est�gio id: instru�ao no est�gio ex
		ula_mem				=> ula_mem,			-- Sa�da da ULA no est�gio de Mem�ria
		rs1_id_ex			=> rs1_id_ex,   	-- Endere�o rs1 no est�gio id sendo passado para o est�gio ex
		rs2_id_ex			=> rs2_id_ex,   	-- Endere�o rs2 no est�gio id sendo passado para o est�gio ex
		MemRead_mem			=> MemRead_mem,		-- Sinal de leitura na mem�ria no est�gio mem
		RegWrite_mem		=> RegWrite_mem,	-- Sinal de escrita nos regs. no est�gio mem
		rd_mem				=> rd_mem,			-- Endere�o de destino nos regs. no est�gio mem
		RegWrite_wb			=> RegWrite_wb,		-- Sinal de escrita nos regs no estagio wb
		rd_wb				=> rd_wb,			-- endere�o de destino no rges no est�gio wb
		writedata_wb		=> writedata_wb,	-- Dado a ser escrito no registrador destino
		Memval_mem			=> Memval_mem,		-- Valor da sa�da da mem�ria no est�gio mem
		
		-- Sa�das
		MemRead_ex			=> MemRead_ex,		-- Sinal de leitura da mem�ria no estagio ex 
		rd_ex				=> rd_ex,			-- Endere�o de destino dos regs no est�gio ex
		ULA_ex				=> ULA_ex,			-- Sa�da da ULA no est�gio ex
		ex_fw_A_Branch		=> ex_fw_A_Branch,	-- Sele�ao do dado a ser comparado em A no id em desvios com forward
        ex_fw_B_Branch		=> ex_fw_B_Branch,	-- Sele�ao do dado a ser comparado em B no id em desvios com forward
        BMEM				=> BMEM, 			-- dados de sa�da para o est�gio de Mem�ria
		COP_mem				=> COP_mem			-- Mnem�nico da instru�ao no est�gio mem
		); 
		
	
		
		
 	clock <= not clock after clock_period / 2;
 
 
   stim: process is
    begin
     
			wait for 3*clock_period; -- Ciclo 3 = 30 ns
            MemRead_mem     <= '0';
            rd_mem			<= "00010"; 
            ula_mem			<= x"00000004";
            NPC_mem			<= x"00000004";
            RegWrite_wb		<= '0';
            writedata_wb	<= x"00000000";
            rd_wb			<= "00000";
            RegWrite_mem	<= '1';
		
        	wait for clock_period;	 -- Ciclo 4 = 40 ns
            MemRead_mem     <= '0';
            rd_mem			<= "01111";
            ula_mem			<= x"0000000F";
            NPC_mem			<= x"00000008";
            RegWrite_wb		<= '1';
            writedata_wb	<= x"00000004";
            rd_wb			<= "00010";
            RegWrite_mem	<= '1';
		
        	wait for clock_period;	-- Ciclo 5 = 50 ns
            MemRead_mem     <= '0';
            rd_mem			<= "00001";
            ula_mem			<= x"0000000A";
            NPC_mem			<= x"0000000C";
            RegWrite_wb		<= '1';
            writedata_wb	<= x"0000000F";
            rd_wb			<= "01111";
            RegWrite_mem	<= '1';
		
        	wait for clock_period;	 -- Ciclo 6 = 60 ns
            MemRead_mem     <= '0';
            rd_mem			<= "00011";
            ula_mem			<= x"00000006";
            NPC_mem			<= x"00000010";
            RegWrite_wb		<= '1';
            writedata_wb	<= x"0000000A";
            rd_wb			<= "00001";
            RegWrite_mem	<= '1';
        	
        	wait for clock_period;	 -- Ciclo 7 = 70 ns
            MemRead_mem     <= '0';
            rd_mem			<= "00010";
            ula_mem			<= x"00000010";
            NPC_mem			<= x"00000014";
            RegWrite_wb		<= '1';
            writedata_wb	<= x"00000006";
            rd_wb			<= "00011";
            RegWrite_mem	<= '1';
		
        	wait for clock_period;	 -- Ciclo 8 = 80 ns
            MemRead_mem     <= '0';
            rd_mem			<= "01100";
            ula_mem			<= x"00000000";
            NPC_mem			<= x"00000018";
            RegWrite_wb		<= '1';
            writedata_wb	<= x"00000010";
            rd_wb			<= "00010";
            RegWrite_mem	<= '1';
		
        	wait for clock_period;	 -- Ciclo 9 = 90 ns
            MemRead_mem     <= '0';
            rd_mem			<= "01101";
            ula_mem			<= x"00000001";
            NPC_mem			<= x"0000001C";
            RegWrite_wb		<= '1';
            writedata_wb	<= x"00000000";
            rd_wb			<= "01100";
            RegWrite_mem	<= '1';
		
        	wait for clock_period;	  -- Ciclo 10 = 100 ns
            MemRead_mem     <= '0';
            rd_mem			<= "01110";
            ula_mem			<= x"00000020";
            NPC_mem			<= x"00000020";
            RegWrite_wb		<= '1';
            writedata_wb	<= x"00000001";
            rd_wb			<= "01101";
            RegWrite_mem	<= '1';

            wait for clock_period;	  -- Ciclo 11 = 110 ns
            MemRead_mem     <= '0';
            rd_mem			<= "00100";
            ula_mem			<= x"00000074";
            NPC_mem			<= x"00000024";
            RegWrite_wb		<= '1';
            writedata_wb	<= x"00000020";
            rd_wb			<= "01110";
            RegWrite_mem	<= '0';

            wait for clock_period;	  -- Ciclo 12 = 120 ns
            MemRead_mem     <= '0';
            rd_mem			<= "00000";
            ula_mem			<= x"00000000";
            NPC_mem			<= x"00000028";
            RegWrite_wb		<= '0';
            writedata_wb	<= x"00000074";
            rd_wb			<= "00100";
            RegWrite_mem	<= '1';

            wait for 2*clock_period;	  -- Ciclo 13-14 = 130-140 ns - ultimos ciclos de execucao

			Keep_simulating <= False;
        wait;
    end process;

    
end architecture;