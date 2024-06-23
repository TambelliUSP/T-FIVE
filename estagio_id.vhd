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

begin

end architecture;