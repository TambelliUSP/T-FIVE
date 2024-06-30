library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

library work;
use work.tipos.all;

-- O estagio de decodificacao e leitura de registradores (id) deve realizar a decodificacao 
-- da instrucao lida no estagio de
-- busca (if) e produzir os sinais de controle necessarios para este estagio, assim como para todos os 
-- demais estagios a seguir.
-- Alem disso ele deve realizar a descisao dos desvios condicionais assim como calcular o endereco de 
-- destino para executar essas instrucoes.
-- Lembrar que no Pipeline com deteccao de Hazards e antecipacao ("Forwarding"), existirao sinais que
-- influenciarao as decisoes tomadas neste estagio.
-- Neste estagio deve ser feita tambem a geracao dos valores imediatos para todas as instrucoes. 
-- Atencao especial deve ser dada a esses imediatos pois o RISK-V optou por embaralhar os 
-- imediatos para manter todos os enderecos de regostradores nas instrucoes nas mesmas posicoes 
-- na instrucao. 
-- As informacoes passadas deste estagio para os seguintes devem ser feitas por meio de um 
-- registrador (BID). Para
-- identificar claramente cada campo desse registrador pode-se utilizar o mecanismo do VHDL de definicao 
-- de apelidos ("alias").
-- Foi adicionado um sinal para fins de ilustracao chamado COP_id que identifica a instrucao sendo 
-- processada pelo estagio.
-- Neste estagio deve ser implementado tambem o modulo de deteccao de conflitos - Hazards.
-- Devem existir diversos sinais vindos do outros modulos que sao necessarios para a relizacao das 
-- funcoes alocadas a este estagio de decodificacao - id.
-- A definicao dos sinais vindos de outros modulos encontra-se nos comentarios da declaracao de 
-- entidade do estagio id.

entity estagio_id is
    port(
		-- Entradas
		clock				: in 	std_logic; 						-- Base de tempo- bancada de teste
		BID					: in 	std_logic_vector(63 downto 0);	-- Informacoes vindas estagio Busca
		MemRead_ex			: in	std_logic;						-- Leitura de memoria no estagio ex
		rd_ex				: in	std_logic_vector(4 downto 0);	-- Destino nos regs. no estagio ex
		ula_ex				: in 	std_logic_vector(31 downto 0);	-- Saida da ULA no estagio Ex
		MemRead_mem			: in	std_logic;						-- Leitura na mem�ria no estagio mem
		rd_mem				: in	std_logic_vector(4 downto 0);	-- Escrita nos regs. no estagio mem
		ula_mem				: in 	std_logic_vector(31 downto 0);	-- Saida da ULA no estagio Mem 
		NPC_mem				: in	std_logic_vector(31 downto 0);  -- Valor do NPC no estagio mem
		RegWrite_wb			: in 	std_logic; 						-- Escrita no RegFile vindo de wb
		writedata_wb		: in 	std_logic_vector(31 downto 0);	-- Valor escrito no RegFile - wb
		rd_wb				: in 	std_logic_vector(4 downto 0);	-- Endereco do registrador escrito
		ex_fw_A_Branch		: in 	std_logic_vector(1 downto 0);	-- Selecao de Branch forwardA
		ex_fw_B_Branch		: in 	std_logic_vector(1 downto 0);	-- Selecao de Branch forwardB 
		
		-- Saidas
		id_Jump_PC			: out	std_logic_vector(31 downto 0) := x"00000000";-- Destino JUmp/Desvio
		id_PC_src			: out	std_logic := '0';				-- Seleciona a entrado do PC
		id_hd_hazard		: out	std_logic := '0';				-- Preserva o if_id e nao inc. PC
		id_Branch_nop		: out	std_logic := '0';				-- Insercao de um NOP devido ao Branch. Limpa o if_id.ri
		rs1_id_ex			: out	std_logic_vector(4 downto 0);	-- Endereco rs1 no estagio id
		rs2_id_ex			: out	std_logic_vector(4 downto 0);	-- Endereco rs2 no estagio id
		BEX					: out 	std_logic_vector(151 downto 0) := (others => '0');-- Saida do ID > EX
		COP_id				: out	instruction_type  := NOP;		-- Instrucao no estagio id
		COP_ex				: out 	instruction_type := NOP			-- Instrucao no estagio id passada> EX
    );
end entity;

architecture behave of estagio_id is
	component regfile is
		port(
			-- Entradas
			clock			: 	in 		std_logic;						-- Base de tempo - Bancada de teste
			RegWrite		: 	in 		std_logic; 						-- Sinal de escrita no RegFile
			read_reg_rs1	: 	in 		std_logic_vector(04 downto 0);	-- Endereco do registrador na saida RA
			read_reg_rs2	: 	in 		std_logic_vector(04 downto 0);	-- Endereco do registrador na saida RB
			write_reg_rd	: 	in 		std_logic_vector(04 downto 0);	-- Endereco do registrador a ser escrito
			data_in			: 	in 		std_logic_vector(31 downto 0);	-- Valor a ser escrito no registrador
			
			-- Saidas
			data_out_a		: 	out 	std_logic_vector(31 downto 0);	-- Valor lido pelo endereco rs1
			data_out_b		: 	out 	std_logic_vector(31 downto 0) 	-- Valor lido pelo endereco rs2
		);
	end component;
    
    -- Alias para sinais vindos do BID
    alias ri_if is BID(31 downto 0);
	alias PC_id is BID(63 downto 32);

	signal ri_id: std_logic_vector(31 downto 0) := x"00000000";

    -- Alias para sinais a serem redirecionados para o BEX
    -- alias RA_id is BEX(31 downto 0);
    -- alias RB_id is BEX(63 downto 0);
    -- alias Imed_id is BEX(95 downto 64);
    -- alias PC_id_Plus4 is BEX(127 downto 96);
    -- alias rs1_id is BEX(132 downto 128);
    -- alias rs2_id is BEX(137 downto 133);
    -- alias rd_id is BEX(142 downto 138);
    -- alias Aluop_id is BEX(145 downto 143);
    -- alias AluSrc_id is BEX(146);
    -- alias Memread_id is BEX(147);
    -- alias Memwrite_id is BEX(148);
    -- alias RegWrite_id is BEX(149);
    -- alias MemtoReg_id is BEX(151 downto 150);

    signal RA_id, RB_id, Imed_id, PC_id_Plus4: std_logic_vector(31 downto 0) := x"00000000";
    signal rs1_id, rs2_id, rd_id: std_logic_vector(4 downto 0) := "00000";
    signal Aluop_id: std_logic_vector(2 downto 0) := "000";
    signal AluSrc_id, Memread_id, Memwrite_id, RegWrite_id: std_logic := '0';
    signal MemtoReg_id: std_logic_vector(1 downto 0) := "00";

	signal controls_id: std_logic_vector(12 downto 0) := "0000000000000";
	signal opcode_id: std_logic_vector(6 downto 0) := "0000000";
	signal funct3_id: std_logic_vector(2 downto 0) := "000";
	signal funct7_id: std_logic_vector(6 downto 0) := "0000000";
	signal RtypeSub_id, PC_Src_id_if: std_logic;
	signal COP_id_signal: instruction_type := NOP;

	signal aluop_type_id: std_logic;
	signal hd_id_flush: std_logic := '0';
	signal branch_id, beq_id, bne_id, blt_id, jump_id, invalid_instr_id: std_logic;
	signal branch_accepted_id: std_logic;
	signal immSrc_id: std_logic_vector(2 downto 0);

	signal branch_operator_A_id, branch_operator_B_id: std_logic_vector(31 downto 0) := x"00000000"; 
begin
	ri_id <= ri_if;

    rs1_id <= ri_id(19 downto 15);
    rs2_id <= ri_id(24 downto 20);
    rd_id <= ri_id(11 downto 7);
	opcode_id <= ri_id(6 downto 0);
	funct3_id <= ri_id(14 downto 12);
	funct7_id <= ri_id(31 downto 25);

	PC_id_Plus4 <= PC_id + x"00000004";

	Imed_id <= 	(31 downto 12 => ri_id(31)) & ri_id(31 downto 20) when immSrc_id = "100" else -- I-type
				(31 downto 12 => ri_id(31)) & ri_id(31 downto 25) & ri_id(11 downto 7) when immSrc_id = "101" else -- S-type
				(31 downto 12 => ri_id(31)) & ri_id(7) & ri_id(30 downto 25) & ri_id(11 downto 8) & '0' when immSrc_id = "110" else -- B-type
			   	(31 downto 20 => ri_id(31)) & ri_id(19 downto 12) & ri_id(20) & ri_id(30 downto 21) & '0' when immSrc_id = "111" else -- J-type
			   	x"00000000";
    
    COP_id_signal <= ADD when (ri_id(14 downto 12) = "000" and ri_id(6 downto 0) = "0110011") else
        SLT when (ri_id(14 downto 12) = "010" and ri_id(6 downto 0) = "0110011") else
        ADDI when (ri_id(14 downto 12) = "000" and ri_id(6 downto 0) = "0010011") else
        SLTI when (ri_id(14 downto 12) = "010" and ri_id(6 downto 0) = "0010011") else
        SLLI when (ri_id(14 downto 12) = "001" and ri_id(6 downto 0) = "0010011") else
        SRLI when (ri_id(31 downto 25) = "0000000" and ri_id(14 downto 12) = "101" and ri_id(6 downto 0) = "0010011") else
        SRAI when (ri_id(31 downto 25) = "0100000" and ri_id(14 downto 12) = "101" and ri_id(6 downto 0) = "0010011") else
        LW when (ri_id(14 downto 12) = "010" and ri_id(6 downto 0) = "0000011") else
        SW when (ri_id(14 downto 12) = "010" and ri_id(6 downto 0) = "0100011") else
        BEQ when (ri_id(14 downto 12) = "000" and ri_id(6 downto 0) = "1100011") else
        BNE when (ri_id(14 downto 12) = "001" and ri_id(6 downto 0) = "1100011") else
        BLT when (ri_id(14 downto 12) = "100" and ri_id(6 downto 0) = "1100011") else
        HALT when (ri_id = x"0000006F") else
        JAL when (ri_id(14 downto 12) = "000" and ri_id(6 downto 0) = "1101111") else
        JALR when (ri_id(14 downto 12) = "000" and ri_id(6 downto 0) = "1100111") else
        NOP when (ri_id = x"00000000") else
        NOINST;
	
	COP_id <= COP_id_signal;
	
	UC_PROC: process(opcode_id, hd_id_flush) 
		begin
			case hd_id_flush is
				when '1' => controls_id <= "0000000000000"; -- NOP
				when others =>
					case opcode_id is
						when "0000011" => controls_id <= "0010001101100"; -- lw
						when "0100011" => controls_id <= "0010100010100"; -- sw
						when "0110011" => controls_id <= "0000000100010"; -- R-type
						when "1100011" => controls_id <= "1011000000000"; -- B-type
						when "0010011" => controls_id <= "0010000100110"; -- I-type ALU
						when "1101111" => controls_id <= "0111110100000"; -- jal
						when "1100111" => controls_id <= "0110010100000"; -- jalr
						when "0000000" => controls_id <= "0000000000000"; -- NOP
						when others => controls_id <= "1111111111111"; -- not valid
					end case;
			end case;
		end process;
	(branch_id, jump_id, immSrc_id(2), immSrc_id(1), immSrc_id(0), MemtoReg_id(1), MemtoReg_id(0), RegWrite_id, Memwrite_id, Memread_id,
	AluSrc_id, aluop_type_id, invalid_instr_id) <= controls_id;

	UC_ALU_DECODER_PROC: process(funct3_id, funct7_id(5), aluop_type_id)
		begin
			case aluop_type_id is
				when '0' => ALUOp_id <= "000"; -- addition
				when others => 
					case funct3_id is -- R-type or I-type ALU
						when "000" => ALUOp_id <= "000"; -- add, addi
						when "010" => ALUOp_id <= "010"; -- slt, slti
						when "001" => ALUOp_id <= "011"; -- slli
						when "101" => if funct7_id(5) = '1' then ALUOp_id <= "101"; -- srai
						else                   ALUOp_id <= "100"; -- srli
						end if;
						when others => ALUOp_id <= "111"; -- unknown
					end case;
			end case;
		end process;

	-- Branch Control Logic
	beq_id <= 	'1' when funct3_id = "000" else
			  	'0';
	bne_id <= 	'1' when funct3_id = "001" else
				'0';
	blt_id <= 	'1' when funct3_id = "100" else
				'0';

	-- Branch Forwarding logic
	branch_operator_A_id <= RA_id when ex_fw_A_Branch="00" else
							ula_ex when ex_fw_A_Branch="10" else
							ula_mem when ex_fw_A_Branch="01" else
							NPC_mem;

	branch_operator_B_id <=	RB_id when ex_fw_B_Branch="00" else
							ula_ex when ex_fw_B_Branch="10" else
							ula_mem when ex_fw_B_Branch="01" else
							NPC_mem;

	branch_accepted_id <=	'1' when (beq_id='1' and branch_operator_A_id=branch_operator_B_id) or (bne_id='1' and not(branch_operator_A_id=branch_operator_B_id)) or (blt_id='1' and branch_operator_A_id<branch_operator_B_id) else
							'0';

	PC_Src_id_if <= jump_id or invalid_instr_id or (branch_id and branch_accepted_id) when hd_id_flush='0' else
					'0';

	MAIN_PROC: process(clock)
		begin
			if(clock'event and clock='1') then
				BEX <= MemtoReg_id & Regwrite_id & Memwrite_id & Memread_id & AluSrc_id & Aluop_id & rd_id & rs2_id & rs1_id & PC_id_Plus4 & Imed_id & RB_id & RA_id;
				COP_EX <= COP_id_signal;
			end if;
		end process;

	-- Hazard unit Logic
	hd_id_flush <= 		'1' when (MemRead_ex = '1' and (rd_ex = rs1_id or rd_ex = rs2_id)) or (MemRead_mem='1' and branch_id='1' and (rd_mem = rs1_id or rd_mem = rs2_id)) else
						'0';
	
	id_hd_hazard <= 	'1' when (MemRead_ex = '1' and (rd_ex = rs1_id or rd_ex = rs2_id)) or (MemRead_mem='1' and branch_id='1' and (rd_mem = rs1_id or rd_mem = rs2_id)) else
						'0';

	id_Branch_nop <=	'1' when PC_Src_id_if = '1' else
					 	'0';

	REGFILE_MAP: regfile
        port map(
			clock			=> clock,
			RegWrite		=> RegWrite_wb,
			read_reg_rs1	=> rs1_id,
			read_reg_rs2	=> rs2_id,
			write_reg_rd	=> rd_wb,
			data_in			=> writedata_wb,
			data_out_a		=> RA_id,
			data_out_b		=> RB_id
        );

	-- Logica de atribuicao do id_PC_Src e id_Jump_PC 
	id_PC_Src <= PC_Src_id_if;
	id_Jump_Pc <= 	x"00000400" when invalid_instr_id='1' else
					RA_id + Imed_id when jump_id='1' and immSrc_id="00"  else -- jalr
				  	PC_id + Imed_id  when jump_id='1' or branch_id='1' else -- jal and B-type
				  	x"00000000";

	rs1_id_ex <= rs1_id;
	rs2_id_ex <= rs2_id;
end architecture;
