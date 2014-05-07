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
-- either express or implied. See the Licensee for the specific language      --
-- governing permissions and limitations under the License.                  --
-------------------------------------------------------------------------------


library ieee;
use ieee.numeric_std.all;

library util;
use util.logic_pkg.all;
use util.types_pkg.all;

library sys;
use sys.sys_config_pkg.all;
use sys.sys_pkg.all;

library tech;

use work.cpu_l1mem_data_cache_pkg.all;
use work.cpu_l1mem_data_cache_config_pkg.all;
use work.cpu_types_pkg.all;

architecture rtl of cpu_l1mem_data_cache_dp is

  type reg_type is record
    b_request_size : cpu_data_size_type;
    b_request_poffset : cpu_poffset_type;
    b_request_vpn : cpu_vpn_type;
    b_request_data : cpu_word_type;

    b_bus_op_size : cpu_data_size_type;
    b_bus_op_paddr : cpu_paddr_type;

    b_stb_array_size : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                           cpu_data_size_bits-1 downto 0);
    b_stb_array_paddr : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                           cpu_paddr_bits-1 downto 0);
    b_stb_array_data : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                          cpu_word_bits-1 downto 0);

  end record;

  type comb_type is record
    b_replace_rstate : cpu_l1mem_data_cache_replace_state_type;
    b_replace_tag : std_ulogic_vector(cpu_l1mem_data_cache_tag_bits-1 downto 0);
    b_tram_rdata : std_ulogic_vector2(cpu_l1mem_data_cache_assoc-1 downto 0,
                                      cpu_l1mem_data_cache_tag_bits-1 downto 0);
    b_dram_rdata : std_ulogic_vector2((cpu_l1mem_data_cache_assoc*cpu_word_bytes)-1 downto 0,
                                      byte_bits-1 downto 0);
    b_bus_op_tag : std_ulogic_vector(cpu_l1mem_data_cache_tag_bits-1 downto 0);
    b_bus_op_index : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    b_bus_op_offset : std_ulogic_vector(cpu_l1mem_data_cache_offset_bits-1 downto 0);

    b_request_ppn : cpu_ppn_type;
    b_request_paddr : cpu_paddr_type;
    b_request_tag   : std_ulogic_vector(cpu_l1mem_data_cache_tag_bits-1 downto 0);
    b_request_index   : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    b_request_block_word_offset : std_ulogic_vector(cpu_l1mem_data_cache_offset_bits-cpu_log2_word_bytes-1 downto 0);
    b_request_word_byte_offset : std_ulogic_vector(cpu_log2_word_bytes-1 downto 0);
    b_request_size_mask : std_ulogic_vector(cpu_log2_word_bytes-1 downto 0);
    b_request_cache_tag_match : std_ulogic_vector(cpu_l1mem_data_cache_assoc-1 downto 0);

    b_cache_way_read_data_le : std_ulogic_vector2(cpu_l1mem_data_cache_assoc-1 downto 0,
                                                  cpu_word_bits-1 downto 0);
    b_cache_read_data_le : std_ulogic_vector(cpu_word_bits-1 downto 0);
    b_cache_read_data_be : std_ulogic_vector(cpu_word_bits-1 downto 0);
    b_cache_read_data : std_ulogic_vector(cpu_word_bits-1 downto 0);
    
    b_result_data_bus : std_ulogic_vector(cpu_word_bits-1 downto 0);
    b_result_data_cache_or_bus_unshifted : std_ulogic_vector(cpu_word_bits-1 downto 0);
    b_result_data_cache_or_bus_shifter : std_ulogic_vector2(cpu_log2_word_bytes downto 0,
                                                            cpu_word_bits-1 downto 0);
    b_result_data_cache_or_bus_shifted : std_ulogic_vector(cpu_word_bits-1 downto 0);
    b_result_data_stb : std_ulogic_vector(cpu_word_bits-1 downto 0);
    
    b_stb_update_data_ptr : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_tag : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                         cpu_l1mem_data_cache_tag_bits-1 downto 0);
    b_stb_array_index : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                           cpu_l1mem_data_cache_index_bits-1 downto 0);
    b_stb_array_block_word_offset : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                                       cpu_l1mem_data_cache_offset_bits-cpu_log2_word_bytes-1 downto 0);
    b_stb_array_word_byte_offset : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                                      cpu_log2_word_bytes-1 downto 0);
    b_stb_array_size_mask : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                               cpu_log2_word_bytes-1 downto 0);

    b_stb_array_size_next : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                               cpu_data_size_bits-1 downto 0);
    b_stb_array_paddr_next : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                                cpu_paddr_bits-1 downto 0);
    b_stb_array_data_next : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                               cpu_word_bits-1 downto 0);
    b_stb_head_paddr : cpu_paddr_type;
    b_stb_head_index : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    
    b_request_stb_array_tag_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_stb_array_index_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_stb_array_block_word_offset_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_stb_array_word_byte_offset_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_request_stb_array_size_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    
    b_block_change_index : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    b_block_change_tag   : std_ulogic_vector(cpu_l1mem_data_cache_tag_bits-1 downto 0);

    b_stb_array_block_change_index_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);
    b_stb_array_block_change_tag_match : std_ulogic_vector(cpu_l1mem_data_cache_stb_entries-1 downto 0);

    b_result_paddr : cpu_paddr_type;
    b_result_data : cpu_word_type;

    b_replace_windex : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    b_replace_wstate : cpu_l1mem_data_cache_replace_state_type;
    b_vram_waddr : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    b_mram_waddr : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);

    a_new_request_size : cpu_data_size_type;
    a_new_request_poffset : cpu_poffset_type;
    a_new_request_vpn : cpu_vpn_type;
    a_new_request_data : cpu_word_type;
    
    a_request_poffset : cpu_poffset_type;
    a_request_vpn : cpu_vpn_type;
    a_request_ppn : cpu_ppn_type;
    a_request_data : cpu_word_type;
    a_request_bus_op_data : cpu_word_type;
    a_request_size : cpu_data_size_type;
    a_request_size_dec : std_ulogic_vector(cpu_log2_word_bytes downto 0);
    a_request_word_byte_mask_by_size : std_ulogic_vector2(cpu_log2_word_bytes downto 0,
                                                          cpu_word_bytes-1 downto 0);
    a_request_word_byte_mask : std_ulogic_vector(cpu_word_bytes-1 downto 0);
    a_request_dram_banken : std_ulogic_vector(cpu_l1mem_data_cache_assoc*cpu_word_bytes-1 downto 0);
    
    a_request_vaddr : cpu_vaddr_type;
    a_request_paddr : cpu_paddr_type;
    a_request_tag : std_ulogic_vector(cpu_l1mem_data_cache_tag_bits-1 downto 0);
    a_request_index : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    a_request_offset : std_ulogic_vector(cpu_l1mem_data_cache_offset_bits-1 downto 0);

    a_stb_array_paddr : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                           cpu_paddr_bits-1 downto 0);
    a_stb_array_data : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                          cpu_word_bits-1 downto 0);
    a_stb_array_size : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                          cpu_data_size_bits-1 downto 0);
    a_stb_array_size_mask : std_ulogic_vector2(cpu_l1mem_data_cache_stb_entries-1 downto 0,
                                               cpu_log2_word_bytes-1 downto 0);

    a_stb_head_size : cpu_data_size_type;
    a_stb_head_paddr : cpu_paddr_type;
    a_stb_head_tag : std_ulogic_vector(cpu_l1mem_data_cache_tag_bits-1 downto 0);
    a_stb_head_index : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    a_stb_head_offset : std_ulogic_vector(cpu_l1mem_data_cache_offset_bits-1 downto 0);
    a_stb_head_data : cpu_word_type;
    a_stb_head_size_dec : std_ulogic_vector(cpu_log2_word_bytes downto 0);
    a_stb_word_byte_mask_by_size : std_ulogic_vector2(cpu_log2_word_bytes downto 0,
                                                      cpu_word_bytes-1 downto 0);
    a_stb_word_byte_mask : std_ulogic_vector(cpu_word_bytes-1 downto 0);
    a_stb_dram_banken : std_ulogic_vector((cpu_l1mem_data_cache_assoc*cpu_word_bytes)-1 downto 0);
    a_stb_dram_wdata_sel : std_ulogic_vector(cpu_log2_word_bytes-1 downto 0);
    a_stb_dram_wdata_word : std_ulogic_vector(cpu_word_bits-1 downto 0);

    a_bus_op_paddr_block_word_offset_next : std_ulogic_vector(cpu_l1mem_data_cache_offset_bits-cpu_log2_word_bytes-1 downto 0);
    a_bus_op_paddr : cpu_paddr_type;
    a_bus_op_size : cpu_data_size_type;
    a_bus_op_data : cpu_word_type;
    a_bus_op_index : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    a_bus_op_offset : std_ulogic_vector(cpu_l1mem_data_cache_offset_bits-1 downto 0);
    a_bus_op_cache_wtag : std_ulogic_vector(cpu_l1mem_data_cache_tag_bits-1 downto 0);
    a_bus_op_cache_index : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    a_bus_op_cache_offset : std_ulogic_vector(cpu_l1mem_data_cache_offset_bits-1 downto 0);
    a_bus_op_tram_wdata_tag : std_ulogic_vector(cpu_l1mem_data_cache_tag_bits-1 downto 0);
    a_bus_op_sys_paddr : cpu_paddr_type;
    a_bus_op_sys_data : cpu_word_type;
    a_bus_op_dram_banken : std_ulogic_vector((cpu_l1mem_data_cache_assoc*cpu_word_bytes)-1 downto 0);
    a_bus_op_dram_wdata_word : std_ulogic_vector(cpu_word_bits-1 downto 0);

    a_sys_size : sys_transfer_size_type;
    a_sys_paddr : sys_paddr_type;
    a_sys_data : sys_bus_type;

    a_vtram_index : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    a_rmdram_index : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    a_rmdram_offset : std_ulogic_vector(cpu_l1mem_data_cache_offset_bits-1 downto 0);

    a_vram_raddr : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    a_mram_raddr : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    
    a_tram_addr : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    a_tram_wtag : std_ulogic_vector(cpu_l1mem_data_cache_tag_bits-1 downto 0);
    a_tram_wdata : std_ulogic_vector2(cpu_l1mem_data_cache_assoc-1 downto 0,
                                      cpu_l1mem_data_cache_tag_bits-1 downto 0);
    a_dram_banken : std_ulogic_vector(cpu_l1mem_data_cache_assoc*cpu_word_bytes-1 downto 0);
    a_dram_addr : std_ulogic_vector(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-cpu_log2_word_bytes-1 downto 0);
    a_dram_wdata_word : std_ulogic_vector(cpu_word_bits-1 downto 0);
    a_dram_wdata_bytes_le : std_ulogic_vector2(cpu_word_bytes-1 downto 0, byte_bits-1 downto 0);
    a_dram_wdata_bytes_be : std_ulogic_vector2(cpu_word_bytes-1 downto 0, byte_bits-1 downto 0);
    a_dram_wdata_bytes : std_ulogic_vector2(cpu_word_bytes-1 downto 0, byte_bits-1 downto 0);
    a_dram_wdata : std_ulogic_vector2(cpu_l1mem_data_cache_assoc*cpu_word_bytes-1 downto 0,
                                      byte_bits-1 downto 0);
    a_replace_rindex : std_ulogic_vector(cpu_l1mem_data_cache_index_bits-1 downto 0);
    
  end record;

  signal c : comb_type;
  signal r, r_next : reg_type;

begin

  c.b_replace_rstate <= cpu_l1mem_data_cache_replace_dp_out.rstate;
  c.b_tram_rdata <= cpu_l1mem_data_cache_dp_in_tram.rdata;
  c.b_dram_rdata <= cpu_l1mem_data_cache_dp_in_dram.rdata;

  b_replace_tag_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_l1mem_data_cache_tag_bits,
      sel_bits => cpu_l1mem_data_cache_assoc
      )
    port map (
      din => c.b_tram_rdata,
      sel => cpu_l1mem_data_cache_dp_in_ctrl.b_replace_way,
      dout => c.b_replace_tag
      );
  
  ----------------------------------

  c.b_request_ppn               <= cpu_mmu_data_dp_out.ppn;
  c.b_request_paddr             <= cpu_mmu_data_dp_out.ppn & r.b_request_poffset;
  c.b_request_tag               <= c.b_request_paddr(cpu_paddr_bits-1 downto
                                                     cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits);
  c.b_request_index             <= c.b_request_paddr(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-1
                                                     downto cpu_l1mem_data_cache_offset_bits);
  c.b_request_block_word_offset <= c.b_request_paddr(cpu_l1mem_data_cache_offset_bits-1 downto cpu_log2_word_bytes);
  c.b_request_word_byte_offset  <= c.b_request_paddr(cpu_log2_word_bytes-1 downto 0);

  c.b_request_size_mask(0) <= all_zeros(r.b_request_size);
  b_request_size_mask_gen : for n in 1 to cpu_log2_word_bytes-1 generate
    c.b_request_size_mask(n) <= (c.b_request_size_mask(n-1) or
                                 logic_eq(r.b_request_size,
                                          std_ulogic_vector(to_unsigned(n, cpu_data_size_bits))));
  end generate;

  b_request_tag_match_gen : for n in cpu_l1mem_data_cache_assoc-1 downto 0 generate
    c.b_request_cache_tag_match(n) <=
      logic_eq(c.b_request_tag,
               std_ulogic_vector2_slice2(c.b_tram_rdata, n));
  end generate;

  ----------------------------------

  b_cache_read_data_way_words_gen : for n in cpu_l1mem_data_cache_assoc-1 downto 0 generate
    byte_loop : for m in cpu_word_bytes-1 downto 0 generate
      bit_loop : for b in byte_bits-1 downto 0 generate
        c.b_cache_way_read_data_le(n, m*byte_bits+b) <= c.b_dram_rdata(n*cpu_word_bytes+m, b);
      end generate;
    end generate;
  end generate;

  b_cache_read_data_word_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_word_bits,
      sel_bits => cpu_l1mem_data_cache_assoc
      )
    port map (
      din  => c.b_cache_way_read_data_le,
      sel  => cpu_l1mem_data_cache_dp_in_ctrl.b_cache_read_data_way,
      dout => c.b_cache_read_data_le
      );

  b_cache_read_data_gen : for m in cpu_word_bytes-1 downto 0 generate
    bit_loop : for b in byte_bits-1 downto 0 generate
      c.b_cache_read_data_be((cpu_word_bytes-m-1)*byte_bits+b) <= c.b_cache_read_data_le(m*byte_bits+b);
    end generate;
  end generate;
  
  with cpu_l1mem_data_cache_dp_in_ctrl.b_cache_read_data_be select
    c.b_cache_read_data <= c.b_cache_read_data_le when '0',
                           c.b_cache_read_data_be when '1',
                           (others => 'X')        when others;
  
  ----------------------------------

  c.b_bus_op_tag <= r.b_bus_op_paddr(cpu_paddr_bits-1 downto
                                     cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits);
  c.b_bus_op_index <= r.b_bus_op_paddr(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-1 downto
                                       cpu_l1mem_data_cache_offset_bits);
  c.b_bus_op_offset <= r.b_bus_op_paddr(cpu_l1mem_data_cache_offset_bits-1 downto 0);

  ----------------------------------

  c.b_result_data_bus <= sys_slave_dp_out.data(cpu_word_bits-1 downto 0);
  with cpu_l1mem_data_cache_dp_in_ctrl.b_result_data_sel select
    c.b_result_data_cache_or_bus_unshifted <= c.b_cache_read_data  when cpu_l1mem_data_cache_b_result_data_sel_cache,
                                              c.b_result_data_bus  when cpu_l1mem_data_cache_b_result_data_sel_bus_shifted,
                                              (others => 'X')      when others;

  b_result_data_cache_or_bus_tmp_0_gen : for n in cpu_word_bits-1 downto 0 generate
    c.b_result_data_cache_or_bus_shifter(cpu_log2_word_bytes, n) <= c.b_result_data_cache_or_bus_unshifted(n);
  end generate;
  
  b_result_data_cache_or_bus_shifter_gen : for n in cpu_log2_word_bytes-1 downto 0 generate
    blk : block
      signal sel : std_ulogic;
      signal word : cpu_word_type;
      signal part : std_ulogic_vector((2**n)*byte_bits-1 downto 0);
    begin
      -- align the result from the cache according to the least significant bits of the address
      sel <= ((r.b_request_poffset(n) xor cpu_l1mem_data_cache_dp_in_ctrl.b_request_be) and c.b_request_size_mask(n));
      word_loop : for b in cpu_word_bits-1 downto 0 generate
        word(b) <= c.b_result_data_cache_or_bus_shifter(n+1, b);
      end generate;
      with sel select
        part <= word(2*(2**n)*byte_bits-1 downto (2**n)*byte_bits) when '1',
                word((2**n)*byte_bits-1 downto 0)                  when '0',
                (others => 'X')                                    when others;
      out_hi_loop : for b in cpu_word_bits-1 downto (2**n)*byte_bits generate
        c.b_result_data_cache_or_bus_shifter(n, b) <= word(b);
      end generate;
      out_lo_loop : for b in (2**n)*byte_bits-1 downto 0 generate
        c.b_result_data_cache_or_bus_shifter(n, b) <= part(b);
      end generate;
    end block;
  end generate;
  b_result_data_cache_or_bus_gen : for n in cpu_word_bits-1 downto 0 generate
    c.b_result_data_cache_or_bus_shifted(n) <= c.b_result_data_cache_or_bus_shifter(0, n);
  end generate;

  b_result_data_stb_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_word_bits,
      sel_bits  => cpu_l1mem_data_cache_stb_entries
      )
    port map (
      din => r.b_stb_array_data,
      sel => cpu_l1mem_data_cache_dp_in_ctrl.b_request_stb_array_hit,
      dout => c.b_result_data_stb
      );

  with cpu_l1mem_data_cache_dp_in_ctrl.b_result_data_sel select
    c.b_result_data <= c.b_result_data_cache_or_bus_shifted when cpu_l1mem_data_cache_b_result_data_sel_cache |
                                                                 cpu_l1mem_data_cache_b_result_data_sel_bus_shifted,
                       c.b_result_data_bus                  when cpu_l1mem_data_cache_b_result_data_sel_bus,
                       c.b_result_data_stb                  when cpu_l1mem_data_cache_b_result_data_sel_stb,
                       (others => 'X')                      when others;

  ----------------------------------

  c.b_block_change_index <= r.b_bus_op_paddr(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-1 downto
                                             cpu_l1mem_data_cache_offset_bits);
  c.b_block_change_tag   <= r.b_bus_op_paddr(cpu_paddr_bits-1 downto
                                             cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits);

  
  b_stb_array_gen : for n in cpu_l1mem_data_cache_stb_entries-1 downto 0 generate
    b_stb_array_word_byte_offset_gen : for m in cpu_log2_word_bytes-1 downto 0 generate
      c.b_stb_array_word_byte_offset(n, m) <= r.b_stb_array_paddr(n, m);
    end generate;
    b_stb_array_block_word_offset_gen : for m in cpu_l1mem_data_cache_offset_bits-cpu_log2_word_bytes-1 downto 0 generate
      c.b_stb_array_block_word_offset(n, m) <= r.b_stb_array_paddr(n, m + cpu_log2_word_bytes);
    end generate;
    b_stb_array_index_gen : for m in cpu_l1mem_data_cache_index_bits-1 downto 0 generate
      c.b_stb_array_index(n, m) <= r.b_stb_array_paddr(n, m + cpu_l1mem_data_cache_offset_bits);
    end generate;
    b_stb_array_tag_gen : for m in cpu_l1mem_data_cache_tag_bits-1 downto 0 generate
      c.b_stb_array_tag(n, m) <= r.b_stb_array_paddr(n, m + cpu_l1mem_data_cache_offset_bits + cpu_l1mem_data_cache_index_bits);
    end generate;

    c.b_stb_array_size_mask(n, 0) <= all_zeros(std_ulogic_vector2_slice2(r.b_stb_array_size, n));
    b_request_size_mask_gen : for m in 1 to cpu_log2_word_bytes-1 generate
      c.b_stb_array_size_mask(n, m) <= (c.b_stb_array_size_mask(n, m-1) or
                                        logic_eq(r.b_request_size,
                                                 std_ulogic_vector(to_unsigned(n, cpu_data_size_bits))));
    end generate;
    c.b_request_stb_array_tag_match(n) <=
      logic_eq(c.b_request_tag,
               std_ulogic_vector2_slice2(c.b_stb_array_tag, n));
    c.b_request_stb_array_index_match(n) <=
      logic_eq(c.b_request_index,
               std_ulogic_vector2_slice2(c.b_stb_array_index, n));
    c.b_request_stb_array_block_word_offset_match(n) <=
      logic_eq(c.b_request_block_word_offset,
               std_ulogic_vector2_slice2(c.b_stb_array_block_word_offset, n));
    c.b_request_stb_array_word_byte_offset_match(n) <=
      logic_eq(c.b_request_word_byte_offset,
               std_ulogic_vector2_slice2(c.b_stb_array_word_byte_offset, n)
               );
    c.b_request_stb_array_size_match(n) <=
      logic_eq(r.b_request_size,
               std_ulogic_vector2_slice2(r.b_stb_array_size, n));

    c.b_stb_array_block_change_index_match(n) <=
      logic_eq(c.b_block_change_index,
               std_ulogic_vector2_slice2(c.b_stb_array_index, n));
    c.b_stb_array_block_change_tag_match(n) <=
      logic_eq(c.b_block_change_tag,
               std_ulogic_vector2_slice2(c.b_stb_array_tag, n));

  end generate;

  b_stb_head_paddr_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_paddr_bits,
      sel_bits => cpu_l1mem_data_cache_stb_entries
      )
    port map (
      din => r.b_stb_array_paddr,
      sel => cpu_l1mem_data_cache_dp_in_ctrl.b_stb_head_ptr,
      dout => c.b_stb_head_paddr
      );
  c.b_stb_head_index <= c.b_stb_head_paddr(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-1 downto
                                           cpu_l1mem_data_cache_offset_bits);
  
  c.b_stb_update_data_ptr <= (
    cpu_l1mem_data_cache_dp_in_ctrl.b_stb_push_ptr or
    cpu_l1mem_data_cache_dp_in_ctrl.b_stb_combine_ptr
    );
  
  b_stb_array_next_gen : for n in cpu_l1mem_data_cache_stb_entries-1 downto 0 generate
    blk : block
      signal size : cpu_data_size_type;
      signal data : cpu_word_type;
      signal paddr : cpu_paddr_type;
    begin
      
      with cpu_l1mem_data_cache_dp_in_ctrl.b_stb_push_ptr(n) select
        paddr <= std_ulogic_vector2_slice2(r.b_stb_array_paddr, n) when '0',
                 c.b_request_paddr                                 when '1',
                 (others => 'X')                                   when others;
      paddr_bit_loop : for m in cpu_paddr_bits-1 downto 0 generate
        c.b_stb_array_paddr_next(n, m) <= paddr(m);
      end generate;
      
      with cpu_l1mem_data_cache_dp_in_ctrl.b_stb_push_ptr(n) select
        size <= std_ulogic_vector2_slice2(r.b_stb_array_size, n) when '0',
                r.b_request_size                                 when '1',
                (others => 'X')                                  when others;
      size_bit_loop : for m in cpu_data_size_bits-1 downto 0 generate
        c.b_stb_array_size_next(n, m) <= size(m);
      end generate;
      
      with c.b_stb_update_data_ptr(n) select
        data <= std_ulogic_vector2_slice2(r.b_stb_array_data, n) when '0',
                r.b_request_data                                 when '1',
                (others => 'X')                                  when others;
      data_bit_loop : for m in cpu_word_bits-1 downto 0 generate
        c.b_stb_array_data_next(n, m) <= data(m);
      end generate;
      
    end block;
  end generate;

  --------------------------

  with cpu_l1mem_data_cache_dp_in_ctrl.b_rmdram_owner select
    c.b_replace_windex <= c.b_request_index  when cpu_l1mem_data_cache_owner_request,
                          c.b_stb_head_index when cpu_l1mem_data_cache_owner_stb,
                          c.b_bus_op_index   when cpu_l1mem_data_cache_owner_bus_op,
                          (others => 'X')    when others;
  c.b_replace_wstate <= c.b_replace_rstate;
  with cpu_l1mem_data_cache_dp_in_ctrl.b_vtram_owner select
    c.b_vram_waddr <= c.b_request_index  when cpu_l1mem_data_cache_owner_request,
                      c.b_bus_op_index   when cpu_l1mem_data_cache_owner_bus_op,
                      (others => 'X')    when others;
  with cpu_l1mem_data_cache_dp_in_ctrl.b_rmdram_owner select
    c.b_mram_waddr <= c.b_stb_head_index when cpu_l1mem_data_cache_owner_stb,
                      c.b_bus_op_index   when cpu_l1mem_data_cache_owner_bus_op,
                      (others => 'X')    when others;
  
  --------------------------

  c.a_stb_array_paddr <= c.b_stb_array_paddr_next;
  c.a_stb_array_size <= c.b_stb_array_size_next;
  c.a_stb_array_data <= c.b_stb_array_data_next;
  
  a_stb_head_paddr_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_paddr_bits,
      sel_bits => cpu_l1mem_data_cache_stb_entries
      )
    port map (
      din => c.a_stb_array_paddr,
      sel => cpu_l1mem_data_cache_dp_in_ctrl.a_stb_head_ptr,
      dout => c.a_stb_head_paddr
      );
  c.a_stb_head_tag    <= c.a_stb_head_paddr(cpu_paddr_bits-1 downto
                                            cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits);
  c.a_stb_head_index  <= c.a_stb_head_paddr(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-1 downto
                                            cpu_l1mem_data_cache_offset_bits);
  c.a_stb_head_offset <= c.a_stb_head_paddr(cpu_l1mem_data_cache_offset_bits-1 downto 0);

  a_stb_head_data_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_word_bits,
      sel_bits => cpu_l1mem_data_cache_stb_entries
      )
    port map (
      din => c.a_stb_array_data,
      sel => cpu_l1mem_data_cache_dp_in_ctrl.a_stb_head_ptr,
      dout => c.a_stb_head_data
      );

  a_stb_head_size_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_data_size_bits,
      sel_bits => cpu_l1mem_data_cache_stb_entries
      )
    port map (
      din => c.a_stb_array_size,
      sel => cpu_l1mem_data_cache_dp_in_ctrl.a_stb_head_ptr,
      dout => c.a_stb_head_size
      );

  a_stb_head_size_decoder : entity tech.decoder(rtl)
    generic map (
      output_bits => cpu_log2_word_bytes + 1
      )
    port map (
      datain  => c.a_stb_head_size,
      dataout => c.a_stb_head_size_dec
      );

  a_stb_word_byte_mask_gen : for m in cpu_word_bytes-1 downto 0 generate
    c.a_stb_word_byte_mask_by_size(cpu_log2_word_bytes, m) <= '1';
    size_loop : for n in cpu_log2_word_bytes-1 downto 0 generate
      c.a_stb_word_byte_mask_by_size(n, m) <= logic_eq(c.a_stb_head_offset(cpu_log2_word_bytes-1 downto n),
                                                       std_ulogic_vector(to_unsigned(m/(2**n), cpu_log2_word_bytes-n)));
    end generate;
  end generate;

  a_stb_word_byte_mask_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_word_bytes,
      sel_bits => cpu_log2_word_bytes + 1
      )
    port map (
      din => c.a_stb_word_byte_mask_by_size,
      sel => c.a_stb_head_size_dec,
      dout => c.a_stb_word_byte_mask
      );

  a_stb_dram_banken_gen : for n in cpu_l1mem_data_cache_assoc-1 downto 0 generate
    word_byte_loop : for m in cpu_word_bytes-1 downto 0 generate
      c.a_stb_dram_banken(n*cpu_word_bytes+m) <= (
        cpu_l1mem_data_cache_dp_in_ctrl.a_stb_way(n) and
        c.a_stb_word_byte_mask(m)
        );
    end generate;
  end generate;

  -- log2_word_bytes size wdata
  -- 0               0    0
  -- 1               0    00
  -- 1               1    10
  -- 2               0    0000
  -- 2               1    1010
  -- 2               2    3210
  -- 3               0    00000000
  -- 3               1    10101010
  -- 3               2    32103210
  -- 3               3    76543210

  c.a_stb_dram_wdata_sel(0) <= c.a_stb_head_size_dec(0);
  a_stb_dram_wdata_word_sel_gen : for n in 1 to cpu_log2_word_bytes-1 generate
    c.a_stb_dram_wdata_sel(n) <= c.a_stb_dram_wdata_sel(n-1) or c.a_stb_head_size_dec(n);
  end generate;
  c.a_stb_dram_wdata_word(byte_bits-1 downto 0) <= c.a_stb_head_data(byte_bits-1 downto 0);
  a_stb_dram_wdata_word_gen : for n in cpu_log2_word_bytes-1 downto 0 generate
    with c.a_stb_dram_wdata_sel(n) select
      c.a_stb_dram_wdata_word((2**(n+1))*byte_bits-1 downto (2**n)*byte_bits) <=
        c.a_stb_head_data((2**(n+1))*byte_bits-1 downto (2**n)*byte_bits) when '0',
        c.a_stb_dram_wdata_word((2**n)*byte_bits-1 downto 0)              when '1',
        (others => 'X')                                                   when others;
  end generate;

  --------------------------

  c.a_new_request_size    <= cpu_l1mem_data_cache_dp_in.size;
  c.a_new_request_poffset <= cpu_l1mem_data_cache_dp_in.vaddr(cpu_poffset_bits-1 downto 0);
  c.a_new_request_vpn     <= cpu_l1mem_data_cache_dp_in.vaddr(cpu_vaddr_bits-1 downto cpu_poffset_bits);
  c.a_new_request_data    <= cpu_l1mem_data_cache_dp_in.data;

  with cpu_l1mem_data_cache_dp_in_ctrl.b_request_complete select
    c.a_request_size <= c.a_new_request_size when '1',
                        r.b_request_size     when '0',
                        (others => 'X')      when others;
  with cpu_l1mem_data_cache_dp_in_ctrl.b_request_complete select
    c.a_request_poffset <= c.a_new_request_poffset when '1',
                        r.b_request_poffset        when '0',
                        (others => 'X')            when others;
  with cpu_l1mem_data_cache_dp_in_ctrl.b_request_complete select
    c.a_request_vpn <= c.a_new_request_vpn when '1',
                       r.b_request_vpn     when '0',
                       (others => 'X')     when others;
  
  c.a_request_ppn    <= c.b_request_ppn;
  c.a_request_paddr  <= c.a_request_ppn & c.a_request_poffset;
  c.a_request_tag    <= c.a_request_paddr(cpu_paddr_bits-1 downto
                                          cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits);
  c.a_request_index  <= c.a_request_paddr(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-1 downto
                                          cpu_l1mem_data_cache_offset_bits);
  c.a_request_offset <= c.a_request_paddr(cpu_l1mem_data_cache_offset_bits-1 downto 0);

  with cpu_l1mem_data_cache_dp_in_ctrl.b_request_complete select
    c.a_request_data <= c.a_new_request_data when '1',
                        r.b_request_data     when '0',
                        (others => 'X')      when others;
  c.a_request_bus_op_data <= r.b_request_data;

  a_request_size_decoder : entity tech.decoder(rtl)
    generic map (
      output_bits => cpu_log2_word_bytes + 1
      )
    port map (
      datain  => c.a_request_size,
      dataout => c.a_request_size_dec
      );

  a_request_word_byte_mask_gen : for m in cpu_word_bytes-1 downto 0 generate
    c.a_request_word_byte_mask_by_size(cpu_log2_word_bytes, m) <= '1';
    size_loop : for n in cpu_log2_word_bytes-1 downto 0 generate
      c.a_request_word_byte_mask_by_size(n, m) <= logic_eq(c.a_request_poffset(cpu_log2_word_bytes-1 downto n),
                                                           std_ulogic_vector(to_unsigned(m/(2**n), cpu_log2_word_bytes-n)));
    end generate;
  end generate;

  a_request_word_byte_mask_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_word_bytes,
      sel_bits => cpu_log2_word_bytes + 1
      )
    port map (
      din => c.a_request_word_byte_mask_by_size,
      sel => c.a_request_size_dec,
      dout => c.a_request_word_byte_mask
      );

  a_request_dram_banken_gen : for n in cpu_l1mem_data_cache_assoc-1 downto 0 generate
    word_byte_loop : for m in cpu_word_bytes-1 downto 0 generate
      c.a_request_dram_banken(n*cpu_word_bytes+m) <= c.a_request_word_byte_mask(m);
    end generate;
  end generate;

  --------------------------------

  with cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_size_sel select
    c.a_bus_op_size <= r.b_bus_op_size                                                         when cpu_l1mem_data_cache_a_bus_op_size_sel_old,
                       c.a_request_size                                                        when cpu_l1mem_data_cache_a_bus_op_size_sel_request,
                       c.a_stb_head_size                                                       when cpu_l1mem_data_cache_a_bus_op_size_sel_stb,
                       std_ulogic_vector(to_unsigned(cpu_log2_word_bytes, cpu_data_size_bits)) when cpu_l1mem_data_cache_a_bus_op_size_sel_word,
                       (others => 'X')                                                         when others;
  
  with cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_owner select
    c.a_bus_op_data <= c.a_request_bus_op_data when cpu_l1mem_data_cache_owner_request,
                       c.a_stb_head_data       when cpu_l1mem_data_cache_owner_stb,
                       (others => 'X')         when others;

  a_bus_op_dram_banken_gen : for n in cpu_l1mem_data_cache_assoc-1 downto 0 generate
    word_byte_loop : for m in cpu_word_bytes-1 downto 0 generate
      c.a_bus_op_dram_banken(n*cpu_word_bytes+m) <= cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_way(n);
    end generate;
  end generate;
  c.a_bus_op_dram_wdata_word <= sys_slave_dp_out.data;

  a_bus_op_paddr_block_word_offset_next_gen : if cpu_l1mem_data_cache_offset_bits > cpu_log2_word_bytes generate
    c.a_bus_op_paddr_block_word_offset_next <=
      std_ulogic_vector(unsigned(r.b_bus_op_paddr(cpu_l1mem_data_cache_offset_bits-1 downto cpu_log2_word_bytes)) +
                        to_unsigned(1, cpu_l1mem_data_cache_offset_bits-cpu_log2_word_bytes));
  end generate;

  with cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_paddr_tag_sel select
    c.a_bus_op_paddr(cpu_paddr_bits-1 downto cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits) <=
      c.a_request_tag  when cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_request,
      c.a_stb_head_tag when cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_stb,
      c.b_bus_op_tag   when cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_old,
      c.b_replace_tag  when cpu_l1mem_data_cache_a_bus_op_paddr_tag_sel_replace,
      (others => 'X')  when others;
  
  with cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_paddr_index_sel select
    c.a_bus_op_paddr(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-1 downto cpu_l1mem_data_cache_offset_bits) <=
      c.a_request_index  when cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_request,
      c.a_stb_head_index when cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_stb,
      c.b_bus_op_index   when cpu_l1mem_data_cache_a_bus_op_paddr_index_sel_old,
      (others => 'X')    when others;
  
  a_bus_op_paddr_block_word_offset_gen : if cpu_l1mem_data_cache_offset_bits > cpu_log2_word_bytes generate
    with cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_paddr_offset_sel select
      c.a_bus_op_paddr(cpu_l1mem_data_cache_offset_bits-1 downto cpu_log2_word_bytes) <=
        c.b_bus_op_offset(cpu_l1mem_data_cache_offset_bits-1 downto cpu_log2_word_bytes)
                                                when cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_old,
        c.a_bus_op_paddr_block_word_offset_next when cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_next_word,
        c.a_request_offset(cpu_l1mem_data_cache_offset_bits-1 downto cpu_log2_word_bytes)
                                                when cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_request |
                                                     cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_request_word,
        c.a_stb_head_offset(cpu_l1mem_data_cache_offset_bits-1 downto cpu_log2_word_bytes)
                                                when cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_stb |
                                                     cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_stb_word,
        (others => 'X')                         when others;
  end generate;
  with cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_paddr_offset_sel select
    c.a_bus_op_paddr(cpu_log2_word_bytes-1 downto 0) <=
      r.b_bus_op_paddr(cpu_log2_word_bytes-1 downto 0)   when cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_old,
      c.a_request_paddr(cpu_log2_word_bytes-1 downto 0)  when cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_request,
      c.a_stb_head_paddr(cpu_log2_word_bytes-1 downto 0) when cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_stb,
      (cpu_log2_word_bytes-1 downto 0 => '0')            when cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_next_word |
                                                              cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_request_word |
                                                              cpu_l1mem_data_cache_a_bus_op_paddr_offset_sel_stb_word,
      (others => 'X')                                    when others;
  
  c.a_bus_op_index <= c.a_bus_op_paddr(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-1 downto
                                       cpu_l1mem_data_cache_offset_bits);
  c.a_bus_op_offset <= c.a_bus_op_paddr(cpu_l1mem_data_cache_offset_bits-1 downto 0);
  
  c.a_bus_op_cache_wtag <= r.b_bus_op_paddr(cpu_paddr_bits-1 downto
                                            cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits);

  with cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_cache_paddr_sel_old select
    c.a_bus_op_cache_index <=
      c.a_bus_op_index when '0',
      c.b_bus_op_index when '1',
      (others => 'X')  when others;
  with cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_cache_paddr_sel_old select
    c.a_bus_op_cache_offset <=
      c.a_bus_op_offset when '0',
      c.b_bus_op_offset when '1',
      (others => 'X')  when others;

  with cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_sys_paddr_sel_old select
    c.a_bus_op_sys_paddr <=
      c.a_bus_op_paddr when '0',
      r.b_bus_op_paddr when '1',
      (others => 'X')  when others;

  with cpu_l1mem_data_cache_dp_in_ctrl.a_bus_op_sys_data_sel_cache select
    c.a_bus_op_sys_data <=
      c.a_bus_op_data     when '0',
      c.b_cache_read_data when '1',
      (others => 'X')     when others;

  --------------------------------

  with cpu_l1mem_data_cache_dp_in_ctrl.a_vtram_owner select
    c.a_vtram_index <= c.a_request_index      when cpu_l1mem_data_cache_owner_request,
                       c.a_stb_head_index     when cpu_l1mem_data_cache_owner_stb,
                       c.a_bus_op_cache_index when cpu_l1mem_data_cache_owner_bus_op,
                       (others => 'X')        when others;

  c.a_vram_raddr  <= c.a_vtram_index;
  
  c.a_tram_addr <= c.a_vtram_index;
  c.a_tram_wtag <= c.a_bus_op_cache_wtag;
  a_tram_wdata_gen : for n in cpu_l1mem_data_cache_assoc-1 downto 0 generate
    bit_gen : for b in cpu_l1mem_data_cache_tag_bits-1 downto 0 generate
      c.a_tram_wdata(n, b) <= c.a_tram_wtag(b);
    end generate;
  end generate;
  
  with cpu_l1mem_data_cache_dp_in_ctrl.a_rmdram_owner select
    c.a_rmdram_index <= c.a_request_paddr(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-1
                                          downto cpu_l1mem_data_cache_offset_bits)
                          when cpu_l1mem_data_cache_owner_request,
                        c.a_stb_head_paddr(cpu_l1mem_data_cache_index_bits+cpu_l1mem_data_cache_offset_bits-1
                                           downto cpu_l1mem_data_cache_offset_bits)
                          when cpu_l1mem_data_cache_owner_stb,
                        c.a_bus_op_cache_index
                          when cpu_l1mem_data_cache_owner_bus_op,
                        (others => 'X')   when others;
  with cpu_l1mem_data_cache_dp_in_ctrl.a_rmdram_owner select
    c.a_rmdram_offset <= c.a_request_paddr(cpu_l1mem_data_cache_offset_bits-1 downto 0)
                           when cpu_l1mem_data_cache_owner_request,
                         c.a_stb_head_paddr(cpu_l1mem_data_cache_offset_bits-1 downto 0)
                           when cpu_l1mem_data_cache_owner_stb,
                         c.a_bus_op_cache_offset
                           when cpu_l1mem_data_cache_owner_bus_op,
                         (others => 'X')   when others;
  
  c.a_mram_raddr <= c.a_rmdram_index;

  c.a_replace_rindex <= c.a_rmdram_index;

  c.a_dram_addr <= c.a_rmdram_index & c.a_rmdram_offset(cpu_l1mem_data_cache_offset_bits-1 downto cpu_log2_word_bytes);
  with cpu_l1mem_data_cache_dp_in_ctrl.a_rmdram_owner select
    c.a_dram_banken <= c.a_request_dram_banken  when cpu_l1mem_data_cache_owner_request,
                       c.a_stb_dram_banken      when cpu_l1mem_data_cache_owner_stb,
                       c.a_bus_op_dram_banken   when cpu_l1mem_data_cache_owner_bus_op,
                       (others => 'X')          when others;

  with cpu_l1mem_data_cache_dp_in_ctrl.a_rmdram_owner select
    c.a_dram_wdata_word <= c.a_stb_dram_wdata_word     when cpu_l1mem_data_cache_owner_stb,
                           c.a_bus_op_dram_wdata_word  when cpu_l1mem_data_cache_owner_bus_op,
                           (others => 'X')             when others;
  a_dram_wdata_bytes_gen : for n in cpu_word_bytes-1 downto 0 generate
    bit_loop : for b in byte_bits-1 downto 0 generate
      c.a_dram_wdata_bytes_le(n,                  b) <= c.a_dram_wdata_word(n*byte_bits+b);
      c.a_dram_wdata_bytes_be(cpu_word_bytes-n-1, b) <= c.a_dram_wdata_word(n*byte_bits+b);
    end generate;
  end generate;
  with cpu_l1mem_data_cache_dp_in_ctrl.a_dram_wdata_be select
    c.a_dram_wdata_bytes <= c.a_dram_wdata_bytes_le     when '0',
                            c.a_dram_wdata_bytes_be     when '1',
                            (others => (others => 'X')) when others;
  a_dram_wdata_gen : for n in cpu_l1mem_data_cache_assoc-1 downto 0 generate
    byte_loop : for m in cpu_word_bytes-1 downto 0 generate
      bit_loop : for b in byte_bits-1 downto 0 generate
        c.a_dram_wdata(n*cpu_word_bytes+m, b) <= c.a_dram_wdata_bytes(m, b);
      end generate;
    end generate;
  end generate;
  
  c.a_sys_size  <= (sys_transfer_size_bits-1 downto cpu_data_size_bits => '0') & c.a_bus_op_size;
  c.a_sys_paddr <= (sys_paddr_bits-1 downto cpu_paddr_bits => '0') & c.a_bus_op_sys_paddr;
  c.a_sys_data  <= c.a_bus_op_sys_data;

  c.b_result_paddr <= r.b_bus_op_paddr;
  
  r_next <= (
    b_request_size => c.a_request_size,
    b_request_poffset => c.a_request_poffset,
    b_request_vpn => c.a_request_vpn,
    b_request_data => c.a_request_data,

    b_bus_op_size => c.a_bus_op_size,
    b_bus_op_paddr => c.a_bus_op_paddr,

    b_stb_array_paddr => c.a_stb_array_paddr,
    b_stb_array_data => c.a_stb_array_data,
    b_stb_array_size => c.a_stb_array_size
    );

  cpu_l1mem_data_cache_dp_out_ctrl <= (
    b_request_cache_tag_match => c.b_request_cache_tag_match,
    b_request_stb_array_tag_match => c.b_request_stb_array_tag_match,
    b_request_stb_array_index_match => c.b_request_stb_array_index_match,
    b_request_stb_array_block_word_offset_match => c.b_request_stb_array_block_word_offset_match,
    b_request_stb_array_word_byte_offset_match => c.b_request_stb_array_word_byte_offset_match,
    b_request_stb_array_size_match => c.b_request_stb_array_size_match,
    b_stb_array_block_change_index_match => c.b_stb_array_block_change_index_match,
    b_stb_array_block_change_tag_match => c.b_stb_array_block_change_tag_match
    );

  cpu_l1mem_data_cache_dp_out_vram <= (
    raddr   => c.a_vram_raddr,
    waddr   => c.b_vram_waddr
    );

  cpu_l1mem_data_cache_dp_out_mram <= (
    raddr   => c.a_mram_raddr,
    waddr   => c.b_mram_waddr
    );

  cpu_l1mem_data_cache_dp_out_tram <= (
    addr  => c.a_tram_addr,
    wdata  => c.a_tram_wdata
    );

  cpu_l1mem_data_cache_dp_out_dram <= (
    banken => c.a_dram_banken,
    addr  => c.a_dram_addr,
    wdata  => c.a_dram_wdata
    );

  cpu_l1mem_data_cache_replace_dp_in <= (
    rindex => c.a_replace_rindex,
    windex => c.b_replace_windex,
    wstate => c.b_replace_wstate
    );

  cpu_l1mem_data_cache_dp_out <= (
    paddr => c.b_result_paddr,
    data => c.b_result_data
    );

  cpu_mmu_data_dp_in <= (
    vpn => c.a_request_vpn
    );

  sys_master_dp_out <= (
    size => c.a_sys_size,
    paddr => c.a_sys_paddr,
    data => c.a_sys_data
    );

  process (clk) is
  begin
    if rising_edge(clk) then
      r <= r_next;
    end if;
  end process;
  
end;
