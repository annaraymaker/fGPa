-- ****************************************************************************
-- taus88_tb.vhd --
--
--     Testbench for `taus88` entity.
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

use arc_std.taus88_pkg.all;

entity taus88_tb is
end taus88_tb;


architecture TB of taus88_tb is

    --Simulation parameters
    constant num_cycles : positive := 5;

    --Simulation signals
    signal done : std_logic := '0';

    -- Entity signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal seed1 : std_logic_vector(31 downto 0) := (others => '0');
    signal seed2 : std_logic_vector(31 downto 0) := (others => '0');
    signal seed3 : std_logic_vector(31 downto 0) := (others => '0');
    signal set_seeds : std_logic := '0';
    signal en : std_logic := '0';

    signal output : std_logic_vector(31 downto 0);
    signal valid_out : std_logic;

begin --TB

    -- Instantiate taus88 entity
    UUT : entity arc_std.taus88
        port map (
            clk => clk,
            rst => rst,
            seed1 => seed1,
            seed2 => seed2,
            seed3 => seed3,
            set_seeds => set_seeds,
            en => en,
            output => output,
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

        for j in 0 to 5 loop
            wait until rising_edge(clk);
        end loop;

        en <= '0';

        for j in 0 to 5 loop
            wait until rising_edge(clk);
        end loop;

        en <= '1';

        for j in 0 to 5 loop
            wait until rising_edge(clk);
        end loop;

        report "Simulation complete!";
        done <= '1';
        wait;

    end process;

end TB;