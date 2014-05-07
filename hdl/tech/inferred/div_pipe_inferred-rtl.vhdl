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
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library util;
use util.logic_pkg.all;

architecture rtl of div_pipe_inferred is

  type comb_type is record
    dbz : std_ulogic;
    overflow : std_ulogic;
    src1_tmp : std_ulogic_vector(src1_bits downto 0);
    src2_tmp : std_ulogic_vector(src2_bits downto 0);
  end record;
  signal c : comb_type;

  type stage_type is record
    dbz : std_ulogic;
    overflow : std_ulogic;
    result : std_ulogic_vector(src1_bits downto 0);
  end record;
  type reg_type is array(0 to stages-1) of stage_type;
  signal r, r_next : reg_type;

  pure function div(src1, src2 : std_ulogic_vector(src1_bits downto 0)) return std_ulogic_vector is
    variable ret : std_ulogic_vector(src1_bits downto 0);
  begin
    -- pragma translate_off
    if is_x(src1) or is_x(src2) or src2 = (src1_bits downto 0 => '0') then
      ret := (others => 'X');
    else
    -- pragma translate_on
      ret := std_ulogic_vector(signed(src1) / signed(src2));
    -- pragma translate_off
    end if;
    -- pragma translate_on
    return ret;
  end function;

begin

  c.src1_tmp <= (src1(src1_bits-1) and not unsgnd) & src1;
  c.src2_tmp <= (src1(src2_bits-1) and not unsgnd) & src2;
  c.dbz        <= all_zeros(src2);
  c.overflow <= (not unsgnd and
                 -- e.g. (signed) 0x80000000 / 0xffffffff = 0x80000000
                 -- so result is not representable
                 src1(src1_bits-1) and all_zeros(src1(src1_bits-2 downto 0)) and
                 all_ones(src2)
                 );

  r_next(0).dbz <= c.dbz;
  r_next(0).overflow <= c.overflow;
  r_next(0).result <= div(c.src1_tmp, c.src2_tmp);

  stages_gt_1 : if stages > 1 generate
    pipeline_loop : for n in 1 to stages-1 generate
        r_next(n) <= r(n-1);
    end generate;
  end generate;

  dbz <= r(stages-1).dbz;
  overflow <= r(stages-1).overflow;
  result <= r(stages-1).result(src1_bits-1 downto 0);

  seq : process(clk) is
  begin

    if rising_edge(clk) then
      r <= r_next;
    end if;
    
  end process;
  
end;
