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

library dware;
use dware.dwpackages.all;
use dware.dw_foundation_comp.all;

architecture rtl of mul_dw is
begin

  mul : dw02_mult
    generic map (a_width => src1_bits,
                 b_width => src2_bits,
                 num_stages => latency,
                 stall_mode => 0,
                 rst_mode => 0)
    port map (clk => clk,
              rstn => 'X',
              en => 'X',
              tc => not unsgnd,
              a => src1,
              b => src2,
              product => result
              );

end;
