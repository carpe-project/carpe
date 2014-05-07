-- -*- vhdl -*-
-------------------------------------------------------------------------------
-- Copyright (c) 2012-2014, The CARPE Project, All rights reserved.          --
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
use ieee.numeric_std.all;

library util;
use util.logic_pkg.all;
use util.types_pkg.all;

-- pragma translate_off
use util.names_pkg.all;

library sim;
use sim.options_pkg.all;
use sim.monitor_pkg.all;
-- pragma translate_on

use work.cpu_l1mem_data_types_pkg.all;
use work.cpu_l1mem_data_cache_pkg.all;
use work.cpu_l1mem_data_cache_config_pkg.all;
use work.cpu_mmu_data_types_pkg.all;
use work.cpu_types_pkg.all;

library tech;

architecture rtl of cpu_l1mem_data_cache_ctrl is

  -- There are 3 main subsystems:

  -- Request subsystem: Handles a request from the pipeline.
  -- Tracks the current request, determines which structures to access depending on the request made.

  -- STB subsystem: The store buffer

  -- Bus subsystem: manages off-core requests.
  -- Tracks the current off-core request, handles cache-line fills and writebacks.

  -- Cache has 4 parts: vram, mram, tram, dram.
  -- Cache is passive and controlled by the 3 subsystems above.

  -- All 3 subsystems can access the cache.
  -- The subsystem currently accessing it is called its "owner".
  -- Each component of the cache (vram, mram, tram, dram) can have a different, unique owner.
  -- This allows e.g. the dram write for a store to occur in parallel with the tag check
  -- for a store immediately after.
  -- (A store that immediately precedes a load will usually have to wait for the load to
  -- complete before completing itself.)
  
  -- The bus can be accessed by a request or the STB, also be uniquely owned by either the STB or the request.
  -- A fill/writeback may be performed on behalf of a request, in which case the request will have
  -- ownership of the bus, and the bus will have ownership of the cache.

  -- Cached load accesses vram, mram, tram, dram for all ways, replace, and mmu in parallel.
  -- Cache hit is detected and result data is returned to pipeline in the same cycle.

  -- Cached store accesses vram, mram, tram for all ways, replace, and mmu in parallel.
  -- Cache hit is detected and address & data are written to stb.

  -- cached load request: want vram, mram, tram, dram, replace
  -- cached store request: want vram, tram
  -- invalidate request: want vram
  -- writeback/flush request: want vram, mram, tram

  -- stb cache hit: want mram, dram, replace
  -- stb cache miss: want vram, mram, tram, dram, replace

  type request_type is record
    code : cpu_l1mem_data_request_code_type;
    be : std_ulogic;
    cacheen : std_ulogic;
    mmuen : std_ulogic;
    writethrough : std_ulogic;
    priv : std_ulogic;
    alloc : std_ulogic;
  end record;
  constant request_x : request_type := (
    code => (others => 'X'),
    be => 'X',
    cacheen => 'X',
    mmuen => 'X',
    writethrough => 'X',
    priv => 'X',
    alloc => 'X'
    );
  constant request_init : request_type := (
    code => cpu_l1mem_data_request_code_none,
    be => 'X',
    cacheen => 'X',
    mmuen => 'X',
    writethrough => 'X',
    priv => 'X',
    alloc => 'X'
    );

  type request_state_index_type is (
    request_state_index_none,
    request_state_index_uncached_load_mmu_access,
    request_state_index_uncached_load_bus_op,
    request_state_index_uncached_store_mmu_access,
    request_state_index_uncached_store_bus_op,
    request_state_index_cached_load_l1_access,
    request_state_index_cached_load_writeback,
    request_state_index_cached_load_fill,
    request_state_index_cached_store_stb_wait,
    request_state_index_cached_store_l1_access,
    request_state_index_invalidate_sync,
    request_state_index_invalidate_l1_access,
    request_state_index_writeback_sync,
    request_state_index_writeback_l1_access,
    request_state_index_writeback_bus_op,
    request_state_index_flush_sync,
    request_state_index_flush_l1_access,
    request_state_index_flush_bus_op,
    request_state_index_flush_invalidate_l1_access,
    request_state_index_sync
    );
  type request_state_type is
    array (request_state_index_type range
           request_state_index_type'high downto
           request_state_index_type'low) of std_ulogic;
  constant request_state_none                       : request_state_type := "00000000000000000001";
  constant request_state_uncached_load_mmu_access   : request_state_type := "00000000000000000010";
  constant request_state_uncached_load_bus_op       : request_state_type := "00000000000000000100";
  constant request_state_uncached_store_mmu_access  : request_state_type := "00000000000000001000";
  constant request_state_uncached_store_bus_op      : request_state_type := "00000000000000010000";
  constant request_state_cached_load_l1_access      : request_state_type := "00000000000000100000";
  constant request_state_cached_load_writeback      : request_state_type := "00000000000001000000";
  constant request_state_cached_load_fill           : request_state_type := "00000000000010000000";
  constant request_state_cached_store_stb_wait      : request_state_type := "00000000000100000000";
  constant request_state_cached_store_l1_access     : request_state_type := "00000000001000000000";
  constant request_state_invalidate_sync            : request_state_type := "00000000010000000000";
  constant request_state_invalidate_l1_access       : request_state_type := "00000000100000000000";
  constant request_state_writeback_sync             : request_state_type := "00000001000000000000";
  constant request_state_writeback_l1_access        : request_state_type := "00000010000000000000";
  constant request_state_writeback_bus_op           : request_state_type := "00000100000000000000";
  constant request_state_flush_sync                 : request_state_type := "00001000000000000000";
  constant request_state_flush_l1_access            : request_state_type := "00010000000000000000";
  constant request_state_flush_bus_op               : request_state_type := "00100000000000000000";
  constant request_state_flush_invalidate_l1_access : request_state_type := "01000000000000000000";
  constant request_state_sync                       : request_state_type := "10000000000000000000";

  type bus_op_code_index_type is (
    bus_op_code_index_none,
    bus_op_code_index_load,
    bus_op_code_index_store,
    bus_op_code_index_fill,
    bus_op_code_index_writeback
    );
  type bus_op_code_type is
    array (bus_op_code_index_type range
           bus_op_code_index_type'high downto
           bus_op_code_index_type'low) of std_ulogic;
  constant bus_op_code_none      : bus_op_code_type := "00001";
  constant bus_op_code_load      : bus_op_code_type := "00010";
  constant bus_op_code_store     : bus_op_code_type := "00100";
  constant bus_op_code_fill      : bus_op_code_type := "01000";
  constant bus_op_code_writeback : bus_op_code_type := "10000";

  type bus_op_state_index_type is (
    bus_op_state_index_none,
    bus_op_state_index_load,
    bus_op_state_index_store,
    bus_op_state_index_fill_first,
    bus_op_state_index_fill,
    bus_op_state_index_fill_last,
    bus_op_state_index_writeback_first,
    bus_op_state_index_writeback,
    bus_op_state_index_writeback_last
    );
  type bus_op_state_type is
    array (bus_op_state_index_type range
           bus_op_state_index_type'high downto
           bus_op_state_index_type'low) of std_ulogic;
  constant bus_op_state_none                 : bus_op_state_type := "000000001";
  constant bus_op_state_load                 : bus_op_state_type := "000000010";
  constant bus_op_state_store                : bus_op_state_type := "000000100";
  constant bus_op_state_fill_first           : bus_op_state_type := "000001000";
  constant bus_op_state_fill                 : bus_op_state_type := "000010000";
  constant bus_op_state_fill_last            : bus_op_state_type := "000100000";
  constant bus_op_state_writeback_first      : bus_op_state_type := "001000000";
  constant bus_op_state_writeback            : bus_op_state_type := "010000000";
  constant bus_op_state_writeback_last       : bus_op_state_type := "100000000";

  type bus_op_type is record
    code : bus_op_code_type;
    way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    be : std_ulogic;
    priv : std_ulogic;
  end record;
  constant bus_op_x : bus_op_type := (
    code => (others => 'X'),
    way => (others => 'X'),
    be => 'X',
    priv => 'X'
    );
  constant bus_op_init : bus_op_type := (
    code => bus_op_code_none,
    way => (others => 'X'),
    be => 'X',
    priv => 'X'
    );

  type stb_state_index_type is (
    stb_state_index_init,
    stb_state_index_replace_access,
    stb_state_index_writeback,
    stb_state_index_fill,
    stb_state_index_write
    );
  type stb_state_type is
    array (stb_state_index_type range
           stb_state_index_type'high downto
           stb_state_index_type'low) of std_ulogic;
  constant stb_state_init           : stb_state_type := "00001";
  constant stb_state_replace_access : stb_state_type := "00010";
  constant stb_state_writeback      : stb_state_type := "00100";
  constant stb_state_fill           : stb_state_type := "01000";
  constant stb_state_write          : stb_state_type := "10000";

  subtype stb_ptr_type is std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
  pure function stb_ptr_init return stb_ptr_type is
    variable ret : stb_ptr_type;
  begin
    if cpu_l1mem_data_cache_stb_entries > 0 then
      ret := (0 => '1', others => '0');
    end if;
    return ret;
  end function;

  type reg_type is record
    b_vtram_owner                  : cpu_l1mem_data_cache_owner_type;
    b_rmdram_owner                 : cpu_l1mem_data_cache_owner_type;
    b_bus_op_owner                 : cpu_l1mem_data_cache_owner_type;

    b_request_granted              : std_ulogic;
    b_request                      : request_type;
    b_request_state                : request_state_type;
    b_request_way                  : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_request_mmu_accessed         : std_ulogic;
    b_request_cache_block_dirty    : std_ulogic;

    b_bus_op_granted               : std_ulogic;
    b_bus_op_state                 : bus_op_state_type;
    b_bus_op_cacheable             : std_ulogic;
    b_bus_op_be                    : std_ulogic;
    b_bus_op_priv                  : std_ulogic;
    b_bus_op_way                   : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_bus_op_block_word            : std_ulogic_vector(cpu_l1mem_data_cache_block_words-1 downto 0);
    b_bus_op_requested             : std_ulogic;

    b_stb_state                    : stb_state_type;
    b_stb_way                      : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_stb_head_ptr                 : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_tail_ptr                 : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_write_cache              : std_ulogic;
    b_stb_write_bus                : std_ulogic;
    
    b_stb_array_valid              : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_alloc              : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_writethrough       : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_be                 : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_priv               : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_cache_hit          : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_way                : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                                        cpu_l1mem_data_cache_assoc-1 downto 0);
    
  end record;
  constant reg_x : reg_type := (
    b_vtram_owner             => (others => 'X'),
    b_rmdram_owner             => (others => 'X'),
    b_bus_op_owner                 => (others => 'X'),

    b_request_granted              => 'X',
    b_request                      => request_x,
    b_request_state                => (others => 'X'),
    b_request_way                  => (others => 'X'),
    b_request_mmu_accessed         => 'X',
    b_request_cache_block_dirty    => 'X',

    b_bus_op_granted               => 'X',
    b_bus_op_state                 => (others => 'X'),
    b_bus_op_cacheable             => 'X',
    b_bus_op_be                    => 'X',
    b_bus_op_priv                  => 'X',
    b_bus_op_way                   => (others => 'X'),
    b_bus_op_block_word            => (others => 'X'),
    b_bus_op_requested             => 'X',

    b_stb_state                    => (others => 'X'),
    b_stb_way                      => (others => 'X'),
    b_stb_head_ptr                 => (others => 'X'),
    b_stb_tail_ptr                 => (others => 'X'),
    b_stb_write_cache              => 'X',
    b_stb_write_bus                => 'X',
    
    b_stb_array_valid              => (others => 'X'),
    b_stb_array_alloc              => (others => 'X'),
    b_stb_array_writethrough       => (others => 'X'),
    b_stb_array_be                 => (others => 'X'),
    b_stb_array_priv               => (others => 'X'),
    b_stb_array_cache_hit          => (others => 'X'),
    b_stb_array_way                => (others => (others => 'X'))
    );
  constant reg_init : reg_type := (
    b_vtram_owner             => cpu_l1mem_data_cache_owner_none,
    b_rmdram_owner             => cpu_l1mem_data_cache_owner_none,
    b_bus_op_owner                 => cpu_l1mem_data_cache_owner_none,
    
    b_request_granted              => 'X',
    b_request                      => request_init,
    b_request_state                => request_state_none,
    b_request_way                  => (others => 'X'),
    b_request_mmu_accessed         => 'X',
    b_request_cache_block_dirty    => 'X',

    b_bus_op_granted               => 'X',
    b_bus_op_state                 => bus_op_state_none,
    b_bus_op_cacheable             => 'X',
    b_bus_op_be                    => 'X',
    b_bus_op_priv                  => 'X',
    b_bus_op_way                   => (others => 'X'),
    b_bus_op_block_word            => (others => 'X'),
    b_bus_op_requested             => 'X',

    b_stb_state                    => stb_state_init,
    b_stb_way                      => (others => 'X'),
    b_stb_head_ptr                 => stb_ptr_init,
    b_stb_tail_ptr                 => stb_ptr_init,
    b_stb_write_cache              => 'X',
    b_stb_write_bus                => 'X',

    b_stb_array_valid              => (others => '0'),
    b_stb_array_alloc              => (others => 'X'),
    b_stb_array_writethrough       => (others => 'X'),
    b_stb_array_be                 => (others => 'X'),
    b_stb_array_priv               => (others => 'X'),
    b_stb_array_cache_hit          => (others => 'X'),
    b_stb_array_way                => (others => (others => 'X'))
    );

  type comb_type is record

    b_vram_rdata : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_vram_rdata_all_ones : std_ulogic;
    b_vram_rdata_first_free : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_mram_rdata : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);

    b_replace_rway : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_replace_way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_replace_way_valid : std_ulogic;
    b_replace_way_dirty : std_ulogic;

    b_bus_op_error : std_ulogic;
    b_bus_op_cycle_complete : std_ulogic;
    b_bus_op_fill_load_data_ready : std_ulogic;
    b_bus_op_fill_complete : std_ulogic;
    b_bus_op_writeback_complete : std_ulogic;
    b_bus_op_complete_no_error : std_ulogic;
    b_bus_op_complete : std_ulogic;
    b_bus_op_state_next_fill_first : bus_op_state_type;
    b_bus_op_state_next_fill : bus_op_state_type;
    b_bus_op_state_next_fill_last : bus_op_state_type;
    b_bus_op_state_next_writeback_first : bus_op_state_type;
    b_bus_op_state_next_writeback : bus_op_state_type;
    b_bus_op_state_next_writeback_last : bus_op_state_type;
    b_bus_op_state_next_no_error : bus_op_state_type;
    b_bus_op_state_next : bus_op_state_type;
    b_bus_op_block_word_advance : std_ulogic;
    b_bus_op_block_word_next : std_ulogic_vector(cpu_l1mem_data_cache_block_words-1 downto 0);
    b_bus_op_vram_we : std_ulogic;
    b_bus_op_vram_wdata : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_bus_op_mram_we : std_ulogic;
    b_bus_op_mram_wdata : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_bus_op_replace_we : std_ulogic;
    b_bus_op_replace_wway : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);

    b_block_change                 : std_ulogic;
    b_block_change_valid           : std_ulogic;
    b_block_change_way             : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    
    b_stb_full : std_ulogic;
    b_stb_empty : std_ulogic;
    b_stb_state_next_replace_access : stb_state_type;
    b_stb_state_next_writeback : stb_state_type;
    b_stb_state_next_fill : stb_state_type;
    b_stb_state_next_write : stb_state_type;
    b_stb_state_next : stb_state_type;

    b_stb_mram_we : std_ulogic;
    b_stb_mram_wdata : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_stb_replace_we : std_ulogic;
    b_stb_replace_wway : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    
    b_stb_pop_write : std_ulogic;
    b_stb_pop : std_ulogic;
    b_stb_head_ptr_next : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_can_push : std_ulogic;

    b_request_sync : std_ulogic;
    
    b_request_mmu_result_ready : std_ulogic;
    b_request_mmu_result_valid : std_ulogic;
    b_request_mmu_error : std_ulogic;

    b_request_cache_way_hit : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_request_cache_hit : std_ulogic;
    b_request_cache_miss : std_ulogic;
    b_request_cache_way_hit_dirty : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_request_cache_hit_dirty : std_ulogic;
    b_request_cache_way_hit_clean : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_request_cache_hit_clean : std_ulogic;
    b_request_cache_block_valid : std_ulogic;
    b_request_cache_block_dirty : std_ulogic;

    b_request_stb_array_hit : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_stb_array_conflict : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_stb_hit : std_ulogic;
    b_request_stb_head_hit : std_ulogic;
    b_request_stb_conflict : std_ulogic;
    b_request_stb_can_combine : std_ulogic;
    
    b_request_complete_uncached_mmu_access : std_ulogic;
    b_request_complete_uncached_bus_op : std_ulogic;
    b_request_complete_cached_load_l1_access : std_ulogic;
    b_request_complete_cached_load_fill : std_ulogic;
    b_request_complete_cached_store_l1_access : std_ulogic;
    b_request_complete_invalidate_l1_access : std_ulogic;
    b_request_complete_writeback_l1_access : std_ulogic;
    b_request_complete_writeback_bus_op : std_ulogic;
    b_request_complete_flush_l1_access : std_ulogic;
    b_request_complete_flush_bus_op : std_ulogic;
    b_request_complete_sync : std_ulogic;
    b_request_complete_no_error : std_ulogic;
    b_request_complete : std_ulogic;
    
    b_request_way_next   : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    
    b_request_state_next_uncached_load_mmu_access : request_state_type;
    b_request_state_next_uncached_store_mmu_access : request_state_type;
    b_request_state_next_cached_load_l1_access : request_state_type;
    b_request_state_next_cached_load_writeback : request_state_type;
    b_request_state_next_cached_store_l1_access : request_state_type;
    b_request_state_next_cached_store_stb_wait : request_state_type;
    b_request_state_next_writeback_l1_access : request_state_type;
    b_request_state_next_writeback_bus_op : request_state_type;
    b_request_state_next_invalidate_sync : request_state_type;
    b_request_state_next_writeback_sync : request_state_type;
    b_request_state_next_flush_sync : request_state_type;
    b_request_state_next_flush_l1_access : request_state_type;
    b_request_state_next_sync : request_state_type;
    b_request_state_next : request_state_type;
    
    b_request_cache_accessed_next : std_ulogic;
    
    b_request_replace_we : std_ulogic;
    b_request_replace_wway : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_request_vram_we : std_ulogic;
    b_request_vram_wdata : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);

    b_stb_push : std_ulogic;
    b_stb_combine : std_ulogic;
    b_stb_tail_ptr_next : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);

    b_stb_push_ptr : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_combine_ptr : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    
    b_stb_push_entry_cache_hit : std_ulogic;
    b_stb_push_entry_alloc : std_ulogic;
    b_stb_push_entry_writethrough : std_ulogic;
    b_stb_push_entry_be : std_ulogic;
    b_stb_push_entry_priv : std_ulogic; 
    b_stb_push_entry_way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    
    b_stb_array_block_change : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    
    b_stb_array_valid_next        : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_cache_hit_next    : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_alloc_next        : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_writethrough_next : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_be_next           : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_priv_next         : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_way_next          : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                                             cpu_l1mem_data_cache_assoc-1 downto 0);

    b_stb_write_bus_next                : std_ulogic;
    b_stb_write_cache_next              : std_ulogic;
    b_stb_way_next : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    
    b_cache_read_data_be : std_ulogic;
    b_cache_read_data_way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);

    b_result_ready   : std_ulogic;
    b_result_code_mmu_access : cpu_l1mem_data_result_code_type;
    b_result_code_no_error   : cpu_l1mem_data_result_code_type;
    b_result_code            : cpu_l1mem_data_result_code_type;
    b_result_data_sel_cached_load_l1_access : cpu_l1mem_data_cache_b_result_data_sel_type;
    b_result_data_sel : cpu_l1mem_data_cache_b_result_data_sel_type;

    b_replace_we_no_error : std_ulogic;
    b_replace_we : std_ulogic;
    b_replace_wway : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_vram_we_no_error : std_ulogic;
    b_vram_we : std_ulogic;
    b_vram_wdata : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    b_mram_we_no_error : std_ulogic;
    b_mram_we : std_ulogic;
    b_mram_wdata : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);

    b_cache_owner_next_bus_op_request : cpu_l1mem_data_cache_owner_type;
    b_cache_owner_next_bus_op_bus_op : cpu_l1mem_data_cache_owner_type;
    b_cache_owner_next_stb : cpu_l1mem_data_cache_owner_type;
    
    b_vtram_owner_next_request : cpu_l1mem_data_cache_owner_type;
    b_vtram_owner_next_bus_op_request : cpu_l1mem_data_cache_owner_type;
    b_vtram_owner_next_bus_op_stb     : cpu_l1mem_data_cache_owner_type;
    b_vtram_owner_next_bus_op_bus_op  : cpu_l1mem_data_cache_owner_type;
    b_vtram_owner_next_bus_op : cpu_l1mem_data_cache_owner_type;
    b_vtram_owner_next_stb : cpu_l1mem_data_cache_owner_type;
    b_vtram_owner_next_no_error : cpu_l1mem_data_cache_owner_type;
    b_vtram_owner_next : cpu_l1mem_data_cache_owner_type;
    
    b_rmdram_owner_next_request : cpu_l1mem_data_cache_owner_type;
    b_rmdram_owner_next_bus_op_request : cpu_l1mem_data_cache_owner_type;
    b_rmdram_owner_next_bus_op_stb     : cpu_l1mem_data_cache_owner_type;
    b_rmdram_owner_next_bus_op_bus_op  : cpu_l1mem_data_cache_owner_type;
    b_rmdram_owner_next_bus_op : cpu_l1mem_data_cache_owner_type;
    b_rmdram_owner_next_stb : cpu_l1mem_data_cache_owner_type;
    b_rmdram_owner_next_no_error : cpu_l1mem_data_cache_owner_type;
    b_rmdram_owner_next : cpu_l1mem_data_cache_owner_type;
    
    b_bus_op_owner_next_request         : cpu_l1mem_data_cache_owner_type;
    b_bus_op_owner_next_stb             : cpu_l1mem_data_cache_owner_type;
    b_bus_op_owner_next_bus_op          : cpu_l1mem_data_cache_owner_type;
    b_bus_op_owner_next_no_error        : cpu_l1mem_data_cache_owner_type;
    b_bus_op_owner_next                 : cpu_l1mem_data_cache_owner_type;

    
    a_stb_head_ptr : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    a_stb_tail_ptr : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);

    a_stb_array_valid              : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    a_stb_array_alloc              : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    a_stb_array_writethrough       : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    a_stb_array_be                 : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    a_stb_array_priv               : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    a_stb_array_cache_hit          : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    a_stb_array_way                : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                                        cpu_l1mem_data_cache_assoc-1 downto 0);
    
    a_stb_head_valid              : std_ulogic;
    a_stb_head_alloc              : std_ulogic;
    a_stb_head_writethrough       : std_ulogic;
    a_stb_head_be                 : std_ulogic;
    a_stb_head_priv               : std_ulogic;
    a_stb_head_cache_hit          : std_ulogic;
    a_stb_head_way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    
    a_stb_full      : std_ulogic;
    a_stb_quick_store : std_ulogic;


    
    a_new_request     : request_type;
    a_new_request_stb_wait : std_ulogic;
    a_new_request_state_load : request_state_type;
    a_new_request_state_store : request_state_type;
    a_new_request_state : request_state_type;

    a_request : request_type;
    a_request_state   : request_state_type;
    a_request_way   : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    a_request_cache_accessed : std_ulogic;
    a_request_mmu_accessed : std_ulogic;
    a_request_cache_block_valid : std_ulogic;
    a_request_cache_block_dirty : std_ulogic;
    
    a_request_want_vtram : std_ulogic;
    a_request_want_rmdram : std_ulogic;
    a_request_want_bus_op : std_ulogic;
    a_request_can_own_vtram : std_ulogic;
    a_request_can_own_rmdram : std_ulogic;
    a_request_can_own_bus_op : std_ulogic;
    a_request_granted : std_ulogic;
    
    a_request_bus_op_code : bus_op_code_type;
    a_request_vram_re : std_ulogic;
    a_request_mram_re : std_ulogic;
    a_request_tram_en : std_ulogic;
    a_request_tram_we : std_ulogic;
    a_request_tram_banken : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    a_request_dram_en : std_ulogic;
    a_request_replace_re : std_ulogic;
    a_request_mmu_accessed_next : std_ulogic;


    a_stb_can_own_bus_op : std_ulogic;
    a_stb_can_own_vtram : std_ulogic;
    a_stb_can_own_rmdram : std_ulogic;
    a_stb_can_activate             : std_ulogic;
    a_stb_activate                 : std_ulogic;
    a_stb_write_cache : std_ulogic;
    a_stb_write_bus : std_ulogic;
    a_stb_way                    : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    a_stb_state                    : stb_state_type;
    a_stb_active                   : std_ulogic;
    a_stb_want_vtram : std_ulogic;
    a_stb_want_rmdram : std_ulogic;
    a_stb_want_bus_op : std_ulogic;
    a_stb_vram_re : std_ulogic;
    a_stb_mram_re : std_ulogic;
    a_stb_tram_en : std_ulogic;
    a_stb_tram_we : std_ulogic;
    a_stb_tram_banken : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    a_stb_dram_en : std_ulogic;
    a_stb_dram_we : std_ulogic;
    a_stb_dram_wdata_be : std_ulogic;
    a_stb_replace_re : std_ulogic;
    a_stb_bus_op_code : bus_op_code_type;
    a_stb_bus_op_way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    
    a_new_bus_op_owner : cpu_l1mem_data_cache_owner_type;
    a_new_bus_op_code : bus_op_code_type;
    a_new_bus_op_state : bus_op_state_type;
    a_new_bus_op_cacheable : std_ulogic;
    a_new_bus_op_be         : std_ulogic;
    a_new_bus_op_priv : std_ulogic;
    a_new_bus_op_way : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    a_new_bus_op_block_word : std_ulogic_vector(cpu_l1mem_data_cache_block_words-1 downto 0);
    a_new_bus_op_paddr_tag_sel_request : cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_type;
    a_new_bus_op_paddr_index_sel_request : cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_type;
    a_new_bus_op_paddr_offset_sel_request : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type;
    a_new_bus_op_paddr_tag_sel_stb : cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_type;
    a_new_bus_op_paddr_index_sel_stb : cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_type;
    a_new_bus_op_paddr_offset_sel_stb : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type;
    a_new_bus_op_paddr_tag_sel : cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_type;
    a_new_bus_op_paddr_index_sel : cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_type;
    a_new_bus_op_paddr_offset_sel : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type;
    a_new_bus_op_size_sel_request : cpu_l1mem_data_cache_a_bus_op_size_sel_type;
    a_new_bus_op_size_sel_stb : cpu_l1mem_data_cache_a_bus_op_size_sel_type;
    a_new_bus_op_size_sel : cpu_l1mem_data_cache_a_bus_op_size_sel_type;
    
    a_bus_op_owner       : cpu_l1mem_data_cache_owner_type;
    a_bus_op_state       : bus_op_state_type;
    a_bus_op_be          : std_ulogic;
    a_bus_op_priv        : std_ulogic;
    a_bus_op_way         : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    a_bus_op_cacheable   : std_ulogic;
    a_bus_op_block_word  : std_ulogic_vector(cpu_l1mem_data_cache_block_words-1 downto 0);
    a_bus_op_requested   : std_ulogic;
    a_bus_op_paddr_tag_sel : cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_type;
    a_bus_op_paddr_index_sel : cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_type;
    a_bus_op_paddr_offset_sel : cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_type;
    a_bus_op_size_sel : cpu_l1mem_data_cache_a_bus_op_size_sel_type;
    a_bus_op_cache_paddr_sel_old : std_ulogic;
    a_bus_op_sys_paddr_sel_old : std_ulogic;
    a_bus_op_sys_data_sel_cache : std_ulogic;

    a_bus_op_want_cache : std_ulogic;

    a_bus_op_vram_re : std_ulogic;
    a_bus_op_mram_re : std_ulogic;

    a_bus_op_tram_en : std_ulogic;
    a_bus_op_tram_we : std_ulogic;
    a_bus_op_tram_banken : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    
    a_bus_op_dram_en : std_ulogic;
    a_bus_op_dram_we : std_ulogic;
    
    a_bus_op_replace_re : std_ulogic;

    a_bus_op_can_own_vtram : std_ulogic;
    a_bus_op_can_own_rmdram : std_ulogic;
    a_bus_op_granted : std_ulogic;
    
    a_new_vtram_owner      : cpu_l1mem_data_cache_owner_type;
    a_new_rmdram_owner      : cpu_l1mem_data_cache_owner_type;
    a_vtram_owner      : cpu_l1mem_data_cache_owner_type;
    a_rmdram_owner      : cpu_l1mem_data_cache_owner_type;
    
    a_vram_re : std_ulogic;
    a_mram_re : std_ulogic;

    a_tram_en : std_ulogic;
    a_tram_we : std_ulogic;
    a_tram_banken : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);

    a_dram_en : std_ulogic;
    a_dram_we : std_ulogic;
    a_dram_wdata_be : std_ulogic;

    a_replace_re : std_ulogic;

    a_mmu_request : std_ulogic;

    a_sys_request : std_ulogic;
    a_sys_be : std_ulogic;
    a_sys_write : std_ulogic;
    a_sys_cacheable : std_ulogic;
    a_sys_priv : std_ulogic;
    a_sys_burst : std_ulogic;
    a_sys_bcycles : sys_burst_cycles_type;

  end record;

  signal c : comb_type;
  signal r, r_next : reg_type;
  
begin

  -------- post-phase

  -- get data read from srams
  c.b_vram_rdata <= cpu_l1mem_data_cache_ctrl_in_vram.rdata;

  c.b_vram_rdata_all_ones <= all_ones(c.b_vram_rdata);
  c.b_vram_rdata_first_free <= prioritize(not c.b_vram_rdata);

  c.b_mram_rdata <= cpu_l1mem_data_cache_ctrl_in_mram.rdata;
  
  c.b_replace_rway <= cpu_l1mem_data_cache_replace_ctrl_out.rway;
  
  with c.b_vram_rdata_all_ones select
    c.b_replace_way <= c.b_replace_rway          when '1',
                       c.b_vram_rdata_first_free when '0',
                       (others => 'X')           when others;

  c.b_replace_way_valid <= reduce_or(c.b_replace_way and c.b_vram_rdata);
  c.b_replace_way_dirty <= reduce_or(c.b_replace_way and c.b_mram_rdata);
  
  ---- bus operation post-phase

  c.b_bus_op_error <= (
    r.b_bus_op_requested and
    sys_slave_ctrl_out.ready and
    sys_slave_ctrl_out.error
    );
  c.b_bus_op_cycle_complete <= (
    r.b_bus_op_requested and
    sys_slave_ctrl_out.ready
    );
  with r.b_bus_op_state select
    c.b_bus_op_fill_load_data_ready <= c.b_bus_op_cycle_complete when bus_op_state_fill_first,
                                       sys_slave_ctrl_out.ready  when bus_op_state_fill,
                                       'X'                       when others;
  c.b_bus_op_fill_complete <= (
    r.b_bus_op_state(bus_op_state_index_fill_last)
    );
  c.b_bus_op_writeback_complete <= (
    r.b_bus_op_state(bus_op_state_index_writeback_last) and
    c.b_bus_op_cycle_complete
    );

  with r.b_bus_op_state select
    c.b_bus_op_complete_no_error <= '1'                       when bus_op_state_none |
                                                                   bus_op_state_fill_last,
                                    c.b_bus_op_cycle_complete when bus_op_state_load |
                                                                   bus_op_state_store |
                                                                   bus_op_state_writeback_last,
                                    '0'                       when bus_op_state_writeback_first |
                                                                   bus_op_state_writeback |
                                                                   bus_op_state_fill_first |
                                                                   bus_op_state_fill,
                                    'X'                       when others;
  c.b_bus_op_complete <= c.b_bus_op_complete_no_error or c.b_bus_op_error;
  
  b_bus_op_state_next_block_words_eq_1_gen : if cpu_l1mem_data_cache_block_words = 1 generate
    c.b_bus_op_state_next_fill_first <= (
      bus_op_state_index_fill_first => (
        not c.b_bus_op_cycle_complete
        ),
      bus_op_state_index_fill_last => (
        c.b_bus_op_cycle_complete
        ),
      others => '0'
      );
    c.b_bus_op_state_next_writeback_first <= (
      bus_op_state_index_writeback_first => (
        not c.b_bus_op_cycle_complete
        ),
      bus_op_state_index_writeback_last => (
        c.b_bus_op_cycle_complete
        ),
      others => '0'
      );
  end generate;
  b_bus_op_state_next_block_words_gt_1_gen : if cpu_l1mem_data_cache_block_words > 1 generate
    c.b_bus_op_state_next_fill_first <= (
      bus_op_state_index_fill_first => (
        not r.b_bus_op_granted
        ),
      bus_op_state_index_fill => (
        r.b_bus_op_granted
        ),
      others => '0'
      );
    c.b_bus_op_state_next_fill <= (
      bus_op_state_index_fill => (
        not c.b_bus_op_cycle_complete or
        not r.b_bus_op_block_word(cpu_l1mem_data_cache_block_words-1)
        ),
      bus_op_state_index_fill_last => (
        c.b_bus_op_cycle_complete and
        r.b_bus_op_block_word(cpu_l1mem_data_cache_block_words-1)
        ),
      others => '0'
      );
    c.b_bus_op_state_next_writeback_first <= (
      bus_op_state_index_writeback_first => (
        not c.b_bus_op_cycle_complete
        ),
      bus_op_state_index_writeback => (
        c.b_bus_op_cycle_complete
        ),
      others => '0'
      );
    c.b_bus_op_state_next_writeback <= (
      bus_op_state_index_writeback => (
        not c.b_bus_op_cycle_complete or
        not r.b_bus_op_block_word(cpu_l1mem_data_cache_block_words-1)
        ),
      bus_op_state_index_writeback_last => (
        c.b_bus_op_cycle_complete and
        r.b_bus_op_block_word(cpu_l1mem_data_cache_block_words-1)
        ),
      others => '0'
      );
  end generate;
  with r.b_bus_op_state select
    c.b_bus_op_state_next_no_error <= bus_op_state_load                          when bus_op_state_load,
                                      bus_op_state_store                         when bus_op_state_store,
                                      c.b_bus_op_state_next_fill_first           when bus_op_state_fill_first,
                                      c.b_bus_op_state_next_fill                 when bus_op_state_fill,
                                      bus_op_state_fill_last                     when bus_op_state_fill_last,
                                      c.b_bus_op_state_next_writeback_first      when bus_op_state_writeback_first,
                                      c.b_bus_op_state_next_writeback            when bus_op_state_writeback,
                                      bus_op_state_writeback_last                when bus_op_state_writeback_last,
                                      (others => 'X')                            when others;
  with c.b_bus_op_error select
    c.b_bus_op_state_next <= c.b_bus_op_state_next_no_error when '0',
                             bus_op_state_none              when '1',
                             (others => 'X')                when others;

  with r.b_bus_op_state select
    c.b_bus_op_block_word_advance <= sys_slave_ctrl_out.ready when bus_op_state_fill_first |
                                                                   bus_op_state_fill |
                                                                   bus_op_state_writeback_first |
                                                                   bus_op_state_writeback,
                                     '0'                      when bus_op_state_load |
                                                                   bus_op_state_store |
                                                                   bus_op_state_writeback_last,
                                     'X'                      when others;
  
  with c.b_bus_op_block_word_advance select
    c.b_bus_op_block_word_next <= r.b_bus_op_block_word when '0',
                                  (r.b_bus_op_block_word(cpu_l1mem_data_cache_block_words-2 downto 0) &
                                   r.b_bus_op_block_word(cpu_l1mem_data_cache_block_words-1)
                                   )                    when '1',
                                  (others => 'X')       when others;

  with r.b_bus_op_state select
    c.b_bus_op_vram_we <= '0'                                                   when bus_op_state_fill |
                                                                                     bus_op_state_writeback_first |
                                                                                     bus_op_state_writeback |
                                                                                     bus_op_state_writeback_last,
                          sys_slave_ctrl_out.ready and r.b_bus_op_block_word(0) when bus_op_state_fill_first,
                          '1'                       when bus_op_state_fill_last,
                          'X'                       when others;
  with r.b_bus_op_state select
    c.b_bus_op_vram_wdata <= c.b_vram_rdata and not r.b_bus_op_way when bus_op_state_fill,
                             c.b_vram_rdata or r.b_bus_op_way      when bus_op_state_fill_last,
                             (others => 'X')                       when others;

  with r.b_bus_op_state select
    c.b_bus_op_mram_we <= '0'                      when bus_op_state_fill_first |
                                                        bus_op_state_fill |
                                                        bus_op_state_writeback_first |
                                                        bus_op_state_writeback,
                          '1'                      when bus_op_state_fill_last,
                          sys_slave_ctrl_out.ready when bus_op_state_writeback_last,
                          'X'                      when others;
  with r.b_bus_op_state select
    c.b_bus_op_mram_wdata <= c.b_mram_rdata and not r.b_bus_op_way when bus_op_state_fill_last |
                                                                        bus_op_state_writeback_last,
                             (others => 'X')                       when others;

  with r.b_bus_op_state select
    c.b_bus_op_replace_we <= '0' when bus_op_state_fill_first |
                                      bus_op_state_fill |
                                      bus_op_state_writeback_first |
                                      bus_op_state_writeback |
                                      bus_op_state_writeback_last,
                             '1' when bus_op_state_fill_last,
                             'X' when others;
  c.b_bus_op_replace_wway <= r.b_bus_op_way;

  -- block change (fill/invalidation) notification

  with r.b_bus_op_state select
    c.b_block_change <= '1'                       when bus_op_state_fill_first |
                                                       bus_op_state_fill_last,
                        '0'                       when bus_op_state_none |
                                                       bus_op_state_load |
                                                       bus_op_state_store |
                                                       bus_op_state_fill |
                                                       bus_op_state_writeback_first |
                                                       bus_op_state_writeback |
                                                       bus_op_state_writeback_last,
                        'X' when others;
  with r.b_bus_op_state select
    c.b_block_change_valid <= '0' when bus_op_state_fill_first,
                              '1' when bus_op_state_fill_last,
                              'X' when others;
  c.b_block_change_way <= r.b_bus_op_way;
  
  ---- stb operation post-phase

  c.b_stb_full  <= all_ones(r.b_stb_array_valid);
  c.b_stb_empty <= all_zeros(r.b_stb_array_valid);

  -- stb_state_init: stb is inactive
  -- stb_state_replace_access:
  --   vram, mram, & replace are already owned
  --   valid, dirty, & replace way are now available.
  -- stb_state_fill: waiting for bus fill operation to complete
  -- stb_state_write: write to cache and/or bus, read/write replace state
  
  c.b_stb_state_next_replace_access <= (
    stb_state_index_writeback => (
      c.b_replace_way_valid and
      c.b_replace_way_dirty
      ),
    stb_state_index_fill => (
      not c.b_replace_way_valid or
      not c.b_replace_way_dirty
      ),
    others => '0'
    );
  c.b_stb_state_next_writeback <= (
    stb_state_index_writeback => (
      not c.b_bus_op_writeback_complete
      ),
    stb_state_index_fill => (
      c.b_bus_op_writeback_complete
      ),
    others => '0'
    );  
  c.b_stb_state_next_fill <= (
    stb_state_index_fill => (
      not c.b_bus_op_fill_complete
      ),
    stb_state_index_write => (
      c.b_bus_op_fill_complete
      ),
    others => '0'
    );  
  c.b_stb_state_next_write <= (
    stb_state_index_init => (
      not r.b_stb_write_bus or
      c.b_bus_op_cycle_complete
      ),
    stb_state_index_write => (
      r.b_stb_write_bus and
      not c.b_bus_op_cycle_complete
      ),
    others => '0'
    );
  with r.b_stb_state select
    c.b_stb_state_next <= stb_state_init                    when stb_state_init,
                          c.b_stb_state_next_replace_access when stb_state_replace_access,
                          c.b_stb_state_next_writeback      when stb_state_writeback,
                          c.b_stb_state_next_fill           when stb_state_fill,
                          c.b_stb_state_next_write          when stb_state_write,
                          (others => 'X')                   when others;

  with r.b_stb_state select
    c.b_stb_mram_we <= '0'                 when stb_state_replace_access |
                                                stb_state_writeback |
                                                stb_state_fill,
                       r.b_stb_write_cache when stb_state_write,
                       'X'                               when others;
  with r.b_stb_state select
    c.b_stb_mram_wdata <= c.b_mram_rdata or r.b_stb_way when stb_state_write,
                          (others => 'X')               when others;
  
  with r.b_stb_state select
    c.b_stb_replace_we <= '0'                               when stb_state_replace_access |
                                                                 stb_state_writeback |
                                                                 stb_state_fill,
                          (r.b_stb_write_cache and
                           (not r.b_stb_write_bus or
                            c.b_bus_op_cycle_complete))     when stb_state_write,
                          'X'                               when others;
  c.b_stb_replace_wway <= r.b_stb_way;
  
  c.b_stb_pop_write <= (
    not r.b_stb_write_bus or
    c.b_bus_op_cycle_complete
    );
  
  with r.b_stb_state select
    c.b_stb_pop <= '0'                       when stb_state_init |
                                                  stb_state_replace_access |
                                                  stb_state_fill |
                                                  stb_state_writeback,
                   c.b_stb_pop_write         when stb_state_write,
                   'X'                       when others;

  b_stb_head_ptr_next_gen : if cpu_l1mem_data_cache_stb_entries > 0 generate
    
    with c.b_stb_pop select
      c.b_stb_head_ptr_next <= (r.b_stb_head_ptr(cpu_l1mem_data_cache_stb_entries-2 downto 0) &
                                r.b_stb_head_ptr(cpu_l1mem_data_cache_stb_entries-1))           when '1',
                               r.b_stb_head_ptr                                                 when '0',
                               (others => 'X')                                                  when others;
    
  end generate;

  c.b_stb_can_push <= not c.b_stb_full or c.b_stb_pop;

  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      assert not is_x(c.b_stb_head_ptr_next) and is_1hot(c.b_stb_head_ptr_next) = '1'
        report "c.b_stb_head_ptr_next is invalid"
        severity failure;
      assert not is_x(c.b_stb_tail_ptr_next) and is_1hot(c.b_stb_tail_ptr_next) = '1'
        report "c.b_stb_tail_ptr_next is invalid"
        severity failure;
      case r.b_stb_state is
        when stb_state_init |
             stb_state_replace_access |
             stb_state_writeback |
             stb_state_fill |
             stb_state_write =>
        when others =>
          assert false
            report "r.b_stb_state is invalid"
            severity failure;
      end case;
      case c.b_stb_state_next is
        when stb_state_init |
             stb_state_replace_access |
             stb_state_writeback |
             stb_state_fill |
             stb_state_write =>
          null;
        when others =>
          assert false
            report "c.b_stb_state_next is invalid"
            severity failure;
      end case;
      assert not is_x(c.b_stb_pop)
        report "c.b_stb_pop is invalid"
        severity failure;
    end if;
  end process;
  -- pragma translate_on
  
  ---- request post-phase

  c.b_request_sync <= (
    r.b_vtram_owner(cpu_l1mem_data_cache_owner_index_none) and
    r.b_rmdram_owner(cpu_l1mem_data_cache_owner_index_none) and
    r.b_bus_op_owner(cpu_l1mem_data_cache_owner_index_none) and
    c.b_stb_empty
    );    

  c.b_request_mmu_result_ready <= (
    r.b_request_mmu_accessed and 
    cpu_mmu_data_ctrl_out.ready
    );
  c.b_request_mmu_result_valid <= (
    r.b_request_mmu_accessed and 
    cpu_mmu_data_ctrl_out.ready and
    cpu_mmu_data_ctrl_out.result(cpu_mmu_data_result_code_index_valid)
    );
  c.b_request_mmu_error <= (
    r.b_request_mmu_accessed and 
    cpu_mmu_data_ctrl_out.ready and
    not cpu_mmu_data_ctrl_out.result(cpu_mmu_data_result_code_index_valid)
    );

  -- check for cache hit
  c.b_request_cache_way_hit <= (c.b_vram_rdata and
                                cpu_l1mem_data_cache_dp_out_ctrl.b_request_cache_tag_match);
  c.b_request_cache_hit <= reduce_or(c.b_request_cache_way_hit);
  c.b_request_cache_miss <= not c.b_request_cache_hit;
  
  c.b_request_cache_way_hit_dirty <= (
    c.b_request_cache_way_hit and c.b_mram_rdata
    );
  c.b_request_cache_hit_dirty <= reduce_or(c.b_request_cache_way_hit_dirty);
  
  c.b_request_cache_way_hit_clean <= (
    c.b_request_cache_way_hit and not c.b_mram_rdata
    );
  c.b_request_cache_hit_clean <= reduce_or(c.b_request_cache_way_hit_clean);

  with r.b_request_state select
    c.b_request_cache_block_valid <= c.b_replace_way_valid               when request_state_cached_load_l1_access,
                                     'X'                                 when others;
  with r.b_request_state select
    c.b_request_cache_block_dirty <= c.b_replace_way_dirty               when request_state_cached_load_l1_access,
                                     'X'                                 when others;
  
  -- check for stb hit
  b_request_stb_gen : for n in cpu_l1mem_data_cache_stb_entries-1 downto 0 generate
    
    c.b_request_stb_array_hit(n) <= (
      r.b_stb_array_valid(n) and
      (r.b_request.be xnor r.b_stb_array_be(n)) and
      (r.b_request.writethrough xnor r.b_stb_array_writethrough(n)) and
      cpu_l1mem_data_cache_dp_out_ctrl.b_request_stb_array_tag_match(n) and
      cpu_l1mem_data_cache_dp_out_ctrl.b_request_stb_array_index_match(n) and
      cpu_l1mem_data_cache_dp_out_ctrl.b_request_stb_array_block_word_offset_match(n) and
      cpu_l1mem_data_cache_dp_out_ctrl.b_request_stb_array_word_byte_offset_match(n) and
      cpu_l1mem_data_cache_dp_out_ctrl.b_request_stb_array_size_match(n)
      );
    c.b_request_stb_array_conflict(n) <= (
      r.b_stb_array_valid(n) and
      cpu_l1mem_data_cache_dp_out_ctrl.b_request_stb_array_tag_match(n) and
      cpu_l1mem_data_cache_dp_out_ctrl.b_request_stb_array_index_match(n) and
      cpu_l1mem_data_cache_dp_out_ctrl.b_request_stb_array_block_word_offset_match(n) and
      ((r.b_request.be xor r.b_stb_array_be(n)) or
       not cpu_l1mem_data_cache_dp_out_ctrl.b_request_stb_array_word_byte_offset_match(n) or
       not cpu_l1mem_data_cache_dp_out_ctrl.b_request_stb_array_size_match(n))
      );

  end generate;

  c.b_request_stb_hit      <= any_ones(c.b_request_stb_array_hit);
  c.b_request_stb_head_hit <= any_ones(c.b_request_stb_array_hit and r.b_stb_head_ptr);
  c.b_request_stb_conflict <= any_ones(c.b_request_stb_array_conflict);

  -- a store request can combine with a request in the stb if
  -- 1) the request address, size, and endianness match
  -- 2) the matching stb entry has not started processing
  --    (e.g. the matching entry is the head and is not in the init state)
  -- 3) the request does not conflict with any other entries
  c.b_request_stb_can_combine <= (
    c.b_request_stb_hit and
    not (c.b_request_stb_head_hit and
         not r.b_stb_state(stb_state_index_init)) and
    not c.b_request_stb_conflict
    );
  
  -- request completion

  c.b_request_complete_uncached_mmu_access <= (
    c.b_request_mmu_error
    );
  c.b_request_complete_uncached_bus_op <= (
    r.b_request_granted and
    c.b_bus_op_cycle_complete
    );
  c.b_request_complete_cached_load_l1_access <= (
    (c.b_request_mmu_result_valid and
     ((r.b_request_granted and
       c.b_request_cache_hit) or
      c.b_request_stb_hit
      )
     ) or
    c.b_request_mmu_error
    );
  c.b_request_complete_cached_load_fill <= (
    r.b_request_granted and
    c.b_bus_op_fill_load_data_ready
    );
  c.b_request_complete_cached_store_l1_access <= (
    (c.b_request_mmu_result_valid and
     r.b_request_granted and
     (c.b_stb_can_push or
      c.b_request_stb_can_combine
      )
     ) or
    c.b_request_mmu_error
    );
  c.b_request_complete_invalidate_l1_access <= (
    r.b_request_granted
    );
  c.b_request_complete_writeback_l1_access <= (
    (r.b_request_granted and
     c.b_request_mmu_result_valid and
     (c.b_request_cache_miss or
      c.b_request_cache_hit_clean)
     ) or
    c.b_request_mmu_error
    );
  c.b_request_complete_writeback_bus_op <= (
    r.b_request_granted and
    c.b_bus_op_writeback_complete
    );
  c.b_request_complete_flush_l1_access <= (
    c.b_request_mmu_error or
    (r.b_request_granted and
     c.b_request_cache_hit_clean)
    );
  c.b_request_complete_sync <= (
    c.b_request_sync
    );
  
  with r.b_request_state select
    c.b_request_complete_no_error <= '1'                                         when request_state_none |
                                                                                      request_state_flush_invalidate_l1_access,
                                     c.b_request_complete_uncached_mmu_access    when request_state_uncached_load_mmu_access |
                                                                                      request_state_uncached_store_mmu_access,
                                     c.b_request_complete_uncached_bus_op        when request_state_uncached_load_bus_op |
                                                                                      request_state_uncached_store_bus_op,
                                     c.b_request_complete_cached_load_l1_access  when request_state_cached_load_l1_access,
                                     c.b_request_complete_cached_load_fill       when request_state_cached_load_fill,
                                     c.b_request_complete_cached_store_l1_access when request_state_cached_store_l1_access,
                                     c.b_request_complete_sync                   when request_state_sync,
                                     c.b_request_complete_invalidate_l1_access   when request_state_invalidate_l1_access,
                                     c.b_request_complete_writeback_l1_access    when request_state_writeback_l1_access,
                                     c.b_request_complete_writeback_bus_op       when request_state_writeback_bus_op,
                                     c.b_request_complete_flush_l1_access        when request_state_flush_l1_access,
                                     '0'                                         when request_state_cached_load_writeback |
                                                                                      request_state_cached_store_stb_wait |
                                                                                      request_state_invalidate_sync |
                                                                                      request_state_writeback_sync |
                                                                                      request_state_flush_sync |
                                                                                      request_state_flush_bus_op,
                                     'X'                                         when others;
  c.b_request_complete <= c.b_request_complete_no_error or c.b_bus_op_error;
  
  with r.b_request_state select
    c.b_request_way_next <= c.b_replace_way           when request_state_cached_load_l1_access,
                            c.b_request_cache_way_hit when request_state_writeback_l1_access |
                                                           request_state_flush_l1_access,
                            r.b_request_way           when request_state_cached_load_fill |
                                                           request_state_cached_load_writeback,
                            (others => 'X')           when others;
  
  c.b_request_state_next_uncached_load_mmu_access <= (
    request_state_index_uncached_load_mmu_access => (
      not c.b_request_mmu_result_ready
      ),
    request_state_index_uncached_load_bus_op => (
      c.b_request_mmu_result_ready
      ),
    others => '0'
    );
  c.b_request_state_next_cached_load_writeback <= (
    request_state_index_cached_load_writeback => (
      not c.b_bus_op_writeback_complete
      ),
    request_state_index_cached_load_fill => (
      c.b_bus_op_writeback_complete
      ),
    others => '0'
    );
  c.b_request_state_next_uncached_store_mmu_access <= (
    request_state_index_uncached_store_mmu_access => (
      not c.b_request_mmu_result_ready
      ),
    request_state_index_uncached_store_bus_op => (
      c.b_request_mmu_result_ready
      ),
    others => '0'
    );
  c.b_request_state_next_cached_load_l1_access <= (
    request_state_index_cached_load_l1_access => (
      not r.b_request_granted or
      not c.b_request_mmu_result_ready
      ),
    request_state_index_cached_load_writeback => (
      r.b_request_granted and
      r.b_request.alloc and
      c.b_request_mmu_result_ready and
      c.b_request_cache_block_valid and
      c.b_request_cache_block_dirty
      ),
    request_state_index_cached_load_fill => (
      r.b_request_granted and
      r.b_request.alloc and
      c.b_request_mmu_result_ready and
      (not c.b_request_cache_block_valid or 
       not c.b_request_cache_block_dirty)
      ),
    request_state_index_uncached_load_bus_op => (
      r.b_request_granted and
      not r.b_request.alloc
      ),
    others => '0'
    );
  c.b_request_state_next_cached_store_stb_wait <= (
    request_state_index_cached_store_stb_wait => (
      not c.b_stb_pop
      ),
    request_state_index_cached_store_l1_access => (
      c.b_stb_pop
      ),
    others => '0'
    );
  c.b_request_state_next_writeback_l1_access <= (
    request_state_index_writeback_l1_access => (
      not r.b_request_granted or
      not c.b_request_mmu_result_ready
      ),
    request_state_index_writeback_bus_op => (
      r.b_request_granted and
      c.b_request_cache_hit_dirty
      ),
    others => '0'
    );
  c.b_request_state_next_invalidate_sync <= (
    request_state_index_invalidate_sync => (
      not c.b_request_sync
      ),
    request_state_index_invalidate_l1_access => (
      c.b_request_sync
      ),
    others => '0'
    );
  c.b_request_state_next_writeback_sync <= (
    request_state_index_writeback_sync => (
      not c.b_request_sync
      ),
    request_state_index_writeback_l1_access => (
      c.b_request_sync
      ),
    others => '0'
    );
  c.b_request_state_next_flush_sync <= (
    request_state_index_flush_sync => (
      not c.b_request_sync
      ),
    request_state_index_flush_l1_access => (
      c.b_request_sync
      ),
    others => '0'
    );
  c.b_request_state_next_flush_l1_access <= (
    request_state_index_none => (
      r.b_request_granted and
      not c.b_request_cache_hit
      ),
    request_state_index_flush_l1_access => (
      not r.b_request_granted
      ),
    request_state_index_flush_bus_op => (
      r.b_request_granted and
      c.b_request_cache_hit
      ),
    others => '0'
    );
  with r.b_request_state select
    c.b_request_state_next <= r.b_request_state                                when request_state_none |
                                                                                    request_state_uncached_load_bus_op |
                                                                                    request_state_uncached_store_bus_op |
                                                                                    request_state_cached_store_l1_access |
                                                                                    request_state_invalidate_l1_access |
                                                                                    request_state_flush_invalidate_l1_access,
                              c.b_request_state_next_cached_load_writeback     when request_state_cached_load_writeback,
                              request_state_cached_load_fill                   when request_state_cached_load_fill,
                              c.b_request_state_next_uncached_load_mmu_access  when request_state_uncached_load_mmu_access,
                              c.b_request_state_next_uncached_store_mmu_access when request_state_uncached_store_mmu_access,
                              c.b_request_state_next_cached_load_l1_access     when request_state_cached_load_l1_access,
                              c.b_request_state_next_cached_store_stb_wait     when request_state_cached_store_stb_wait,
                              c.b_request_state_next_writeback_l1_access       when request_state_writeback_l1_access,
                              request_state_writeback_bus_op                   when request_state_writeback_bus_op,
                              c.b_request_state_next_invalidate_sync           when request_state_invalidate_sync,
                              c.b_request_state_next_writeback_sync            when request_state_writeback_sync,
                              c.b_request_state_next_flush_sync                when request_state_flush_sync,
                              c.b_request_state_next_flush_l1_access           when request_state_flush_l1_access,
                              request_state_sync                               when request_state_sync,
                              (others => 'X')                                  when others;

  with r.b_request_state select
    c.b_request_cache_accessed_next <= r.b_request_granted when request_state_cached_load_l1_access |
                                                                request_state_cached_store_l1_access |
                                                                request_state_invalidate_l1_access |
                                                                request_state_writeback_l1_access |
                                                                request_state_flush_l1_access |
                                                                request_state_flush_invalidate_l1_access,
                                       '0'                 when request_state_none |
                                                                request_state_cached_store_stb_wait |
                                                                request_state_invalidate_sync |
                                                                request_state_writeback_sync |
                                                                request_state_flush_sync |
                                                                request_state_flush_bus_op,
                                       'X'                 when others;

  with r.b_request_state select
    c.b_request_replace_we <= (c.b_request_mmu_result_valid and
                               c.b_request_cache_hit
                               )  when request_state_cached_load_l1_access,
                              '0' when request_state_cached_store_l1_access |
                                       request_state_flush_invalidate_l1_access |
                                       request_state_invalidate_l1_access,
                              'X' when others;
  with r.b_request_state select
    c.b_request_replace_wway <= c.b_request_cache_way_hit when request_state_cached_load_l1_access |
                                                               request_state_cached_store_l1_access,
                                (others => 'X')           when others;

  with r.b_request_state select
    c.b_request_vram_we <= '1' when request_state_invalidate_l1_access |
                                    request_state_flush_invalidate_l1_access,
                           '0' when request_state_cached_load_l1_access |
                                    request_state_cached_store_l1_access |
                                    request_state_writeback_l1_access |
                                    request_state_flush_l1_access,
                           'X' when others;
  
  with r.b_request_state select
    c.b_request_vram_wdata <= (others => '0')                        when request_state_invalidate_l1_access,
                              c.b_vram_rdata and not r.b_request_way when request_state_flush_invalidate_l1_access,
                              (others => 'X')                        when others;

  -- stb update
  c.b_stb_push <= (
    r.b_request_state(request_state_index_cached_store_l1_access) and
    c.b_request_mmu_result_valid and
    r.b_request_granted and
    not c.b_request_stb_can_combine and
    c.b_stb_can_push
    );
  c.b_stb_combine <= (
    r.b_request_state(request_state_index_cached_store_l1_access) and
    c.b_request_mmu_result_valid and
    r.b_request_granted and
    c.b_request_stb_can_combine
    );

  b_stb_tail_ptr_next_gen : if cpu_l1mem_data_cache_stb_entries > 0 generate
 
   with c.b_stb_push select
      c.b_stb_tail_ptr_next <= (r.b_stb_tail_ptr(cpu_l1mem_data_cache_stb_entries-2 downto 0) &
                                r.b_stb_tail_ptr(cpu_l1mem_data_cache_stb_entries-1))           when '1',
                               r.b_stb_tail_ptr                                                 when '0',
                               (others => 'X')                                                  when others;
    
  end generate;

  c.b_stb_push_ptr <= (
    ((cpu_l1mem_data_cache_stb_entries-1 downto 0 => c.b_stb_push) and
     r.b_stb_tail_ptr)
    );

  c.b_stb_combine_ptr <= (
    (cpu_l1mem_data_cache_stb_entries-1 downto 0 => c.b_stb_combine) and
    (not r.b_stb_head_ptr or
     (cpu_l1mem_data_cache_stb_entries-1 downto 0 => r.b_stb_state(stb_state_index_init))) and
    c.b_request_stb_array_hit
    );

  c.b_stb_push_entry_cache_hit    <= c.b_request_cache_hit;
  c.b_stb_push_entry_writethrough <= r.b_request.writethrough;
  c.b_stb_push_entry_alloc        <= r.b_request.alloc;
  c.b_stb_push_entry_be           <= r.b_request.be;
  c.b_stb_push_entry_priv         <= r.b_request.priv;
  c.b_stb_push_entry_way          <= c.b_request_cache_way_hit;

  b_stb_array_block_change_gen : for n in cpu_l1mem_data_cache_stb_entries-1 downto 0 generate
    c.b_stb_array_block_change(n) <= (
      c.b_block_change and
      cpu_l1mem_data_cache_dp_out_ctrl.b_stb_array_block_change_index_match(n) and
      logic_if(c.b_block_change_valid,
               cpu_l1mem_data_cache_dp_out_ctrl.b_stb_array_block_change_tag_match(n),
               reduce_or(std_ulogic_vector2_slice2(r.b_stb_array_way, n) and
                         c.b_block_change_way))
      );
  end generate;
  
  c.b_stb_array_valid_next <= (
    ((r.b_stb_array_valid and
      not (r.b_stb_head_ptr and
           (cpu_l1mem_data_cache_stb_entries-1 downto 0 => c.b_stb_pop))) or
     c.b_stb_push_ptr) and
    not (cpu_l1mem_data_cache_stb_entries-1 downto 0 => c.b_bus_op_error)
    );

  c.b_stb_array_cache_hit_next <= (
    (c.b_stb_push_ptr and (cpu_l1mem_data_cache_stb_entries-1 downto 0 => c.b_stb_push_entry_cache_hit)) or
    (not c.b_stb_push_ptr and
     ((c.b_stb_array_block_change and (cpu_l1mem_data_cache_stb_entries-1 downto 0 => c.b_block_change_valid)) or
      (not c.b_stb_array_block_change and r.b_stb_array_cache_hit))
     )
    );
  c.b_stb_array_alloc_next <= (
    (c.b_stb_push_ptr and (cpu_l1mem_data_cache_stb_entries-1 downto 0 => c.b_stb_push_entry_alloc)) or
    (not c.b_stb_push_ptr and r.b_stb_array_alloc)
    );
  c.b_stb_array_writethrough_next <= (
    (c.b_stb_push_ptr and (cpu_l1mem_data_cache_stb_entries-1 downto 0 => c.b_stb_push_entry_writethrough)) or
    (not c.b_stb_push_ptr and r.b_stb_array_writethrough)
    );
  c.b_stb_array_be_next <= (
    (c.b_stb_push_ptr and (cpu_l1mem_data_cache_stb_entries-1 downto 0 => c.b_stb_push_entry_be)) or
    (not c.b_stb_push_ptr and r.b_stb_array_be)
    );
  c.b_stb_array_priv_next <= (
    (c.b_stb_push_ptr and (cpu_l1mem_data_cache_stb_entries-1 downto 0 => c.b_stb_push_entry_priv)) or
    (not c.b_stb_push_ptr and r.b_stb_array_priv)
    );

  b_stb_array_way_next_gen : for n in cpu_l1mem_data_cache_stb_entries-1 downto 0 generate
    blk : block
      signal din : std_ulogic_vector2(2 downto 0, cpu_l1mem_data_cache_assoc-1 downto 0);
      signal sel : std_ulogic_vector(2 downto 0);
      signal dout : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);
    begin
      sel <= (0 => c.b_stb_push_ptr(n),
              1 => not c.b_stb_push_ptr(n) and not c.b_stb_array_block_change(n),
              2 => not c.b_stb_push_ptr(n) and c.b_stb_array_block_change(n)
              );
      din_gen : for m in cpu_l1mem_data_cache_assoc-1 downto 0 generate
        din(0, m) <= c.b_stb_push_entry_way(m);
        din(1, m) <= r.b_stb_array_way(n, m);
        din(2, m) <= c.b_block_change_way(m);
      end generate;
      mux : entity tech.mux_1hot(rtl)
        generic map (
          data_bits => cpu_l1mem_data_cache_assoc,
          sel_bits => 3
          )
        port map (
          din => din,
          sel => sel,
          dout => dout
          );
      dout_gen : for m in cpu_l1mem_data_cache_assoc-1 downto 0 generate
        c.b_stb_array_way_next(n, m) <= dout(m);
      end generate;
    end block;
  end generate;

  c.b_stb_write_bus_next <= r.b_stb_write_bus;
  with r.b_stb_state select
    c.b_stb_write_cache_next <= r.b_stb_write_cache when stb_state_replace_access |
                                                         stb_state_writeback |
                                                         stb_state_fill,
                                '0'                 when stb_state_write,
                                'X'                 when others;

  with r.b_stb_state select
    c.b_stb_way_next <= c.b_replace_way  when stb_state_replace_access,
                        r.b_stb_way      when stb_state_fill |
                                              stb_state_writeback |
                                              stb_state_write,
                        (others => 'X')  when others;
  
  -- cache read
  with r.b_rmdram_owner select
    c.b_cache_read_data_be <= r.b_bus_op_be   when cpu_l1mem_data_cache_owner_bus_op,
                              r.b_request.be  when cpu_l1mem_data_cache_owner_request,
                              'X'             when others;
  with r.b_rmdram_owner select
    c.b_cache_read_data_way <= r.b_bus_op_way            when cpu_l1mem_data_cache_owner_bus_op,
                               c.b_request_cache_way_hit when cpu_l1mem_data_cache_owner_request,
                               (others => 'X')           when others;

  -- request result processing
  c.b_result_ready <= c.b_request_complete;
  
  c.b_result_code_mmu_access <= (
    cpu_l1mem_data_result_code_index_valid => (
      not r.b_request.mmuen or
      cpu_mmu_data_ctrl_out.result(cpu_mmu_data_result_code_index_valid)
      ),
    cpu_l1mem_data_result_code_index_error => (
      r.b_request.mmuen and
      cpu_mmu_data_ctrl_out.result(cpu_mmu_data_result_code_index_error)
      ),
    cpu_l1mem_data_result_code_index_tlbmiss => (
      r.b_request.mmuen and
      cpu_mmu_data_ctrl_out.result(cpu_mmu_data_result_code_index_tlbmiss)
      ),
    cpu_l1mem_data_result_code_index_pf => (
      r.b_request.mmuen and
      cpu_mmu_data_ctrl_out.result(cpu_mmu_data_result_code_index_pf)
      )
    );
  
  with r.b_request_state select
    c.b_result_code_no_error <= c.b_result_code_mmu_access       when request_state_uncached_load_mmu_access |
                                                                      request_state_uncached_store_mmu_access |
                                                                      request_state_cached_load_l1_access |
                                                                      request_state_cached_store_l1_access,
                                cpu_l1mem_data_result_code_valid when request_state_none |
                                                                      request_state_uncached_load_bus_op |
                                                                      request_state_uncached_store_bus_op |
                                                                      request_state_cached_load_fill |
                                                                      request_state_invalidate_l1_access |
                                                                      request_state_writeback_l1_access |
                                                                      request_state_writeback_bus_op |
                                                                      request_state_flush_l1_access |
                                                                      request_state_flush_invalidate_l1_access |
                                                                      request_state_sync,
                                (others => 'X')                  when others;
  
  with c.b_bus_op_error select
    c.b_result_code <= cpu_l1mem_data_result_code_error when '1',
                       c.b_result_code_no_error         when '0',
                       (others => 'X')                  when others;


  with c.b_request_stb_hit select
    c.b_result_data_sel_cached_load_l1_access <= cpu_l1mem_data_cache_b_result_data_sel_stb   when '1',
                                                 cpu_l1mem_data_cache_b_result_data_sel_cache when '0',
                                                 (others => 'X')                              when others;
  
  with r.b_request_state select
    c.b_result_data_sel <= c.b_result_data_sel_cached_load_l1_access          when request_state_cached_load_l1_access,
                           cpu_l1mem_data_cache_b_result_data_sel_bus         when request_state_uncached_load_bus_op,
                           cpu_l1mem_data_cache_b_result_data_sel_bus_shifted when request_state_cached_load_fill,
                           (others => 'X')                                    when others;

  -- write vram, mram, replace ram
  with r.b_rmdram_owner select
    c.b_replace_we_no_error <= c.b_request_replace_we when cpu_l1mem_data_cache_owner_request,
                               c.b_stb_replace_we     when cpu_l1mem_data_cache_owner_stb,
                               c.b_bus_op_replace_we  when cpu_l1mem_data_cache_owner_bus_op,
                               '0'                    when cpu_l1mem_data_cache_owner_none,
                               'X'                    when others;
  c.b_replace_we <= c.b_replace_we_no_error and not c.b_bus_op_error;

  with r.b_rmdram_owner select
    c.b_replace_wway <= c.b_request_replace_wway when cpu_l1mem_data_cache_owner_request,
                        c.b_stb_replace_wway     when cpu_l1mem_data_cache_owner_stb,
                        c.b_bus_op_replace_wway  when cpu_l1mem_data_cache_owner_bus_op,
                        (others => 'X')          when others;

  with r.b_vtram_owner select
    c.b_vram_we_no_error <= c.b_request_vram_we when cpu_l1mem_data_cache_owner_request,
                            c.b_bus_op_vram_we  when cpu_l1mem_data_cache_owner_bus_op,
                            '0'                 when cpu_l1mem_data_cache_owner_stb |
                                                     cpu_l1mem_data_cache_owner_none,
                            'X'                 when others;
  c.b_vram_we <= c.b_vram_we_no_error and not c.b_bus_op_error;
  
  with r.b_vtram_owner select
    c.b_vram_wdata <= c.b_request_vram_wdata when cpu_l1mem_data_cache_owner_request,
                      c.b_bus_op_vram_wdata  when cpu_l1mem_data_cache_owner_bus_op,
                      (others => 'X')        when others;

  with r.b_rmdram_owner select
    c.b_mram_we_no_error <= c.b_stb_mram_we    when cpu_l1mem_data_cache_owner_stb,
                            c.b_bus_op_mram_we when cpu_l1mem_data_cache_owner_bus_op,
                            '0'                when cpu_l1mem_data_cache_owner_request |
                                                    cpu_l1mem_data_cache_owner_none,
                            'X'                when others;
  c.b_mram_we <= c.b_mram_we_no_error and not c.b_bus_op_error;
  
  with r.b_rmdram_owner select
    c.b_mram_wdata <= c.b_stb_mram_wdata    when cpu_l1mem_data_cache_owner_stb,
                      c.b_bus_op_mram_wdata when cpu_l1mem_data_cache_owner_bus_op,
                      (others => 'X')       when others;
  
  -- preserve ownerships for next cycle if necessary
  -- current owner decides who gets it next

  -- cache owner when the current owner is a bus op, that is in turn owned by a request
  with r.b_request_state select
    c.b_cache_owner_next_bus_op_request <=
      (cpu_l1mem_data_cache_owner_index_none => (
         c.b_bus_op_error
         ),
       cpu_l1mem_data_cache_owner_index_bus_op => (
         not c.b_bus_op_error
         ),
       others => '0'
       ) when request_state_cached_load_writeback,
      (cpu_l1mem_data_cache_owner_index_none => (
         c.b_bus_op_fill_complete or
         c.b_bus_op_error
         ),
       cpu_l1mem_data_cache_owner_index_bus_op => (
         not c.b_bus_op_fill_complete and
         not c.b_bus_op_error
         ),
       others => '0'
       ) when request_state_cached_load_fill,
      (cpu_l1mem_data_cache_owner_index_none => (
         c.b_bus_op_writeback_complete
         ),
       cpu_l1mem_data_cache_owner_index_bus_op => (
         not c.b_bus_op_writeback_complete
         ),
       others => '0'
       ) when request_state_writeback_bus_op,
      (cpu_l1mem_data_cache_owner_index_request => (
         c.b_bus_op_writeback_complete
         ),
       cpu_l1mem_data_cache_owner_index_bus_op => (
         not c.b_bus_op_writeback_complete
         ),
       others => '0'
       ) when request_state_flush_bus_op,
      (others => 'X') when others;

  with r.b_bus_op_state select
    c.b_cache_owner_next_bus_op_bus_op <=
      cpu_l1mem_data_cache_owner_bus_op    when bus_op_state_fill_first |
                           bus_op_state_fill,
      cpu_l1mem_data_cache_owner_none      when bus_op_state_fill_last,
      (others => 'X') when others;

  with r.b_stb_state select
    c.b_cache_owner_next_stb <=
      cpu_l1mem_data_cache_owner_bus_op    when stb_state_replace_access,
      cpu_l1mem_data_cache_owner_none      when stb_state_write,
      (others => 'X') when others;
  
  -- Choose the next cache vram & tram owner when the current owner is the request
  with r.b_request_state select
    c.b_vtram_owner_next_request <=
      (cpu_l1mem_data_cache_owner_index_none => (
         c.b_request_mmu_result_ready
         ),
       cpu_l1mem_data_cache_owner_index_request => (
         not c.b_request_mmu_result_ready
         ),
       others => '0'
       ) when request_state_cached_load_l1_access |
              request_state_writeback_l1_access |
              request_state_flush_l1_access,
      (cpu_l1mem_data_cache_owner_index_none => (
        (c.b_request_mmu_result_ready and
         (c.b_stb_can_push or
          c.b_request_stb_can_combine
          )) or
        c.b_request_mmu_error
        ),
       cpu_l1mem_data_cache_owner_index_request => (
         not c.b_request_mmu_result_ready or
         (not c.b_stb_can_push and
          not c.b_request_stb_can_combine)
         ),
       others => '0'
       ) when request_state_cached_store_l1_access,
      cpu_l1mem_data_cache_owner_none when request_state_invalidate_l1_access,
      (others => 'X') when others;

  -- Choose the next cache vram & tram owner when the current owner is a bus op.
  c.b_vtram_owner_next_bus_op_request <=
    c.b_cache_owner_next_bus_op_request;
  
  with r.b_stb_state select
    c.b_vtram_owner_next_bus_op_stb <=
      cpu_l1mem_data_cache_owner_bus_op when stb_state_writeback,
      (cpu_l1mem_data_cache_owner_index_none => c.b_bus_op_fill_complete,
       cpu_l1mem_data_cache_owner_index_bus_op => not c.b_bus_op_fill_complete,
       others => '0'
       ) when stb_state_fill,
      (others => 'X') when others;

  c.b_vtram_owner_next_bus_op_bus_op <=
    c.b_cache_owner_next_bus_op_bus_op;
  
  with r.b_bus_op_owner select
    c.b_vtram_owner_next_bus_op <= cpu_l1mem_data_cache_owner_none          when cpu_l1mem_data_cache_owner_none,
                                        c.b_vtram_owner_next_bus_op_request when cpu_l1mem_data_cache_owner_request,
                                        c.b_vtram_owner_next_bus_op_stb     when cpu_l1mem_data_cache_owner_stb,
                                        c.b_vtram_owner_next_bus_op_bus_op  when cpu_l1mem_data_cache_owner_bus_op,
                                        (others => 'X')                    when others;

  -- Choose the next cache vram & tram owner when the current owner is the stb
  c.b_vtram_owner_next_stb <=
    c.b_cache_owner_next_stb;
  
  -- Choose the next cache vram & tram owner
  with r.b_vtram_owner select
    c.b_vtram_owner_next_no_error <= c.b_vtram_owner_next_request    when cpu_l1mem_data_cache_owner_request,
                                     c.b_vtram_owner_next_bus_op     when cpu_l1mem_data_cache_owner_bus_op,
                                     c.b_vtram_owner_next_stb        when cpu_l1mem_data_cache_owner_stb,
                                     cpu_l1mem_data_cache_owner_none when cpu_l1mem_data_cache_owner_none,
                                     (others => 'X')                 when others;

  with c.b_bus_op_error select
    c.b_vtram_owner_next <= c.b_vtram_owner_next_no_error when '0',
                            cpu_l1mem_data_cache_owner_none when '1',
                            (others => 'X') when others;


  -- Choose the next cache mram & dram owner when the current cache mram & dram owner is the request
  with r.b_request_state select
    c.b_rmdram_owner_next_request <=
      (cpu_l1mem_data_cache_owner_index_none => (
         c.b_request_mmu_result_ready
         ),
       cpu_l1mem_data_cache_owner_index_request => (
         not c.b_request_mmu_result_ready
         ),
       others => '0'
       ) when request_state_cached_load_l1_access |
              request_state_writeback_l1_access |
              request_state_flush_l1_access,
      cpu_l1mem_data_cache_owner_none when request_state_invalidate_l1_access,
      (others => 'X') when others;
  
  c.b_rmdram_owner_next_bus_op_request <=
    c.b_cache_owner_next_bus_op_request;

  -- when stb is requesting a line fill, ownership of data goes back to stb afterwards
  with r.b_stb_state select
    c.b_rmdram_owner_next_bus_op_stb <=
      cpu_l1mem_data_cache_owner_bus_op when stb_state_writeback,
      (cpu_l1mem_data_cache_owner_index_none => (
         c.b_bus_op_error
         ),
       cpu_l1mem_data_cache_owner_index_stb => (
         c.b_bus_op_fill_complete and
         not c.b_bus_op_error
         ),
       cpu_l1mem_data_cache_owner_index_bus_op => (
         not c.b_bus_op_fill_complete and
         not c.b_bus_op_error
         ),
       others => '0'
       ) when stb_state_fill,
      (others => 'X') when others;

  c.b_rmdram_owner_next_bus_op_bus_op <=
    c.b_cache_owner_next_bus_op_bus_op;
  
  with r.b_bus_op_owner select
    c.b_rmdram_owner_next_bus_op <= cpu_l1mem_data_cache_owner_none                               when cpu_l1mem_data_cache_owner_none,
                                        c.b_rmdram_owner_next_bus_op_request when cpu_l1mem_data_cache_owner_request,
                                        c.b_rmdram_owner_next_bus_op_stb     when cpu_l1mem_data_cache_owner_stb,
                                        c.b_rmdram_owner_next_bus_op_bus_op  when cpu_l1mem_data_cache_owner_bus_op,
                                        (others => 'X')                    when others;

  -- Choose the next cache data owner when the current cache data owner is the stb
  c.b_rmdram_owner_next_stb <=
    c.b_cache_owner_next_stb;
  
  -- Choose the next cache data owner
  with r.b_rmdram_owner select
    c.b_rmdram_owner_next_no_error <= c.b_rmdram_owner_next_request when cpu_l1mem_data_cache_owner_request,
                                      c.b_rmdram_owner_next_bus_op  when cpu_l1mem_data_cache_owner_bus_op,
                                      c.b_rmdram_owner_next_stb     when cpu_l1mem_data_cache_owner_stb,
                                      cpu_l1mem_data_cache_owner_none                   when cpu_l1mem_data_cache_owner_none,
                                      (others => 'X')              when others;

  with c.b_bus_op_error select
    c.b_rmdram_owner_next <= c.b_rmdram_owner_next_no_error when '0',
                             cpu_l1mem_data_cache_owner_none when '1',
                             (others => 'X') when others;
  
  -- Choose the next bus owner when the current owner is a request.
  -- Uncached requests hold ownership until the first word is returned.
  -- Cached load requests that are waiting on a fill hold ownership until the first transfer completes, then drop ownership
  -- Writeback and flush operations hold ownership until the block is complete.
  with r.b_request_state select
    c.b_bus_op_owner_next_request <=
      (cpu_l1mem_data_cache_owner_index_none    => c.b_bus_op_cycle_complete,
       cpu_l1mem_data_cache_owner_index_request => not c.b_bus_op_cycle_complete,
       others => '0'
       ) when request_state_uncached_load_bus_op |
              request_state_uncached_store_bus_op,
      (cpu_l1mem_data_cache_owner_index_none    => c.b_bus_op_error,
       cpu_l1mem_data_cache_owner_index_request => not c.b_bus_op_error,
       others => '0'
       ) when request_state_cached_load_writeback,
      (cpu_l1mem_data_cache_owner_index_none    => c.b_bus_op_fill_complete or c.b_bus_op_error,
       cpu_l1mem_data_cache_owner_index_bus_op  => c.b_bus_op_fill_load_data_ready and not c.b_bus_op_fill_complete and not c.b_bus_op_error,
       cpu_l1mem_data_cache_owner_index_request => not c.b_bus_op_fill_load_data_ready and not c.b_bus_op_error,
       others => '0'
       ) when request_state_cached_load_fill,
      (cpu_l1mem_data_cache_owner_index_none    => c.b_bus_op_writeback_complete or c.b_bus_op_error,
       cpu_l1mem_data_cache_owner_index_request => not c.b_bus_op_writeback_complete and not c.b_bus_op_error,
       others => '0'
       ) when request_state_writeback_bus_op |
              request_state_flush_bus_op,
      (others => 'X'
       ) when others;

  -- Choose the next bus owner when the current owner is the stb.
  -- The stb shouldn't have ownership while in the init state
  with r.b_stb_state select
    c.b_bus_op_owner_next_stb <=
      cpu_l1mem_data_cache_owner_stb when stb_state_replace_access,
      (cpu_l1mem_data_cache_owner_index_none => (
         c.b_bus_op_error
         ),
       cpu_l1mem_data_cache_owner_index_stb => (
         not c.b_bus_op_error
         ),
       others => '0'
       ) when stb_state_writeback,
      (cpu_l1mem_data_cache_owner_index_none => (
         c.b_bus_op_error or
         (c.b_bus_op_fill_complete and
          not r.b_stb_write_bus
          )
         ),
       cpu_l1mem_data_cache_owner_index_stb => (
         not c.b_bus_op_error and
         (not c.b_bus_op_fill_complete or
          r.b_stb_write_bus
          )
         ),
       others => '0'
       ) when stb_state_fill,
      (cpu_l1mem_data_cache_owner_index_none => (
         c.b_bus_op_cycle_complete
         ),
       cpu_l1mem_data_cache_owner_index_stb => (
         not c.b_bus_op_cycle_complete
         ),
       others => '0'
       ) when stb_state_write,
      (others => 'X') when others;

  with r.b_bus_op_state select
    c.b_bus_op_owner_next_bus_op <=
      cpu_l1mem_data_cache_owner_bus_op when bus_op_state_fill,
      cpu_l1mem_data_cache_owner_none   when bus_op_state_fill_last,
      (others => 'X') when others;

  with r.b_bus_op_owner select
    c.b_bus_op_owner_next_no_error <= cpu_l1mem_data_cache_owner_none when cpu_l1mem_data_cache_owner_none,
                                      c.b_bus_op_owner_next_request   when cpu_l1mem_data_cache_owner_request,
                                      c.b_bus_op_owner_next_stb       when cpu_l1mem_data_cache_owner_stb,
                                      c.b_bus_op_owner_next_bus_op    when cpu_l1mem_data_cache_owner_bus_op,
                                      (others => 'X')                 when others;

  with c.b_bus_op_error select
    c.b_bus_op_owner_next <= c.b_bus_op_owner_next_no_error when '0',
                             cpu_l1mem_data_cache_owner_none when '1',
                             (others => 'X') when others;
  
  ------ Pre-phase

  -- stb stuff
  c.a_stb_head_ptr               <= c.b_stb_head_ptr_next;
  c.a_stb_tail_ptr               <= c.b_stb_tail_ptr_next;
  
  c.a_stb_array_valid            <= c.b_stb_array_valid_next;
  c.a_stb_array_cache_hit        <= c.b_stb_array_cache_hit_next;
  c.a_stb_array_alloc            <= c.b_stb_array_alloc_next;
  c.a_stb_array_writethrough     <= c.b_stb_array_writethrough_next;
  c.a_stb_array_be               <= c.b_stb_array_be_next;
  c.a_stb_array_priv             <= c.b_stb_array_priv_next;
  c.a_stb_array_way              <= c.b_stb_array_way_next;

  c.a_stb_head_valid             <= reduce_or(c.a_stb_head_ptr and c.a_stb_array_valid);
  c.a_stb_head_alloc             <= reduce_or(c.a_stb_head_ptr and c.a_stb_array_alloc);
  c.a_stb_head_writethrough      <= reduce_or(c.a_stb_head_ptr and c.a_stb_array_writethrough);
  c.a_stb_head_cache_hit         <= reduce_or(c.a_stb_head_ptr and c.a_stb_array_cache_hit);
  c.a_stb_head_be                <= reduce_or(c.a_stb_head_ptr and c.a_stb_array_be);
  c.a_stb_head_priv              <= reduce_or(c.a_stb_head_ptr and c.a_stb_array_priv);

  a_stb_head_way_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_l1mem_data_cache_assoc,
      sel_bits  => cpu_l1mem_data_cache_stb_entries
      )
    port map (
      din => c.a_stb_array_way,
      sel => c.a_stb_head_ptr,
      dout => c.a_stb_head_way
      );

  c.a_stb_full                   <= reduce_and(c.a_stb_array_valid);

  c.a_stb_quick_store <= (
    c.a_stb_head_cache_hit and
    not c.a_stb_head_writethrough and
    c.b_rmdram_owner_next(cpu_l1mem_data_cache_owner_index_none)
    );

  -- new request selection, declare wants
  c.a_new_request <= (code          => cpu_l1mem_data_cache_ctrl_in.request,
                      cacheen       => cpu_l1mem_data_cache_ctrl_in.cacheen,
                      mmuen         => cpu_l1mem_data_cache_ctrl_in.mmuen,
                      writethrough  => cpu_l1mem_data_cache_ctrl_in.writethrough,
                      priv          => cpu_l1mem_data_cache_ctrl_in.priv,
                      be            => cpu_l1mem_data_cache_ctrl_in.be,
                      alloc         => cpu_l1mem_data_cache_ctrl_in.alloc
                      );
  
  c.a_new_request_stb_wait <= (
    c.a_stb_full and
    not c.a_stb_quick_store
    );
  
  with c.a_request.cacheen select
    c.a_new_request_state_load <= request_state_uncached_load_mmu_access when '0',
                                  request_state_cached_load_l1_access    when '1',
                                  (others => 'X')                        when others;
  c.a_new_request_state_store <= (
    request_state_index_uncached_store_mmu_access => (
      not c.a_request.cacheen
      ),
    request_state_index_cached_store_stb_wait => (
      c.a_request.cacheen and
      c.a_new_request_stb_wait
      ),
    request_state_index_cached_store_l1_access => (
      c.a_request.cacheen and
      not c.a_new_request_stb_wait
      ),
    others => '0'
    );
  with c.a_request.code select
    c.a_new_request_state <= request_state_none                when cpu_l1mem_data_request_code_none,
                             c.a_new_request_state_load        when cpu_l1mem_data_request_code_load,
                             c.a_new_request_state_store       when cpu_l1mem_data_request_code_store,
                             request_state_invalidate_sync     when cpu_l1mem_data_request_code_invalidate,
                             request_state_flush_l1_access     when cpu_l1mem_data_request_code_flush,
                             request_state_writeback_l1_access when cpu_l1mem_data_request_code_writeback,
                             request_state_sync                when cpu_l1mem_data_request_code_sync,
                             (others => 'X')                   when others;
  
  with c.b_request_complete select
    c.a_request <= c.a_new_request when '1',
                   r.b_request     when '0',
                   request_x       when others;
  with c.b_request_complete select
    c.a_request_state <= c.a_new_request_state  when '1',
                         c.b_request_state_next when '0',
                         (others => 'X')        when others;
  c.a_request_way <= c.b_request_way_next;
  c.a_request_cache_accessed    <= c.b_request_cache_accessed_next and not c.b_request_complete;
  c.a_request_mmu_accessed      <= r.b_request_mmu_accessed and not c.b_request_complete;
  c.a_request_cache_block_valid <= c.b_request_cache_block_valid;
  c.a_request_cache_block_dirty <= c.b_request_cache_block_dirty;

  with c.a_request_state select
    c.a_request_want_vtram <= '0' when request_state_none |
                                       request_state_uncached_load_mmu_access |
                                       request_state_uncached_load_bus_op |
                                       request_state_uncached_store_mmu_access |
                                       request_state_uncached_store_bus_op |
                                       request_state_cached_load_writeback |
                                       request_state_cached_load_fill |
                                       request_state_cached_store_stb_wait |
                                       request_state_writeback_bus_op |
                                       request_state_invalidate_sync,
                              '1' when request_state_cached_load_l1_access |
                                       request_state_cached_store_l1_access |
                                       request_state_invalidate_l1_access |
                                       request_state_writeback_l1_access |
                                       request_state_flush_l1_access,
                              'X' when others;

  with c.a_request_state select
    c.a_request_want_rmdram <= '0' when request_state_none |
                                        request_state_uncached_load_mmu_access |
                                        request_state_uncached_load_bus_op |
                                        request_state_uncached_store_mmu_access |
                                        request_state_uncached_store_bus_op |
                                        request_state_cached_load_writeback |
                                        request_state_cached_load_fill |
                                        request_state_cached_store_l1_access |
                                        request_state_cached_store_stb_wait |
                                        request_state_writeback_bus_op |
                                        request_state_invalidate_sync,
                               '1' when request_state_cached_load_l1_access |
                                        request_state_writeback_l1_access |
                                        request_state_invalidate_l1_access |
                                        request_state_flush_l1_access,
                               'X' when others;
  
  with c.a_request_state select
    c.a_request_want_bus_op <= '0' when request_state_none |
                                        request_state_uncached_load_mmu_access |
                                        request_state_uncached_store_mmu_access |
                                        request_state_cached_load_l1_access |
                                        request_state_cached_store_stb_wait |
                                        request_state_cached_store_l1_access |
                                        request_state_writeback_l1_access |
                                        request_state_flush_l1_access |
                                        request_state_flush_invalidate_l1_access |
                                        request_state_invalidate_sync |
                                        request_state_invalidate_l1_access,
                               '1' when request_state_uncached_load_bus_op |
                                        request_state_uncached_store_bus_op |
                                        request_state_cached_load_writeback |
                                        request_state_cached_load_fill |
                                        request_state_writeback_bus_op |
                                        request_state_flush_bus_op,
                               'X' when others;

  with c.b_bus_op_owner_next select
    c.a_request_can_own_bus_op <= '1' when cpu_l1mem_data_cache_owner_request |
                                           cpu_l1mem_data_cache_owner_none,
                                  '0' when cpu_l1mem_data_cache_owner_stb |
                                           cpu_l1mem_data_cache_owner_bus_op,
                                  'X' when others;
  
  with c.b_vtram_owner_next select
    c.a_request_can_own_vtram <= '1' when cpu_l1mem_data_cache_owner_request |
                                          cpu_l1mem_data_cache_owner_none,
                                 '0' when cpu_l1mem_data_cache_owner_stb |
                                          cpu_l1mem_data_cache_owner_bus_op,
                                 'X' when others;
  with c.b_rmdram_owner_next select
    c.a_request_can_own_rmdram <= '1' when cpu_l1mem_data_cache_owner_request |
                                           cpu_l1mem_data_cache_owner_none,
                                  '0' when cpu_l1mem_data_cache_owner_stb |
                                           cpu_l1mem_data_cache_owner_bus_op,
                                  'X' when others;
  
  c.a_request_granted <= (
    not (c.a_request_want_vtram and
         not c.a_request_can_own_vtram
         ) and
    not (c.a_request_want_rmdram and
         not c.a_request_can_own_rmdram
         ) and
    not (c.a_request_want_bus_op and
         not c.a_request_can_own_bus_op
         )
    );

  with c.a_request_state select
    c.a_request_bus_op_code <= bus_op_code_load      when request_state_uncached_load_bus_op,
                               bus_op_code_store     when request_state_uncached_store_bus_op,
                               bus_op_code_fill      when request_state_cached_load_fill,
                               bus_op_code_writeback when request_state_writeback_bus_op |
                                                          request_state_cached_load_writeback,
                               (others => 'X')       when others;

  with c.a_request_state select
    c.a_request_vram_re <= not c.a_request_cache_accessed when request_state_cached_load_l1_access |
                                                               request_state_cached_store_l1_access |
                                                               request_state_writeback_l1_access,
                           '0'                            when request_state_invalidate_l1_access,
                           'X'                            when others;

  with c.a_request_state select
    c.a_request_mram_re <= not c.a_request_cache_accessed when request_state_cached_load_l1_access |
                                                               request_state_writeback_l1_access |
                                                               request_state_flush_l1_access,
                           '0'                            when request_state_invalidate_l1_access,
                           'X'                            when others;
  
  with c.a_request_state select
    c.a_request_tram_en <= not c.a_request_cache_accessed when request_state_cached_load_l1_access |
                                                               request_state_cached_store_l1_access |
                                                               request_state_writeback_l1_access |
                                                               request_state_flush_l1_access,
                           '0'                            when request_state_invalidate_l1_access,
                           'X' when others;
  with c.a_request_state select
    c.a_request_tram_we <= '0' when request_state_cached_load_l1_access |
                                    request_state_cached_store_l1_access |
                                    request_state_writeback_l1_access |
                                    request_state_flush_l1_access,
                           'X' when others;
  with c.a_request_state select
    c.a_request_tram_banken <= (others => '1') when request_state_cached_load_l1_access |
                                                    request_state_cached_store_l1_access |
                                                    request_state_writeback_l1_access |
                                                    request_state_flush_l1_access,
                               (others => 'X') when others;

  with c.a_request_state select
    c.a_request_dram_en <= not c.a_request_cache_accessed when request_state_cached_load_l1_access,
                           '0'                            when request_state_writeback_l1_access |
                                                               request_state_flush_l1_access |
                                                               request_state_invalidate_l1_access,
                           'X'                            when others;

  with c.a_request_state select
    c.a_request_replace_re <= not c.a_request_cache_accessed when request_state_cached_load_l1_access |
                                                                  request_state_cached_store_l1_access |
                                                                  request_state_invalidate_l1_access,
                              'X'                            when others;
  
  c.a_request_mmu_accessed_next   <= c.a_request_mmu_accessed or cpu_mmu_data_ctrl_out.ready;

  with c.b_bus_op_owner_next select
    c.a_stb_can_own_bus_op <= '1' when cpu_l1mem_data_cache_owner_stb |
                                       cpu_l1mem_data_cache_owner_none,
                              '0' when cpu_l1mem_data_cache_owner_request |
                                       cpu_l1mem_data_cache_owner_bus_op,
                              'X' when others;
  
  with c.b_vtram_owner_next select
    c.a_stb_can_own_vtram <= '1' when cpu_l1mem_data_cache_owner_stb |
                                      cpu_l1mem_data_cache_owner_none,
                             '0' when cpu_l1mem_data_cache_owner_request |
                                      cpu_l1mem_data_cache_owner_bus_op,
                             'X' when others;
  with c.b_rmdram_owner_next select
    c.a_stb_can_own_rmdram <= '1' when cpu_l1mem_data_cache_owner_stb |
                                       cpu_l1mem_data_cache_owner_none,
                              '0' when cpu_l1mem_data_cache_owner_request |
                                       cpu_l1mem_data_cache_owner_bus_op,
                              'X' when others;

  with c.b_stb_state_next select
    c.a_stb_can_activate <= '1' when stb_state_init,
                            '0' when stb_state_replace_access |
                                     stb_state_writeback |
                                     stb_state_fill |
                                     stb_state_write,
                            'X' when others;
  
  c.a_stb_activate <= (
    c.a_stb_can_activate and
    c.a_stb_head_valid and
    not c.a_request_want_bus_op and
    not (not c.a_stb_can_own_rmdram or
         (c.a_request_granted and c.a_request_want_rmdram)
         ) and
    not (not c.a_stb_head_cache_hit and
         c.a_stb_head_alloc and
         (not c.a_stb_can_own_vtram or
          (c.a_request_granted and c.a_request_want_vtram) or
          not c.a_stb_can_own_bus_op or
          (c.a_request_granted and c.a_request_want_bus_op))
         ) and
    not (((not c.a_stb_head_cache_hit and
           not c.a_stb_head_alloc
           ) or
          c.a_stb_head_writethrough) and
         not c.a_stb_can_own_bus_op and
         (c.a_request_granted and c.a_request_want_bus_op)
         )
    );

  with c.a_stb_activate select
    c.a_stb_write_cache <= (c.a_stb_head_cache_hit or
                            c.a_stb_head_alloc)       when '1',
                           c.b_stb_write_cache_next   when '0',
                           'X'                        when others;
  with c.a_stb_activate select
    c.a_stb_write_bus <= (c.a_stb_head_writethrough or
                          (not c.a_stb_head_alloc and
                           not c.a_stb_head_cache_hit)) when '1',
                         c.b_stb_write_bus_next         when '0',
                         'X'                            when others;

  with c.a_stb_activate select
    c.a_stb_way <= c.a_stb_head_way when '1',
                   c.b_stb_way_next when '0',
                   (others => 'X')  when others;

  with c.a_stb_activate select
    c.a_stb_state <= (stb_state_index_init           => '0',
                      stb_state_index_replace_access => not c.a_stb_head_cache_hit and c.a_stb_head_alloc,
                      stb_state_index_write          => c.a_stb_head_cache_hit or not c.a_stb_head_alloc,
                      others => '0'
                      )                 when '1',
                     c.b_stb_state_next when '0',
                     (others => 'X')    when others;
  
  with c.a_stb_state select
    c.a_stb_active <= '0' when stb_state_init,
                      '1' when stb_state_replace_access |
                               stb_state_fill |
                               stb_state_writeback |
                               stb_state_write,
                      'X' when others;
  
  with c.a_stb_state select
    c.a_stb_want_vtram <= '1' when stb_state_replace_access,
                          '0' when stb_state_init |
                                   stb_state_write |
                                   stb_state_fill |
                                   stb_state_writeback,
                          'X' when others;
  
  with c.a_stb_state select
    c.a_stb_want_rmdram <= '1'                 when stb_state_replace_access,
                           c.a_stb_write_cache when stb_state_write,
                           '0'                 when stb_state_init |
                                                    stb_state_fill |
                                                    stb_state_writeback,
                           'X'                 when others;
  with c.a_stb_state select
    c.a_stb_want_bus_op <= c.a_stb_write_bus when stb_state_write,
                           '1'               when stb_state_replace_access |
                                                  stb_state_writeback |
                                                  stb_state_fill,
                           '0'               when stb_state_init,
                           'X'               when others;

  with c.a_stb_state select
    c.a_stb_vram_re <= '1' when stb_state_replace_access,
                       'X' when others;
  with c.a_stb_state select
    c.a_stb_mram_re <= '1'                 when stb_state_replace_access,
                       c.a_stb_write_cache when stb_state_write,
                       'X'                 when others;

  with c.a_stb_state select
    c.a_stb_tram_en <= '1' when stb_state_replace_access,
                       'X' when others;
  with c.a_stb_state select
    c.a_stb_tram_we <= '0' when stb_state_replace_access,
                       'X' when others;
  with c.a_stb_state select
    c.a_stb_tram_banken <= (others => '1') when stb_state_replace_access, 
                          (others => 'X') when others;

  with c.a_stb_state select
    c.a_stb_dram_en <= '0' when stb_state_replace_access,
                       '1' when stb_state_write,
                       'X' when others;
  with c.a_stb_state select
    c.a_stb_dram_we <= '1' when stb_state_write,
                       'X' when others;
  c.a_stb_dram_wdata_be <= c.a_stb_head_be;

  with c.a_stb_state select
    c.a_stb_replace_re <= '1' when stb_state_replace_access,
                          '0' when stb_state_writeback |
                                   stb_state_fill |
                                   stb_state_write,
                          'X' when others;

  with c.a_stb_state select
    c.a_stb_bus_op_code <= bus_op_code_none      when stb_state_replace_access,
                           bus_op_code_writeback when stb_state_writeback,
                           bus_op_code_fill      when stb_state_fill,
                           bus_op_code_store     when stb_state_write,
                           (others => 'X')       when others;
  c.a_stb_bus_op_way <= c.a_stb_way;
  
  c.a_new_bus_op_owner <= (
    cpu_l1mem_data_cache_owner_index_none => (
      not (c.a_request_granted and c.a_request_want_bus_op) and
      not (c.a_stb_active and c.a_stb_want_bus_op)
      ),
    cpu_l1mem_data_cache_owner_index_request => (
      c.a_request_granted and c.a_request_want_bus_op
      ),
    cpu_l1mem_data_cache_owner_index_stb => (
      c.a_stb_active and c.a_stb_want_bus_op
      ),
    cpu_l1mem_data_cache_owner_index_bus_op => '0'
    );
  
  with c.a_new_bus_op_owner select
    c.a_new_bus_op_code <= c.a_request_bus_op_code when cpu_l1mem_data_cache_owner_request,
                           c.a_stb_bus_op_code     when cpu_l1mem_data_cache_owner_stb,
                           bus_op_code_none        when cpu_l1mem_data_cache_owner_none,
                           (others => 'X')         when others;
  with c.a_new_bus_op_code select
    c.a_new_bus_op_state <= bus_op_state_none            when bus_op_code_none,
                            bus_op_state_load            when bus_op_code_load,
                            bus_op_state_store           when bus_op_code_store,
                            bus_op_state_fill_first      when bus_op_code_fill,
                            bus_op_state_writeback_first when bus_op_code_writeback,
                            (others => 'X')              when others;
  
  with c.a_new_bus_op_owner select
    c.a_new_bus_op_cacheable <= c.a_request.cacheen when cpu_l1mem_data_cache_owner_request,
                                '1'                 when cpu_l1mem_data_cache_owner_stb,
                                'X'                 when others;
  with c.a_new_bus_op_owner select
    c.a_new_bus_op_be <= c.a_request.be  when cpu_l1mem_data_cache_owner_request,
                         c.a_stb_head_be when cpu_l1mem_data_cache_owner_stb,
                         'X'             when others;
  with c.a_new_bus_op_owner select
    c.a_new_bus_op_priv <= c.a_request.priv  when cpu_l1mem_data_cache_owner_request,
                           c.a_stb_head_priv when cpu_l1mem_data_cache_owner_stb,
                           'X'               when others;
  with c.a_new_bus_op_owner select
    c.a_new_bus_op_way <= c.a_request_way    when cpu_l1mem_data_cache_owner_request,
                          c.a_stb_bus_op_way when cpu_l1mem_data_cache_owner_stb,
                          (others => 'X')    when others;
  c.a_new_bus_op_block_word <= (0 => '1', others => '0');

  with c.a_request_state select
    c.a_new_bus_op_paddr_tag_sel_request <=
      cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_request      when request_state_uncached_load_bus_op |
                                                                    request_state_uncached_store_bus_op |
                                                                    request_state_cached_load_fill |
                                                                    request_state_writeback_bus_op |
                                                                    request_state_flush_bus_op,
      cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_replace      when request_state_cached_load_writeback,
      (others => 'X')                                          when others;

  with c.a_request_state select
    c.a_new_bus_op_paddr_index_sel_request <=
      cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_request      when request_state_uncached_load_bus_op |
                                                                      request_state_uncached_store_bus_op |
                                                                      request_state_cached_load_fill |
                                                                      request_state_cached_load_writeback |
                                                                      request_state_writeback_bus_op |
                                                                      request_state_flush_bus_op,
      (others => 'X')                                            when others;

  with c.a_request_state select
    c.a_new_bus_op_paddr_offset_sel_request <=
      cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_request      when request_state_uncached_load_bus_op |
                                                                       request_state_uncached_store_bus_op,
      cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_request_word when request_state_cached_load_fill |
                                                                       request_state_cached_load_writeback |
                                                                       request_state_writeback_bus_op |
                                                                       request_state_flush_bus_op,
      (others => 'X')                                             when others;

  with c.a_stb_state select
    c.a_new_bus_op_paddr_tag_sel_stb <=
      cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_stb      when stb_state_write |
                                                                stb_state_fill,
      cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_replace  when stb_state_writeback,
      (others => 'X')                                      when others;

  with c.a_stb_state select
    c.a_new_bus_op_paddr_index_sel_stb <=
      cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_stb      when stb_state_write |
                                                                  stb_state_fill |
                                                                  stb_state_writeback,
      (others => 'X')                                        when others;

  with c.a_stb_state select
    c.a_new_bus_op_paddr_offset_sel_stb <=
      cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_stb      when stb_state_write,
      cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_stb_word when stb_state_fill |
                                                                   stb_state_writeback,
      (others => 'X')                                         when others;

  with c.a_new_bus_op_owner select
    c.a_new_bus_op_paddr_tag_sel <= c.a_new_bus_op_paddr_tag_sel_request when cpu_l1mem_data_cache_owner_request,
                                c.a_new_bus_op_paddr_tag_sel_stb         when cpu_l1mem_data_cache_owner_stb,
                                (others => 'X')                          when others;

  with c.a_new_bus_op_owner select
    c.a_new_bus_op_paddr_index_sel <= c.a_new_bus_op_paddr_index_sel_request when cpu_l1mem_data_cache_owner_request,
                                      c.a_new_bus_op_paddr_index_sel_stb     when cpu_l1mem_data_cache_owner_stb,
                                      (others => 'X')                        when others;

  with c.a_new_bus_op_owner select
    c.a_new_bus_op_paddr_offset_sel <= c.a_new_bus_op_paddr_offset_sel_request when cpu_l1mem_data_cache_owner_request,
                                       c.a_new_bus_op_paddr_offset_sel_stb     when cpu_l1mem_data_cache_owner_stb,
                                       (others => 'X')                         when others;

  with c.a_request_state select
    c.a_new_bus_op_size_sel_request <=
      cpu_l1mem_data_cache_a_bus_op_size_sel_request when request_state_uncached_load_bus_op |
                                                          request_state_uncached_store_bus_op,
      cpu_l1mem_data_cache_a_bus_op_size_sel_word    when request_state_cached_load_fill |
                                                          request_state_cached_load_writeback |
                                                          request_state_writeback_bus_op |
                                                          request_state_flush_bus_op,
      (others => 'X')                                when others;

  with c.a_stb_state select
    c.a_new_bus_op_size_sel_stb <=
      cpu_l1mem_data_cache_a_bus_op_size_sel_stb  when stb_state_write,
      cpu_l1mem_data_cache_a_bus_op_size_sel_word when stb_state_fill |
                                                       stb_state_writeback,
      (others => 'X')                             when others;

  with c.a_new_bus_op_owner select
    c.a_new_bus_op_size_sel <= c.a_new_bus_op_size_sel_request when cpu_l1mem_data_cache_owner_request,
                               c.a_new_bus_op_size_sel_stb     when cpu_l1mem_data_cache_owner_stb,
                               (others => 'X')                 when others;

  with c.b_bus_op_owner_next(cpu_l1mem_data_cache_owner_index_none) select
    c.a_bus_op_owner <= c.b_bus_op_owner_next when '0',
                        c.a_new_bus_op_owner  when '1',
                        (others => 'X')       when others;
  
  with c.b_bus_op_complete select
    c.a_bus_op_state <= c.b_bus_op_state_next when '0',
                        c.a_new_bus_op_state  when '1',
                        (others => 'X')       when others;
  with c.b_bus_op_complete select
    c.a_bus_op_cacheable <= r.b_bus_op_cacheable     when '0',
                            c.a_new_bus_op_cacheable when '1',
                            'X'                      when others;
  with c.b_bus_op_complete select
    c.a_bus_op_be <= r.b_bus_op_be     when '0',
                     c.a_new_bus_op_be when '1',
                     'X'               when others;
  with c.b_bus_op_complete select
    c.a_bus_op_priv <= r.b_bus_op_priv     when '0',
                       c.a_new_bus_op_priv when '1',
                       'X'                 when others;
  with c.b_bus_op_complete select
    c.a_bus_op_way <= r.b_bus_op_way     when '0',
                      c.a_new_bus_op_way when '1',
                      (others => 'X')    when others;
  
  with c.b_bus_op_complete select
    c.a_bus_op_block_word <= c.b_bus_op_block_word_next when '0',
                             c.a_new_bus_op_block_word  when '1',
                             (others => 'X')            when others;
  c.a_bus_op_requested <= (
    (r.b_bus_op_requested and
     not c.b_bus_op_complete) or
    sys_slave_ctrl_out.ready
    );

  with c.b_bus_op_complete select
    c.a_bus_op_paddr_tag_sel <= cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_old when '0',
                                c.a_new_bus_op_paddr_tag_sel                    when '1',
                                (others => 'X')                                 when others;
  
  with c.b_bus_op_complete select
    c.a_bus_op_paddr_index_sel <= cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_old when '0',
                                  c.a_new_bus_op_paddr_index_sel                    when '1',
                                  (others => 'X')                                   when others;
  
  with c.b_bus_op_complete select
    c.a_bus_op_paddr_offset_sel <= (cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_old =>
                                      not c.b_bus_op_block_word_advance,
                                    cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_index_next_word =>
                                      c.b_bus_op_block_word_advance,
                                    others => '0'
                                    )                              when '0',
                                   c.a_new_bus_op_paddr_offset_sel when '1',
                                   (others => 'X')                 when others;
  
  with c.b_bus_op_complete select
    c.a_bus_op_size_sel <= cpu_l1mem_data_cache_a_bus_op_size_sel_old when '0',
                           c.a_new_bus_op_size_sel                    when '1',
                           (others => 'X')                            when others;
  
  with c.a_bus_op_state select
    c.a_bus_op_cache_paddr_sel_old <= '1' when bus_op_state_fill |
                                               bus_op_state_fill_last,
                                      '0' when bus_op_state_writeback_first |
                                               bus_op_state_writeback |
                                               bus_op_state_writeback_last |
                                               bus_op_state_fill_first,
                                      'X' when others;
  with c.a_bus_op_state select
    c.a_bus_op_sys_paddr_sel_old <= '1' when bus_op_state_writeback |
                                              bus_op_state_writeback_last,
                                     '0' when bus_op_state_load |
                                              bus_op_state_store |
                                              bus_op_state_writeback_first |
                                              bus_op_state_fill |
                                              bus_op_state_fill_first,
                                     'X' when others;
  with c.a_bus_op_state select
    c.a_bus_op_sys_data_sel_cache <= '1' when bus_op_state_writeback |
                                               bus_op_state_writeback_last,
                                      '0' when bus_op_state_store,
                                      'X' when others;
  
  with c.a_bus_op_state select
    c.a_bus_op_want_cache <= '0' when bus_op_state_none |
                                      bus_op_state_load |
                                      bus_op_state_store,
                             '1' when bus_op_state_fill_first |
                                      bus_op_state_writeback_first,
                             'X' when others;

  with c.a_bus_op_state select
    c.a_bus_op_vram_re <= '1' when bus_op_state_fill_first | -- clear valid bit
                                   bus_op_state_fill_last,   -- set valid bit
                          '0' when bus_op_state_fill |
                                   bus_op_state_writeback_first |
                                   bus_op_state_writeback |
                                   bus_op_state_writeback_last,
                          'X' when others;

  with c.a_bus_op_state select
    c.a_bus_op_mram_re <= '1'                      when bus_op_state_fill_last,
                          sys_slave_ctrl_out.ready when bus_op_state_writeback_last,
                          '0'                      when bus_op_state_fill_first |
                                                        bus_op_state_fill |
                                                        bus_op_state_writeback_first |
                                                        bus_op_state_writeback,
                          'X'                      when others;

  with c.a_bus_op_state select
    c.a_bus_op_tram_en <= '1' when bus_op_state_fill_last, -- write tag for fill
                          '0' when bus_op_state_fill_first |
                                   bus_op_state_fill |
                                   bus_op_state_writeback_first |
                                   bus_op_state_writeback |
                                   bus_op_state_writeback_last,
                          'X' when others;
  with c.a_bus_op_state select
    c.a_bus_op_tram_we <= '1' when bus_op_state_fill_last, -- write tag for fill
                          'X' when others;
  c.a_bus_op_tram_banken <= c.a_bus_op_way;

  with c.a_bus_op_state select
    c.a_bus_op_dram_en <= '1'                      when bus_op_state_writeback_first,
                          sys_slave_ctrl_out.ready when bus_op_state_fill |
                                                        bus_op_state_fill_last |
                                                        bus_op_state_writeback,
                          '0'                      when bus_op_state_fill_first |
                                                        bus_op_state_writeback_last,
                          'X'                      when others;
  with c.a_bus_op_state select
    c.a_bus_op_dram_we <= '1' when bus_op_state_fill |
                                   bus_op_state_fill_last,
                          '0' when bus_op_state_writeback_first |
                                   bus_op_state_writeback,
                          'X' when others;

  with c.a_bus_op_state select
    c.a_bus_op_replace_re <= '1' when bus_op_state_fill_last,
                             '0' when bus_op_state_fill_first |
                                      bus_op_state_fill |
                                      bus_op_state_writeback_first |
                                      bus_op_state_writeback |
                                      bus_op_state_writeback_last,
                             'X' when others;

  with c.b_vtram_owner_next select
    c.a_bus_op_can_own_vtram <= '1' when cpu_l1mem_data_cache_owner_bus_op |
                                         cpu_l1mem_data_cache_owner_none,
                                '0' when cpu_l1mem_data_cache_owner_stb |
                                         cpu_l1mem_data_cache_owner_request,
                                'X' when others;
  with c.b_rmdram_owner_next select
    c.a_bus_op_can_own_rmdram <= '1' when cpu_l1mem_data_cache_owner_bus_op |
                                          cpu_l1mem_data_cache_owner_none,
                                 '0' when cpu_l1mem_data_cache_owner_stb |
                                          cpu_l1mem_data_cache_owner_request,
                                 'X' when others;
  c.a_bus_op_granted <= (
    not (c.a_bus_op_want_cache and
         (not c.a_bus_op_can_own_vtram or
          not c.a_bus_op_can_own_rmdram or
          (c.a_request_granted and (c.a_request_want_vtram or
                                    c.a_request_want_rmdram)) or
          (c.a_stb_active and (c.a_stb_want_vtram or
                                c.a_stb_want_rmdram))
          )
         )
    );

  c.a_new_vtram_owner <= (
    cpu_l1mem_data_cache_owner_index_none => (
      not (c.a_request_granted and c.a_request_want_vtram) and
      not (c.a_stb_active and c.a_stb_want_vtram) and
      not (c.a_bus_op_granted and c.a_bus_op_want_cache)
      ),
    cpu_l1mem_data_cache_owner_index_request => (
      c.a_request_granted and c.a_request_want_vtram
      ),
    cpu_l1mem_data_cache_owner_index_stb => (
      c.a_stb_active and c.a_stb_want_vtram
      ),
    cpu_l1mem_data_cache_owner_index_bus_op => (
      c.a_bus_op_granted and c.a_bus_op_want_cache
      )
    );
  with c.b_vtram_owner_next select
    c.a_vtram_owner <= c.a_new_vtram_owner  when cpu_l1mem_data_cache_owner_none,
                       c.b_vtram_owner_next when cpu_l1mem_data_cache_owner_request |
                                                 cpu_l1mem_data_cache_owner_stb |
                                                 cpu_l1mem_data_cache_owner_bus_op,
                       (others => 'X')      when others;
  
  c.a_new_rmdram_owner <= (
    cpu_l1mem_data_cache_owner_index_none => (
      not (c.a_request_granted and c.a_request_want_rmdram) and
      not (c.a_stb_active and c.a_stb_want_rmdram) and
      not (c.a_bus_op_granted and c.a_bus_op_want_cache)
      ),
    cpu_l1mem_data_cache_owner_index_request => (
      c.a_request_granted and c.a_request_want_rmdram
      ),
    cpu_l1mem_data_cache_owner_index_stb => (
      c.a_stb_active and c.a_stb_want_rmdram
      ),
    cpu_l1mem_data_cache_owner_index_bus_op => (
      c.a_bus_op_granted and c.a_bus_op_want_cache
      )
    );
  with c.b_rmdram_owner_next select
    c.a_rmdram_owner <= c.a_new_rmdram_owner  when cpu_l1mem_data_cache_owner_none,
                        c.b_rmdram_owner_next when cpu_l1mem_data_cache_owner_request |
                                                   cpu_l1mem_data_cache_owner_stb |
                                                   cpu_l1mem_data_cache_owner_bus_op,
                        (others => 'X')      when others;
  
  -- choose cache component inputs

  with c.a_vtram_owner select
    c.a_vram_re <= c.a_request_vram_re when cpu_l1mem_data_cache_owner_request,
                   c.a_stb_vram_re     when cpu_l1mem_data_cache_owner_stb,
                   c.a_bus_op_vram_re  when cpu_l1mem_data_cache_owner_bus_op,
                   '0'                 when cpu_l1mem_data_cache_owner_none,
                   'X'                 when others;
  
  with c.a_rmdram_owner select
    c.a_mram_re <= c.a_request_mram_re when cpu_l1mem_data_cache_owner_request,
                   c.a_stb_mram_re     when cpu_l1mem_data_cache_owner_stb,
                   c.a_bus_op_mram_re  when cpu_l1mem_data_cache_owner_bus_op,
                   '0'                 when cpu_l1mem_data_cache_owner_none,
                   'X'                 when others;
  
  with c.a_vtram_owner select
    c.a_tram_en <= c.a_request_tram_en when cpu_l1mem_data_cache_owner_request,
                   c.a_stb_tram_en     when cpu_l1mem_data_cache_owner_stb,
                   c.a_bus_op_tram_en  when cpu_l1mem_data_cache_owner_bus_op,
                   '0'                 when cpu_l1mem_data_cache_owner_none,
                   'X'                 when others;
  
  with c.a_vtram_owner select
    c.a_tram_we <= c.a_request_tram_we when cpu_l1mem_data_cache_owner_request,
                   c.a_stb_tram_we     when cpu_l1mem_data_cache_owner_stb,
                   c.a_bus_op_tram_we  when cpu_l1mem_data_cache_owner_bus_op,
                   'X'                 when others;

  with c.a_vtram_owner select
    c.a_tram_banken <= c.a_request_tram_banken when cpu_l1mem_data_cache_owner_request,
                       c.a_stb_tram_banken     when cpu_l1mem_data_cache_owner_stb,
                       c.a_bus_op_tram_banken  when cpu_l1mem_data_cache_owner_bus_op,
                       (others => 'X')         when others;

  with c.a_rmdram_owner select
    c.a_dram_en <= c.a_request_dram_en when cpu_l1mem_data_cache_owner_request,
                   c.a_stb_dram_en     when cpu_l1mem_data_cache_owner_stb,
                   c.a_bus_op_dram_en  when cpu_l1mem_data_cache_owner_bus_op,
                   '0'                 when cpu_l1mem_data_cache_owner_none,
                   'X'                 when others;
  
  with c.a_rmdram_owner select
    c.a_dram_we <= '0'                 when cpu_l1mem_data_cache_owner_request,
                   c.a_stb_dram_we     when cpu_l1mem_data_cache_owner_stb,
                   c.a_bus_op_dram_we  when cpu_l1mem_data_cache_owner_bus_op,
                   'X'                 when others;

  with c.a_rmdram_owner select
    c.a_dram_wdata_be <= c.a_stb_head_be when cpu_l1mem_data_cache_owner_stb,
                         c.a_bus_op_be   when cpu_l1mem_data_cache_owner_bus_op,
                         'X'             when others;
  
  with c.a_rmdram_owner select
    c.a_replace_re <= c.a_request_replace_re when cpu_l1mem_data_cache_owner_request,
                      c.a_stb_replace_re     when cpu_l1mem_data_cache_owner_stb,
                      c.a_bus_op_replace_re  when cpu_l1mem_data_cache_owner_bus_op,
                      '0'                    when cpu_l1mem_data_cache_owner_none,
                      'X'                    when others;

  with c.a_request_state select
    c.a_mmu_request <= '0' when request_state_none |
                                request_state_uncached_load_bus_op |
                                request_state_uncached_store_bus_op |
                                request_state_cached_load_fill |
                                request_state_cached_load_writeback |
                                request_state_cached_store_stb_wait |
                                request_state_invalidate_sync |
                                request_state_writeback_sync |
                                request_state_writeback_bus_op |
                                request_state_flush_sync |
                                request_state_flush_bus_op |
                                request_state_sync,
                       '1' when request_state_uncached_load_mmu_access |
                                request_state_uncached_store_mmu_access |
                                request_state_cached_load_l1_access |
                                request_state_cached_store_l1_access |
                                request_state_invalidate_l1_access |
                                request_state_writeback_l1_access |
                                request_state_flush_l1_access |
                                request_state_flush_invalidate_l1_access,
                       'X' when others;
  
  with c.a_bus_op_state select
    c.a_sys_request <= '1' when bus_op_state_load |
                                     bus_op_state_store |
                                     bus_op_state_fill_first |
                                     bus_op_state_fill |
                                     bus_op_state_writeback |
                                     bus_op_state_writeback_last,
                            '0' when bus_op_state_none |
                                     bus_op_state_fill_last |
                                     bus_op_state_writeback_first,
                            'X' when others;
  
  c.a_sys_be <= c.a_bus_op_be;

  with c.a_bus_op_state select
    c.a_sys_write <= '0'                    when bus_op_state_load |
                                                      bus_op_state_fill_first |
                                                      bus_op_state_fill |
                                                      bus_op_state_fill_last,
                          '1'                    when bus_op_state_store |
                                                      bus_op_state_writeback |
                                                      bus_op_state_writeback_last,
                          'X'                    when others;
  with c.a_bus_op_state select
    c.a_sys_cacheable <= '0' when bus_op_state_load |
                                       bus_op_state_store,
                              '1' when bus_op_state_fill_first |
                                       bus_op_state_fill |
                                       bus_op_state_fill_last |
                                       bus_op_state_writeback_first |
                                       bus_op_state_writeback |
                                       bus_op_state_writeback_last,
                              'X' when others;
                              
  c.a_sys_priv <= c.a_bus_op_priv;

  a_sys_burst_gen_bursts : if sys_max_burst_cycles > 1 generate
    with c.a_bus_op_state select
      c.a_sys_burst <=
        not c.a_bus_op_block_word(cpu_l1mem_data_cache_block_words-1) when bus_op_state_fill_first |
                                                                           bus_op_state_fill,
        '1'                                                           when bus_op_state_writeback,
        '0'                                                           when bus_op_state_load |
                                                                           bus_op_state_store |
                                                                           bus_op_state_writeback_last,
        'X'                                                           when others;
    c.a_sys_bcycles <= std_ulogic_vector(to_unsigned(cpu_l1mem_data_cache_offset_bits-cpu_log2_word_bytes, sys_burst_cycles_bits));
  end generate;
  a_sys_burst_gen_no_bursts : if sys_max_burst_cycles <= 1 generate
    c.a_sys_burst <= '0';
    c.a_sys_bcycles <= (others => 'X');
  end generate;
  
  r_next <= (
    b_vtram_owner                  => c.a_vtram_owner,
    b_rmdram_owner                 => c.a_rmdram_owner,

    b_request_granted              => c.a_request_granted,
    b_request                      => c.a_request,
    b_request_state                => c.a_request_state,
    b_request_way                  => c.a_request_way,
    b_request_mmu_accessed         => c.a_request_mmu_accessed_next,
    b_request_cache_block_dirty    => c.a_request_cache_block_dirty,

    b_bus_op_granted               => c.a_bus_op_granted,
    b_bus_op_owner                 => c.a_bus_op_owner,
    b_bus_op_state                 => c.a_bus_op_state,
    b_bus_op_way                   => c.a_bus_op_way,
    b_bus_op_be                    => c.a_bus_op_be,
    b_bus_op_block_word            => c.a_bus_op_block_word,
    b_bus_op_cacheable             => c.a_bus_op_cacheable,
    b_bus_op_priv                  => c.a_bus_op_priv,
    b_bus_op_requested             => c.a_bus_op_requested,

    b_stb_state                    => c.a_stb_state,
    b_stb_head_ptr                 => c.a_stb_head_ptr,
    b_stb_tail_ptr                 => c.a_stb_tail_ptr,
    b_stb_way                      => c.a_stb_way,
    b_stb_write_cache              => c.a_stb_write_cache,
    b_stb_write_bus                => c.a_stb_write_bus,

    b_stb_array_valid              => c.a_stb_array_valid,
    b_stb_array_alloc              => c.a_stb_array_alloc,
    b_stb_array_writethrough       => c.a_stb_array_writethrough,
    b_stb_array_be                 => c.a_stb_array_be,
    b_stb_array_priv               => c.a_stb_array_priv,
    b_stb_array_cache_hit          => c.a_stb_array_cache_hit,
    b_stb_array_way                => c.a_stb_array_way
    );

  cpu_l1mem_data_cache_ctrl_out <= (
    ready => c.b_result_ready,
    result => c.b_result_code
    );
  
  sys_master_ctrl_out <= (request => c.a_sys_request,
                        be => c.a_sys_be,
                        write => c.a_sys_write,
                        cacheable => c.a_sys_cacheable,
                        priv => c.a_sys_priv,
                        inst => '0',
                        burst => c.a_sys_burst,
                        bwrap => '1',
                        bcycles => c.a_sys_bcycles
                        );

  cpu_l1mem_data_cache_ctrl_out_vram <= (re => c.a_vram_re,
                                         we => c.b_vram_we,
                                         wdata => c.b_vram_wdata
                                         );
  
  cpu_l1mem_data_cache_ctrl_out_mram <= (re => c.a_mram_re,
                                         we => c.b_mram_we,
                                         wdata => c.b_mram_wdata
                                         );
  
  cpu_l1mem_data_cache_ctrl_out_tram <= (en => c.a_tram_en,
                                         we => c.a_tram_we,
                                         banken => c.a_tram_banken
                                         );
  
  cpu_l1mem_data_cache_ctrl_out_dram <= (en => c.a_dram_en,
                                         we => c.a_dram_we
                                         );

  cpu_l1mem_data_cache_dp_in_ctrl <= (
    a_stb_head_ptr => c.a_stb_head_ptr,
    a_stb_head_be => c.a_stb_head_be,
    a_stb_way => c.a_stb_way,
    a_vtram_owner => c.a_vtram_owner,
    a_rmdram_owner => c.a_rmdram_owner,
    a_bus_op_owner => c.a_bus_op_owner,
    a_bus_op_way => c.a_bus_op_way,
    a_bus_op_size_sel => c.a_bus_op_size_sel,
    a_bus_op_paddr_tag_sel => c.a_bus_op_paddr_tag_sel,
    a_bus_op_paddr_index_sel => c.a_bus_op_paddr_index_sel,
    a_bus_op_paddr_offset_sel => c.a_bus_op_paddr_offset_sel,
    a_bus_op_cache_paddr_sel_old => c.a_bus_op_cache_paddr_sel_old,
    a_bus_op_sys_paddr_sel_old => c.a_bus_op_sys_paddr_sel_old,
    a_bus_op_sys_data_sel_cache => c.a_bus_op_sys_data_sel_cache,
    a_dram_wdata_be => c.a_dram_wdata_be,
    b_vtram_owner => r.b_vtram_owner,
    b_rmdram_owner => r.b_rmdram_owner,
    b_stb_head_ptr => r.b_stb_head_ptr,
    b_replace_way => c.b_replace_way,
    b_stb_push_ptr => c.b_stb_push_ptr,
    b_stb_combine_ptr => c.b_stb_combine_ptr,
    b_cache_read_data_be => c.b_cache_read_data_be,
    b_cache_read_data_way => c.b_cache_read_data_way,
    b_request_be => r.b_request.be,
    b_request_stb_array_hit => c.b_request_stb_array_hit,
    b_request_complete => c.b_request_complete,
    b_result_data_sel   => c.b_result_data_sel
    );

  cpu_l1mem_data_cache_replace_ctrl_in <= (
    re => c.a_replace_re,
    we => c.b_replace_we,
    wway => c.b_replace_wway
    );

  cpu_mmu_data_ctrl_in <= (
    request => c.a_mmu_request,
    mmuen   => c.a_request.mmuen
    );
  
  seq : process (clk) is
  begin
    if rising_edge(clk) then
      case rstn is
        when '1' =>
          r <= r_next;
        when '0' =>
          r <= reg_init;
        when others =>
          r <= reg_x;
      end case;
    end if;
  end process;
  
end;
