----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity full_adder is
    Port ( A    : in STD_LOGIC;
           B    : in STD_LOGIC;
           Cin  : in STD_LOGIC;
           S    : out STD_LOGIC;
           Cout : out STD_LOGIC);
end full_adder;

architecture Behavioral of full_adder is
begin

    S    <= A xor B xor Cin;
    Cout <= (A and B) or (A and Cin) or (B and Cin);

end Behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ripple_adder_8bit is
    Port ( A    : in STD_LOGIC_VECTOR (7 downto 0);
           B    : in STD_LOGIC_VECTOR (7 downto 0);
           Cin  : in STD_LOGIC;
           S    : out STD_LOGIC_VECTOR (7 downto 0);
           Cout : out STD_LOGIC);
end ripple_adder_8bit;

architecture Behavioral of ripple_adder_8bit is

    component full_adder is
        Port ( A    : in STD_LOGIC;
               B    : in STD_LOGIC;
               Cin  : in STD_LOGIC;
               S    : out STD_LOGIC;
               Cout : out STD_LOGIC);
    end component;

    signal w_carry : STD_LOGIC_VECTOR(7 downto 0);

begin

-- PORT MAPS --------------------
    full_adder_0: full_adder
    port map(
        A    => A(0),
        B    => B(0),
        Cin  => Cin,
        S    => S(0),
        Cout => w_carry(0)
    );

    full_adder_1: full_adder
    port map(
        A    => A(1),
        B    => B(1),
        Cin  => w_carry(0),
        S    => S(1),
        Cout => w_carry(1)
    );

    full_adder_2: full_adder
    port map(
        A    => A(2),
        B    => B(2),
        Cin  => w_carry(1),
        S    => S(2),
        Cout => w_carry(2)
    );

    full_adder_3: full_adder
    port map(
        A    => A(3),
        B    => B(3),
        Cin  => w_carry(2),
        S    => S(3),
        Cout => w_carry(3)
    );

    full_adder_4: full_adder
    port map(
        A    => A(4),
        B    => B(4),
        Cin  => w_carry(3),
        S    => S(4),
        Cout => w_carry(4)
    );

    full_adder_5: full_adder
    port map(
        A    => A(5),
        B    => B(5),
        Cin  => w_carry(4),
        S    => S(5),
        Cout => w_carry(5)
    );

    full_adder_6: full_adder
    port map(
        A    => A(6),
        B    => B(6),
        Cin  => w_carry(5),
        S    => S(6),
        Cout => w_carry(6)
    );

    full_adder_7: full_adder
    port map(
        A    => A(7),
        B    => B(7),
        Cin  => w_carry(6),
        S    => S(7),
        Cout => w_carry(7)
    );

    Cout <= w_carry(7);

end Behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU is
    Port ( i_A      : in STD_LOGIC_VECTOR (7 downto 0);
           i_B      : in STD_LOGIC_VECTOR (7 downto 0);
           i_op     : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags  : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

    component ripple_adder_8bit is
        Port ( A    : in STD_LOGIC_VECTOR (7 downto 0);
               B    : in STD_LOGIC_VECTOR (7 downto 0);
               Cin  : in STD_LOGIC;
               S    : out STD_LOGIC_VECTOR (7 downto 0);
               Cout : out STD_LOGIC);
    end component;

    -- Declare signals here
    signal w_B        : STD_LOGIC_VECTOR(7 downto 0);
    signal w_Cin      : STD_LOGIC;
    signal w_sum      : STD_LOGIC_VECTOR(7 downto 0);
    signal w_Cout     : STD_LOGIC;
    signal w_result   : STD_LOGIC_VECTOR(7 downto 0);
    signal w_overflow : STD_LOGIC;

begin

-- ADDER CONTROL --------------------
    w_B <= i_B when i_op = "000" else
           not i_B when i_op = "001" else
           i_B;

    w_Cin <= '1' when i_op = "001" else
             '0';

-- PORT MAPS --------------------
    ripple_adder: ripple_adder_8bit
    port map(
        A    => i_A,
        B    => w_B,
        Cin  => w_Cin,
        S    => w_sum,
        Cout => w_Cout
    );

-- RESULT MUX --------------------
    with i_op select
        w_result <= w_sum         when "000",
                    w_sum         when "001",
                    i_A and i_B   when "010",
                    i_A or i_B    when "011",
                    "00000000"    when others;

-- OVERFLOW LOGIC --------------------
    w_overflow <= '1' when (i_op = "000" and i_A(7) = i_B(7) and w_sum(7) /= i_A(7)) else
                  '1' when (i_op = "001" and i_A(7) /= i_B(7) and w_sum(7) /= i_A(7)) else
                  '0';

-- OUTPUTS --------------------
    o_result <= w_result;

    -- Flags are NZCV
    o_flags(3) <= w_result(7);

    o_flags(2) <= '1' when w_result = "00000000" else
                  '0';

    o_flags(1) <= w_Cout when i_op = "000" or i_op = "001" else
                  '0';

    o_flags(0) <= w_overflow;

end Behavioral;