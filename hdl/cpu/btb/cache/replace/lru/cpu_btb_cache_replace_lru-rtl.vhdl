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

library mem;

use work.cpu_btb_cache_config_pkg.all;

architecture rtl of cpu_btb_cache_replace_lru is
begin

  lru : entity mem.cache_replace_lru(rtl)
    generic map (
      log2_assoc => cpu_btb_cache_log2_assoc,
      index_bits => cpu_btb_cache_index_bits
      )
    port map (
      clk => clk,
      rstn => rstn,
      re => cpu_btb_cache_replace_lru_ctrl_in.re,
      rindex => cpu_btb_cache_replace_lru_dp_in.rindex,
      rway => cpu_btb_cache_replace_lru_dp_out.rway,
      rstate => cpu_btb_cache_replace_lru_dp_out.rstate,
      we => cpu_btb_cache_replace_lru_ctrl_in.we,
      windex => cpu_btb_cache_replace_lru_dp_in.windex,
      wway => cpu_btb_cache_replace_lru_dp_in.wway,
      wstate => cpu_btb_cache_replace_lru_dp_in.wstate
      );

end;
