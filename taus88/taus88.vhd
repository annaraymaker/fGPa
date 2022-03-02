library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity taus88 is
    port (
        clk, rst : in std_logic;
        load : in std_logic;
        seed1, seed2, seed3 : in std_logic_vector(31 downto 0);
        num : out std_logic_vector(31 downto 0)
    );
end taus88;

architecture BHV of taus88 is
    signal s1, s2, s3 : std_logic_vector(31 downto 0);
begin
    process(clk, rst, load, seed)
        variable b : std_logic_vector(31 downto 0);
    begin
        if (rst = '1') then
            s1 <= (others => '0');
            s2 <= (others => '0');
            s3 <= (others => '0');
        elsif (rising_edge(clk)) then
            if (load = '1') then
                s1 <= seed1;
                s2 <= seed2;
                s3 <= seed3;
            else
                b := shift_right(((shift_left(s1, 13)) xor s1), 19);
                s1 <= (shift_left((s1 and std_logic_vector(to_unsigned(4294967294, 32))), 12) xor b);

                b := shift_right(((shift_left(s2, 2)) xor s2), 25);
                s2 <= (shift_left((s2 and std_logic_vector(to_unsigned(4294967288, 32))), 4) xor b);
                
                b := shift_right(((shift_left(s3, 3)) xor s3), 11);
                s3 <= (shift_left((s3 and std_logic_vector(to_unsigned(4294967280, 32))), 17) xor b);
            end if;
        end if;
    end process;
end BHV;