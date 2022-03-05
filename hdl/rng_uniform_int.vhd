-- ****************************************************************************
-- taus88.vhd --
--
--     Random number generator meant to generate uniform integers within a
--     range based on an input from a taus88
--
-- Author(s):
--     Christopher Crary (ccrary@ufl.edu), Jared Herbert (jaredherbert@ufl.edu), 
--     Anna Raymaker (annaraymaker@ufl.edu)
--
-- Last Modified By:
--     Jared Herbert
--
-- Last Modified On:
--     March 3, 2022
-- ****************************************************************************

library arc_std;

context arc_std.std_context;

use arc_std.multiplier_pkg;
use arc_std.adder_pkg;

package rng_uniform_int_pkg is

  -- Return latency of overall entity.
  function get_latency return positive;

end package;

package body rng_uniform_int_pkg is
  
  function get_latency return positive is

    -- -- Latency of floating-point add.
    constant adder_latency : positive := adder_pkg.get_latency(float32_t);

    -- -- Latency of floating-point multiply.
    constant mult_latency : positive := multiplier_pkg.get_latency(float32_t);

    -- -- Latency of converter
    constant conv_latency : positive := 4;

  begin
    -- -- Overall latency.
    return (adder_latency + mult_latency + conv_latency);
    
  end function;

end package body;

--------------------------------------------------------------------------------

library arc_std;

context arc_std.std_context;

use arc_std.multiplier_pkg;
use arc_std.adder_pkg;
use arc_std.rng_uniform_int_pkg;

entity rng_uniform_int is
  port (
    clk           : in  std_logic;
    rst           : in  std_logic;
    rand_num_in   : in std_logic_vector(31 downto 0);
    scale         : in std_logic_vector(31 downto 0);
    offset        : in std_logic_vector(31 downto 0);
    valid_in      : in std_logic;
    rand_num_out  : out std_logic_vector(31 downto 0);
    valid_out     : out std_logic);
end rng_uniform_int;

architecture STR of rng_uniform_int is

  constant num_cycles_valid_delay : positive := rng_uniform_int_pkg.get_latency;
  constant mult_latency : positive := multiplier_pkg.get_latency(float32_t);   
   
  signal multiplier_out            : std_logic_vector(31 downto 0);
  signal offset_delay_out          : std_logic_vector(31 downto 0);
  signal adder_out                 : std_logic_vector(31 downto 0);

  component convert_float32_to_uint32 is
		port (
			clk    : in  std_logic                     := 'X';             -- clk
			areset : in  std_logic                     := 'X';             -- reset
			a      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- a
			q      : out std_logic_vector(31 downto 0)                     -- q
		);
	end component convert_float32_to_uint32;
  
begin

  -- Multiply input by the scale
  U_MULTIPLIER : entity arc_std.multiplier
    generic map (
      input1_type => float32_t,
      input2_type => float32_t)
    port map (
      clk    => clk,
      rst    => rst,
      input1 => rand_num_in,
      input2 => scale,
      output => multiplier_out);
	  
  -- Delay offset by multiplier latency
  U_OFFSET_DELAY : entity arc_std.delay
    generic map (
      data_type => float32_t,
      num_cycles => mult_latency)
    port map (
      clk => clk,
      input  => offset,
      output => offset_delay_out);	 

  -- Add offset to multiplier output
  U_ADDER : entity arc_std.adder
    generic map (
      input1_type => float32_t,
      input2_type => float32_t)
    port map (
      clk       => clk,
      rst       => rst,
      input1    => multiplier_out,
      input2    => offset_delay_out,
      output    => adder_out); 
 
  --convert final value to integer
  U_CONVERT_TO_UINT : convert_float32_to_uint32
    port map (
      clk => clk,
      areset => rst,
      a => adder_out,
      q => rand_num_out);
  
  --delay valid input signal by total latency of system
  U_VALID_DELAY : entity arc_std.delay
    generic map (
      num_cycles => num_cycles_valid_delay,
      use_valid  => true)
    port map (
      clk       => clk,
      valid_in  => valid_in,
      valid_out => valid_out);	

end STR;