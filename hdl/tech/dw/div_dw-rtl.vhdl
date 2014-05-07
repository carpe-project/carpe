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

library ieee;
use ieee.std_logic_1164.all;

library dware;
use dware.dwpackages.all;
use dware.dw_foundation_comp.all;

architecture rtl of div_dw is

  signal src1_ext : std_ulogic_vector(src1_bits downto 0);
  signal src2_ext : std_ulogic_vector(src2_bits downto 0);
  
begin

  src1_ext <= (src1(src1_bits-1) and not unsgnd) & src1;
  src2_ext <= (src2(src2_bits-1) and not unsgnd) & src2;

  mul : dw02_mult
    generic map (a_width => src1_bits+1,
                 b_width => src2_bits+2,
                 tc_mode => 1,
                 rem_mode => 0,
                 num_stages => latency,
                 stall_mode => 0,
                 rst_mode => 0)
    port map (clk => clk,
              rstn => 'X',
              en => 'X',
              a => src1,
              b => src2,
              product => result
              );

end;
