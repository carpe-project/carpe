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

architecture rtl of mul_pipe_inferred is

  type comb_type is record
    src1_tmp : std_ulogic_vector(src1_bits downto 0);
    src2_tmp : std_ulogic_vector(src2_bits downto 0);
    result_tmp : std_ulogic_vector(src1_bits+src2_bits+1 downto 0);
  end record;
  
  type register_type is array(0 to stages-1) of std_ulogic_vector(src1_bits+src2_bits-1 downto 0);
  
  signal c : comb_type;
  signal r, r_next : register_type;
  
begin

  c.src1_tmp <= (src1(src1_bits-1) and not unsgnd) & src1;
  c.src2_tmp <= (src1(src2_bits-1) and not unsgnd) & src2;
  c.result_tmp <= std_ulogic_vector(signed(c.src1_tmp) * signed(c.src2_tmp));

  r_next(0) <= c.result_tmp(src1_bits+src2_bits-1 downto 0);
  stages_gt_1 : if stages > 1 generate
    pipeline_loop : for n in 1 to stages-1 generate
        r_next(n) <= r(n-1);
    end generate;
  end generate;

  result <= r(stages-1);
  
  seq : process(clk) is
  begin

    if rising_edge(clk) then
      r <= r_next;
    end if;
    
  end process;
  
end;
