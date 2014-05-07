-- -*- vhdl -*-
-------------------------------------------------------------------------------
-- Copyright (c) 2012, The CARPE Project, All rights reserved.               --
-- See the AUTHORS file for individual contributors.                         --
--                                                                           --
-- Copyright and related rights are licensed under the Solderpad             --
-- Hardware License, Version 0.51 (the "License"); you may not use this      --
-- file except in compliance with the License. You may obtain a copy of      --
-- the License at http://solderpad.org/licenses/SHL-0.51.                    --
--                                                                           --
-- Unless required by applicable law or agreed to in writing, software,      --
-- hardware and materials distributed under this License is distributed      --
-- on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,        --
-- either express or implied. See the License for the specific language      --
-- governing permissions and limitations under the License.                  --
-------------------------------------------------------------------------------


library ieee;
use ieee.numeric_std.all;

library util;
use util.numeric_pkg.all;
use util.logic_pkg.all;

-- right shift unsigned result zero sel in_left in_right
-- 0     00    1        1234   1    00  XXXX    XXXX
-- 0     01    1        234R   0    01  1234    RRRR
-- 0     10    1        34RR   0    10  1234    RRRR     
-- 0     11    1        4RRR   0    11  1234    RRRR
-- 1     00    1        1234   1    00  XXXX    XXXX
-- 1     01    1        L123   0    11  LLLL    1234
-- 1     10    1        LL12   0    10  LLLL    1234
-- 1     11    1        LLL1   0    01  LLLL    1234
-- 0     00    0        1234   1    00  XXXX    XXXX
-- 0     01    0        234R   0    01  1234    RRRR
-- 0     10    0        LL12   0    10  LLLL    1234
-- 0     11    0        L123   0    11  LLLL    1234
-- 1     00    0        1234   1    00  XXXX    XXXX
-- 1     01    0        L123   0    11  LLLL    1234
-- 1     10    0        34RR   0    10  1234    RRRR
-- 1     11    0        234R   0    01  1234    RRRR

-- right shift unsigned result   zero sel in_left  in_right
-- 0     000   1        12345678 1    XXX  12345678 RRRRRRRR
-- 0     001   1        2345678R 0    001  12345678 RRRRRRRR
-- 0     010   1        345678RR 0    010  12345678 RRRRRRRR     
-- 0     011   1        45678RRR 0    011  12345678 RRRRRRRR
-- 0     100   1        5678RRRR 0    100  12345678 RRRRRRRR
-- 0     101   1        678RRRRR 0    101  12345678 RRRRRRRR
-- 0     110   1        78RRRRRR 0    110  12345678 RRRRRRRR     
-- 0     111   1        8RRRRRRR 0    111  12345678 RRRRRRRR
-- 1     000   1        12345678 1    XXX  LLLLLLLL 12345678
-- 1     001   1        L1234567 0    111  LLLLLLLL 12345678
-- 1     010   1        LL123456 0    110  LLLLLLLL 12345678
-- 1     011   1        LLL12345 0    101  LLLLLLLL 12345678
-- 1     100   1        LLLL1234 0    100  LLLLLLLL 12345678
-- 1     101   1        LLLLL123 0    011  LLLLLLLL 12345678
-- 1     110   1        LLLLLL12 0    010  LLLLLLLL 12345678
-- 1     111   1        LLLLLLL1 0    001  LLLLLLLL 12345678
-- 0     000   0        12345678 1    000  12345678 RRRRRRRR
-- 0     001   0        2345678R 0    001  12345678 RRRRRRRR
-- 0     010   0        345678RR 0    010  12345678 RRRRRRRR
-- 0     011   0        45678RRR 0    011  12345678 RRRRRRRR
-- 0     100   0        LLLL1234 0    100  LLLLLLLL 12345678
-- 0     101   0        LLL12345 0    101  LLLLLLLL 12345678
-- 0     110   0        LL123456 0    110  LLLLLLLL 12345678
-- 0     111   0        L1234567 0    111  LLLLLLLL 12345678
-- 1     000   0        12345678 1    000  LLLLLLLL 12345678
-- 1     001   0        L1234567 0    111  LLLLLLLL 12345678
-- 1     010   0        LL123456 0    110  LLLLLLLL 12345678
-- 1     011   0        LLL12345 0    101  LLLLLLLL 12345678
-- 1     100   0        5678RRRR 0    100  12345678 RRRRRRRR
-- 1     101   0        45678RRR 0    011  12345678 RRRRRRRR
-- 1     110   0        345678RR 0    010  12345678 RRRRRRRR
-- 1     111   0        2345678R 0    001  12345678 RRRRRRRR

architecture rtl of shifter_inferred is
 
  constant barrel_size : natural := integer_minimum(shift_bits, log2ceil(src_bits));
  type barrel_type is array(0 to barrel_size) of std_ulogic_vector(2*src_bits-1 downto 0);

  type comb_type is record
    shift_is_neg : std_ulogic;
    right_shift : std_ulogic;

    right_shift_fill : std_ulogic;
    
    abs_shift : std_ulogic_vector(shift_bits downto 0);
    
    barrel_sel : std_ulogic_vector(barrel_size-1 downto 0);
    
    barrel : barrel_type;
    
    shift_is_zero : std_ulogic;
  end record;
  signal c : comb_type;
  
begin

  c.shift_is_neg  <= not shift_unsgnd and shift(shift_bits-1);
  c.right_shift   <= (right xor c.shift_is_neg);
  
  c.right_shift_fill <= not unsgnd and src(src_bits-1);
  
  c.abs_shift <= logic_if(right, std_ulogic_vector(-signed(shift)), shift);
  
  c.barrel_sel <= c.abs_shift(barrel_size-1 downto 0);
  
  -- barrel shifter

  with c.right_shift select
    c.barrel(0) <= (src &
                    logic_if(rot, src, (src_bits-1 downto 0 => '0'))
                    ) when '0',
                   (logic_if(rot, src, (src_bits-1 downto 0 => c.right_shift_fill)) &
                    src
                    ) when '1',
                   (others => 'X') when others;
  barrel_loop : for n in 0 to barrel_size-1 generate
    with c.barrel_sel(n) select
      c.barrel(n+1) <= c.barrel(n)                                                        when '0',
                       c.barrel(n)(2*src_bits-2**n-1 downto 0) & (2**n-1 downto 0 => 'X') when '1',
                       (others => 'X') when others;
  end generate;

  c.shift_is_zero <= all_zeros(shift);
  result_1 : if shift_bits > log2(src_bits) generate
    blk : block
      signal shift_diff : std_ulogic_vector(shift_bits downto 0);
      signal shift_overflow : std_ulogic;
      signal result_sel : std_ulogic_vector(1 downto 0);
    begin
      shift_diff     <= std_ulogic_vector(to_unsigned(src_bits-1, shift_bits+1) - unsigned('0' & c.abs_shift));
      shift_overflow <= shift_diff(shift_bits-1);
      result_sel <= (0 => c.shift_is_zero,
                     1 => shift_overflow
                     );
      with result_sel select
        result <= c.barrel(barrel_size)(2*src_bits-1 downto src_bits) when "00",
                  src                                                 when "01",
                  (others => c.right_shift and c.right_shift_fill)    when "10",
                  (others => 'X')                                     when others;
    end block;
  end generate;
  
  result_2 : if shift_bits <= log2(src_bits) generate
    with c.shift_is_zero select
      result <= c.barrel(barrel_size)(2*src_bits-1 downto src_bits) when '0',
                src                                                 when '1',
                (others => 'X')                                     when others;
  end generate;

  
end;
