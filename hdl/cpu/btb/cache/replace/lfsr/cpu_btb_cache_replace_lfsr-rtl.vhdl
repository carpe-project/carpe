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
library tech;

use work.cpu_btb_cache_config_pkg.all;
use work.cpu_btb_cache_replace_lfsr_config_pkg.all;

architecture rtl of cpu_btb_cache_replace_lfsr is

  type comb_type is record
    rway_enc : std_ulogic_vector(cpu_btb_cache_log2_assoc-1 downto 0);
  end record;
  signal c : comb_type;
  
begin

  lfsr_assoc_loop : for n in cpu_btb_cache_log2_assoc-1 downto 0 generate
    -- use different sizes for LFSRs for each bit so each sequence is different
    lfsr : entity tech.lfsr(rtl)
      generic map (
        state_bits => cpu_btb_cache_replace_lfsr_state_bits + n
        )
      port map (
        clk => clk,
        rstn => rstn,
        en => cpu_btb_cache_replace_lfsr_ctrl_in.re,
        output => c.rway_enc(n)
        );
  end generate;

  rway_dec : entity tech.decoder(rtl)
    generic map (
      output_bits => 2**cpu_btb_cache_log2_assoc
      )
    port map (
      datain => c.rway_enc,
      dataout => cpu_btb_cache_replace_lfsr_dp_out.rway
      );

end;
