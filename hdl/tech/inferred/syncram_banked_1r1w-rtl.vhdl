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


architecture rtl of syncram_banked_1r1w is
begin
  
  syncram : entity work.syncram_banked_1r1w_inferred(rtl)
    generic map (
      addr_bits => addr_bits,
      word_bits => word_bits,
      log2_banks => log2_banks,
      write_first => write_first
      )
    port map (
      clk => clk,
      we => we,
      wbanken => wbanken,
      waddr => waddr,
      wdata => wdata,
      re => re,
      rbanken => rbanken,
      raddr => raddr,
      rdata => rdata
      );
  
end;
