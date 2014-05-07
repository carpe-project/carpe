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

-- Architecture level constants


library ieee;
use ieee.std_logic_1164.all;

library isa;
use isa.or1k_pkg.all;

package cpu_arch_pkg is

  constant cpu_context_bits    : natural := or1k_cid_bits;
  constant cpu_vaddr_bits      : natural := or1k_vaddr_bits;
  constant cpu_paddr_bits      : natural := or1k_paddr_bits;
  constant cpu_log2_word_bytes : natural := or1k_log2_word_bytes;
  constant cpu_word_bytes      : natural := or1k_word_bytes;
  constant cpu_log2_inst_bytes : natural := or1k_log2_inst_bytes;
  constant cpu_inst_bytes      : natural := or1k_inst_bytes;
  constant cpu_rfaddr_bits     : natural := or1k_rfaddr_bits;
  constant cpu_wmask_bits      : natural := or1k_wmask_bits;

  constant cpu_log2_data_size_bits : natural := or1k_log2_data_size_bits;
  
  constant cpu_word_bits : natural := or1k_word_bits;
  constant cpu_inst_bits : natural := or1k_inst_bits;
  constant cpu_wvaddr_bits : natural := or1k_wvaddr_bits;
  constant cpu_ivaddr_bits : natural := or1k_ivaddr_bits;
  constant cpu_wpaddr_bits : natural := or1k_wpaddr_bits;
  constant cpu_ipaddr_bits : natural := or1k_ipaddr_bits;
  constant cpu_shift_bits : natural := or1k_shift_bits;
  
  subtype cpu_vaddr_type is or1k_vaddr_type;
  subtype cpu_paddr_type is or1k_paddr_type;
  subtype cpu_wvaddr_type is or1k_wvaddr_type;
  subtype cpu_ivaddr_type is or1k_ivaddr_type;
  subtype cpu_wpaddr_type is or1k_wpaddr_type;
  subtype cpu_ipaddr_type is or1k_ipaddr_type;
  subtype cpu_word_bytes_type is or1k_word_bytes_type;
  subtype cpu_word_type is or1k_word_type;
  subtype cpu_dword_type is or1k_dword_type;
  subtype cpu_inst_bytes_type is or1k_inst_bytes_type;
  subtype cpu_inst_type is or1k_inst_type;
  subtype cpu_rfaddr_type is or1k_rfaddr_type;
  subtype cpu_shift_type is or1k_shift_type;
  subtype cpu_wmask_type is or1k_wmask_type;
  subtype cpu_log2_data_size_type is or1k_log2_data_size_type;
  
end package;
