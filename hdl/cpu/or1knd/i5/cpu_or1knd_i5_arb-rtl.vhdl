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
use util.logic_pkg.all;

use work.cpu_or1knd_i5_pkg.all;

architecture rtl of cpu_or1knd_i5_arb is

  type arb_sel_index_type is (
    arb_sel_index_l1mem_inst,
    arb_sel_index_mmu_inst,
    arb_sel_index_l1mem_data,
    arb_sel_index_mmu_data
    );
  type arb_sel_type is array (arb_sel_index_type range
                              arb_sel_index_mmu_data downto arb_sel_index_l1mem_inst) of std_ulogic;
  constant arb_sel_l1mem_inst : arb_sel_type := "0001";
  constant arb_sel_mmu_inst  : arb_sel_type := "0010";
  constant arb_sel_l1mem_data : arb_sel_type := "0100";
  constant arb_sel_mmu_data  : arb_sel_type := "1000";

  type request_type is record
    size      : sys_transfer_size_type;
    be        : std_ulogic;
    write     : std_ulogic;
    cacheable : std_ulogic;
    priv      : std_ulogic;
    inst      : std_ulogic;
    burst     : std_ulogic;
    bwrap     : std_ulogic;
    bcycles   : sys_burst_cycles_type;
    paddr     : sys_paddr_type;
    data      : sys_bus_type;
  end record;
  constant request_x : request_type := (
    size     => (others => 'X'),
    be       => 'X',
    write    => 'X',
    cacheable => 'X',
    priv     => 'X',
    inst     => 'X',
    burst    => 'X',
    bwrap    => 'X',
    bcycles  => (others => 'X'),
    paddr    => (others => 'X'),
    data     => (others => 'X')
    );
  
  type request_array_type is array (arb_sel_index_type range arb_sel_index_type'high downto arb_sel_index_type'low) of request_type;

  type comb_type is record
    
    new_valid : arb_sel_type;
    new_burst : arb_sel_type;
    new_requests : request_array_type;
    
    pending : arb_sel_type;
    not_ready : arb_sel_type;
    any_not_ready : std_ulogic;
    any_burst_lock : std_ulogic;
    request_sel_default_unpri : arb_sel_type;
    request_sel_default : arb_sel_type;
    request_sel : arb_sel_type;
    use_new_request : arb_sel_type;
    requests : request_array_type;
    request : request_type;
  end record;

  type reg_type is record
    valid : arb_sel_type;
    requested : arb_sel_type;
    burst_lock : arb_sel_type;
    requests : request_array_type;
  end record;
  constant reg_x : reg_type := (
    valid => (others => 'X'),
    requested => (others => 'X'),
    burst_lock => (others => 'X'),
    requests => (others => request_x)
    );
  constant reg_init : reg_type := (
    valid => (others => '0'),
    requested => (others => '0'),
    burst_lock => (others => '0'),
    requests => (others => request_x)
    );

  signal c : comb_type;
  signal r, r_next : reg_type;
  
begin

  c.new_valid <= (
    arb_sel_index_l1mem_inst => sys_master_ctrl_out_l1mem_inst.request,
    arb_sel_index_mmu_inst   => sys_master_ctrl_out_mmu_inst.request,
    arb_sel_index_l1mem_data => sys_master_ctrl_out_l1mem_data.request,
    arb_sel_index_mmu_data   => sys_master_ctrl_out_mmu_data.request
    );
  c.new_burst <= (
    arb_sel_index_l1mem_inst => sys_master_ctrl_out_l1mem_inst.burst,
    arb_sel_index_mmu_inst   => sys_master_ctrl_out_mmu_inst.burst,
    arb_sel_index_l1mem_data => sys_master_ctrl_out_l1mem_data.burst,
    arb_sel_index_mmu_data   => sys_master_ctrl_out_mmu_data.burst
    );
  c.new_requests <= (
    arb_sel_index_l1mem_inst => (
      be        => sys_master_ctrl_out_l1mem_inst.be,
      write     => sys_master_ctrl_out_l1mem_inst.write, 
      cacheable => sys_master_ctrl_out_l1mem_inst.cacheable,
      priv      => sys_master_ctrl_out_l1mem_inst.priv,
      inst      => sys_master_ctrl_out_l1mem_inst.inst,
      burst     => sys_master_ctrl_out_l1mem_inst.burst,
      bwrap     => sys_master_ctrl_out_l1mem_inst.bwrap,
      bcycles   => sys_master_ctrl_out_l1mem_inst.bcycles,
      size      => sys_master_dp_out_l1mem_inst.size,
      paddr     => sys_master_dp_out_l1mem_inst.paddr,
      data      => sys_master_dp_out_l1mem_inst.data
      ),
    arb_sel_index_mmu_inst  => (
      be        => sys_master_ctrl_out_mmu_inst.be,
      write     => sys_master_ctrl_out_mmu_inst.write, 
      cacheable => sys_master_ctrl_out_mmu_inst.cacheable,
      priv      => sys_master_ctrl_out_mmu_inst.priv,
      inst      => sys_master_ctrl_out_mmu_inst.inst,
      burst     => sys_master_ctrl_out_mmu_inst.burst,
      bwrap     => sys_master_ctrl_out_mmu_inst.bwrap,
      bcycles   => sys_master_ctrl_out_mmu_inst.bcycles,
      size      => sys_master_dp_out_mmu_inst.size,
      paddr     => sys_master_dp_out_mmu_inst.paddr,
      data      => sys_master_dp_out_mmu_inst.data
      ),
    arb_sel_index_l1mem_data => (
      be        => sys_master_ctrl_out_l1mem_data.be,
      write     => sys_master_ctrl_out_l1mem_data.write, 
      cacheable => sys_master_ctrl_out_l1mem_data.cacheable,
      priv      => sys_master_ctrl_out_l1mem_data.priv,
      inst      => sys_master_ctrl_out_l1mem_data.inst,
      burst     => sys_master_ctrl_out_l1mem_data.burst,
      bwrap     => sys_master_ctrl_out_l1mem_data.bwrap,
      bcycles   => sys_master_ctrl_out_l1mem_data.bcycles,
      size      => sys_master_dp_out_l1mem_data.size,
      paddr     => sys_master_dp_out_l1mem_data.paddr,
      data      => sys_master_dp_out_l1mem_data.data
      ),
    arb_sel_index_mmu_data  => (
      be        => sys_master_ctrl_out_mmu_data.be,
      write     => sys_master_ctrl_out_mmu_data.write, 
      cacheable => sys_master_ctrl_out_mmu_data.cacheable,
      priv      => sys_master_ctrl_out_mmu_data.priv,
      inst      => sys_master_ctrl_out_mmu_data.inst,
      burst     => sys_master_ctrl_out_mmu_data.burst,
      bwrap     => sys_master_ctrl_out_mmu_data.bwrap,
      bcycles   => sys_master_ctrl_out_mmu_data.bcycles,
      size      => sys_master_dp_out_mmu_data.size,
      paddr     => sys_master_dp_out_mmu_data.paddr,
      data      => sys_master_dp_out_mmu_data.data
      )
    );

  pending_loop :
    for n in arb_sel_index_type'high downto arb_sel_index_type'low generate
      c.pending(n) <= r.valid(n) and not (r.requested(n) and sys_slave_ctrl_out.ready);
    end generate;

  not_ready_loop :
    for n in arb_sel_index_type'high downto arb_sel_index_type'low generate
      c.not_ready(n) <= r.requested(n) and not sys_slave_ctrl_out.ready;
    end generate;
  c.any_not_ready <= (
    c.not_ready(arb_sel_index_l1mem_inst) or
    c.not_ready(arb_sel_index_mmu_inst) or
    c.not_ready(arb_sel_index_l1mem_data) or
    c.not_ready(arb_sel_index_mmu_data)
    );

  requests_loop :
    for n in arb_sel_index_type'high downto arb_sel_index_type'low generate
      c.use_new_request(n) <= c.new_valid(n) and not c.pending(n);
      with c.use_new_request(n) select
        c.requests(n) <= c.new_requests(n) when '1',
                         r.requests(n) when '0',
                         request_x when others;
    end generate;

  c.any_burst_lock <= (
    r.burst_lock(arb_sel_index_l1mem_inst) or
    r.burst_lock(arb_sel_index_mmu_inst) or
    r.burst_lock(arb_sel_index_l1mem_data) or
    r.burst_lock(arb_sel_index_mmu_data)
    );

  request_sel_default_unpri_loop :
    for n in arb_sel_index_type'high downto arb_sel_index_type'low generate
      c.request_sel_default_unpri(n) <= c.pending(n) or c.new_valid(n);
    end generate;
  c.request_sel_default <= (
    arb_sel_index_mmu_data   => c.request_sel_default_unpri(arb_sel_index_mmu_data),
    arb_sel_index_l1mem_data => (c.request_sel_default_unpri(arb_sel_index_l1mem_data) and
                                 not c.request_sel_default_unpri(arb_sel_index_mmu_data)),
    arb_sel_index_mmu_inst   => (c.request_sel_default_unpri(arb_sel_index_mmu_inst) and
                                 not c.request_sel_default_unpri(arb_sel_index_l1mem_data) and
                                 not c.request_sel_default_unpri(arb_sel_index_mmu_data)),
    arb_sel_index_l1mem_inst => (c.request_sel_default_unpri(arb_sel_index_l1mem_inst) and
                                 not c.request_sel_default_unpri(arb_sel_index_mmu_inst) and
                                 not c.request_sel_default_unpri(arb_sel_index_l1mem_data) and
                                 not c.request_sel_default_unpri(arb_sel_index_mmu_data))
    );
  
  request_sel_loop :
    for n in arb_sel_index_type'high downto arb_sel_index_type'low generate
      -- select the next request to fill
      -- stay on the current request if it hasn't been completed yet
      -- otherwise, if the last request had the burst flag set, continue filling requests from that source, excluding the other sources
      -- otherwise, pick a new request
      c.request_sel(n) <= ((c.any_not_ready     and r.requested(n)) or
                           (not c.any_not_ready and ((c.any_burst_lock     and r.burst_lock(n)) or
                                                     (not c.any_burst_lock and c.request_sel_default(n)))));
    end generate;
  
  r_next_loop :
    for n in arb_sel_index_type'high downto arb_sel_index_type'low generate
      r_next.valid(n)      <= c.new_valid(n) or c.pending(n);
      r_next.requested(n)  <= logic_if(c.any_not_ready, r.requested(n),  c.request_sel(n));
      r_next.burst_lock(n) <= logic_if(c.any_not_ready, r.burst_lock(n), c.request_sel(n) and c.requests(n).burst);
      r_next.requests(n)   <= c.requests(n);
    end generate;
  
  with c.request_sel select
    c.request <= c.requests(arb_sel_index_mmu_data)   when arb_sel_mmu_data,
                 c.requests(arb_sel_index_l1mem_data) when arb_sel_l1mem_data,
                 c.requests(arb_sel_index_mmu_inst)   when arb_sel_mmu_inst,
                 c.requests(arb_sel_index_l1mem_inst) when arb_sel_l1mem_inst,
                 request_x                            when others;
  
  sys_master_ctrl_out <= (
    request    => (
      c.request_sel(arb_sel_index_mmu_data) or
      c.request_sel(arb_sel_index_l1mem_data) or
      c.request_sel(arb_sel_index_mmu_inst) or
      c.request_sel(arb_sel_index_l1mem_inst)
      ),
    be         => c.request.be,
    write      => c.request.write,
    cacheable  => c.request.cacheable,
    priv       => c.request.priv,
    inst       => c.request.inst,
    burst      => c.request.burst,
    bwrap      => c.request.bwrap,
    bcycles      => c.request.bcycles
    );

  sys_master_dp_out <= (
    size       => c.request.size,
    paddr      => c.request.paddr,
    data       => c.request.data
    );
  
  sys_slave_ctrl_out_l1mem_inst <= (
    ready => not c.pending(arb_sel_index_l1mem_inst),
    error => sys_slave_ctrl_out.error
    );
  
  sys_slave_ctrl_out_mmu_inst <= (
    ready => not c.pending(arb_sel_index_mmu_inst),
    error => sys_slave_ctrl_out.error
    );

  sys_slave_ctrl_out_l1mem_data <= (
    ready => not c.pending(arb_sel_index_l1mem_data),
    error => sys_slave_ctrl_out.error
    );

  sys_slave_ctrl_out_mmu_data <= (
    ready => not c.pending(arb_sel_index_mmu_data),
    error => sys_slave_ctrl_out.error
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
