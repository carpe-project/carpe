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


library isa;
use isa.or1k_pkg.all;

library util;
use util.types_pkg.all;

use work.cpu_or1knd_i5_pkg.all;

package cpu_types_pkg is

  constant cpu_vaddr_bits : natural := or1k_vaddr_bits;
  constant cpu_paddr_bits : natural := or1k_paddr_bits;
  constant cpu_poffset_bits : natural := or1k_poffset_bits;
  constant cpu_ppn_bits : natural := or1k_ppn_bits;
  constant cpu_vpn_bits : natural := or1k_vpn_bits;
  
  constant cpu_ivaddr_bits : natural := or1k_ivaddr_bits;
  constant cpu_ipaddr_bits : natural := or1k_ipaddr_bits;
  constant cpu_wvaddr_bits : natural := or1k_wvaddr_bits;
  constant cpu_wpaddr_bits : natural := or1k_wpaddr_bits;
  constant cpu_ipoffset_bits : natural := or1k_ipoffset_bits;
  constant cpu_wpoffset_bits : natural := or1k_wpoffset_bits;

  constant cpu_word_bits : natural := or1k_word_bits;
  constant cpu_log2_word_bytes : natural := or1k_log2_word_bytes;
  constant cpu_word_bytes : natural := or1k_word_bytes;
  constant cpu_log2_inst_bytes : natural := or1k_log2_inst_bytes;
  constant cpu_inst_bits : natural := or1k_inst_bits;

  constant cpu_inst_endianness : endianness_type := or1k_inst_endianness;

  subtype cpu_vaddr_type is or1k_vaddr_type;
  subtype cpu_paddr_type is or1k_paddr_type;
  subtype cpu_poffset_type is or1k_poffset_type;
  subtype cpu_vpn_type is or1k_vpn_type;
  subtype cpu_ppn_type is or1k_ppn_type;

  subtype cpu_ivaddr_type is or1k_ivaddr_type;
  subtype cpu_ipaddr_type is or1k_ipaddr_type;
  subtype cpu_wvaddr_type is or1k_wvaddr_type;
  subtype cpu_wpaddr_type is or1k_wpaddr_type;
  subtype cpu_ipoffset_type is or1k_ipoffset_type;
  subtype cpu_wpoffset_type is or1k_wpoffset_type;

  subtype cpu_word_type is or1k_word_type;
  subtype cpu_word_bytes_type is or1k_word_bytes_type;
  subtype cpu_inst_type is or1k_inst_type;
  subtype cpu_inst_bytes_type is or1k_inst_bytes_type;

  constant cpu_data_size_bits : natural := cpu_or1knd_i5_data_size_bits;
  subtype cpu_data_size_type is cpu_or1knd_i5_data_size_type;

end package;
