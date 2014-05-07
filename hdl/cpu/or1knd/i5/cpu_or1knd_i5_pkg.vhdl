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

library isa;
use isa.or1k_pkg.all;

library util;
use util.types_pkg.all;
use util.numeric_pkg.all;

use work.cpu_or1knd_i5_config_pkg.all;

package cpu_or1knd_i5_pkg is

  constant cpu_or1knd_i5_spr_sys_vr_ver : std_ulogic_vector(31 downto 24) := "00010000";
  constant cpu_or1knd_i5_spr_sys_vr_cfg : std_ulogic_vector(23 downto 16) := "00000000";
  constant cpu_or1knd_i5_spr_sys_vr_rev : std_ulogic_vector(5 downto 0)   := "000000";
  constant cpu_or1knd_i5_spr_sys_vr     : or1k_spr_data_type           := (cpu_or1knd_i5_spr_sys_vr_ver &
                                                                           cpu_or1knd_i5_spr_sys_vr_cfg &
                                                                           (15 downto 6 => '0')             &
                                                                           cpu_or1knd_i5_spr_sys_vr_rev);
  
  constant cpu_or1knd_i5_data_size_bits : natural := bitsize(or1k_log2_word_bytes);
  subtype cpu_or1knd_i5_data_size_type     is std_ulogic_vector(cpu_or1knd_i5_data_size_bits-1 downto 0);
  
end package;
