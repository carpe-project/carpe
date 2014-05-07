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

library util;
use util.types_pkg.all;

use work.cpu_btb_cache_config_pkg.all;

package cpu_btb_cache_replace_none_pkg is

  constant cpu_btb_cache_replace_none_state_bits : natural := 0;
  subtype cpu_btb_cache_replace_none_state_type is std_ulogic_vector(cpu_btb_cache_replace_none_state_bits-1 downto 0);

  type cpu_btb_cache_replace_none_ctrl_in_type is record
    flush : std_ulogic;
    re : std_ulogic;
    we : std_ulogic;
  end record;

  type cpu_btb_cache_replace_none_dp_in_type is record
    rindex : std_ulogic_vector(cpu_btb_cache_index_bits-1 downto 0);
    windex : std_ulogic_vector(cpu_btb_cache_index_bits-1 downto 0);
    wway   : std_ulogic_vector(2**cpu_btb_cache_log2_assoc-1 downto 0);
    wstate : cpu_btb_cache_replace_none_state_type;
  end record;

  type cpu_btb_cache_replace_none_dp_out_type is record
    rway   : std_ulogic_vector(2**cpu_btb_cache_assoc-1 downto 0);
    rstate : cpu_btb_cache_replace_none_state_type;
  end record;

end package;
