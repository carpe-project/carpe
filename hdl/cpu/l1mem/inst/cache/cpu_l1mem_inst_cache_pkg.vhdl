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

use work.cpu_l1mem_inst_cache_config_pkg.all;
use work.cpu_l1mem_inst_types_pkg.all;
use work.cpu_types_pkg.all;

package cpu_l1mem_inst_cache_pkg is

  constant cpu_l1mem_inst_cache_assoc : natural := 2**cpu_l1mem_inst_cache_log2_assoc;

  type cpu_l1mem_inst_cache_ctrl_in_type is record
    -- when '1' indicates a new request, must be '0' while
    -- waiting for a miss return, otherwise '1' will cancel
    -- a pending request
    request   : cpu_l1mem_inst_request_code_type;
    cacheen   : std_ulogic;
    mmuen     : std_ulogic;
    alloc     : std_ulogic;
    priv      : std_ulogic;
    direction : cpu_l1mem_inst_fetch_direction_type;
  end record;

  type cpu_l1mem_inst_cache_dp_in_type is record
    vaddr  : cpu_ivaddr_type;
  end record;

  type cpu_l1mem_inst_cache_ctrl_out_type is record
    ready : std_ulogic;
    result : cpu_l1mem_inst_result_code_type;
  end record;

  type cpu_l1mem_inst_cache_dp_out_type is record
    paddr : cpu_ipaddr_type;
    data  : cpu_inst_type;
  end record;
  
  constant cpu_l1mem_inst_cache_block_insts : natural := 2**cpu_l1mem_inst_cache_offset_bits;
  constant cpu_l1mem_inst_cache_tag_bits : natural := cpu_ipaddr_bits - cpu_l1mem_inst_cache_index_bits - cpu_l1mem_inst_cache_offset_bits;

  type cpu_l1mem_inst_cache_owner_index_type is (
    cpu_l1mem_inst_cache_owner_index_none,
    cpu_l1mem_inst_cache_owner_index_request,
    cpu_l1mem_inst_cache_owner_index_bus_op
    );
  type cpu_l1mem_inst_cache_owner_type is
    array (cpu_l1mem_inst_cache_owner_index_type range
           cpu_l1mem_inst_cache_owner_index_type'high downto
           cpu_l1mem_inst_cache_owner_index_type'low) of std_ulogic;
  constant cpu_l1mem_inst_cache_owner_none    : cpu_l1mem_inst_cache_owner_type := "001";
  constant cpu_l1mem_inst_cache_owner_request : cpu_l1mem_inst_cache_owner_type := "010";
  constant cpu_l1mem_inst_cache_owner_bus_op  : cpu_l1mem_inst_cache_owner_type := "100";

  type cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_index_type is (
    cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_index_old,
    cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_index_request
    );
  type cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_type is
    array (cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_index_type range
           cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_index_type'high downto
           cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_index_type'low) of std_ulogic;
  constant cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_old          : cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_type := "01";
  constant cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_request      : cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_type := "10";
  
  type cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_index_type is (
    cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_index_old,
    cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_index_request
    );
  type cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_type is
    array (cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_index_type range
           cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_index_type'high downto
           cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_index_type'low) of std_ulogic;
  constant cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_old          : cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_type := "01";
  constant cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_request      : cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_type := "10";

  type cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_index_type is (
    cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_index_old,
    cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_index_next,
    cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_index_request
    );
  type cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_type is
    array (cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_index_type range
           cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_index_type'high downto
           cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_index_type'low) of std_ulogic;
  constant cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_old     : cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_type := "001";
  constant cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_next    : cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_type := "010";
  constant cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_request : cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_type := "100";

  type cpu_l1mem_inst_cache_b_result_inst_sel_index_type is (
    cpu_l1mem_inst_cache_b_result_inst_sel_index_b_cache,
    cpu_l1mem_inst_cache_b_result_inst_sel_index_b_bus
    );
  type cpu_l1mem_inst_cache_b_result_inst_sel_type is
    array (cpu_l1mem_inst_cache_b_result_inst_sel_index_type range
           cpu_l1mem_inst_cache_b_result_inst_sel_index_type'high downto
           cpu_l1mem_inst_cache_b_result_inst_sel_index_type'low) of std_ulogic;
  constant cpu_l1mem_inst_cache_b_result_inst_sel_b_cache : cpu_l1mem_inst_cache_b_result_inst_sel_type := "01";
  constant cpu_l1mem_inst_cache_b_result_inst_sel_b_bus   : cpu_l1mem_inst_cache_b_result_inst_sel_type := "10";

  type cpu_l1mem_inst_cache_dp_in_ctrl_type is record
    a_bus_op_paddr_tag_sel : cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_type;
    a_bus_op_paddr_index_sel : cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_type;
    a_bus_op_paddr_offset_sel : cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_type;
    a_bus_op_cache_paddr_sel_old : std_ulogic;
    a_cache_owner : cpu_l1mem_inst_cache_owner_type;
    b_request_complete : std_ulogic;
    b_cache_owner : cpu_l1mem_inst_cache_owner_type;
    b_cache_read_data_way : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_replace_way : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_result_inst_sel : cpu_l1mem_inst_cache_b_result_inst_sel_type;
  end record;

  type cpu_l1mem_inst_cache_dp_out_ctrl_type is record
    b_request_last_in_block : std_ulogic;
    b_request_cache_tag_match : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
  end record;

  type cpu_l1mem_inst_cache_ctrl_out_vram_type is record
    re : std_ulogic;
    we : std_ulogic;
    wdata : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
  end record;

  type cpu_l1mem_inst_cache_ctrl_in_vram_type is record
    rdata : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
  end record;
  
  type cpu_l1mem_inst_cache_dp_out_vram_type is record
    raddr : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    waddr : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
  end record;
  
  type cpu_l1mem_inst_cache_ctrl_out_tram_type is record
    en : std_ulogic;
    we : std_ulogic;
    banken : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
  end record;

  type cpu_l1mem_inst_cache_dp_in_tram_type is record
    rdata : std_ulogic_vector2(cpu_l1mem_inst_cache_assoc-1 downto 0,
                               cpu_l1mem_inst_cache_tag_bits-1 downto 0);
  end record;

  type cpu_l1mem_inst_cache_dp_out_tram_type is record
    addr : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    wdata : std_ulogic_vector2(cpu_l1mem_inst_cache_assoc-1 downto 0,
                               cpu_l1mem_inst_cache_tag_bits-1 downto 0);
  end record;

  type cpu_l1mem_inst_cache_ctrl_out_dram_type is record
    en : std_ulogic;
    we : std_ulogic;
    banken : std_ulogic_vector(2**cpu_l1mem_inst_cache_log2_assoc-1 downto 0);
  end record;

  type cpu_l1mem_inst_cache_dp_in_dram_type is record
    rdata : std_ulogic_vector2(cpu_l1mem_inst_cache_assoc-1 downto 0,
                               cpu_inst_bits-1 downto 0);
  end record;

  type cpu_l1mem_inst_cache_dp_out_dram_type is record
    addr  : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits-1 downto 0);
    wdata : std_ulogic_vector2(cpu_l1mem_inst_cache_assoc-1 downto 0,
                               cpu_inst_bits-1 downto 0);
  end record;


end package;
