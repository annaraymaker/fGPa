-- ****************************************************************************
-- taus88.vhd --
--
--     Tauseworthe-88 pseudorandom number generator (RNG).
--
--     This RNG is based on the paper "MAXIMALLY EQUIDISTRIBUTED
--     COMBINED TAUSWORTHE GENERATORS" by PIERRE L'sECUYER.
--
--
-- Usage (TODO: CHANGE FOR THIS ENTITY!!!):
--
--     > Two sets of inputs are to be multiply-accumulated, and the overall
--       MAC result is to be fed out of the `output` port. The generics
--       `input1_type` and `input2_type` specify the type of input
--       data that is to be multiply-accumulated. These two inputs must
--       have the same base data type, but if the base data type is
--       `unsigned_t` or `signed_t`, the width of each input may be
--       different. For a list of the data types currently supported, see
--       the definition of the `type_t` type in the `type_pkg` package file.
--
--     > The generic `num_inputs` defines the number of inputs within
--       *each* input set, *not* the total number of inputs.
--       For example, if sixteen pairs of inputs are to be multiply-
--       accumulated, the value `16`, not `32`, should be specified
--       for `num_inputs`.
--
--     > The generic `num_inputs_per_cycle` defines the number of inputs
--       from *each* input set that will be fed into the accumulator at
--       any given time, by way of the `input1` and `input2` ports. It
--       must be ensured that `num_inputs_per_cycle` is less than or
--       equal to `num_inputs`.
--
--     > A parallel accumulator is to be utilized whenever
--       `num_inputs_per_cycle` is greater than one, and a sequential
--       accumulator is to be utilized whenever `num_inputs_per_cycle`
--       is less than `num_inputs`. (See the file containing the
--       `accumulator` entity for more details.) The generic `accumulator_
--       type` defines the architecture types of the relevant parallel
--       and sequential accumulators, if one is to be utilized.
--       For a list of the values currently supported for these
--       generics, see the definitions of the `parallel_accumulator_t`
--       and `sequential_accumulator_t` types within the `parallel_
--       accumulator.vhd` and `sequential_accumulator.vhd` files,
--       respectively.
--
--     > For each input set, all `num_inputs_per_cycle` inputs must be
--       passed in as "generic data arrays", via the `input1` and input2`
--       ports.
--
--     > The `ready` output signal defines when the entity is able to accept
--       new inputs. If `ready` is set to `1`, new inputs can be specified;
--       otherwise, if `ready` is set to `0`, new inputs cannot be specified. 
--
--     > The `valid_in` and `valid_out` signals define whether or not the
--       input and output ports contain new valid data, respectively.
--       Overall, the `valid_in` signal should be set to `1` whenever both
--       the `input1` and `input2` ports contain new valid data, and set to
--       `0` otherwise.
--
--
-- Author(s):
--     Christopher Crary (ccrary@ufl.edu), Jared Herbert (jaredherbert@ufl.edu)
--
-- Last Modified By:
--     Jared Herbert
--
-- Last Modified On:
--     March 3, 2022
-- ****************************************************************************

library arc_std;
library ieee;
context arc_std.std_context;

use arc_std.multiplier_pkg;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package taus88_pkg is

  -- Return latency of overall entity.
  function get_latency return positive;

end package;

package body taus88_pkg is
  
  function get_latency return positive is

    -- NOTE: THE FOLLOWING SHOULD BE CHANGED BASED ON HOW THE
    -- HARDWARE ARCHITECTURE IS CONSTRUCTED.

    -- constant shift_latency : positive := 1;
    -- constant xor_latency : positive := 1;
    -- constant and_latency : positive := 1;

    -- -- Latency of each `b` calculation in the relevant pseudocode.
    -- constant b_latency : positive := shift_latency + xor_latency + and_latency;

    -- -- Latency of each `s_` calculation, where everything except
    -- -- the final XOR in the calculation is done in parallel with 
    -- -- the corresponding `b`.
    constant s_latency : positive := 1;

    -- -- Latency of combining each distinct `s_` output via XOR.
    -- -- (Final line of pseudocode.)
    constant s_xor_latency : positive := 2;

    -- -- Latency of floating-point multiply.
    constant mult_latency : positive := multiplier_pkg.get_latency(float32_t);

    -- -- Latency of converter
    constant conv_latency : positive := 7;

  begin

    -- ARBITRARY VALUE TO GET THE ENTITY TO COMPILE.
    --return mult_latency;
    
    -- -- Overall latency.
    return (s_latency + s_xor_latency + mult_latency + conv_latency);
    
  end function;

end package body;

--------------------------------------------------------------------------------

library arc_std;
context arc_std.std_context;

use arc_std.multiplier_pkg;
use arc_std.taus88_pkg;

entity taus88 is
  port (
    clk : in std_logic;
    rst : in std_logic;

    seed1 : in std_logic_vector(31 downto 0);
    seed2 : in std_logic_vector(31 downto 0);
    seed3 : in std_logic_vector(31 downto 0);
    set_seeds : std_logic;
    
    en : in std_logic;
    output : out std_logic_vector(31 downto 0);
    valid_out : out std_logic);
end entity;


architecture STR of taus88 is

  -- Overall latency of entity.
  constant latency : positive := taus88_pkg.get_latency;

  -- Add fixed 32-bit constants given by the `taus88` algorithm.
  constant multipler_c : std_logic_vector(31 downto 0) := x"2f800000";
  -- Add any other necessary constants.

  ------------------------------------------------------------------------------

  -- State signals.
  signal s1_in, s2_in, s3_in : std_logic_vector(31 downto 0);
  signal s1, s2, s3 : std_logic_vector(31 downto 0);
  signal new_s1, new_s2, new_s3 : std_logic_vector(31 downto 0);
  signal b1, b2, b3 : std_logic_vector(31 downto 0);
  signal s1xs2, s1xs2_out, s3_reg :std_logic_vector(31 downto 0);
  signal xor_total, xor_total_reg : std_logic_vector(31 downto 0);
  signal s1_temp, s2_temp, s3_temp : unsigned(31 downto 0);
  signal b1_temp, b2_temp, b3_temp : unsigned(31 downto 0);
  signal xor_total_float : std_logic_vector(31 downto 0);

  -- Add any other necessary signals.

  -- IP Components
  component convert_uint32_to_float32 is
		port (
			clk    : in  std_logic                     := 'X';             -- clk
			areset : in  std_logic                     := 'X';             -- reset
			a      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- a
			q      : out std_logic_vector(31 downto 0)                     -- q
		);
	end component convert_uint32_to_float32;

begin

  -- Use clocked process to update RNG state.
  --
  -- Register input seeds whenever `set_seed` is true.
  --
  -- Consider using some default seed values other than zero.
  --
  -- Change internal state signals on rising clock edge 
  -- whenever `en` is set. The `en` signal will naturally
  -- propagate through the design to become a `valid_out`
  -- signal.
  --
  -- Note that the three pairs of `b` and `s_` calculations can be 
  -- done in parallel, and most of any latency incurred by each `s_` 
  -- calculation can be amortized by the latency of the corresponding 
  -- `b` calculation.

  process(en, set_seeds, seed1, seed2, seed3, new_s1, new_s2, new_s3, s1, s2, s3)
  begin
    if (en = '1') then
      if (set_seeds = '1') then
        s1_in <= seed1;
        s2_in <= seed2;
        s3_in <= seed3;
      else
        s1_in <= new_s1;
        s2_in <= new_s2;
        s3_in <= new_s3;
      end if;
    else
      s1_in <= s1;
      s2_in <= s2;
      s3_in <= s3;
    end if;
  end process;

  U_S1 : entity arc_std.reg
    generic map (
      data_type => float32_t)
    port map (
      clk => clk,
      rst => rst,
      enable => en,
      input => s1_in,
      output => s1);

  U_S2 : entity arc_std.reg
    generic map (
      data_type => float32_t)
    port map (
      clk => clk,
      rst => rst,
      enable => en,
      input => s2_in,
      output => s2);

  U_S3 : entity arc_std.reg
    generic map (
      data_type => float32_t)
    port map (
      clk => clk,
      rst => rst,
      enable => en,
      input => s3_in,
      output => s3);

  b1_temp <= (SHIFT_LEFT(unsigned(s1), 13)) xor unsigned(s1);
  b1      <= std_logic_vector(SHIFT_RIGHT(b1_temp, 19));

  s1_temp <= SHIFT_LEFT((unsigned(s1) and x"FFFFFFFE"), 12);
  new_s1 <= std_logic_vector(s1_temp) xor b1;

  b2_temp <= (SHIFT_LEFT(unsigned(s2), 2)) xor unsigned(s2);
  b2      <= std_logic_vector(SHIFT_RIGHT(b2_temp, 25));
  
  s2_temp <= SHIFT_LEFT((unsigned(s2) and x"FFFFFFF8"), 4);
  new_s2 <= std_logic_vector(s2_temp) xor b2;


  b3_temp <= (SHIFT_LEFT(unsigned(s3), 3)) xor unsigned(s3);
  b3      <= std_logic_vector(SHIFT_RIGHT(b3_temp, 11));
  
  s3_temp <= SHIFT_LEFT((unsigned(s3) and x"FFFFFFF0"), 17);
  new_s3 <= std_logic_vector(s3_temp) xor b3;

  s1xs2 <= s1 xor s2;

  U_XOR1 : entity arc_std.reg
    generic map (
      data_type => float32_t)
    port map (
      clk => clk,
      rst => rst,
      enable => '1',
      input => s1xs2,
      output => s1xs2_out);

  U_XOR2 : entity arc_std.reg
    generic map (
      data_type => float32_t)
    port map (
      clk => clk,
      rst => rst,
      enable => '1',
      input => s3,
      output => s3_reg);

  xor_total <= s1xs2_out xor s3_reg;
  
  U_CONVERT_TO_FLOAT : convert_uint32_to_float32
    port map (
      clk => clk,
      areset => rst,
      a => xor_total,
      q => xor_total_float);
  
  U_OUT_REG : entity arc_std.reg
    generic map (
      data_type => float32_t)
    port map (
      clk => clk,
      rst => rst,
      enable => '1',
      input => xor_total_float,
      output => xor_total_reg);

  -- -- Structurally instantiate floating-point multiplier.
  U_MULTIPLIER : entity arc_std.multiplier
    generic map (
      input1_type => float32_t,
      input2_type => float32_t)
    port map (
      clk => clk,
      rst => rst,
      input1 => xor_total_reg,
      input2 => multipler_c,
      output => output);

  -- Structurally instantiate `valid_out` delay entity.
  U_VALID_DELAY : entity arc_std.delay
    generic map (
      num_cycles => latency,
      use_valid => true)
    port map (
      clk => clk,
      valid_in => en,
      valid_out => valid_out);
    
end architecture STR;