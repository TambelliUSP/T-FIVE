library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use std.textio.all;

library work;
use work.tipos.all;

entity tb_fd_if_id is
    generic(
        imem_init_file: string := "imem_tb_if_id.txt";
        dmem_init_file: string := "dmem.txt"
    );
end entity;

architecture tb_fd_if_id_arch2 of tb_fd_if_id is	

    component estagio_if_grupo_3
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

    component estagio_id_grupo_3
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

	-- Per�odo do rel�gio do Pipeline
	constant clock_period: time := 10 ns; 
	
	-- Sinais internos para conexao das portas do est�gio IF
	signal		clock			: std_logic := '1';	-- Base de tempo vinda da bancada de teste
    signal    	id_hd_hazard	: std_logic;		-- Sinal de controle que carrega 0's na parte do RI do registrador de sa�da do if_stage
	signal		id_PC_Src		: std_logic;		-- Sele�ao do mux da entrada do PC
	signal		id_Jump_PC		: std_logic_vector(31 downto 0) := x"00000000";		-- Endere�o do Jump ou desvio realizado
	signal		BID				: std_logic_vector(63 downto 0) := x"0000000000000000";--Registrador de sa�da do if_stage-if_id clock 
	signal		Keep_simulating	: boolean := true;	-- Continue a simula�ao
	
	
	-- Sinais internos para conexao das portas do est�gio ID
	--Entradas
	signal	MemRead_ex		: std_logic;						-- Sinal de leitura de mem�ria no estagio ex
	--signal	RegWrite_ex		: std_logic;						-- Sinal de escrita nos regs. no est�gio ex
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
	signal	id_Branch_nop	: std_logic; 
	signal	rs1_id_ex		: std_logic_vector(04 downto 0);
	signal	rs2_id_ex		: std_logic_vector(04 downto 0);
	signal	COP_id			: instruction_type;
	 
			-- Sa�das
	signal	BEX				: std_logic_vector(151 downto 0) := (others => '0'); 	-- Sa�da do ID para o EX
	signal	COP_ex			: instruction_type := NOP;						  		-- Instru�ao no est�gio id passada para EX
	
	--	Mostrando a aloca�ao dos sinais no buffer de sa�da  id - BEX

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

	
begin
	
    fetch : estagio_if_grupo_3 
        generic map(
            imem_init_file => "imem_tb_if_id.txt"
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
        	BID				=> BID				--Registrador de sa�da do if_stage-if_id
        );

    decode : estagio_id_grupo_3 
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


	clock <= not clock after clock_period / 2;

    process(clock) 
	variable count: integer := 0; 
	variable fstatus       :file_open_status;
	variable file_line     :line;
	
    begin
		
        if rising_edge(clock) then
			   	
		   case count is  
			   when 0 => 		--Teste da primeira instru��o do programa swap: addi,a0,zero,0 ==> 10 ns
			   				MemRead_ex 		<= '0';
							rd_ex			<= "00000";
							--RegWrite_ex 	<= '0';
							ULA_ex 			<= x"00000000";
							rs1_id_ex		<= "00000";
							rs2_id_ex		<= "01000";
							MemRead_mem 	<= '0';
							rd_mem			<= "00000";
							ula_mem 		<= x"00000000";
							NPC_mem			<= x"00000000";
			   				RegWrite_wb 	<= '1';
							writedata_wb 	<= x"00000000";
							rd_wb			<= "00000";
			   				ex_fw_A_Branch 	<= "00";
							ex_fw_B_Branch 	<= "00"; 
							file_open(fstatus, fptr, C_FILE_NAME, write_mode);
							
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE1: primeira instru��o: Verificando leitura de RA" severity note;
							if RA = x"00000000" then
								report "Teste 1: primeira instru��o ==> EST� CORRETO" severity warning;
							end if;
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							
        					report "TESTE 2: primeira instru��o: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: primeira instru��o ==>  EST� CORRETO" severity warning;
							end if;
							assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: primeira instru��o: Verificando que Imed est� no buffer de sa�da" severity note;
							if Imed = x"00000000" then
								report "Teste 3: primeira instrucao ==> EST� CORRETO" severity warning;
							end if;
							assert Imed = x"00000000" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
			   				report "TESTE 4: primeira instru��o: Verificando que PC_id est� no buffer de sa�da: 10 ns" severity note;
							if PC_id = x"00000000" then
							report "Teste 4: primeira instru��o ==> EST� CORRETO" severity warning;
							end if;
							assert PC_id = x"00000000" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
        					report "TESTE 5: primeira instru��o: Verificando que rs1 est� no buffer de sa�da" severity note;
							if reg_rs1 = "00000" then  -- 
								report "Teste 5: primeira instru��o ==> EST� CORRETO" severity warning;
							end if;
							assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
        					report "TESTE 6: primeira instru��o: Verificando que rs2 est� no buffer de sa�da" severity note;
							if reg_rs2 = "00000" then
								report "Teste 6: primeira instrucao ==> EST� CORRETO" severity warning;
							end if;
							assert reg_rs2 = "00000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
        					report "TESTE 7: primeira instru��o: Verificando que rd est� no buffer de sa�da" severity note;
							if reg_rd = "00000" then
								report "Teste 7: primeira instru��o ==> EST� CORRETO" severity warning;
							end if;
							assert reg_rd  = "00000" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX = "00000000000000000000000000000000000000" severity error;
							report "BEX = " & to_hex_string(BEX) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_in = " & to_string(BEX(151 downto 143)) severity warning;
							if BEX(151 downto 143) = "000000000"then
								report "Teste 8: primeira instru��o Sinais de controle ==> EST�0 CORRETOs" severity warning;
							else
								report "Teste 8: primeira instru��o Sinais de controle ==> EST�0 ERRADOS severity error";
							end if;
							assert BEX(151 downto 143) = "000000000" severity error;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
												
				when 1 => 	--Teste da segunda instru��o do programa swap: addi,a1,zero,3 ==> 20 ns
							MemRead_ex 		<= '0';
							rd_ex			<= "00000";	
							rs2_id_ex		<= "00000";
							NPC_mem			<= x"00000004";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: segunda instru��o: Verificando leitura de RA est� no buffer de sa�da" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da segunda instru��o est� correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: segunda instru��o: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da segunda instru��o est� correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3 segunda instru��o: Verificando que Imed est� no buffer de sa�da" severity note;
							if Imed = x"00000000" then
								report "Teste 3 da segunda instru��o est� correto" severity warning;
							end if;
        					assert Imed = x"00000000" severity error;
							report "Imed = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: segunda instru��o: Verificando que PC_id est� no buffer de sa�da: 20 ns" severity note;     
							if PC_id = x"00000004" then                       
								report "Teste 4: da segunda instru��o est� correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000004" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: segunda instru��o: Verificando que rs1 est� no buffer de sa�da" severity note;
							if reg_rs1 = "00000" then  -- 
								report "Teste 5: da segunda instru��o est� correto" severity warning;
							end if;
        					assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6 segunda instru��o: Verificando que rs2 est� no buffer de sa�da" severity note;
							if reg_rs2 = "00000" then
								report "Teste 6 da segunda instru��o est� correto" severity warning;
							end if;
        					assert reg_rs2 = "00000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7 segunda instru��o: Verificando que rd est� no buffer de sa�da" severity note;
							if reg_rd = "00000" then
								report "Teste 7 da segunda instru��o est� correto" severity warning;
							end if;
        					assert reg_rd = "00000" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX = x"00000000000004000000000000000000000000" severity warning;
							report "BEX = " & to_hex_string(BEX) severity warning;
							report "#################################################################################  " severity warning;
							
							if BEX(151 downto 143) = "000000000"then
								report "TESTE 8: segunda instru��o Sinais de controle ==> EST�0 CORRETOs" severity warning;
							else
								report "Teste 8: segunda instru��o Sinais de controle ==> EST�0 ERRADOS" severity error;
							end if;
							assert BEX(151 downto 143) = "000000000" severity error;
							report "BEX_in = " & to_string(BEX(151 downto 143)) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
							
				when 2 => 	--Teste da terceira instru��o do programa swap: slli,t0,a1,2	==> 30 ns
							MemRead_ex 		<= '0';
							rd_ex			<= "01010";	
							rd_mem			<= "00001";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: terceira instru��o: Verificando leitura de RA est� no buffer de sa�da" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da terceira instru��o est� correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: terceira instru��o: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da terceira instru��o est� correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
						    report "=================================================================================  " severity warning;
						   	
							report "TESTE 3: terceira instru��o: Verificando que Imed est� no buffer de sa�da" severity note;
							if Imed = x"00000008" then
								report "Teste 3: da terceira instru��o est� correto" severity warning;
							end if;
        					assert Imed = x"00000008" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: terceira instru��o: Verificando que PC_id est� no buffer de sa�da: 30 ns" severity note;     
							if PC_id = x"00000004" then                       
								report "Teste 4: da terceira instru��o est� correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000004" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: terceira instru��o: Verificando que rs1 est� no buffer de sa�da" severity note;
							if reg_rs1 = "00000" then  -- 
								report "Teste 5: da terceira instru��o est� correto" severity warning;
							end if;
        					assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: terceira instru��o: Verificando que rs2 est� no buffer de sa�da" severity note;
							if reg_rs2 = "01000" then
								report "Teste 6: da terceira instru��o est� correto" severity warning;
							else
								report "Teste 6: da terceira instru��o reg_rs2 est� errado" severity error;
							end if;
        					assert reg_rs2 = "01000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: terceira instru��o: Verificando que rd est� no buffer de sa�da" severity note;
							if reg_rd = "00001" then
								report "Teste 7: da terceira instru��o est� correto" severity warning;
							end if;
        					assert reg_rd = "00001" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX = x"A0050000000004000000080000000000000000" severity error;
							report "BEX = " & to_hex_string(BEX) severity warning;
							report "#################################################################################  " severity warning;
							
							
							if BEX(151 downto 143) = "101000000" then
								report "TESTE 8: terceira instru��o Sinais de controle ==> EST�0 CORRETOs" severity warning;
							else
								report "Teste 8: terceira instru��o Sinais de controle ==> EST�0 ERRADOS" severity error;
							end if;
							assert BEX(151 downto 143) = "101000000" severity error;
							report "BEX_in = " & to_string(BEX(151 downto 143)) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
							
							
				when 3 => 	--Teste da quarta instru��o do programa	swap: add,t0,a0,0(t0)	==> 40 ns
							MemRead_ex 		<= '0';
							rd_ex			<= "01011";
							rs2_id_ex		<= "00011";	
							rd_mem			<= "00000";	
							NPC_mem			<= x"00000008";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: quarta instru��o: Verificando leitura de RA est� no buffer de sa�da" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da quarta instru��o est� correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
						    report "=================================================================================  " severity warning;
							
							report "TESTE 2: quarta instru��o: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da quarta instru��o est� correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: quarta instru��o: Verificando que Imed est� no buffer de sa�da" severity note;
							if Imed = x"00000000" then
								report "Teste 3: da quarta instru��o est� correto" severity warning;
							end if;
        					assert Imed = x"00000000" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: quarta instru��o: Verificando que PC_id est� no buffer de sa�da: 40 ns" severity note;     
							if PC_id= x"00000008" then                       
								report "Teste 4: da quarta instru��o est� correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000008" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: quarta instru��o: Verificando que rs1 est� no buffer de sa�da" severity note;
							if reg_rs1 = "00000" then  -- 
								report "Teste 5: da quarta instru��o est� correto" severity warning;
							end if;
        					assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: quarta instru��o: Verificando que rs2 est� no buffer de sa�da" severity note;
							if reg_rs2 = "00000" then
								report "Teste 6: da quarta instru��o est� correto" severity warning;
							end if;
        					assert reg_rs2 = "00000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: quarta instru��o: Verificando que rd est� no buffer de sa�da" severity note;
							if reg_rd = "00000" then
								report "Teste 7: da quarta instru��o est� correto" severity warning;
							end if;
        					assert reg_rd = "00000" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX = x"00000000000008000000000000000000000000" severity error;
							report "BEX = " & to_hex_string(BEX) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_in = " & to_hex_string(BEX(151 downto 143)) severity warning;
							if BEX(151 downto 143) = "000000000"then
								report "TESTE 8: quarta instru��o Sinais de controle ==> EST�0 CORRETOs" severity warning;
							else
								report "Teste 8: quarta instru��o Sinais de controle ==> EST�0 ERRADOS" severity error;
							end if;
							assert BEX(151 downto 143) = "000000000" severity error;
							report "BEX_in = " & to_string(BEX(151 downto 143)) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
				
				when 4 => 	--Teste da quinta instru��o do programa swap: lw t1, 0(t0)		 ==> 50 ns 
							MemRead_ex 		<= '0';
							rd_ex			<= "01011";
							ula_ex			<= x"00000003";
							rs1_id_ex		<= "01011";	
							rs2_id_ex		<= "00010";  
							rd_mem			<= "01010";	  
							NPC_mem			<= x"0000000C";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: quinta instru��o: Verificando leitura de RA est� no buffer de sa�da" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da quinta instru��o est� correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: quinta instru��o: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da quinta instru��o est� correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: quinta instru��o: Verificando que Imed est� no buffer de sa�da" severity note;
							if Imed = x"00000000" then
								report "Teste 7\3: da quinta instru��o est� correto" severity warning;
							end if;
        					assert Imed = x"00000000" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: quinta instru��o: Verificando que PC_id est� no buffer de sa�da: 50 ns" severity note;     
							if PC_id = x"0000000C" then                       
								report "Teste 4: da quinta instru��o est� correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"0000000C" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: quinta instru��o: Verificando que rs1 est� no buffer de sa�da" severity note;
							if reg_rs1 = "01000" then  -- 
								report "Teste 5: da quarta instru��o est� correto" severity warning;
							end if;
							assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: quinta instru��o: Verificando que rs2 est� no buffer de sa�da" severity note;
							if reg_rs2 = "00000" then
								report "Teste 6: da quinta instru��o est� correto" severity warning;
							end if;
        					assert reg_rs2 = "00000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: quinta instru��o: Verificando que rd est� no buffer de sa�da" severity note; 
							if reg_rd = "01010" then
								report "Teste 7: da quinta instru��o est� correto" severity warning;
							end if;
        					assert reg_rd = "01010" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
						    report "=================================================================================  " severity warning;
							
							assert BEX = x"2428000000000C000000000000000000000000" severity error;
							report "BEX = " & to_hex_string(BEX) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_in = " & to_hex_string(BEX(151 downto 143)) severity warning;
							if BEX(151 downto 143) = "001001000"then
								report "TESTE 8: quinta instru��o Sinais de controle ==> EST�0 CORRETOs" severity warning;
							else
								report "Teste 8: quinta instru��o Sinais de controle ==> EST�0 ERRADOS" severity error;
							end if;
							assert BEX(151 downto 143) = "001001000" severity error;
							report "BEX_in = " & to_string(BEX(151 downto 143)) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
							
				when 5 => 	 --Teste da sexta instru��o do programa	swap: lw t2, 4(t0)	  ==> 60 ns
							MemRead_ex 		<= '1';
							rd_ex			<= "00101";
							ULA_ex			<= x"0000000C";
							rs1_id_ex		<= "01010";	
							rs2_id_ex		<= "00101";	
							rd_mem			<= "01011";
							ula_mem 		<= x"00000003";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: sexta instru��o: Verificando leitura de RA est� no buffer de sa�da" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da sexta instru��o est� correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error; 
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: sexta instru��o: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da sexta instru��o est� correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: sexta instru��o: Verificando que Imed est� no buffer de sa�da" severity note;
							if Imed = x"00000003" then
								report "Teste 3: da sexta instru��o est� correto" severity warning;
							end if;
        					assert Imed = x"00000003" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: sexta instru��o: Verificando que PC_id est� no buffer de sa�da: 60 ns" severity note;     
							if PC_id = x"00000010" then                       
								report "Teste 1\4 da sexta instru��o est� correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000010" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: sexta instru��o: Verificando que rs1 est� no buffer de sa�da" severity note;
							if reg_rs1 = "00000" then  -- 
								report "Teste 5: da sexta instru��o est� correto" severity warning;
							end if;
        					assert reg_rs1 = "00000" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: sexta instru��o: Verificando que rs2 est� no buffer de sa�da" severity note;
							if reg_rs2 = "00011" then
								report "Teste 6: da sexta instru��o est� correto" severity warning;
							end if;
        					assert reg_rs2 = "00011" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: sexta instru��o: Verificando que rd est� no buffer de sa�da" severity note;
							if reg_rd = "01011" then
								report "Teste 7: da sexta instru��o est� correto" severity warning;
							end if;
        					assert reg_rd = "01011" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX = x"242C6000000010000000030000000000000000" severity error;
							report "BEX = " & to_hex_string(BEX);
							report "#################################################################################  " severity warning;
							
							report "BEX_in = " & to_hex_string(BEX(151 downto 143)) severity warning;
							if BEX(151 downto 143) = "001001000"then
								report "TESTE 8: sexta instru��o Sinais de controle ==> EST�0 CORRETOs" severity warning;
							else
								report "Teste 8: sexta instru��o Sinais de controle ==> EST�0 ERRADOS" severity error;
							end if;
							assert BEX(151 downto 143) = "001001000" severity error;
							report "BEX_in = " & to_string(BEX(151 downto 143)) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
				
				when 6 => 	--Teste da s�tima instru��o do programa swap: sw t2, 0(t0)	 ==> 70 ns
							MemRead_ex 		<= '1';
							rd_ex			<= "00110";
							rs1_id_ex		<= "00101";	
							rs2_id_ex		<= "00000";
							rd_mem			<= "00101";
							ula_mem 		<= x"0000000C";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: s�tima instru��o: Verificando leitura de RA est� no buffer de sa�da" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da s�tima instru��o est� correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: s�tima instru��o: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da s�tima instru��o est� correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: s�tima instru��o: Verificando que Imed est� no buffer de sa�da" severity note;
							if Imed = x"00000002" then
								report "Teste 3: da s�tima instru��o est� correto" severity warning;
							end if;
        					assert Imed = x"00000002" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: s�tima instru��o: Verificando que PC_id est� no buffer de sa�da: 70 ns" severity note;     
							if PC_id = x"00000014" then                       
								report "Teste 4: da s�tima instru��o est� correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000014" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: s�tima instru��o: Verificando que rs1 est� no buffer de sa�da" severity note;
							if reg_rs1 = "01011" then
								report "Teste 5: da s�tima instru��o est� correto" severity warning;
							end if;
        					assert reg_rs1 = "01011" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: s�tima instru��o: Verificando que rs2 est� no buffer de sa�da" severity note; 
							if reg_rs2 = "00010" then
								report "Teste 5\6: da s�tima instru��o est� correto" severity warning;
							end if;
        					assert reg_rs2 = "00010" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: s�tima instru��o: Verificando que rd est� no buffer de sa�da" severity note;
							if reg_rd = "00101" then
								report "Teste 7: da s�tima instru��o est� correto" severity warning;
							end if;
        					assert reg_rd = "00101" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX = x"25944B00000014000000020000000000000000" severity error;
							report "BEX = " & to_hex_string(BEX) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_in = " & to_hex_string(BEX(151 downto 143)) severity warning;
							if BEX(151 downto 143) = "001001011"then
								report "TESTE 8: setima instru��o Sinais de controle ==> EST�0 CORRETOs" severity warning;
							else
								report "Teste 8: setima instru��o Sinais de controle ==> EST�0 ERRADOS" severity error;
							end if;
							assert BEX(151 downto 143) = "001001011" severity error;
							report "BEX_in = " & to_string(BEX(151 downto 143)) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;

				
				when 7 => 	--Teste da oitava instru��o do programa swap: sw t1, 4(t0)	   ==> 80 ns
							MemRead_ex 		<= '1';
							rd_ex			<= "00110";	
							rs2_id_ex		<= "00100";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: oitava instru��o: Verificando leitura de RA est� no buffer de sa�da" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da oitava instru��o est� correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: oitava instru��o: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da oitava instru��o est� correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3: oitava instru��o: Verificando que Imed est� no buffer de sa�da" severity note;
							if Imed = x"00000000" then
								report "Teste 3: da oitava instru��o est� correto" severity warning;
							end if;
       						assert Imed = x"00000000" severity error; 
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: oitava instru��o: Verificando que PC_id est� no buffer de sa�da: 80 ns" severity note;     
							if PC_id = x"0000000018" then                       
								report "Teste 4: da oitava instru��o est� correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000018" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: oitava instru��o: Verificando que rs1 est� no buffer de sa�da" severity note;
							if reg_rs1 = "01010" then  -- 
								report "Teste 5: da oitava instru��o est� correto" severity warning;
							end if;
        					assert reg_rs1 = "01010" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: oitava instru��o: Verificando que rs2 est� no buffer de sa�da" severity note;
							if reg_rs2 = "00101" then
								report "Teste 6: da oitava instru��o est� correto" severity warning;
							end if;
        					assert reg_rs2 = "00101" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: oitava instru��o: Verificando que rd est� no buffer de sa�da" severity note;
							if reg_rd = "00101" then
								report "Teste 7: da oitava instru��o est� correto" severity warning;
							end if;
        					assert reg_rd = "00101" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX = x"0014AA00000018000000000000000000000000" severity error;
							report "BEX = " & to_hex_string(BEX) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_in = " & to_hex_string(BEX(151 downto 143)) severity warning;
							if BEX(151 downto 143) = "000000000"then
								report "TESTE 8: oitava instru��o Sinais de controle ==> EST�0 CORRETOs" severity warning;
							else
								report "Teste 8: oitava instru��o Sinais de controle ==> EST�0 ERRADOS" severity error;
							end if;
							assert BEX(151 downto 143) = "000000000" severity error;
							report "BEX_in = " & to_string(BEX(151 downto 143)) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
				
				when 8 => --Teste da nona instru��o do programa swap: Jal zero, fim	   ==> 90 ns
							MemRead_ex 		<= '1';
							rd_ex			<= "00111";
							ULA_ex			<= x"00000010";
							rs2_id_ex		<= "00111";
							MemRead_mem 	<= '1';
							rd_mem			<= "00110";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1: nona instru��o: Verificando leitura de RA est� no buffer de sa�da" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1: da nona instru��o est� correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2: nona instru��o: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2: da nona instru��o est� correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							report "TESTE 3: nona instru��o: Verificando que Imed est� no buffer de sa�da" severity note;
							if Imed = x"00000000" then
								report "Teste 3: da nona instru��o est� correto" severity warning;
							end if;
       						assert Imed = x"00000000" severity error;
							report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4: nona instru��o: Verificando que PC_id est� no buffer de sa�da: 90 ns" severity note;     
							if PC_id = x"00000018" then                       
								report "Teste 4 da nona instru��o est� correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"00000018" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5: nona instru��o: Verificando que rs1 est� no buffer de sa�da" severity note;
							if reg_rs1 = "01010" then  -- 
								report "Teste 5: da nona instru��o est� correto" severity warning;
							end if;
        					assert reg_rs1 = "01010" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6: nona instru��o: Verificando que rs2 est� no buffer de sa�da" severity note;
							if reg_rs2 = "00101" then
								report "Teste 6: da nona instru��o est� correto" severity warning;
							end if;
        					assert reg_rs2 = "00101" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7: nona instru��o: Verificando que rd est� no buffer de sa�da" severity note;
							if reg_rd = "00101" then
								report "Teste 7: da nona instru��o est� correto" severity warning;
							end if;
        					assert reg_rd = "00101" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX = x"2014AA00000018000000000000000000000000" severity error;
							report "BEX = " & to_hex_string(BEX) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_in = " & to_hex_string(BEX(151 downto 143)) severity warning;
							if BEX(151 downto 143) = "001000000"then
								report "TESTE 8: nona instru��o Sinais de controle ==> EST�0 CORRETOs" severity warning;
							else
								report "Teste 8: nona instru��o Sinais de controle ==> EST�0 ERRADOS" severity error;
							end if;
							assert BEX(151 downto 143) = "001000000" severity error;
							report "BEX_in = " & to_string(BEX(151 downto 143)) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
							
				when 9 =>	--Teste da decima instru��o do programa swap: Jal zero, fim	   ==> 100 ns
							MemRead_ex 		<= '0';
							rd_ex			<= "00000";
							ULA_ex			<= x"00000000"; 
							rd_mem			<= "00111";	
							ula_mem 		<= x"00000010";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 1 decima instru��o: Verificando leitura de RA est� no buffer de sa�da" severity note;
							if RA = x"00000000" then                 
       							report "Teste 1 da decima instru��o est� correto" severity warning;                         
							end if;                                                     
							assert RA = x"00000000" severity error;
							report "RA = " & to_hex_string(RA) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 2 decima instru��o: Verificando leitura de RB" severity note;
							if RB = x"00000000" then
								report "Teste 2 da decima instru��o est� correto" severity warning;
							end if;
        					assert RB = x"00000000" severity error;
							report "RB = " & to_hex_string(RB) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 3 decima instru��o: Verificando que Imed est� no buffer de sa�da" severity note;
							if Imed = x"00000000" then
								report "Teste 3 da decima instru��o est� correto" severity warning;
							end if;
       						assert Imed = x"00000000" severity error;
							   report "Imed = " & to_hex_string(Imed) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 4 decima instru��o: Verificando que PC_id est� no buffer de sa�da: 90 ns" severity note;     
							if PC_id = x"0000001C" then                       
								report "Teste 4 da decima instru��o est� correto" severity warning;                               
        					end if;                                                      
	    					assert PC_id = x"0000001C" severity error;
							report "PC_id = " & to_hex_string(PC_id) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 5 decima instru��o: Verificando que rs1 est� no buffer de sa�da" severity note;
							if reg_rs1 = "00101" then  -- 
								report "Teste 5 da decima instru��o est� correto" severity warning;
							end if;
        					assert reg_rs1 = "00101" severity error;
							report "reg_rs1 = " & to_hex_string(reg_rs1) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 6 decima instru��o: Verificando que rs2 est� no buffer de sa�da" severity note;
							if reg_rs2 = "00000" then
								report "Teste 6 da decima instru��o est� correto" severity warning;
							end if;
        					assert reg_rs2 = "00000" severity error;
							report "reg_rs2 = " & to_hex_string(reg_rs2) severity warning;
							report "=================================================================================  " severity warning;
							
							report "TESTE 7 decima instru��o: Verificando que rd est� no buffer de sa�da" severity note;
							if reg_rd = "00110" then
								report "Teste 7 da decima instru��o est� correto" severity warning;
							end if;
        					assert reg_rd = "00110" severity error;
							report "reg_rd = " & to_hex_string(reg_rd) severity warning;
							report "=================================================================================  " severity warning;
							
							assert BEX = x"6C18050000001C000000000000000000000000" severity error;
							report "BEX = " & to_hex_string(BEX) severity warning;
							report "#################################################################################  " severity warning;
							
							report "BEX_in = " & to_hex_string(BEX(151 downto 143)) severity warning;
							if BEX(151 downto 143) = "011011000"then
								report "TESTE 8: decima instru��o Sinais de controle ==> EST�0 CORRETOs" severity warning;
							else
								report "Teste 8: decima instru��o Sinais de controle ==> EST�0 ERRADOS" severity error;
							end if;
							assert BEX(151 downto 143) = "011011000" severity error;
							report "BEX_in = " & to_string(BEX(151 downto 143)) severity warning;
							report "#################################################################################  " severity warning;
							report "#################################################################################  " severity warning;
							
							
				when 10 => 	--Terminaram as instru��es do programa 
							rs1_id_ex		<= "00000";
							rs2_id_ex		<= "00110";
							rd_mem			<= "00000";
							MemRead_mem 	<= '0';
							ula_mem 		<= x"00000000";
							report "  ";
							report "=================================================================================  " severity warning;
							report "Count = " & to_string(count) severity warning;
							report "=================================================================================  " severity warning;
							
							null;
				
				when 11 => rs1_id_ex <= "00000";
				when 12 => rs1_id_ex <= "00000";
				when 13 => rs1_id_ex <= "00000";
				when others => keep_simulating <= false;
			end case;
			count := count + 1;
        end if;
		eof       <= '1';
   		file_close(fptr);
		
    end process;
	
end architecture;
