----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_clk   : in STD_LOGIC;
           i_reset : in STD_LOGIC;
           i_adv   : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    -- Declare FSM states here
    type sm_cycle is (clear_display, load_A, load_B, show_result);

    -- Declare signals here
    signal current_cycle : sm_cycle;
    signal next_cycle    : sm_cycle;

begin

-- NEXT STATE LOGIC --------------------
    next_cycle <= load_A        when current_cycle = clear_display and i_adv = '1' else
                  load_B        when current_cycle = load_A        and i_adv = '1' else
                  show_result   when current_cycle = load_B        and i_adv = '1' else
                  clear_display when current_cycle = show_result   and i_adv = '1' else
                  current_cycle;

-- OUTPUT LOGIC --------------------
    with current_cycle select
        o_cycle <= "0001" when clear_display,
                   "0010" when load_A,
                   "0100" when load_B,
                   "1000" when show_result,
                   "0001" when others;

-- STATE REGISTER --------------------
    state_register : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                current_cycle <= clear_display;
            else
                current_cycle <= next_cycle;
            end if;
        end if;
    end process state_register;

end FSM;