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

architecture rtl of syncram_2r1w is
begin
  
  rf : entity work.syncram_2r1w_inferred(rtl)
    generic map (
      addr_bits => addr_bits,
      data_bits => data_bits,
      write_first => write_first
      )
    port map (
      clk => clk,
      we => we,
      waddr => waddr,
      wdata => wdata,
      re1 => re1,
      raddr1 => raddr1,
      rdata1 => rdata1,
      re2 => re2,
      raddr2 => raddr2,
      rdata2 => rdata2
      );
  
end;
