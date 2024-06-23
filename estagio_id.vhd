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
		NPC_mem				: in	std_logic_vector(31 downto 0); -- Valor do NPC no estagio mem
		RegWrite_wb			: in 	std_logic; 						-- Escrita no RegFile vindo de wb
		writedata_wb		: in 	std_logic_vector(31 downto 0);	-- Valor escrito no RegFile - wb
		rd_wb				: in 	std_logic_vector(4 downto 0);	-- Endereco do registrador escrito
		ex_fw_A_Branch		: in 	std_logic_vector(1 downto 0);	-- Selecao de Branch forwardA
		ex_fw_B_Branch		: in 	std_logic_vector(1 downto 0);	-- Selecao de Branch forwardB 
		
		-- Saidas
		id_Jump_PC			: out	std_logic_vector(31 downto 0) := x"00000000";-- Destino JUmp/Desvio
		id_PC_src			: out	std_logic := '0';				-- Seleciona a entrado do PC
		id_hd_hazard		: out	std_logic := '0';				-- Preserva o if_id e nao inc. PC
		id_Branch_nop		: out	std_logic := '0';				-- Insercao de um NOP devido ao Branch. 
																	-- limpa o if_id.ri
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
    alias PC_id is BID(31 downto 0);
    alias ri_id is BID(63 downto 32);

    -- Alias para sinais a serem redirecionados para o BEX
    alias RA_id is BEX(31 downto 0);
    alias RB_id is BEX(63 downto 0);
    alias Imed_id is BEX(95 downto 64);
    alias PC_id_Plus4 is BEX(127 downto 96);
    alias rs1_id is BEX(132 downto 128);
    alias rs2_id is BEX(137 downto 133);
    alias rd_id is BEX(142 downto 138);
    alias Aluop_id is BEX(145 downto 143);
    alias AluSrc_id is BEX(146);
    alias Memread_id is BEX(147);
    alias Memwrite_id is BEX(148);
    alias RegWrite_id is BEX(149);
    alias MemtoReg_id is BEX(151 downto 150);

    signal RA_id, RB_id, Imem_id, PC_id_Plus4: std_logic_vector(31 downto 0) := x"00000000";
    signal rs1_id, rs2_id, rd_id: std_logic_vector(31 downto 0) := "00000";
    signal Aluop_id: std_logic_vector(2 downto 0) := "00";
    signal AluSrc_id, Memread_id, Memwrite_id, RegWrite_id: std_logic := '0';
    signal MemtoReg_id: std_logic_vector(1 downto 0) := "00";

begin
    rs1_id <= ri_id(19 downto 15);
    rs2_id <= ri_id(24 downto 20);
    rd_id <= ri_id()
    
    COP_id <= ADD when (ri_id(14 downto 12) = "000" and ri_id(6 downto 0) = "0110011") else
        SLT when (ri_id(14 downto 12) = "010" and ri_id(6 downto 0) = "0110011") else
        ADDI when (ri_id(14 downto 12) = "000" and ri_id(6 downto 0) = "0010011") else
        SLTI when (ri_id(14 downto 12) = "010" and ri_id(6 downto 0) = "0010011") else
        SLLI when (ri_id(14 downto 12) = "001" and ri_id(6 downto 0) = "0010011") else
        SRLI when (ri_id(31 downto 25) = "0000000" and ri_id(14 downto 12) = "101" and ri_id(6 downto 0) = "0010011") else
        SRAI when (ri_id(31 downto 25) = "0100000" and ri_id(14 downto 12) = "101" and ri_id(6 downto 0) = "0010011") else
        LW when (ri_id(14 downto 12) = "010" and ri_id(6 downto 0) = "0000011") else
        SW when (ri_id(14 downto 12) = "010" and ri_id(6 downto 0) = "0100011") else
        BEQ when (ri_id(14 downto 12) = "000" and ri_id(6 downto 0) = "1100011") else
        BNE when (ri_id(14 downto 12) = "001" and ri_id(6 downto 0) = "0000000") else
        BLT when (ri_id(14 downto 12) = "100" and ri_id(6 downto 0) = "0000000") else
        HALT when (ri_id = x"0000006F") else
        JAL when (ri_id(14 downto 12) = "000" and ri_id(6 downto 0) = "1101111") else
        JALR when (ri_id(14 downto 12) = "000" and ri_id(6 downto 0) = "1100111") else
        NOP when (ri_id = x"00000000") else
        NOINST;
	
	signal controls: std_logic_vector(10 downto 0);
	UC_PROC: process(op) 
		begin
			case op is
				when "0000011" => controls <= "10010010000"; -- lw
				when "0100011" => controls <= "00111000000"; -- sw
				when "0110011" => controls <= "1--00000100"; -- R-type
				when "1100011" => controls <= "01000001010"; -- beq
				when "0010011" => controls <= "10010000100"; -- I-type ALU
				when "1101111" => controls <= "11100100001"; -- jal
				when others => controls <= "11111111111"; -- not valid
			end case;
		end process;
	(RegWriteD, ImmSrcD(1), ImmSrcD(0), ALUSrcD, MemWriteD,
	ResultSrcD(1), ResultSrcD(0), AlUOp_id(2), ALUOp_id(1), ALUOp_id(0), AluSrc_id,
	Memread, ) <= controls;


	
	RtypeSub <= funct7b5 and opb5; -- TRUE for R–type subtract
	UC_PROC_2: process(opb5, funct3, funct7b5, ALUOp, RtypeSub) 
		begin
			case ALUOp is
				when "00" => ALUControlD <= "000"; -- addition
				when "01" => ALUControlD <= "001"; -- subtraction
				when others => 
					case funct3 is -- R-type or I-type ALU
						when "000" => if RtypeSub = '1' then ALUControlD <= "001"; -- sub
									else                   ALUControlD <= "000"; -- add, addi
									end if;
						when "010" => ALUControlD <= "101"; -- slt, slti
						when "110" => ALUControlD <= "011"; -- or, ori
						when "111" => ALUControlD <= "010"; -- and, andi
						when others => ALUControlD <= "---"; -- unknown
					end case;
			end case;
    	end process;

	MAIN_PROC:

	HAZARD_PROC:

	REGFILE : regfile
        port map(
			RegWrite		=> RegWrite_wb,
			read_reg_rs1	=> rs1_id,
			read_reg_rs2	=> rs2_id,
			write_reg_rd	=> rd_wb,
			data_in			=> writedata_wb,
			data_out_a		=> RA_id,
			data_out_b		=> RB_id
        );
end architecture;