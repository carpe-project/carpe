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

library tech;

library sys;
use sys.sys_config_pkg.all;
use sys.sys_pkg.all;

use work.cpu_l1mem_inst_cache_pkg.all;
use work.cpu_l1mem_inst_cache_config_pkg.all;
use work.cpu_types_pkg.all;

architecture rtl of cpu_l1mem_inst_cache_dp is

  type reg_type is record
    b_request_vpn : cpu_vpn_type;
    b_request_poffset : cpu_ipoffset_type;

    b_bus_op_paddr : cpu_ipaddr_type;
  end record;

  type comb_type is record

    b_replace_rstate : cpu_l1mem_inst_cache_replace_state_type;
    b_tram_rdata : std_ulogic_vector2(cpu_l1mem_inst_cache_assoc-1 downto 0,
                                      cpu_l1mem_inst_cache_tag_bits-1 downto 0);
    b_dram_rdata : std_ulogic_vector2(cpu_l1mem_inst_cache_assoc-1 downto 0,
                                      cpu_inst_bits-1 downto 0);
    b_bus_op_tag : std_ulogic_vector(cpu_l1mem_inst_cache_tag_bits-1 downto 0);
    b_bus_op_index : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    b_bus_op_offset : std_ulogic_vector(cpu_l1mem_inst_cache_offset_bits-1 downto 0);

    b_request_ppn : cpu_ppn_type;
    b_request_paddr : cpu_ipaddr_type;
    b_request_tag   : std_ulogic_vector(cpu_l1mem_inst_cache_tag_bits-1 downto 0);
    b_request_index   : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    b_request_offset   : std_ulogic_vector(cpu_l1mem_inst_cache_offset_bits-1 downto 0);
    b_request_cache_tag_match : std_ulogic_vector(cpu_l1mem_inst_cache_assoc-1 downto 0);
    b_request_last_in_block : std_ulogic;

    b_cache_way_read_data : std_ulogic_vector2(cpu_l1mem_inst_cache_assoc-1 downto 0,
                                               cpu_inst_bits-1 downto 0);
    b_cache_read_data : std_ulogic_vector(cpu_inst_bits-1 downto 0);
    
    b_result_inst_bus : std_ulogic_vector(cpu_inst_bits-1 downto 0);
    b_result_inst_cache : std_ulogic_vector(cpu_inst_bits-1 downto 0);
    
    b_result_paddr : cpu_ipaddr_type;
    b_result_inst : cpu_inst_type;

    b_replace_windex : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    b_replace_wstate : cpu_l1mem_inst_cache_replace_state_type;
    b_vram_waddr : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    b_mram_waddr : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);

    a_new_request_poffset : cpu_ipoffset_type;
    a_new_request_vpn : cpu_vpn_type;
    
    a_request_poffset : cpu_ipoffset_type;
    a_request_vpn : cpu_vpn_type;
    a_request_ppn : cpu_ppn_type;
    a_request_bus_op_data : cpu_inst_type;
    
    a_request_vaddr : cpu_vaddr_type;
    a_request_paddr : cpu_ipaddr_type;
    a_request_tag : std_ulogic_vector(cpu_l1mem_inst_cache_tag_bits-1 downto 0);
    a_request_index : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    a_request_offset : std_ulogic_vector(cpu_l1mem_inst_cache_offset_bits-1 downto 0);

    a_bus_op_paddr_block_inst_offset_next : std_ulogic_vector(cpu_l1mem_inst_cache_offset_bits-1 downto 0);
    a_bus_op_paddr : cpu_ipaddr_type;
    a_bus_op_size : cpu_data_size_type;
    a_bus_op_data : cpu_inst_type;
    a_bus_op_index : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    a_bus_op_offset : std_ulogic_vector(cpu_l1mem_inst_cache_offset_bits-1 downto 0);
    a_bus_op_cache_wtag : std_ulogic_vector(cpu_l1mem_inst_cache_tag_bits-1 downto 0);
    a_bus_op_cache_index : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    a_bus_op_cache_offset : std_ulogic_vector(cpu_l1mem_inst_cache_offset_bits-1 downto 0);
    a_bus_op_tram_wdata_tag : std_ulogic_vector(cpu_l1mem_inst_cache_tag_bits-1 downto 0);
    a_bus_op_sys_paddr : cpu_ipaddr_type;
    a_bus_op_sys_data : cpu_inst_type;
    a_bus_op_dram_wdata : std_ulogic_vector(cpu_inst_bits-1 downto 0);

    a_sys_size : sys_transfer_size_type;
    a_sys_paddr : sys_paddr_type;
    a_sys_data : sys_bus_type;

    a_cache_index : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    a_cache_offset : std_ulogic_vector(cpu_l1mem_inst_cache_offset_bits-1 downto 0);

    a_vram_raddr : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    
    a_tram_addr : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    a_tram_wtag : std_ulogic_vector(cpu_l1mem_inst_cache_tag_bits-1 downto 0);
    a_tram_wdata : std_ulogic_vector2(cpu_l1mem_inst_cache_assoc-1 downto 0,
                                      cpu_l1mem_inst_cache_tag_bits-1 downto 0);
    a_dram_addr : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits-1 downto 0);
    a_dram_wdata_inst : std_ulogic_vector(cpu_inst_bits-1 downto 0);
    a_dram_wdata : std_ulogic_vector2(cpu_l1mem_inst_cache_assoc-1 downto 0,
                                      cpu_inst_bits-1 downto 0);
    a_replace_rindex : std_ulogic_vector(cpu_l1mem_inst_cache_index_bits-1 downto 0);
    
  end record;

  signal c : comb_type;
  signal r, r_next : reg_type;

begin

  c.b_replace_rstate <= cpu_l1mem_inst_cache_replace_dp_out.rstate;
  c.b_tram_rdata <= cpu_l1mem_inst_cache_dp_in_tram.rdata;
  c.b_dram_rdata <= cpu_l1mem_inst_cache_dp_in_dram.rdata;

  ----------------------------------

  c.b_request_ppn               <= cpu_mmu_inst_dp_out.ppn;
  c.b_request_paddr             <= c.b_request_ppn & r.b_request_poffset;
  c.b_request_tag               <= c.b_request_paddr(cpu_ipaddr_bits-1 downto
                                                     cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits);
  c.b_request_index             <= c.b_request_paddr(cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits-1
                                                     downto cpu_l1mem_inst_cache_offset_bits);
  c.b_request_offset            <= c.b_request_paddr(cpu_l1mem_inst_cache_offset_bits-1 downto 0);

  b_request_tag_match_gen : for n in cpu_l1mem_inst_cache_assoc-1 downto 0 generate
    c.b_request_cache_tag_match(n) <=
      logic_eq(c.b_request_tag,
               std_ulogic_vector2_slice2(c.b_tram_rdata, n));
  end generate;

  c.b_request_last_in_block <= all_ones(c.b_request_offset);
  
  ----------------------------------

  b_cache_read_data_way_gen : for n in cpu_l1mem_inst_cache_assoc-1 downto 0 generate
    bit_loop : for b in cpu_inst_bits-1 downto 0 generate
      c.b_cache_way_read_data(n, b) <= c.b_dram_rdata(n, b);
    end generate;
  end generate;

  b_cache_read_data_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_inst_bits,
      sel_bits => cpu_l1mem_inst_cache_assoc
      )
    port map (
      din  => c.b_cache_way_read_data,
      sel  => cpu_l1mem_inst_cache_dp_in_ctrl.b_cache_read_data_way,
      dout => c.b_cache_read_data
      );

  ----------------------------------

  c.b_bus_op_tag <= r.b_bus_op_paddr(cpu_ipaddr_bits-1 downto
                                     cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits);
  c.b_bus_op_index <= r.b_bus_op_paddr(cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits-1 downto
                                       cpu_l1mem_inst_cache_offset_bits);
  c.b_bus_op_offset <= r.b_bus_op_paddr(cpu_l1mem_inst_cache_offset_bits-1 downto 0);

  ----------------------------------

  c.b_result_inst_bus <= sys_slave_dp_out.data(cpu_inst_bits-1 downto 0);
  c.b_result_inst_cache <= c.b_cache_read_data;
  
  with cpu_l1mem_inst_cache_dp_in_ctrl.b_result_inst_sel select
    c.b_result_inst <= c.b_result_inst_cache when cpu_l1mem_inst_cache_b_result_inst_sel_b_cache,
                       c.b_result_inst_bus   when cpu_l1mem_inst_cache_b_result_inst_sel_b_bus,
                       (others => 'X')       when others;

  ----------------------------------

  with cpu_l1mem_inst_cache_dp_in_ctrl.b_cache_owner select
    c.b_replace_windex <= c.b_request_index  when cpu_l1mem_inst_cache_owner_request,
                          c.b_bus_op_index   when cpu_l1mem_inst_cache_owner_bus_op,
                          (others => 'X')    when others;
  c.b_replace_wstate <= c.b_replace_rstate;
  with cpu_l1mem_inst_cache_dp_in_ctrl.b_cache_owner select
    c.b_vram_waddr <= c.b_request_index  when cpu_l1mem_inst_cache_owner_request,
                      c.b_bus_op_index   when cpu_l1mem_inst_cache_owner_bus_op,
                      (others => 'X')    when others;
  
  --------------------------

  c.a_new_request_poffset <= cpu_l1mem_inst_cache_dp_in.vaddr(cpu_ipoffset_bits-1 downto 0);
  c.a_new_request_vpn     <= cpu_l1mem_inst_cache_dp_in.vaddr(cpu_ivaddr_bits-1 downto cpu_ipoffset_bits);

  with cpu_l1mem_inst_cache_dp_in_ctrl.b_request_complete select
    c.a_request_poffset <= c.a_new_request_poffset when '1',
                           r.b_request_poffset     when '0',
                           (others => 'X')         when others;
  with cpu_l1mem_inst_cache_dp_in_ctrl.b_request_complete select
    c.a_request_vpn <= c.a_new_request_vpn when '1',
                       r.b_request_vpn     when '0',
                       (others => 'X')     when others;
  
  c.a_request_ppn    <= c.b_request_ppn;
  c.a_request_paddr  <= c.a_request_ppn & c.a_request_poffset;
  c.a_request_tag    <= c.a_request_paddr(cpu_ipaddr_bits-1 downto
                                          cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits);
  c.a_request_index  <= c.a_request_paddr(cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits-1 downto
                                          cpu_l1mem_inst_cache_offset_bits);
  c.a_request_offset <= c.a_request_paddr(cpu_l1mem_inst_cache_offset_bits-1 downto 0);

  --------------------------------

  c.a_bus_op_dram_wdata <= sys_slave_dp_out.data;

  a_bus_op_paddr_block_inst_offset_next_gen : if cpu_l1mem_inst_cache_offset_bits > 0 generate
    c.a_bus_op_paddr_block_inst_offset_next <=
      std_ulogic_vector(unsigned(r.b_bus_op_paddr(cpu_l1mem_inst_cache_offset_bits-1 downto 0)) +
                        to_unsigned(1, cpu_l1mem_inst_cache_offset_bits));
  end generate;

  with cpu_l1mem_inst_cache_dp_in_ctrl.a_bus_op_paddr_tag_sel select
    c.a_bus_op_paddr(cpu_ipaddr_bits-1 downto cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits) <=
      c.a_request_tag  when cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_request,
      c.b_bus_op_tag   when cpu_l1mem_inst_cache_a_bus_op_paddr_tag_sel_old,
      (others => 'X')  when others;
  
  with cpu_l1mem_inst_cache_dp_in_ctrl.a_bus_op_paddr_index_sel select
    c.a_bus_op_paddr(cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits-1 downto cpu_l1mem_inst_cache_offset_bits) <=
      c.a_request_index  when cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_request,
      c.b_bus_op_index   when cpu_l1mem_inst_cache_a_bus_op_paddr_index_sel_old,
      (others => 'X')    when others;
  
  a_bus_op_paddr_block_inst_offset_gen : if cpu_l1mem_inst_cache_offset_bits > 0 generate
    with cpu_l1mem_inst_cache_dp_in_ctrl.a_bus_op_paddr_offset_sel select
      c.a_bus_op_paddr(cpu_l1mem_inst_cache_offset_bits-1 downto 0) <=
        c.b_bus_op_offset(cpu_l1mem_inst_cache_offset_bits-1 downto 0)
                                                when cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_old,
        c.a_bus_op_paddr_block_inst_offset_next when cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_next,
        c.a_request_offset(cpu_l1mem_inst_cache_offset_bits-1 downto 0)
                                                when cpu_l1mem_inst_cache_a_bus_op_paddr_offset_sel_request,
        (others => 'X')                         when others;
  end generate;
  
  c.a_bus_op_index <= c.a_bus_op_paddr(cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits-1 downto
                                       cpu_l1mem_inst_cache_offset_bits);
  c.a_bus_op_offset <= c.a_bus_op_paddr(cpu_l1mem_inst_cache_offset_bits-1 downto 0);
  
  c.a_bus_op_cache_wtag <= r.b_bus_op_paddr(cpu_ipaddr_bits-1 downto
                                            cpu_l1mem_inst_cache_index_bits+cpu_l1mem_inst_cache_offset_bits);

  with cpu_l1mem_inst_cache_dp_in_ctrl.a_bus_op_cache_paddr_sel_old select
    c.a_bus_op_cache_index <=
      c.a_bus_op_index when '0',
      c.b_bus_op_index when '1',
      (others => 'X')  when others;
  with cpu_l1mem_inst_cache_dp_in_ctrl.a_bus_op_cache_paddr_sel_old select
    c.a_bus_op_cache_offset <=
      c.a_bus_op_offset when '0',
      c.b_bus_op_offset when '1',
      (others => 'X')  when others;

  c.a_bus_op_sys_paddr <= c.a_bus_op_paddr;

  --------------------------------

  with cpu_l1mem_inst_cache_dp_in_ctrl.a_cache_owner select
    c.a_cache_index <= c.a_request_index      when cpu_l1mem_inst_cache_owner_request,
                       c.a_bus_op_cache_index when cpu_l1mem_inst_cache_owner_bus_op,
                       (others => 'X')        when others;

  with cpu_l1mem_inst_cache_dp_in_ctrl.a_cache_owner select
    c.a_cache_offset <= c.a_request_paddr(cpu_l1mem_inst_cache_offset_bits-1 downto 0)
                           when cpu_l1mem_inst_cache_owner_request,
                         c.a_bus_op_cache_offset
                           when cpu_l1mem_inst_cache_owner_bus_op,
                         (others => 'X')   when others;

  c.a_vram_raddr  <= c.a_cache_index;
  
  c.a_tram_addr <= c.a_cache_index;
  c.a_tram_wtag <= c.a_bus_op_cache_wtag;
  a_tram_wdata_gen : for n in cpu_l1mem_inst_cache_assoc-1 downto 0 generate
    bit_gen : for b in cpu_l1mem_inst_cache_tag_bits-1 downto 0 generate
      c.a_tram_wdata(n, b) <= c.a_tram_wtag(b);
    end generate;
  end generate;
  
  c.a_replace_rindex <= c.a_cache_index;

  c.a_dram_addr <= c.a_cache_index & c.a_cache_offset;

  with cpu_l1mem_inst_cache_dp_in_ctrl.a_cache_owner select
    c.a_dram_wdata_inst <= c.a_bus_op_dram_wdata  when cpu_l1mem_inst_cache_owner_bus_op,
                           (others => 'X')             when others;
  a_dram_wdata_gen : for n in cpu_l1mem_inst_cache_assoc-1 downto 0 generate
    bit_loop : for b in cpu_inst_bits-1 downto 0 generate
      c.a_dram_wdata(n, b) <= c.a_dram_wdata_inst(b);
    end generate;
  end generate;

  c.a_sys_size <= std_ulogic_vector(to_unsigned(cpu_log2_inst_bytes, sys_transfer_size_bits));
  c.a_sys_paddr <= (sys_paddr_bits-1 downto cpu_paddr_bits => '0') & c.a_bus_op_sys_paddr & (cpu_log2_inst_bytes-1 downto 0 => '0');

  c.b_result_paddr <= r.b_bus_op_paddr;
  
  r_next <= (
    b_request_poffset => c.a_request_poffset,
    b_request_vpn => c.a_request_vpn,

    b_bus_op_paddr => c.a_bus_op_paddr
    );

  cpu_l1mem_inst_cache_dp_out_ctrl <= (
    b_request_last_in_block => c.b_request_last_in_block,
    b_request_cache_tag_match => c.b_request_cache_tag_match
    );

  cpu_l1mem_inst_cache_dp_out_vram <= (
    raddr   => c.a_vram_raddr,
    waddr   => c.b_vram_waddr
    );

  cpu_l1mem_inst_cache_dp_out_tram <= (
    addr  => c.a_tram_addr,
    wdata  => c.a_tram_wdata
    );

  cpu_l1mem_inst_cache_dp_out_dram <= (
    addr  => c.a_dram_addr,
    wdata  => c.a_dram_wdata
    );

  cpu_l1mem_inst_cache_replace_dp_in <= (
    rindex => c.a_replace_rindex,
    windex => c.b_replace_windex,
    wstate => c.b_replace_wstate
    );

  cpu_l1mem_inst_cache_dp_out <= (
    paddr => c.b_result_paddr,
    data => c.b_result_inst
    );

  cpu_mmu_inst_dp_in <= (
    vpn => c.a_request_vpn
    );

  sys_master_dp_out <= (
    size => c.a_sys_size,
    paddr => c.a_sys_paddr,
    data => (others => 'X')
    );

  process (clk) is
  begin
    if rising_edge(clk) then
      r <= r_next;
    end if;
  end process;
  
end;
