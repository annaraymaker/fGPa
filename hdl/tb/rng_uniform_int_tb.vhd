-- ****************************************************************************
-- rng_uniform_int_tb.vhd --
--
--     Testbench for `rng_uniform_int` entity.
--
-- Author(s):
--     Jared Herbert (jaredherbert@ufl.edu)
--
-- Last Modified By:
--     Jared Herbert
--
-- Last Modified On:
--     March 3, 2021
-- ****************************************************************************

library arc_std;
context arc_std.std_context;

use arc_std.rng_uniform_int_pkg.all;
use arc_std.taus88_pkg.all;

entity taus88_tb is
end taus88_tb;

architecture TB of rng_uniform_int_tb is

    --Simulation parameters
    constant num_cycles : positive := 5;
    constant taus88_latency : positive := taus88_pkg.get_latency;
    constant rng_latency : positive := rng_uniform_int_pkg.get_latency;
    constant total_latency : positive := rng_latency + taus88_latency;

    --Simulation signals
    signal done : std_logic := '0';

    -- Entity parameters
    signal clk           :  std_logic := '0';
    signal rst           :  std_logic := '1';
    signal rand_num_in   :  std_logic_vector(31 downto 0) := (others => '0');
    signal scale         :  std_logic_vector(31 downto 0) := (others => '0');
    signal offset        :  std_logic_vector(31 downto 0) := (others => '0');
    signal valid_in      :  std_logic := '0';

    signal rand_num_out  : std_logic_vector(31 downto 0);
    signal valid_out     : std_logic);

    -- Taus88 parameters
    signal seed1 : std_logic_vector(31 downto 0) := (others => '0');
    signal seed2 : std_logic_vector(31 downto 0) := (others => '0');
    signal seed3 : std_logic_vector(31 downto 0) := (others => '0');
    signal set_seeds : std_logic := '0';
    signal en : std_logic := '0';

    signal taus88_output : std_logic_vector(31 downto 0);

    -- Helper function
    function random_int_calculation (taus88_input : std_logic_vector(31 downto 0),
                                     offset : std_logic_vector(31 downto 0),
                                     scale  : std_logic_vector(31 downto 0))
                                     return integer is
    begin
        -- Integer output
        return to_integer(to_real(taus88_input, float32_t) * to_real(scale, float32_t) + to_real(offset, float32_t));
        
    end function;

begin

    -- Instantiate taus88 entity
    U_TAUS88 : entity arc_std.taus88
        port map (
            clk => clk,
            rst => rst,
            seed1 => seed1,
            seed2 => seed2,
            seed3 => seed3,
            set_seeds => set_seeds,
            en => en,
            output => taus88_output,
            valid_out => valid_in
        );

    -- Instantiate rng_uniform_int entity
    UUT : entity arc_std.rng_uniform_int
        port map (
            clk => clk,
            rst => rst,
            rand_num_in => rand_num_in,
            scale => scale,
            offset => offset,
            valid_in => valid_in,
            rand_num_out => rand_num_out,
            valid_out => valid_out
        );

    -- Clock driver statement
    clk <= not clk after 10 ns when done = '0' else clk;

    process

    begin

        -- Reset design for, arbitrarily, `num_cycles` clock cycles.
        for j in 0 to num_cycles-1 loop
            wait until rising_edge(clk);
        end loop;

        rst <= '0';

        -- Do not send inputs for `num_cycles` clock cycles.
        en <= '0';

        for j in 0 to num_cycles-1 loop
            wait until rising_edge(clk);
        end loop;

        -- Set seeds
        en <= '1';
        set_seeds <= '1';
        seed1 <= x"59F57B02";
        seed2 <= x"E10D3B9E";
        seed3 <= x"D0978CB9";

        wait until rising_edge(clk);

        set_seeds <= '0';

        for j in 0 to  loop
            wait until rising_edge(clk);
        end loop;
    end process;

end TB;