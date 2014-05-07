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

use work.cpu_l1mem_inst_types_pkg.all;
use work.cpu_l1mem_inst_cache_pkg.all;
use work.cpu_l1mem_inst_cache_config_pkg.all;
use work.cpu_mmu_inst_types_pkg.all;
use work.cpu_types_pkg.all;

architecture rtl of cpu_l1mem_inst_cache_ctrl is

  type request_type is record
    code : cpu_l1mem_inst_request_code_type;
    direction : cpu_l1mem_inst_fetch_direction_type;
    cacheen : std_ulogic;
    mmuen : std_ulogic;
    priv : std_ulogic;
    alloc : std_ulogic;
  end record;
  constant request_x : request_type := (
    code => (others => 'X'),
    direction => (others => 'X'),
    cacheen => 'X',
    mmuen => 'X',
    priv => 'X',
    alloc => 'X'
    );
  constant request_init : request_type := (
    code => cpu_l1mem_inst_request_code_none,
    direction => (others => 'X'),
    cacheen => 'X',
    mmuen => 'X',
    priv => 'X',
    alloc => 'X'
    );

  type request_state_index_type is (
    request_state_index_none,
    request_state_index_uncached_fetch_mmu_access,
    request_state_index_uncached_fetch_bus_op,
    request_state_index_cached_fetch_l1_access,
    request_state_index_cached_fetch_fill,
    request_state_index_invalidate_sync,
    request_state_index_invalidate_l1_access,
    request_state_index_sync
    );
  type request_state_type is
    array (request_state_index_type range
           request_state_index_type'high downto
           request_state_index_type'low) of std_ulogic;
  constant request_state_none                      : request_state_type := "00000001";
  constant request_state_uncached_fetch_mmu_access : request_state_type := "00000010";
  constant request_state_uncached_fetch_bus_op     : request_state_type := "00000100";
  constant request_state_cached_fetch_l1_access    : request_state_type := "00001000";
  constant request_state_cached_fetch_fill         : request_state_type := "00010000";
  constant request_state_invalidate_sync           : request_state_type := "00100000";
  constant request_state_invalidate_l1_access      : request_state_type := "01000000";
  constant request_state_sync                      : request_state_type := "10000000";

  type bus_op_code_index_type is (
    bus_op_code_index_none,
    bus_op_code_index_fetch,
    bus_op_code_index_fill
    );
  type bus_op_code_type is
    array (bus_op_code_index_type range
           bus_op_code_index_type'high downto
           bus_op_code_index_type'low) of std_ulogic;
  constant bus_op_code_none      : bus_op_code_type := "001";
  constant bus_op_code_fetch     : bus_op_code_type := "010";
  constant bus_op_code_fill      : bus_op_code_type := "100";
  
  type bus_op_state_index_type is (
    bus_op_state_index_none,
    bus_op_state_index_fetch,
    bus_op_state_index_fill_first,
    bus_op_state_index_fill,
    bus_op_state_index_fill_last
    );
  type bus_op_state_type is
    array (bus_op_state_index_type range
           bus_op_state_index_type'high downto
           bus_op_state_index_type'low) of std_ulogic;
  constant bus_op_state_none                 : bus_op_state_type := "00001";
  constant bus_op_state_fetch                : bus_op_state_type := "00010";
  constant bus_op_state_fill_first           : bus_op_state_type := "00100";
  constant bus_op_state_fill                 : bus_op_state_type := "01000";
  constant bus_op_state_fill_last            : bus_op_state_type := "10000";

  type bus_op_type is record
    code : bus_op_code_type;
    way : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    priv : std_ulogic;
  end record;
  constant bus_op_x : bus_op_type := (
    code => (others => 'X'),
    way => (others => 'X'),
    priv => 'X'
    );
  constant bus_op_init : bus_op_type := (
    code => bus_op_code_none,
    way => (others => 'X'),
    priv => 'X'
    );

  type reg_type is record
    b_cache_owner                  : cpu_l1mem_inst_cache_owner_type;
    b_bus_op_owner                 : cpu_l1mem_inst_cache_owner_type;

    b_request_granted              : std_ulogic;
    b_request_state : request_state_type;
    b_request : request_type;
    b_request_tagless : std_ulogic;
    b_request_way : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_request_mmu_accessed : std_ulogic;

    b_bus_op_granted               : std_ulogic;
    b_bus_op_state : bus_op_state_type;
    b_bus_op_cacheable : std_ulogic;
    b_bus_op_priv : std_ulogic;
    b_bus_op_way : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_bus_op_block_inst : std_ulogic_vector(cpu_l1mem_inst_cache_block_insts-1 downto 0);
    b_bus_op_requested : std_ulogic;
    
  end record;
  constant reg_x : reg_type := (
    b_cache_owner => (others => 'X'),
    b_bus_op_owner => (others => 'X'),

    b_request_granted => 'X',
    b_request_state => (others => 'X'),
    b_request => request_x,
    b_request_tagless => 'X',
    b_request_way => (others => 'X'),
    b_request_mmu_accessed => 'X',

    b_bus_op_granted => 'X',
    b_bus_op_state => (others => 'X'),
    b_bus_op_cacheable => 'X',
    b_bus_op_priv => 'X',
    b_bus_op_way => (others => 'X'),
    b_bus_op_block_inst => (others => 'X'),
    b_bus_op_requested => 'X'

    );
  constant reg_init : reg_type := (
    b_cache_owner => cpu_l1mem_inst_cache_owner_none,
    b_bus_op_owner => cpu_l1mem_inst_cache_owner_none,
    
    b_request_granted => 'X',
    b_request_state => request_state_none,
    b_request => request_init,
    b_request_tagless => 'X',
    b_request_way => (others => 'X'),
    b_request_mmu_accessed => 'X',

    b_bus_op_granted => 'X',
    b_bus_op_state => bus_op_state_none,
    b_bus_op_cacheable => 'X',
    b_bus_op_priv => 'X',
    b_bus_op_way => (others => 'X'),
    b_bus_op_block_inst => (others => 'X'),
    b_bus_op_requested => 'X'
    );

  type comb_type is record
    b_vram_rdata : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_vram_rdata_all_ones : std_ulogic;
    b_vram_rdata_first_free : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);

    b_replace_rway : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_replace_way : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);

    b_bus_op_error : std_ulogic;
    b_bus_op_cycle_complete : std_ulogic;
    b_bus_op_fill_fetch_data_ready : std_ulogic;
    b_bus_op_fill_complete : std_ulogic;
    b_bus_op_complete : std_ulogic;
    b_bus_op_state_next_fill_first : bus_op_state_type;
    b_bus_op_state_next_fill : bus_op_state_type;
    b_bus_op_state_next_fill_last : bus_op_state_type;
    b_bus_op_state_next_no_error : bus_op_state_type;
    b_bus_op_state_next : bus_op_state_type;
    b_bus_op_block_inst_advance : std_ulogic;
    b_bus_op_block_inst_next : std_ulogic_vector(cpu_l1mem_inst_cache_block_insts-1 downto 0);
    b_bus_op_vram_we : std_ulogic;
    b_bus_op_vram_wdata : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_bus_op_replace_we : std_ulogic;
    b_bus_op_replace_wway : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    
    b_request_sync : std_ulogic;
    
    b_request_mmu_result_ready : std_ulogic;
    b_request_mmu_result_valid : std_ulogic;
    b_request_mmu_error : std_ulogic;

    b_request_cache_way_hit : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_request_cache_hit : std_ulogic;
    b_request_cache_miss : std_ulogic;

    b_request_complete_uncached_fetch_mmu_access : std_ulogic;
    b_request_complete_uncached_fetch_bus_op : std_ulogic;
    b_request_complete_cached_fetch_l1_access : std_ulogic;
    b_request_complete_cached_fetch_fill : std_ulogic;
    b_request_complete_invalidate_l1_access : std_ulogic;
    b_request_complete_sync : std_ulogic;
    b_request_complete_no_error : std_ulogic;
    b_request_complete : std_ulogic;

    b_request_way_next_sel : std_ulogic_vector(2 downto 0);
    b_request_way_next   : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_request_tagless_seq_next : std_ulogic;
    
    b_request_state_next_uncached_fetch_mmu_access : request_state_type;
    b_request_state_next_cached_fetch_l1_access : request_state_type;
    b_request_state_next_invalidate_sync : request_state_type;
    b_request_state_next_no_error : request_state_type;
    b_request_state_next : request_state_type;

    b_request_cache_accessed_next : std_ulogic;
    
    b_request_replace_we : std_ulogic;
    b_request_replace_wway : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_request_vram_we : std_ulogic;
    b_request_vram_wdata : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);

    b_cache_read_data_way : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);

    b_result_ready   : std_ulogic;
    b_result_code_mmu_access    : cpu_l1mem_inst_result_code_type;
    b_result_code_no_error      : cpu_l1mem_inst_result_code_type;
    b_result_code               : cpu_l1mem_inst_result_code_type;
    b_result_inst_sel           : cpu_l1mem_inst_cache_b_result_inst_sel_type;

    b_replace_we_no_error : std_ulogic;
    b_replace_we : std_ulogic;
    b_replace_wway : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_vram_we_no_error : std_ulogic;
    b_vram_we : std_ulogic;
    b_vram_wdata : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    
    b_cache_owner_next_request : cpu_l1mem_inst_cache_owner_type;
    b_cache_owner_next_bus_op_request : cpu_l1mem_inst_cache_owner_type;
    b_cache_owner_next_bus_op_bus_op  : cpu_l1mem_inst_cache_owner_type;
    b_cache_owner_next_bus_op : cpu_l1mem_inst_cache_owner_type;
    b_cache_owner_next_no_error : cpu_l1mem_inst_cache_owner_type;
    b_cache_owner_next : cpu_l1mem_inst_cache_owner_type;

    b_bus_op_owner_next_request         : cpu_l1mem_inst_cache_owner_type;
    b_bus_op_owner_next_bus_op          : cpu_l1mem_inst_cache_owner_type;
    b_bus_op_owner_next_no_error        : cpu_l1mem_inst_cache_owner_type;
    b_bus_op_owner_next                 : cpu_l1mem_inst_cache_owner_type;
    
    a_new_request     : request_type;
    a_new_request_fill_forward : std_ulogic;
    a_new_request_state_fetch : request_state_type;
    a_new_request_state : request_state_type;

    a_request : request_type;
    a_request_fill_forward : std_ulogic;
    a_request_state   : request_state_type;
    a_request_tagless : std_ulogic;
    a_request_way   : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    a_request_cache_accessed : std_ulogic;
    a_request_mmu_accessed : std_ulogic;

    a_request_want_cache : std_ulogic;
    a_request_want_bus_op : std_ulogic;
    a_request_can_own_cache : std_ulogic;
    a_request_can_own_bus_op : std_ulogic;
    a_request_granted : std_ulogic;
    
    a_request_bus_op_code : bus_op_code_type;
    a_request_vram_re : std_ulogic;
    a_request_tram_en : std_ulogic;
    a_request_tram_we : std_ulogic;
    a_request_tram_banken : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    a_request_dram_en : std_ulogic;
    a_request_dram_banken : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    a_request_replace_re : std_ulogic;
    a_request_mmu_accessed_next : std_ulogic;
    
    a_new_bus_op_owner : cpu_l1mem_inst_cache_owner_type;
    a_new_bus_op_code : bus_op_code_type;
    a_new_bus_op_state : bus_op_state_type;
    a_new_bus_op_cacheable : std_ulogic;
    a_new_bus_op_priv : std_ulogic;
    a_new_bus_op_way : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    a_new_bus_op_block_inst : std_ulogic_vector(cpu_l1mem_inst_cache_block_insts-1 downto 0);

    a_bus_op_owner       : cpu_l1mem_inst_cache_owner_type;
    a_bus_op_state       : bus_op_state_type;
    a_bus_op_priv        : std_ulogic;
    a_bus_op_way         : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    a_bus_op_cacheable   : std_ulogic;
    a_bus_op_block_inst  : std_ulogic_vector(cpu_l1mem_inst_cache_block_insts-1 downto 0);
    a_bus_op_requested   : std_ulogic;
    a_bus_op_paddr_tag_sel : cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_type;
    a_bus_op_paddr_index_sel : cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_type;
    a_bus_op_paddr_offset_sel : cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_type;
    a_bus_op_cache_paddr_sel_old : std_ulogic;


    a_bus_op_want_cache : std_ulogic;
    
    a_bus_op_vram_re : std_ulogic;

    a_bus_op_tram_en : std_ulogic;
    a_bus_op_tram_we : std_ulogic;
    a_bus_op_tram_banken : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    
    a_bus_op_dram_en : std_ulogic;
    a_bus_op_dram_we : std_ulogic;
    a_bus_op_dram_banken : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    
    a_bus_op_replace_re : std_ulogic;

    a_bus_op_can_own_cache : std_ulogic;
    a_bus_op_granted : std_ulogic;
    
    a_new_cache_owner      : cpu_l1mem_inst_cache_owner_type;
    a_cache_owner      : cpu_l1mem_inst_cache_owner_type;
    
    a_vram_re : std_ulogic;

    a_tram_en : std_ulogic;
    a_tram_we : std_ulogic;
    a_tram_banken : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);

    a_dram_en : std_ulogic;
    a_dram_we : std_ulogic;
    a_dram_banken : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);

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

  c.b_vram_rdata <= cpu_l1mem_inst_cache_ctrl_in_vram.rdata;

  c.b_vram_rdata_all_ones <= all_ones(c.b_vram_rdata);
  c.b_vram_rdata_first_free <= prioritize(not c.b_vram_rdata);

  c.b_replace_rway <= cpu_l1mem_inst_cache_replace_ctrl_out.rway;
  
  with c.b_vram_rdata_all_ones select
    c.b_replace_way <= c.b_replace_rway          when '1',
                       c.b_vram_rdata_first_free when '0',
                       (others => 'X')           when others;




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
    c.b_bus_op_fill_fetch_data_ready <= c.b_bus_op_cycle_complete when bus_op_state_fill_first,
                                        sys_slave_ctrl_out.ready  when bus_op_state_fill,
                                        'X'                       when others;
  c.b_bus_op_fill_complete <= (
    r.b_bus_op_state(bus_op_state_index_fill_last)
    );
  
  with r.b_bus_op_state select
    c.b_bus_op_complete <= '1'                       when bus_op_state_none |
                                                          bus_op_state_fill_last,
                           c.b_bus_op_cycle_complete when bus_op_state_fetch,
                           '0'                       when bus_op_state_fill_first |
                                                          bus_op_state_fill,
                           'X'                       when others;
  
  b_bus_op_state_next_block_insts_eq_1_gen : if cpu_l1mem_inst_cache_block_insts = 1 generate
    c.b_bus_op_state_next_fill_first <= (
      bus_op_state_index_fill_first => (
        not c.b_bus_op_cycle_complete
        ),
      bus_op_state_index_fill_last => (
        c.b_bus_op_cycle_complete
        ),
      others => '0'
      );
  end generate;
  b_bus_op_state_next_block_insts_gt_1_gen : if cpu_l1mem_inst_cache_block_insts > 1 generate
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
        not r.b_bus_op_block_inst(cpu_l1mem_inst_cache_block_insts-1)
        ),
      bus_op_state_index_fill_last => (
        c.b_bus_op_cycle_complete and
        r.b_bus_op_block_inst(cpu_l1mem_inst_cache_block_insts-1)
        ),
      others => '0'
      );
  end generate;
  with r.b_bus_op_state select
    c.b_bus_op_state_next_no_error <= bus_op_state_fetch                         when bus_op_state_fetch,
                                      c.b_bus_op_state_next_fill_first           when bus_op_state_fill_first,
                                      c.b_bus_op_state_next_fill                 when bus_op_state_fill,
                                      bus_op_state_fill_last                     when bus_op_state_fill_last,
                                      (others => 'X')                            when others;
  with c.b_bus_op_error select
    c.b_bus_op_state_next <= c.b_bus_op_state_next_no_error when '0',
                             bus_op_state_none              when '1',
                             (others => 'X')                when others;
  
  with r.b_bus_op_state select
    c.b_bus_op_block_inst_advance <= sys_slave_ctrl_out.ready when bus_op_state_fill_first |
                                                                   bus_op_state_fill,
                                     '0'                      when bus_op_state_fetch,
                                     'X'                      when others;
  
  with c.b_bus_op_block_inst_advance select
    c.b_bus_op_block_inst_next <= r.b_bus_op_block_inst when '0',
                                  (r.b_bus_op_block_inst(cpu_l1mem_inst_cache_block_insts-2 downto 0) &
                                   r.b_bus_op_block_inst(cpu_l1mem_inst_cache_block_insts-1)
                                   )                    when '1',
                                  (others => 'X')       when others;

  with r.b_bus_op_state select
    c.b_bus_op_vram_we <= '0'                       when bus_op_state_fill,
                          sys_slave_ctrl_out.ready and r.b_bus_op_block_inst(0) when bus_op_state_fill_first,
                          '1'                       when bus_op_state_fill_last,
                          'X'                       when others;
  with r.b_bus_op_state select
    c.b_bus_op_vram_wdata <= c.b_vram_rdata and not r.b_bus_op_way when bus_op_state_fill_first,
                             c.b_vram_rdata or r.b_bus_op_way      when bus_op_state_fill_last,
                             (others => 'X')                       when others;

  with r.b_bus_op_state select
    c.b_bus_op_replace_we <= '0' when bus_op_state_fill_first |
                                      bus_op_state_fill,
                             '1' when bus_op_state_fill_last,
                             'X' when others;
  c.b_bus_op_replace_wway <= r.b_bus_op_way;

  ---- request post-phase

  c.b_request_sync <= (
    r.b_cache_owner(cpu_l1mem_inst_cache_owner_index_none) and
    r.b_bus_op_owner(cpu_l1mem_inst_cache_owner_index_none)
    );    

  c.b_request_mmu_result_ready <= (
    r.b_request_mmu_accessed and 
    cpu_mmu_inst_ctrl_out.ready
    );
  c.b_request_mmu_result_valid <= (
    r.b_request_mmu_accessed and 
    cpu_mmu_inst_ctrl_out.ready and
    cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_valid)
    );
  c.b_request_mmu_error <= (
    r.b_request_mmu_accessed and 
    cpu_mmu_inst_ctrl_out.ready and
    not cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_valid)
    );

  -- check for cache hit
  c.b_request_cache_way_hit <= (c.b_vram_rdata and
                                cpu_l1mem_inst_cache_dp_out_ctrl.b_request_cache_tag_match);
  c.b_request_cache_hit <= reduce_or(c.b_request_cache_way_hit);
  c.b_request_cache_miss <= not c.b_request_cache_hit;
  
  -- request completion

  c.b_request_complete_uncached_fetch_mmu_access <= (
    c.b_request_mmu_error
    );
  c.b_request_complete_uncached_fetch_bus_op <= (
    r.b_request_granted and
    c.b_bus_op_cycle_complete
    );
  c.b_request_complete_cached_fetch_l1_access <= (
    (c.b_request_mmu_result_valid and
     ((r.b_request_granted and
       (r.b_request_tagless or
        c.b_request_cache_hit))
      )
     ) or
    c.b_request_mmu_error
    );
  c.b_request_complete_cached_fetch_fill <= (
    r.b_request_granted and
    c.b_bus_op_fill_fetch_data_ready
    );
  c.b_request_complete_invalidate_l1_access <= (
    r.b_request_granted
    );
  c.b_request_complete_sync <= (
    c.b_request_sync
    );
  
  with r.b_request_state select
    c.b_request_complete_no_error <= '1'                                               when request_state_none,
                                     c.b_request_complete_uncached_fetch_mmu_access    when request_state_uncached_fetch_mmu_access,
                                     c.b_request_complete_uncached_fetch_bus_op        when request_state_uncached_fetch_bus_op,
                                     c.b_request_complete_cached_fetch_l1_access       when request_state_cached_fetch_l1_access,
                                     c.b_request_complete_cached_fetch_fill            when request_state_cached_fetch_fill,
                                     c.b_request_complete_sync                         when request_state_sync,
                                     c.b_request_complete_invalidate_l1_access         when request_state_invalidate_l1_access,
                                     '0'                                               when request_state_invalidate_sync,
                                     'X'                                               when others;
  c.b_request_complete <= c.b_request_complete_no_error or c.b_bus_op_error;

  c.b_request_way_next_sel <= (
    0 => (
      r.b_request_state(request_state_index_none) or
      r.b_request_state(request_state_index_cached_fetch_fill) or
      (r.b_request_state(request_state_index_cached_fetch_l1_access) and
       r.b_request_tagless)
      ),
    1 => (
      r.b_request_state(request_state_index_cached_fetch_l1_access) and
      not r.b_request_tagless and
      c.b_request_cache_hit
      ),
    2 => (
      r.b_request_state(request_state_index_cached_fetch_l1_access) and
      not r.b_request_tagless and
      not c.b_request_cache_hit
      )
    );

  with c.b_request_way_next_sel select
    c.b_request_way_next <= r.b_request_way           when "001",
                            c.b_request_cache_way_hit when "010",
                            c.b_replace_way           when "100",
                            (others => 'X')           when others;
  
  with r.b_request_state select
    c.b_request_tagless_seq_next <= r.b_request_tagless when request_state_none,
                                    not cpu_l1mem_inst_cache_dp_out_ctrl.b_request_last_in_block
                                                        when request_state_cached_fetch_l1_access |
                                                             request_state_cached_fetch_fill,
                                    '0'                 when request_state_uncached_fetch_mmu_access |
                                                             request_state_uncached_fetch_bus_op |
                                                             request_state_invalidate_sync |
                                                             request_state_invalidate_l1_access |
                                                             request_state_sync,
                                    'X'                 when others;
  
  c.b_request_state_next_uncached_fetch_mmu_access <= (
    request_state_index_uncached_fetch_mmu_access => (
      not c.b_request_mmu_result_ready
      ),
    request_state_index_uncached_fetch_bus_op => (
      c.b_request_mmu_result_ready
      ),
    others => '0'
    );
  c.b_request_state_next_cached_fetch_l1_access <= (
    request_state_index_cached_fetch_l1_access => (
      not r.b_request_granted or
      not c.b_request_mmu_result_ready
      ),
    request_state_index_cached_fetch_fill => (
      r.b_request_granted and
      r.b_request.alloc and
      c.b_request_mmu_result_ready
      ),
    request_state_index_uncached_fetch_bus_op => (
      r.b_request_granted and
      not r.b_request.alloc
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
  with r.b_request_state select
    c.b_request_state_next_no_error <= r.b_request_state                                when request_state_none |
                                                                                             request_state_uncached_fetch_bus_op |
                                                                                             request_state_invalidate_l1_access |
                                                                                             request_state_sync,
                                       c.b_request_state_next_uncached_fetch_mmu_access when request_state_uncached_fetch_mmu_access,
                                       c.b_request_state_next_cached_fetch_l1_access    when request_state_cached_fetch_l1_access,
                                       request_state_cached_fetch_fill                  when request_state_cached_fetch_fill,
                                       c.b_request_state_next_invalidate_sync           when request_state_invalidate_sync,
                                       (others => 'X')                                  when others;
  with c.b_bus_op_error select
    c.b_request_state_next <= c.b_request_state_next_no_error when '0',
                              request_state_none              when '1',
                              (others => 'X')                 when others;

  with r.b_request_state select
    c.b_request_cache_accessed_next <= r.b_request_granted when request_state_cached_fetch_l1_access |
                                                                request_state_invalidate_l1_access,
                                       '0'                 when request_state_none |
                                                                request_state_invalidate_sync,
                                       'X'                 when others;

  with r.b_request_state select
    c.b_request_replace_we <= (c.b_request_mmu_result_valid and
                               (c.b_request_cache_hit or
                                r.b_request_tagless)
                               )  when request_state_cached_fetch_l1_access,
                              '0' when request_state_invalidate_l1_access,
                              'X' when others;
  with r.b_request_state select
    c.b_request_replace_wway <= logic_if(r.b_request_tagless,
                                         r.b_request_way,
                                         c.b_request_cache_way_hit) when request_state_cached_fetch_l1_access,
                                (others => 'X')                     when others;

  with r.b_request_state select
    c.b_request_vram_we <= '1' when request_state_invalidate_l1_access,
                           '0' when request_state_cached_fetch_l1_access,
                           'X' when others;
  
  with r.b_request_state select
    c.b_request_vram_wdata <= (others => '0')                        when request_state_invalidate_l1_access,
                              (others => 'X')                        when others;

  with r.b_cache_owner select
    c.b_cache_read_data_way <= r.b_bus_op_way                      when cpu_l1mem_inst_cache_owner_bus_op,
                               logic_if(r.b_request_tagless,
                                        r.b_request_way,
                                        c.b_request_cache_way_hit) when cpu_l1mem_inst_cache_owner_request,
                               (others => 'X')                     when others;

  -- request result processing
  c.b_result_ready <= c.b_request_complete;
  
  c.b_result_code_mmu_access <= (
    cpu_l1mem_inst_result_code_index_valid => (
      not r.b_request.mmuen or
      cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_valid)
      ),
    cpu_l1mem_inst_result_code_index_error => (
      r.b_request.mmuen and
      cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_error)
      ),
    cpu_l1mem_inst_result_code_index_tlbmiss => (
      r.b_request.mmuen and
      cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_tlbmiss)
      ),
    cpu_l1mem_inst_result_code_index_pf => (
      r.b_request.mmuen and
      cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_pf)
      )
    );
  
  with r.b_request_state select
    c.b_result_code_no_error <= c.b_result_code_mmu_access       when request_state_uncached_fetch_mmu_access |
                                                                      request_state_cached_fetch_l1_access,
                                cpu_l1mem_inst_result_code_valid when request_state_none |
                                                                      request_state_sync |
                                                                      request_state_uncached_fetch_bus_op |
                                                                      request_state_cached_fetch_fill |
                                                                      request_state_invalidate_l1_access,
                                (others => 'X')                  when others;
  
  with c.b_bus_op_error select
    c.b_result_code <= c.b_result_code_no_error         when '0',
                       cpu_l1mem_inst_result_code_error when '1',
                       (others => 'X')                  when others;

  with r.b_request_state select
    c.b_result_inst_sel <= cpu_l1mem_inst_cache_b_result_inst_sel_b_cache       when request_state_cached_fetch_l1_access,
                           cpu_l1mem_inst_cache_b_result_inst_sel_b_bus         when request_state_uncached_fetch_bus_op |
                                                                                     request_state_cached_fetch_fill,
                           (others => 'X')                                    when others;

  -- write vram, replace
  with r.b_cache_owner select
    c.b_replace_we_no_error <= c.b_request_replace_we when cpu_l1mem_inst_cache_owner_request,
                               c.b_bus_op_replace_we  when cpu_l1mem_inst_cache_owner_bus_op,
                               '0'                    when cpu_l1mem_inst_cache_owner_none,
                               'X'                    when others;
  c.b_replace_we <= c.b_replace_we_no_error and not c.b_bus_op_error;

  with r.b_cache_owner select
    c.b_replace_wway <= c.b_request_replace_wway when cpu_l1mem_inst_cache_owner_request,
                        c.b_bus_op_replace_wway  when cpu_l1mem_inst_cache_owner_bus_op,
                        (others => 'X')          when others;

  with r.b_cache_owner select
    c.b_vram_we_no_error <= c.b_request_vram_we when cpu_l1mem_inst_cache_owner_request,
                            c.b_bus_op_vram_we  when cpu_l1mem_inst_cache_owner_bus_op,
                            '0'                 when cpu_l1mem_inst_cache_owner_none,
                            'X'                 when others;
  c.b_vram_we <= c.b_vram_we_no_error and not c.b_bus_op_error;
  
  with r.b_cache_owner select
    c.b_vram_wdata <= c.b_request_vram_wdata when cpu_l1mem_inst_cache_owner_request,
                      c.b_bus_op_vram_wdata  when cpu_l1mem_inst_cache_owner_bus_op,
                      (others => 'X')        when others;

  with r.b_request_state select
    c.b_cache_owner_next_request <=
      (cpu_l1mem_inst_cache_owner_index_none => (
         c.b_request_mmu_result_ready
         ),
       cpu_l1mem_inst_cache_owner_index_request => (
         not c.b_request_mmu_result_ready
         ),
       others => '0'
       ) when request_state_cached_fetch_l1_access,
      cpu_l1mem_inst_cache_owner_none when request_state_invalidate_l1_access,
      (others => 'X') when others;


  with r.b_request_state select
    c.b_cache_owner_next_bus_op_request <=
      (cpu_l1mem_inst_cache_owner_index_none => (
         c.b_bus_op_fill_complete or
         c.b_bus_op_error
         ),
       cpu_l1mem_inst_cache_owner_index_bus_op => (
         not c.b_bus_op_fill_complete and
         not c.b_bus_op_error
         ),
       others => '0'
       ) when request_state_cached_fetch_fill,
      (others => 'X') when others;

  with r.b_bus_op_state select
    c.b_cache_owner_next_bus_op_bus_op <=
      cpu_l1mem_inst_cache_owner_bus_op    when bus_op_state_fill_first |
                                                bus_op_state_fill,
      cpu_l1mem_inst_cache_owner_none      when bus_op_state_fill_last,
      (others => 'X') when others;

  with r.b_bus_op_owner select
    c.b_cache_owner_next_bus_op <= cpu_l1mem_inst_cache_owner_none     when cpu_l1mem_inst_cache_owner_none,
                                   c.b_cache_owner_next_bus_op_request when cpu_l1mem_inst_cache_owner_request,
                                   c.b_cache_owner_next_bus_op_bus_op  when cpu_l1mem_inst_cache_owner_bus_op,
                                   (others => 'X')                     when others;
  
  -- Choose the next cache vram & tram owner
  with r.b_cache_owner select
    c.b_cache_owner_next_no_error <= c.b_cache_owner_next_request    when cpu_l1mem_inst_cache_owner_request,
                                     c.b_cache_owner_next_bus_op     when cpu_l1mem_inst_cache_owner_bus_op,
                                     cpu_l1mem_inst_cache_owner_none when cpu_l1mem_inst_cache_owner_none,
                                     (others => 'X')                 when others;
  with c.b_bus_op_error select
    c.b_cache_owner_next <= c.b_cache_owner_next_no_error when '0',
                            cpu_l1mem_inst_cache_owner_none when '1',
                            (others => 'X') when others;

  with r.b_request_state select
    c.b_bus_op_owner_next_request <=
      (cpu_l1mem_inst_cache_owner_index_none    => c.b_bus_op_cycle_complete,
       cpu_l1mem_inst_cache_owner_index_request => not c.b_bus_op_cycle_complete,
       others => '0'
       ) when request_state_uncached_fetch_bus_op,
      (cpu_l1mem_inst_cache_owner_index_none    => c.b_bus_op_fill_complete or c.b_bus_op_error,
       cpu_l1mem_inst_cache_owner_index_bus_op  => c.b_bus_op_fill_fetch_data_ready and not c.b_bus_op_fill_complete and not c.b_bus_op_error,
       cpu_l1mem_inst_cache_owner_index_request => not c.b_bus_op_fill_fetch_data_ready and not c.b_bus_op_error,
       others => '0'
       ) when request_state_cached_fetch_fill,
      (others => 'X'
       ) when others;
  with r.b_bus_op_state select
    c.b_bus_op_owner_next_bus_op <=
      cpu_l1mem_inst_cache_owner_bus_op when bus_op_state_fill,
      cpu_l1mem_inst_cache_owner_none   when bus_op_state_fill_last,
      (others => 'X') when others;

  with r.b_bus_op_owner select
    c.b_bus_op_owner_next_no_error <= cpu_l1mem_inst_cache_owner_none when cpu_l1mem_inst_cache_owner_none,
                                      c.b_bus_op_owner_next_request   when cpu_l1mem_inst_cache_owner_request,
                                      c.b_bus_op_owner_next_bus_op    when cpu_l1mem_inst_cache_owner_bus_op,
                                      (others => 'X')                 when others;
  with c.b_bus_op_error select
    c.b_bus_op_owner_next <= c.b_bus_op_owner_next_no_error when '0',
                             cpu_l1mem_inst_cache_owner_none when '1',
                             (others => 'X') when others;


  -- new request selection, declare wants
  c.a_new_request <= (code          => cpu_l1mem_inst_cache_ctrl_in.request,
                      direction     => cpu_l1mem_inst_cache_ctrl_in.direction,
                      cacheen       => cpu_l1mem_inst_cache_ctrl_in.cacheen,
                      mmuen         => cpu_l1mem_inst_cache_ctrl_in.mmuen,
                      priv          => cpu_l1mem_inst_cache_ctrl_in.priv,
                      alloc         => cpu_l1mem_inst_cache_ctrl_in.alloc
                      );

  c.a_new_request_fill_forward <= (
    c.a_new_request.code(cpu_l1mem_inst_request_code_index_fetch) and
    r.b_request_state(request_state_index_cached_fetch_fill) and
    c.a_new_request.direction(cpu_l1mem_inst_fetch_direction_index_seq) and
    not cpu_l1mem_inst_cache_dp_out_ctrl.b_request_last_in_block and
    not (c.a_new_request.mmuen xor r.b_request.mmuen)
    );
  
  c.a_new_request_state_fetch <= (
    request_state_index_uncached_fetch_mmu_access => (
      not c.a_request.cacheen
      ),
    request_state_index_cached_fetch_l1_access => (
      c.a_request.cacheen and
      not c.a_new_request_fill_forward
      ),
    request_state_index_cached_fetch_fill => (
      c.a_request.cacheen and
      c.a_new_request_fill_forward
      ),
    others => '0'
    );
  
  with c.a_request.code select
    c.a_new_request_state <= request_state_none                when cpu_l1mem_inst_request_code_none,
                             c.a_new_request_state_fetch       when cpu_l1mem_inst_request_code_fetch,
                             request_state_invalidate_sync     when cpu_l1mem_inst_request_code_invalidate,
                             request_state_sync                when cpu_l1mem_inst_request_code_sync,
                             (others => 'X')                   when others;

  with c.b_request_complete select
    c.a_request <= c.a_new_request when '1',
                   r.b_request     when '0',
                   request_x       when others;

  c.a_request_fill_forward <= c.b_request_complete and c.a_new_request_fill_forward;

  with c.b_request_complete select
    c.a_request_state <= c.a_new_request_state  when '1',
                         c.b_request_state_next when '0',
                         (others => 'X')        when others;

  with c.b_request_complete select
    c.a_request_tagless <= (c.b_request_tagless_seq_next and
                            c.a_request.direction(cpu_l1mem_inst_fetch_direction_index_seq)
                            )                       when '1',
                           r.b_request_tagless      when '0',
                           'X'                      when others;
  
  c.a_request_way <= c.b_request_way_next;
  c.a_request_cache_accessed    <= c.b_request_cache_accessed_next and not c.b_request_complete;
  c.a_request_mmu_accessed      <= r.b_request_mmu_accessed and not c.b_request_complete;

  with c.a_request_state select
    c.a_request_want_cache <= '0' when request_state_none |
                                       request_state_uncached_fetch_mmu_access |
                                       request_state_uncached_fetch_bus_op |
                                       request_state_cached_fetch_fill |
                                       request_state_invalidate_sync,
                              '1' when request_state_cached_fetch_l1_access |
                                       request_state_invalidate_l1_access,
                              'X' when others;
  
  with c.a_request_state select
    c.a_request_want_bus_op <= '0' when request_state_none |
                                        request_state_uncached_fetch_mmu_access |
                                        request_state_cached_fetch_l1_access |
                                        request_state_invalidate_sync |
                                        request_state_invalidate_l1_access,
                               '1' when request_state_uncached_fetch_bus_op |
                                        request_state_cached_fetch_fill,
                               'X' when others;

  with c.b_bus_op_owner_next select
    c.a_request_can_own_bus_op <= '1' when cpu_l1mem_inst_cache_owner_request |
                                           cpu_l1mem_inst_cache_owner_none,
                                  '0' when cpu_l1mem_inst_cache_owner_bus_op,
                                  'X' when others;
  
  with c.b_cache_owner_next select
    c.a_request_can_own_cache <= '1' when cpu_l1mem_inst_cache_owner_request |
                                          cpu_l1mem_inst_cache_owner_none,
                                 '0' when cpu_l1mem_inst_cache_owner_bus_op,
                                 'X' when others;

  c.a_request_granted <= (
    (not (c.a_request_want_cache and
          not c.a_request_can_own_cache
          ) and
     not (c.a_request_want_bus_op and
          not c.a_request_can_own_bus_op
          )
     ) or
    c.a_request_fill_forward
    );

  with c.a_request_state select
    c.a_request_bus_op_code <= bus_op_code_fetch     when request_state_uncached_fetch_bus_op,
                               bus_op_code_fill      when request_state_cached_fetch_fill,
                               (others => 'X')       when others;

  with c.a_request_state select
    c.a_request_vram_re <= (not c.a_request_cache_accessed and
                            not c.a_request_tagless)      when request_state_cached_fetch_l1_access,
                           '0'                            when request_state_invalidate_l1_access,
                           'X'                            when others;


  with c.a_request_state select
    c.a_request_tram_en <= (not c.a_request_cache_accessed and
                            not c.a_request_tagless)           when request_state_cached_fetch_l1_access,
                           '0'                                 when request_state_invalidate_l1_access,
                           'X' when others;
  with c.a_request_state select
    c.a_request_tram_we <= '0' when request_state_cached_fetch_l1_access,
                           'X' when others;
  with c.a_request_state select
    c.a_request_tram_banken <= (others => '1') when request_state_cached_fetch_l1_access,
                               (others => 'X') when others;

  with c.a_request_state select
    c.a_request_dram_en <= not c.a_request_cache_accessed when request_state_cached_fetch_l1_access,
                           '0'                            when request_state_invalidate_l1_access,
                           'X'                            when others;

  with c.a_request_state select
    c.a_request_dram_banken <= ((cpu_l1mem_inst_cache_assoc-1 downto 0 => not c.a_request_tagless) or
                                c.a_request_way) when request_state_cached_fetch_l1_access,
                               (others => 'X')   when others;

  with c.a_request_state select
    c.a_request_replace_re <= not c.a_request_cache_accessed when request_state_cached_fetch_l1_access |
                                                                  request_state_invalidate_l1_access,
                              'X'                            when others;
  
  c.a_request_mmu_accessed_next   <= c.a_request_mmu_accessed or cpu_mmu_inst_ctrl_out.ready;



  ---


  c.a_new_bus_op_owner <= (
    cpu_l1mem_inst_cache_owner_index_none => (
      not (c.a_request_granted and c.a_request_want_bus_op)
      ),
    cpu_l1mem_inst_cache_owner_index_request => (
      c.a_request_granted and c.a_request_want_bus_op
      ),
    cpu_l1mem_inst_cache_owner_index_bus_op => '0'
    );
  
  with c.a_new_bus_op_owner select
    c.a_new_bus_op_code <= c.a_request_bus_op_code when cpu_l1mem_inst_cache_owner_request,
                           bus_op_code_none        when cpu_l1mem_inst_cache_owner_none,
                           (others => 'X')         when others;
  with c.a_new_bus_op_code select
    c.a_new_bus_op_state <= bus_op_state_none            when bus_op_code_none,
                            bus_op_state_fetch           when bus_op_code_fetch,
                            bus_op_state_fill_first      when bus_op_code_fill,
                            (others => 'X')              when others;
  
  with c.a_new_bus_op_owner select
    c.a_new_bus_op_cacheable <= c.a_request.cacheen when cpu_l1mem_inst_cache_owner_request,
                                'X'                 when others;
  with c.a_new_bus_op_owner select
    c.a_new_bus_op_priv <= c.a_request.priv  when cpu_l1mem_inst_cache_owner_request,
                           'X'               when others;
  with c.a_new_bus_op_owner select
    c.a_new_bus_op_way <= c.a_request_way    when cpu_l1mem_inst_cache_owner_request,
                          (others => 'X')    when others;
  c.a_new_bus_op_block_inst <= (0 => '1', others => '0');

  with c.b_bus_op_owner_next(cpu_l1mem_inst_cache_owner_index_none) select
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
    c.a_bus_op_priv <= r.b_bus_op_priv     when '0',
                       c.a_new_bus_op_priv when '1',
                       'X'                 when others;
  with c.b_bus_op_complete select
    c.a_bus_op_way <= r.b_bus_op_way     when '0',
                      c.a_new_bus_op_way when '1',
                      (others => 'X')    when others;
  
  with c.b_bus_op_complete select
    c.a_bus_op_block_inst <= c.b_bus_op_block_inst_next when '0',
                             c.a_new_bus_op_block_inst  when '1',
                             (others => 'X')            when others;
  c.a_bus_op_requested <= (
    (r.b_bus_op_requested and
     not c.b_bus_op_complete) or
    sys_slave_ctrl_out.ready
    );

  with c.b_bus_op_complete select
    c.a_bus_op_paddr_tag_sel <= cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_old     when '0',
                                cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_request when '1',
                                (others => 'X')                                     when others;
  
  with c.b_bus_op_complete select
    c.a_bus_op_paddr_index_sel <= cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_old when '0',
                                  cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_request when '1',
                                  (others => 'X')                                   when others;
  
  with c.b_bus_op_complete select
    c.a_bus_op_paddr_offset_sel <= (cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_index_old =>
                                      not c.b_bus_op_block_inst_advance,
                                    cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_index_next =>
                                      c.b_bus_op_block_inst_advance,
                                    others => '0'
                                    )                                                     when '0',
                                   cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_request when '1',
                                   (others => 'X')                                        when others;
  
  with c.a_bus_op_state select
    c.a_bus_op_cache_paddr_sel_old <= '1' when bus_op_state_fill |
                                               bus_op_state_fill_last,
                                      '0' when bus_op_state_fill_first,
                                      'X' when others;
  with c.a_bus_op_state select
    c.a_bus_op_want_cache <= '0' when bus_op_state_none |
                                      bus_op_state_fetch,
                             '1' when bus_op_state_fill_first,
                             'X' when others;

  with c.a_bus_op_state select
    c.a_bus_op_vram_re <= '1' when bus_op_state_fill_first | -- clear valid bit
                                   bus_op_state_fill_last,   -- set valid bit
                          '0' when bus_op_state_fill,
                          'X' when others;

  with c.a_bus_op_state select
    c.a_bus_op_tram_en <= '1' when bus_op_state_fill_last, -- write tag for fill
                          '0' when bus_op_state_fill_first |
                                   bus_op_state_fill,
                          'X' when others;
  with c.a_bus_op_state select
    c.a_bus_op_tram_we <= '1' when bus_op_state_fill_last, -- write tag for fill
                          'X' when others;
  c.a_bus_op_tram_banken <= c.a_bus_op_way;

  with c.a_bus_op_state select
    c.a_bus_op_dram_en <= sys_slave_ctrl_out.ready when bus_op_state_fill |
                                                        bus_op_state_fill_last,
                          '0'                      when bus_op_state_fill_first,
                          'X'                      when others;
  with c.a_bus_op_state select
    c.a_bus_op_dram_we <= '1' when bus_op_state_fill |
                                   bus_op_state_fill_last,
                          'X' when others;

  c.a_bus_op_dram_banken <= c.a_bus_op_way;

  with c.a_bus_op_state select
    c.a_bus_op_replace_re <= '1' when bus_op_state_fill_last,
                             '0' when bus_op_state_fill_first |
                                      bus_op_state_fill,
                             'X' when others;

  with c.b_cache_owner_next select
    c.a_bus_op_can_own_cache <= '1' when cpu_l1mem_inst_cache_owner_bus_op |
                                         cpu_l1mem_inst_cache_owner_none,
                                '0' when cpu_l1mem_inst_cache_owner_request,
                                'X' when others;
  
  c.a_bus_op_granted <= (
    not (c.a_bus_op_want_cache and
         (not c.a_bus_op_can_own_cache or
          (c.a_request_granted and c.a_request_want_cache)
          )
         )
    );

  c.a_new_cache_owner <= (
    cpu_l1mem_inst_cache_owner_index_none => (
      not (c.a_request_granted and c.a_request_want_cache) and
      not (c.a_bus_op_granted and c.a_bus_op_want_cache)
      ),
    cpu_l1mem_inst_cache_owner_index_request => (
      c.a_request_granted and c.a_request_want_cache
      ),
    cpu_l1mem_inst_cache_owner_index_bus_op => (
      c.a_bus_op_granted and c.a_bus_op_want_cache
      )
    );
  with c.b_cache_owner_next select
    c.a_cache_owner <= c.a_new_cache_owner  when cpu_l1mem_inst_cache_owner_none,
                       c.b_cache_owner_next when cpu_l1mem_inst_cache_owner_request |
                                                 cpu_l1mem_inst_cache_owner_bus_op,
                       (others => 'X')      when others;

  -- choose cache component inputs

  with c.a_cache_owner select
    c.a_vram_re <= c.a_request_vram_re when cpu_l1mem_inst_cache_owner_request,
                   c.a_bus_op_vram_re  when cpu_l1mem_inst_cache_owner_bus_op,
                   '0'                 when cpu_l1mem_inst_cache_owner_none,
                   'X'                 when others;
  
  with c.a_cache_owner select
    c.a_tram_en <= c.a_request_tram_en when cpu_l1mem_inst_cache_owner_request,
                   c.a_bus_op_tram_en  when cpu_l1mem_inst_cache_owner_bus_op,
                   '0'                 when cpu_l1mem_inst_cache_owner_none,
                   'X'                 when others;
  
  with c.a_cache_owner select
    c.a_tram_we <= c.a_request_tram_we when cpu_l1mem_inst_cache_owner_request,
                   c.a_bus_op_tram_we  when cpu_l1mem_inst_cache_owner_bus_op,
                   'X'                 when others;

  with c.a_cache_owner select
    c.a_tram_banken <= c.a_request_tram_banken when cpu_l1mem_inst_cache_owner_request,
                       c.a_bus_op_tram_banken  when cpu_l1mem_inst_cache_owner_bus_op,
                       (others => 'X')         when others;

  with c.a_cache_owner select
    c.a_dram_en <= c.a_request_dram_en when cpu_l1mem_inst_cache_owner_request,
                   c.a_bus_op_dram_en  when cpu_l1mem_inst_cache_owner_bus_op,
                   '0'                 when cpu_l1mem_inst_cache_owner_none,
                   'X'                 when others;
  
  with c.a_cache_owner select
    c.a_dram_we <= '0'                 when cpu_l1mem_inst_cache_owner_request,
                   c.a_bus_op_dram_we  when cpu_l1mem_inst_cache_owner_bus_op,
                   'X'                 when others;

  with c.a_cache_owner select
    c.a_replace_re <= c.a_request_replace_re when cpu_l1mem_inst_cache_owner_request,
                      c.a_bus_op_replace_re  when cpu_l1mem_inst_cache_owner_bus_op,
                      '0'                    when cpu_l1mem_inst_cache_owner_none,
                      'X'                    when others;

  with c.a_cache_owner select
    c.a_dram_banken <= c.a_request_dram_banken when cpu_l1mem_inst_cache_owner_request,
                       c.a_bus_op_dram_banken  when cpu_l1mem_inst_cache_owner_bus_op,
                       (others => 'X')         when others;

  with c.a_request_state select
    c.a_mmu_request <= '0' when request_state_none |
                                request_state_uncached_fetch_bus_op |
                                request_state_cached_fetch_fill |
                                request_state_invalidate_sync |
                                request_state_sync,
                       '1' when request_state_uncached_fetch_mmu_access |
                                request_state_cached_fetch_l1_access |
                                request_state_invalidate_l1_access,
                       'X' when others;
  
  with c.a_bus_op_state select
    c.a_sys_request <= '1' when bus_op_state_fetch |
                                bus_op_state_fill_first |
                                bus_op_state_fill,
                       '0' when bus_op_state_none |
                                bus_op_state_fill_last,
                       'X' when others;

  a_sys_be_0 : if cpu_inst_endianness = little_endian generate
    c.a_sys_be <= '0';
  end generate;
  a_sys_be_1 : if cpu_inst_endianness = big_endian generate
    c.a_sys_be <= '1';
  end generate;
  
  with c.a_bus_op_state select
    c.a_sys_write <= '0'                    when bus_op_state_fetch |
                                                 bus_op_state_fill_first |
                                                 bus_op_state_fill |
                                                 bus_op_state_fill_last,
                     'X'                    when others;
  with c.a_bus_op_state select
    c.a_sys_cacheable <= '0' when bus_op_state_fetch,
                         '1' when bus_op_state_fill_first |
                                  bus_op_state_fill |
                                  bus_op_state_fill_last,
                         'X' when others;
                              
  c.a_sys_priv <= c.a_bus_op_priv;

  a_sys_burst_gen_bursts : if sys_max_burst_cycles > 1 generate
    with c.a_bus_op_state select
      c.a_sys_burst <=
        not c.a_bus_op_block_inst(cpu_l1mem_inst_cache_block_insts-1) when bus_op_state_fill_first |
                                                                           bus_op_state_fill,
        '0'                                                           when bus_op_state_fetch,
        'X'                                                           when others;
    c.a_sys_bcycles <= std_ulogic_vector(to_unsigned(cpu_l1mem_inst_cache_offset_bits-cpu_log2_word_bytes, sys_burst_cycles_bits));
  end generate;
  a_sys_burst_gen_no_bursts : if sys_max_burst_cycles <= 1 generate
    c.a_sys_burst <= '0';
    c.a_sys_bcycles <= (others => 'X');
  end generate;
  
  r_next <= (
    b_cache_owner                  => c.a_cache_owner,
    b_bus_op_owner                 => c.a_bus_op_owner,

    b_request_granted              => c.a_request_granted,
    b_request_state                => c.a_request_state,
    b_request                      => c.a_request,
    b_request_tagless              => c.a_request_tagless,
    b_request_way                  => c.a_request_way,
    b_request_mmu_accessed         => c.a_request_mmu_accessed_next,

    b_bus_op_granted               => c.a_bus_op_granted,
    b_bus_op_state                 => c.a_bus_op_state,
    b_bus_op_cacheable             => c.a_bus_op_cacheable,
    b_bus_op_priv                  => c.a_bus_op_priv,
    b_bus_op_way                   => c.a_bus_op_way,
    b_bus_op_block_inst            => c.a_bus_op_block_inst,
    b_bus_op_requested             => c.a_bus_op_requested
    );

  cpu_l1mem_inst_cache_ctrl_out <= (
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

  cpu_l1mem_inst_cache_ctrl_out_vram <= (re => c.a_vram_re,
                                         we => c.b_vram_we,
                                         wdata => c.b_vram_wdata
                                         );
  
  cpu_l1mem_inst_cache_ctrl_out_tram <= (en => c.a_tram_en,
                                         we => c.a_tram_we,
                                         banken => c.a_tram_banken
                                         );
  
  cpu_l1mem_inst_cache_ctrl_out_dram <= (en => c.a_dram_en,
                                         we => c.a_dram_we,
                                         banken => c.a_dram_banken
                                         );

  cpu_l1mem_inst_cache_dp_in_ctrl <= (
    a_cache_owner => c.a_cache_owner,
    a_bus_op_paddr_tag_sel => c.a_bus_op_paddr_tag_sel,
    a_bus_op_paddr_index_sel => c.a_bus_op_paddr_index_sel,
    a_bus_op_paddr_offset_sel => c.a_bus_op_paddr_offset_sel,
    a_bus_op_cache_paddr_sel_old => c.a_bus_op_cache_paddr_sel_old,
    b_request_complete => c.b_request_complete,
    b_cache_owner => r.b_cache_owner,
    b_cache_read_data_way => c.b_cache_read_data_way,
    b_replace_way => c.b_replace_way,
    b_result_inst_sel   => c.b_result_inst_sel
    );

  cpu_l1mem_inst_cache_replace_ctrl_in <= (
    re => c.a_replace_re,
    we => c.b_replace_we,
    wway => c.b_replace_wway
    );

  cpu_mmu_inst_ctrl_in <= (
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

  --pragma translate_off
  a_dram_en_monitor : block is
    signal a_dram_en_mon : std_ulogic_vector(0 downto 0);
  begin
    a_dram_en_mon(0) <= c.a_dram_en;
    mon : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
        name => "a_dram_en",
        data_bits => 1
        )
      port map (
        clk => clk,
        data => a_dram_en_mon
        );
  end block;
    
  a_dram_we_monitor : block is
    signal a_dram_we_mon : std_ulogic_vector(0 downto 0);
  begin
    with c.a_dram_en select
      a_dram_we_mon(0) <= c.a_dram_we when '1',
                          'X'         when others;
    mon : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
        name => "a_dram_we",
        data_bits => 1
        )
      port map (
        clk => clk,
        data => a_dram_we_mon
        );
  end block;
    
  a_tram_en_monitor : block is
    signal a_tram_en_mon : std_ulogic_vector(0 downto 0);
  begin
    a_tram_en_mon(0) <= c.a_tram_en;
    mon : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
        name => "a_tram_en",
        data_bits => 1
        )
      port map (
        clk => clk,
        data => a_tram_en_mon
        );
  end block;
    
  a_tram_we_monitor : block is
    signal a_tram_we_mon : std_ulogic_vector(0 downto 0);
  begin
    with c.a_tram_en select
      a_tram_we_mon(0) <= c.a_tram_we when '1',
                          'X'         when others;
    mon : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
        name => "a_tram_we",
        data_bits => 1
        )
      port map (
        clk => clk,
        data => a_tram_we_mon
        );
  end block;
    
  a_vram_re_monitor : block is
    signal a_vram_re_mon : std_ulogic_vector(0 downto 0);
  begin
    a_vram_re_mon(0) <= c.a_vram_re;
    mon : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
        name => "a_vram_re",
        data_bits => 1
        )
      port map (
        clk => clk,
        data => a_vram_re_mon
        );
  end block;
    
  b_vram_we_monitor : block is
    signal b_vram_we_mon : std_ulogic_vector(0 downto 0);
  begin
    b_vram_we_mon(0) <= c.b_vram_we;
    mon : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
        name => "b_vram_we",
        data_bits => 1
        )
      port map (
        clk => clk,
        data => b_vram_we_mon
        );
  end block;

  a_replace_re_monitor : block is
    signal a_replace_re_mon : std_ulogic_vector(0 downto 0);
  begin
    a_replace_re_mon(0) <= c.a_replace_re;
    mon : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
        name => "a_replace_re",
        data_bits => 1
        )
      port map (
        clk => clk,
        data => a_replace_re_mon
        );
  end block;
    
  b_replace_we_monitor : block is
    signal b_replace_we_mon : std_ulogic_vector(0 downto 0);
  begin
    b_replace_we_mon(0) <= c.b_replace_we;
    mon : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
        name => "b_replace_we",
        data_bits => 1
        )
      port map (
        clk => clk,
        data => b_replace_we_mon
        );
  end block;

  --monitor : block is
  --  signal b_inst_fetch_valid : std_ulogic_vector(0 downto 0);
  --  signal b_inst_fetch_cacheen : std_ulogic;
  --  signal b_inst_fetch_mmuen : std_ulogic;
  --  signal b_inst_fetch_vpc : cpu_ivaddr_type;
  --  signal b_inst_fetch_ppc : cpu_ipaddr_type;
  --  signal b_inst_fetch_cache_hit : std_ulogic_vector(0 downto 0);
  --  signal b_inst_fetch_cache_miss : std_ulogic_vector(0 downto 0);
  --  signal b_inst_fetch_fill_forward : std_ulogic_vector(0 downto 0);
  --begin

    --b_fetch(0) <= (
    --  r.b_request.code(cpu_l1mem_inst_request_code_index_fetch) and
    --  c.b_request_complete and
    --  c.b_result_code(cpu_l1mem_inst_result_code_index_valid)
    --  );
    --b_cached(0) <= r.b_request.cacheen;
    --b_cache_hit(0) <= c.b_request_cache_hit;
    --b_cache_fill(0) <= c.b_fill_start;
    --b_cache_invalidate(0) <= r.b_request.code(cpu_l1mem_inst_request_code_index_invalidate);

    --b_fetch_monitor : entity sim.monitor_sync_watch(behav)
    --  generic map (
    --    instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
    --    name => "b_fetch",
    --    data_bits => 1
    --    )
    --  port map (
    --    clk => clk,
    --    data => b_fetch
    --    );
    --b_cached_monitor : entity sim.monitor_sync_watch(behav)
    --  generic map (
    --    instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
    --    name => "b_cached",
    --    data_bits => 1
    --    )
    --  port map (
    --    clk => clk,
    --    data => b_cached
    --    );
    --b_cache_hit_monitor : entity sim.monitor_sync_watch(behav)
    --  generic map (
    --    instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
    --    name => "b_cache_hit",
    --    data_bits => 1
    --    )
    --  port map (
    --    clk => clk,
    --    data => b_cache_hit
    --    );
    --b_invalidate_monitor : entity sim.monitor_sync_watch(behav)
    --  generic map (
    --    instance => entity_path_name(cpu_l1mem_inst_cache_ctrl'path_name),
    --    name => "b_cache_invalidate",
    --    data_bits => 1
    --    )
    --  port map (
    --    clk => clk,
    --    data => b_cache_invalidate
    --    );

  --end block;
  --pragma translate_on
  
end;
