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

use work.cpu_l1mem_data_cache_config_pkg.all;
use work.cpu_l1mem_data_types_pkg.all;
use work.cpu_types_pkg.all;

package cpu_l1mem_data_cache_pkg is

  constant cpu_l1mem_data_cache_assoc : natural := 2**cpu_l1mem_data_cache_log2_assoc;

  type cpu_l1mem_data_cache_ctrl_in_type is record
    -- when '1' indicates a new request, must be '0' while
    -- waiting for a miss return, otherwise '1' will cancel
    -- a pending request
    request      : cpu_l1mem_data_request_code_type;
    cacheen      : std_ulogic;
    mmuen        : std_ulogic;
    alloc        : std_ulogic;
    writethrough : std_ulogic;
    priv         : std_ulogic;
    be           : std_ulogic;
  end record;

  type cpu_l1mem_data_cache_dp_in_type is record
    size         : cpu_data_size_type;
    vaddr  : cpu_vaddr_type;
    data : cpu_word_type;
  end record;

  type cpu_l1mem_data_cache_ctrl_out_type is record
    ready : std_ulogic;
    result : cpu_l1mem_data_result_code_type;
  end record;

  type cpu_l1mem_data_cache_dp_out_type is record
    paddr : cpu_paddr_type;
    data  : cpu_word_type;
  end record;
  
  constant cpu_l1mem_data_cache_block_bytes      : natural := 2**cpu_l1mem_data_cache_offset_bits;
  constant cpu_l1mem_data_cache_log2_block_words : natural := cpu_l1mem_data_cache_offset_bits - cpu_log2_word_bytes;
  constant cpu_l1mem_data_cache_block_words      : natural := 2**cpu_l1mem_data_cache_log2_block_words;
  constant cpu_l1mem_data_cache_tag_bits         : natural := cpu_paddr_bits - cpu_l1mem_data_cache_index_bits - cpu_l1mem_data_cache_offset_bits;
  
  type cpu_l1mem_data_cache_owner_index_type is (
    cpu_l1mem_data_cache_owner_index_none,
    cpu_l1mem_data_cache_owner_index_request,
    cpu_l1mem_data_cache_owner_index_stb,
    cpu_l1mem_data_cache_owner_index_bus_op
    );
  type cpu_l1mem_data_cache_owner_type is
    array (cpu_l1mem_data_cache_owner_index_type range
           cpu_l1mem_data_cache_owner_index_type'high downto
           cpu_l1mem_data_cache_owner_index_type'low) of std_ulogic;
  constant cpu_l1mem_data_cache_owner_none    : cpu_l1mem_data_cache_owner_type := "0001";
  constant cpu_l1mem_data_cache_owner_request : cpu_l1mem_data_cache_owner_type := "0010";
  constant cpu_l1mem_data_cache_owner_stb     : cpu_l1mem_data_cache_owner_type := "0100";
  constant cpu_l1mem_data_cache_owner_bus_op  : cpu_l1mem_data_cache_owner_type := "1000";

  type cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_index_type is (
    cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_index_old,
    cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_index_request,
    cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_index_stb,
    cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_index_replace
    );
  type cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_type is
    array (cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_index_type range
           cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_index_type'high downto
           cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_index_type'low) of std_ulogic;
  constant cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_old          : cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_type := "0001";
  constant cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_request      : cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_type := "0010";
  constant cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_stb          : cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_type := "0100";
  constant cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_replace      : cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_type := "1000";
  
  type cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_index_type is (
    cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_index_old,
    cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_index_request,
    cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_index_stb
    );
  type cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_type is
    array (cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_index_type range
           cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_index_type'high downto
           cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_index_type'low) of std_ulogic;
  constant cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_old          : cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_type := "001";
  constant cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_request      : cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_type := "010";
  constant cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_stb          : cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_type := "100";

  type cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_type is (
    cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_old,
    cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_next_word,
    cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_request,
    cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_request_word,
    cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_stb,
    cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_stb_word
    );
  type cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type is
    array (cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_type range
           cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_type'high downto
           cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_type'low) of std_ulogic;
  constant cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_old          : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type := "000001";
  constant cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_next_word    : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type := "000010";
  constant cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_request      : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type := "000100";
  constant cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_request_word : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type := "001000";
  constant cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_stb          : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type := "010000";
  constant cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_stb_word     : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type := "100000";
  
  type cpu_l1mem_data_cache_a_bus_op_size_sel_index_type is (
    cpu_l1mem_data_cache_a_bus_op_size_sel_index_old,
    cpu_l1mem_data_cache_a_bus_op_size_sel_index_word,
    cpu_l1mem_data_cache_a_bus_op_size_sel_index_request,
    cpu_l1mem_data_cache_a_bus_op_size_sel_index_stb
    );
  type cpu_l1mem_data_cache_a_bus_op_size_sel_type is
    array (cpu_l1mem_data_cache_a_bus_op_size_sel_index_type range
           cpu_l1mem_data_cache_a_bus_op_size_sel_index_type'high downto
           cpu_l1mem_data_cache_a_bus_op_size_sel_index_type'low) of std_ulogic;
  constant cpu_l1mem_data_cache_a_bus_op_size_sel_old          : cpu_l1mem_data_cache_a_bus_op_size_sel_type := "0001";
  constant cpu_l1mem_data_cache_a_bus_op_size_sel_word         : cpu_l1mem_data_cache_a_bus_op_size_sel_type := "0010";
  constant cpu_l1mem_data_cache_a_bus_op_size_sel_request      : cpu_l1mem_data_cache_a_bus_op_size_sel_type := "0100";
  constant cpu_l1mem_data_cache_a_bus_op_size_sel_stb          : cpu_l1mem_data_cache_a_bus_op_size_sel_type := "1000";

  type cpu_l1mem_data_cache_b_result_data_sel_index_type is (
    cpu_l1mem_data_cache_b_result_data_sel_index_cache,
    cpu_l1mem_data_cache_b_result_data_sel_index_bus,
    cpu_l1mem_data_cache_b_result_data_sel_index_bus_shifted,
    cpu_l1mem_data_cache_b_result_data_sel_index_stb
    );
  type cpu_l1mem_data_cache_b_result_data_sel_type is
    array (cpu_l1mem_data_cache_b_result_data_sel_index_type range
           cpu_l1mem_data_cache_b_result_data_sel_index_type'high downto
           cpu_l1mem_data_cache_b_result_data_sel_index_type'low) of std_ulogic;
  constant cpu_l1mem_data_cache_b_result_data_sel_cache       : cpu_l1mem_data_cache_b_result_data_sel_type := "0001";
  constant cpu_l1mem_data_cache_b_result_data_sel_bus         : cpu_l1mem_data_cache_b_result_data_sel_type := "0010";
  constant cpu_l1mem_data_cache_b_result_data_sel_bus_shifted : cpu_l1mem_data_cache_b_result_data_sel_type := "0100";
  constant cpu_l1mem_data_cache_b_result_data_sel_stb         : cpu_l1mem_data_cache_b_result_data_sel_type := "1000";

  type cpu_l1mem_data_cache_dp_in_ctrl_type is record
    a_stb_head_ptr : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    a_stb_head_be : std_ulogic;
    a_stb_way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    a_bus_op_way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    a_bus_op_paddr_tag_sel : cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_type;
    a_bus_op_paddr_index_sel : cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_type;
    a_bus_op_paddr_offset_sel : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type;
    a_bus_op_size_sel : cpu_l1mem_data_cache_a_bus_op_size_sel_type;
    a_bus_op_cache_paddr_sel_old : std_ulogic;
    a_bus_op_sys_paddr_sel_old : std_ulogic;
    a_bus_op_sys_data_sel_cache : std_ulogic;
    a_vtram_owner : cpu_l1mem_data_cache_owner_type;
    a_rmdram_owner : cpu_l1mem_data_cache_owner_type;
    a_bus_op_owner : cpu_l1mem_data_cache_owner_type;
    a_dram_wdata_be : std_ulogic;
    b_vtram_owner : cpu_l1mem_data_cache_owner_type;
    b_rmdram_owner : cpu_l1mem_data_cache_owner_type;
    b_replace_way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_cache_read_data_be : std_ulogic;
    b_cache_read_data_way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_request_be : std_ulogic;
    b_request_stb_array_hit : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_complete : std_ulogic;
    b_stb_head_ptr : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_push_ptr : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_combine_ptr : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_result_data_sel : cpu_l1mem_data_cache_b_result_data_sel_type;
  end record;

  type cpu_l1mem_data_cache_dp_out_ctrl_type is record
    b_request_cache_tag_match : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_request_stb_array_tag_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_stb_array_size_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_stb_array_index_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_stb_array_block_word_offset_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_stb_array_word_byte_offset_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_block_change_tag_match   : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_block_change_index_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
  end record;

  type cpu_l1mem_data_cache_ctrl_in_vram_type is record
    rdata : std_ulogic_vector(2**cpu_l1mem_data_cache_log2_assoc-1 downto 0);
  end record;
  
  type cpu_l1mem_data_cache_ctrl_out_vram_type is record
    re : std_ulogic;
    we : std_ulogic;
    wdata : std_ulogic_vector(2**cpu_l1mem_data_cache_log2_assoc-1 downto 0);
  end record;

  type cpu_l1mem_data_cache_dp_out_vram_type is record
    raddr : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    waddr : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
  end record;
  
  type cpu_l1mem_data_cache_ctrl_in_mram_type is record
    rdata : std_ulogic_vector(2**cpu_l1mem_data_cache_log2_assoc-1 downto 0);
  end record;
  
  type cpu_l1mem_data_cache_ctrl_out_mram_type is record
    re : std_ulogic;
    we : std_ulogic;
    wdata : std_ulogic_vector(2**cpu_l1mem_data_cache_log2_assoc-1 downto 0);
  end record;

  type cpu_l1mem_data_cache_dp_out_mram_type is record
    raddr : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    waddr : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
  end record;
  
  type cpu_l1mem_data_cache_ctrl_out_tram_type is record
    en : std_ulogic;
    we : std_ulogic;
    banken : std_ulogic_vector(2**cpu_l1mem_data_cache_log2_assoc-1 downto 0);
  end record;

  type cpu_l1mem_data_cache_dp_in_tram_type is record
    rdata : std_ulogic_vector2(2**cpu_l1mem_data_cache_log2_assoc-1 downto 0,
                               cpu_l1mem_data_cache_tag_bits-1 downto 0);
  end record;

  type cpu_l1mem_data_cache_dp_out_tram_type is record
    addr  : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    wdata : std_ulogic_vector2(2**cpu_l1mem_data_cache_log2_assoc-1 downto 0,
                               cpu_l1mem_data_cache_tag_bits-1 downto 0);
  end record;

  type cpu_l1mem_data_cache_ctrl_out_dram_type is record
    en : std_ulogic;
    we : std_ulogic;
  end record;

  type cpu_l1mem_data_cache_dp_in_dram_type is record
    rdata : std_ulogic_vector2(2**(cpu_l1mem_data_cache_log2_assoc+cpu_log2_word_bytes)-1 downto 0,
                               byte_bits-1 downto 0);
  end record;

  type cpu_l1mem_data_cache_dp_out_dram_type is record
    banken : std_ulogic_vector(2**(cpu_l1mem_data_cache_log2_assoc+cpu_log2_word_bytes)-1 downto 0);
    addr  : std_ulogic_vector(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-cpu_log2_word_bytes-1 downto 0);
    wdata : std_ulogic_vector2(2**(cpu_l1mem_data_cache_log2_assoc+cpu_log2_word_bytes)-1 downto 0,
                               byte_bits-1 downto 0);
  end record;

end package;
