--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    : in std_logic;
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	signal w_clk_slow       : std_logic;
    signal w_btnC_action    : std_logic;

    signal w_cycle          : std_logic_vector(3 downto 0);

    signal w_reg_A          : std_logic_vector(7 downto 0);
    signal w_reg_B          : std_logic_vector(7 downto 0);

    signal w_alu_result     : std_logic_vector(7 downto 0);
    signal w_alu_flags      : std_logic_vector(3 downto 0);

    signal w_display_value  : std_logic_vector(7 downto 0);

    signal w_sign           : std_logic;
    signal w_hund           : std_logic_vector(3 downto 0);
    signal w_tens           : std_logic_vector(3 downto 0);
    signal w_ones           : std_logic_vector(3 downto 0);

    signal w_sign_digit     : std_logic_vector(3 downto 0);
    signal w_tdm_data       : std_logic_vector(3 downto 0);
    signal w_tdm_sel        : std_logic_vector(3 downto 0);

    constant k_BLANK        : std_logic_vector(3 downto 0) := x"F";
    constant k_MINUS        : std_logic_vector(3 downto 0) := x"C";
    
    component clock_divider is
        generic ( constant k_DIV : natural := 2 );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            o_clk    : out std_logic
        );
    end component clock_divider;

    component button_debounce is
        Port(
            clk     : in  STD_LOGIC;
            reset   : in  STD_LOGIC;
            button  : in  STD_LOGIC;
            action  : out STD_LOGIC
        );
    end component button_debounce;

    component controller_fsm is
        Port (
            i_clk   : in STD_LOGIC;
            i_reset : in STD_LOGIC;
            i_adv   : in STD_LOGIC;
            o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component controller_fsm;

    component ALU is
        Port (
            i_A      : in STD_LOGIC_VECTOR (7 downto 0);
            i_B      : in STD_LOGIC_VECTOR (7 downto 0);
            i_op     : in STD_LOGIC_VECTOR (2 downto 0);
            o_result : out STD_LOGIC_VECTOR (7 downto 0);
            o_flags  : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component ALU;

    component twos_comp is
        port (
            i_bin   : in std_logic_vector(7 downto 0);
            o_sign  : out std_logic;
            o_hund  : out std_logic_vector(3 downto 0);
            o_tens  : out std_logic_vector(3 downto 0);
            o_ones  : out std_logic_vector(3 downto 0)
        );
    end component twos_comp;

    component TDM4 is
        generic ( constant k_WIDTH : natural := 4 );
        Port (
            i_clk   : in  STD_LOGIC;
            i_reset : in  STD_LOGIC;
            i_D3    : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D2    : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D1    : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D0    : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            o_data  : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            o_sel   : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component TDM4;

    component sevenseg_decoder is
        port (
            i_Hex   : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;

  
begin
	-- PORT MAPS ----------------------------------------
clk_div_inst : clock_divider
        generic map ( k_DIV => 50000 )
        port map (
            i_clk   => clk,
            i_reset => btnL,
            o_clk   => w_clk_slow
        );

    debounce_inst : button_debounce
        port map (
            clk     => clk,
            reset   => btnU,
            button  => btnC,
            action  => w_btnC_action
        );

    fsm_inst : controller_fsm
        port map (
            i_clk   => clk,
            i_reset => btnU,
            i_adv   => w_btnC_action,
            o_cycle => w_cycle
        );

    alu_inst : ALU
        port map (
            i_A      => w_reg_A,
            i_B      => w_reg_B,
            i_op     => sw(2 downto 0),
            o_result => w_alu_result,
            o_flags  => w_alu_flags
        );

    twos_comp_inst : twos_comp
        port map (
            i_bin  => w_display_value,
            o_sign => w_sign,
            o_hund => w_hund,
            o_tens => w_tens,
            o_ones => w_ones
        );

    tdm_inst : TDM4
        generic map ( k_WIDTH => 4 )
        port map (
            i_clk   => clk,
            i_reset => btnU,
            i_D3    => w_sign_digit,
            i_D2    => w_hund,
            i_D1    => w_tens,
            i_D0    => w_ones,
            o_data  => w_tdm_data,
            o_sel   => w_tdm_sel
        );

    seg_dec_inst : sevenseg_decoder
        port map (
            i_Hex   => w_tdm_data,
            o_seg_n => seg
        );
	
	register_proc : process(clk)
    begin
        if rising_edge(clk) then
            if btnU = '1' then
                w_reg_A <= (others => '0');
                w_reg_B <= (others => '0');
            else
                if w_cycle = "0010" then
                    w_reg_A <= sw;
                elsif w_cycle = "0100" then
                    w_reg_B <= sw;
                end if;
            end if;
        end if;
    end process register_proc;
    
	-- CONCURRENT STATEMENTS ----------------------------
	
	w_display_value <= w_reg_A      when w_cycle = "0010" else
                       w_reg_B      when w_cycle = "0100" else
                       w_alu_result when w_cycle = "1000" else
                       "00000000";

    w_sign_digit <= k_MINUS when w_sign = '1' and w_cycle /= "0001" else
                    k_BLANK;

    an <= "1111" when w_cycle = "0001" else
          w_tdm_sel;

    led(3 downto 0) <= w_cycle;
    led(15 downto 12) <= w_alu_flags;
    led(11 downto 4) <= (others => '0');
	
	
end top_basys3_arch;
