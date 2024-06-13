------------------------------------------------------------------
-- Arquivo   : mux_2x1_n.vhd
-- Projeto   : Experiencia 4 - Trena Digital com Saida Serial
------------------------------------------------------------------
-- Descricao : multiplexador 4x1  
-- > parametro BITS: numero de bits das entradas
--
-- > adaptado a partir do codigo my_4t1_mux.vhd 
-- > do livro "Free Range VHDL" 
--
------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor             Descricao
--     20/09/2019  1.0     Edson Midorikawa  versao inicial
--     31/08/2022  2.0     Edson Midorikawa  revisao do codigo
--     17/09/2023  2.1     Edson Midorikawa  revisao
------------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;

entity mux_2x1_n is
    generic (
        constant BITS: integer := 4
    );
    port(
        D1      : in  std_logic_vector (BITS-1 downto 0);
        D0      : in  std_logic_vector (BITS-1 downto 0);
        SEL     : in  std_logic;
        MUX_OUT : out std_logic_vector (BITS-1 downto 0)
    );
end entity mux_2x1_n;

architecture arch_mux_2x1_n of mux_2x1_n is
begin

    MUX_OUT <= D1 when (SEL = '1') else
               D0 when (SEL = '0') else
               (others => '1');

end architecture arch_mux_2x1_n;
