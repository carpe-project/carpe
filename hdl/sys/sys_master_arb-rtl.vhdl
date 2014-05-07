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
use util.types_pkg.all;

library tech;

use work.sys_pkg.all;
use work.sys_config_pkg.all;

architecture rtl of sys_master_arb is

  subtype arb_sel_type is std_ulogic_vector(masters-1 downto 0);

  type request_type is record
    be        : std_ulogic;
    write     : std_ulogic;
    cacheable : std_ulogic;
    priv      : std_ulogic;
    inst      : std_ulogic;
    burst     : std_ulogic;
    bwrap     : std_ulogic;
    bcycles   : sys_burst_cycles_type;
    size      : sys_transfer_size_type;
    paddr     : sys_paddr_type;
    data      : sys_bus_type;
  end record;
  constant request_x : request_type := (
    be       => 'X',
    write    => 'X',
    cacheable => 'X',
    priv     => 'X',
    inst     => 'X',
    burst    => 'X',
    bwrap    => 'X',
    bcycles  => (others => 'X'),
    size     => (others => 'X'),
    paddr    => (others => 'X'),
    data     => (others => 'X')
    );
  
  type comb_type is record
    
    new_valid : arb_sel_type;
    new_burst : arb_sel_type;
    
    pending : arb_sel_type;
    not_ready : arb_sel_type;
    any_not_ready : std_ulogic;
    any_burst_lock : std_ulogic;
    request_sel_default_unpri : arb_sel_type;
    request_sel_default : arb_sel_type;
    request_sel : arb_sel_type;
    
    request_array_be : arb_sel_type;
    request_array_write : arb_sel_type;
    request_array_cacheable : arb_sel_type;
    request_array_priv : arb_sel_type;
    request_array_inst : arb_sel_type;
    request_array_burst : arb_sel_type;
    request_array_bwrap : arb_sel_type;
    request_array_bcycles : std_ulogic_vector2(masters-1 downto 0, sys_burst_cycles_bits-1 downto 0);
    request_array_size  : std_ulogic_vector2(masters-1 downto 0, sys_transfer_size_bits-1 downto 0);
    request_array_paddr : std_ulogic_vector2(masters-1 downto 0, sys_paddr_bits-1 downto 0);
    request_array_data : std_ulogic_vector2(masters-1 downto 0, sys_bus_bits-1 downto 0);

    use_new_request : arb_sel_type;

    request_be        : std_ulogic;
    request_write     : std_ulogic;
    request_cacheable : std_ulogic;
    request_priv      : std_ulogic;
    request_inst      : std_ulogic;
    request_burst     : std_ulogic;
    request_bwrap     : std_ulogic;
    request_bcycles   : sys_burst_cycles_type;
    request_size      : sys_transfer_size_type;
    request_paddr     : sys_paddr_type;
    request_data      : sys_bus_type;
  end record;

  type reg_type is record
    valid : arb_sel_type;
    requested : arb_sel_type;
    burst_lock : arb_sel_type;
    request_array_be : arb_sel_type;
    request_array_write : arb_sel_type;
    request_array_cacheable : arb_sel_type;
    request_array_priv : arb_sel_type;
    request_array_inst : arb_sel_type;
    request_array_burst : arb_sel_type;
    request_array_bwrap : arb_sel_type;
    request_array_bcycles : std_ulogic_vector2(masters-1 downto 0, sys_burst_cycles_bits-1 downto 0);
    request_array_size  : std_ulogic_vector2(masters-1 downto 0, sys_transfer_size_bits-1 downto 0);
    request_array_paddr : std_ulogic_vector2(masters-1 downto 0, sys_paddr_bits-1 downto 0);
    request_array_data : std_ulogic_vector2(masters-1 downto 0, sys_bus_bits-1 downto 0);
  end record;
  constant reg_x : reg_type := (
    valid => (others => 'X'),
    requested => (others => 'X'),
    burst_lock => (others => 'X'),
    request_array_be => (others => 'X'),
    request_array_write => (others => 'X'),
    request_array_cacheable => (others => 'X'),
    request_array_priv => (others => 'X'),
    request_array_inst => (others => 'X'),
    request_array_burst => (others => 'X'),
    request_array_bwrap => (others => 'X'),
    request_array_bcycles => (others => (others => 'X')),
    request_array_size => (others => (others => 'X')),
    request_array_paddr => (others => (others => 'X')),
    request_array_data => (others => (others => 'X'))
    );
  constant reg_init : reg_type := (
    valid => (others => '0'),
    requested => (others => '0'),
    burst_lock => (others => '0'),
    request_array_be => (others => 'X'),
    request_array_write => (others => 'X'),
    request_array_cacheable => (others => 'X'),
    request_array_priv => (others => 'X'),
    request_array_inst => (others => 'X'),
    request_array_burst => (others => 'X'),
    request_array_bwrap => (others => 'X'),
    request_array_bcycles => (others => (others => 'X')),
    request_array_size => (others => (others => 'X')),
    request_array_paddr => (others => (others => 'X')),
    request_array_data => (others => (others => 'X'))
    );

  signal c : comb_type;
  signal r, r_next : reg_type;
  
begin

  master_loop : for n in masters-1 downto 0 generate
    c.new_valid(n) <= sys_master_ctrl_out_master(n).request;
    c.new_burst(n) <= sys_master_ctrl_out_master(n).burst;
    c.pending(n) <= r.valid(n) and not (r.requested(n) and sys_slave_ctrl_out_sys.ready);
    c.not_ready(n) <= r.requested(n) and not sys_slave_ctrl_out_sys.ready;
    c.use_new_request(n) <= c.new_valid(n) and not c.pending(n);
    with c.use_new_request(n) select
      c.request_array_be(n) <= sys_master_ctrl_out_master(n).be when '1',
                               r.request_array_be(n)     when '0',
                               'X'                       when others;
    with c.use_new_request(n) select
      c.request_array_write(n) <= sys_master_ctrl_out_master(n).write when '1',
                                  r.request_array_write(n)     when '0',
                                  'X'                       when others;
    with c.use_new_request(n) select
      c.request_array_cacheable(n) <= sys_master_ctrl_out_master(n).cacheable when '1',
                                      r.request_array_cacheable(n)     when '0',
                                      'X'                       when others;
    with c.use_new_request(n) select
      c.request_array_priv(n) <= sys_master_ctrl_out_master(n).priv when '1',
                                 r.request_array_priv(n)     when '0',
                                 'X'                       when others;
    with c.use_new_request(n) select
      c.request_array_inst(n) <= sys_master_ctrl_out_master(n).inst when '1',
                                 r.request_array_inst(n)     when '0',
                                 'X'                       when others;
    with c.use_new_request(n) select
      c.request_array_burst(n) <= sys_master_ctrl_out_master(n).burst when '1',
                               r.request_array_burst(n)     when '0',
                               'X'                       when others;
    with c.use_new_request(n) select
      c.request_array_bwrap(n) <= sys_master_ctrl_out_master(n).bwrap when '1',
                                  r.request_array_bwrap(n)     when '0',
                                  'X'                          when others;
    blk : block
      signal bcycles, new_bcycles, old_bcycles : sys_burst_cycles_type;
      signal paddr, new_paddr, old_paddr : sys_paddr_type;
      signal size, new_size, old_size : sys_transfer_size_type;
      signal data, new_data, old_data : sys_bus_type;
    begin
      bcycles_in_loop : for m in sys_burst_cycles_bits-1 downto 0 generate
        new_bcycles(m) <= sys_master_ctrl_out_master(n).bcycles(m);
        old_bcycles(m) <= r.request_array_bcycles(n, m);
      end generate;
      size_in_loop : for m in sys_transfer_size_bits-1 downto 0 generate
        new_size(m) <= sys_master_dp_out_master(n).size(m);
        old_size(m) <= r.request_array_size(n, m);
      end generate;
      paddr_in_loop : for m in sys_paddr_bits-1 downto 0 generate
        new_paddr(m) <= sys_master_dp_out_master(n).paddr(m);
        old_paddr(m) <= r.request_array_paddr(n, m);
      end generate;
      data_in_loop : for m in sys_bus_bits-1 downto 0 generate
        new_data(m) <= sys_master_dp_out_master(n).data(m);
        old_data(m) <= r.request_array_data(n, m);
      end generate;
      with c.use_new_request(n) select
        bcycles <= new_bcycles     when '1',
                   old_bcycles     when '0',
                   (others => 'X') when others;
      with c.use_new_request(n) select
        size <= new_size when '1',
                old_size when '0',
                (others => 'X') when others;
      with c.use_new_request(n) select
        paddr <= new_paddr when '1',
                 old_paddr when '0',
                 (others => 'X') when others;
      with c.use_new_request(n) select
        data <= new_data when '1',
                old_data when '0',
                 (others => 'X') when others;
      bcycles_out_loop : for m in sys_burst_cycles_bits-1 downto 0 generate
        c.request_array_bcycles(n, m) <= bcycles(m);
      end generate;
      size_out_loop : for m in sys_transfer_size_bits-1 downto 0 generate
        c.request_array_size(n, m) <= size(m);
      end generate;
      paddr_out_loop : for m in sys_paddr_bits-1 downto 0 generate
        c.request_array_paddr(n, m) <= paddr(m);
      end generate;
      data_out_loop : for m in sys_bus_bits-1 downto 0 generate
        c.request_array_data(n, m) <= data(m);
      end generate;
    end block;
  end generate;

  c.any_not_ready <= any_ones(c.not_ready);
  c.any_burst_lock <= any_ones(r.burst_lock);

  c.request_sel_default_unpri <= c.pending or c.new_valid;
  c.request_sel_default <= prioritize_none(c.request_sel_default_unpri);

  c.request_sel <= logic_if(c.any_not_ready,
                            r.requested,
                            logic_if(c.any_burst_lock,
                                     r.burst_lock,
                                     c.request_sel_default
                                     )
                            );
  
  r_next.valid <= c.new_valid or c.pending;
  r_next.requested <= logic_if(c.any_not_ready, r.requested,  c.request_sel);
  r_next.burst_lock <= logic_if(c.any_not_ready, r.burst_lock, c.request_sel and c.request_array_burst);
  
  r_next.request_array_be <= c.request_array_be;
  r_next.request_array_write <= c.request_array_write;
  r_next.request_array_cacheable <= c.request_array_cacheable;
  r_next.request_array_priv <= c.request_array_priv;
  r_next.request_array_inst <= c.request_array_inst;
  r_next.request_array_burst <= c.request_array_burst;
  r_next.request_array_bwrap <= c.request_array_bwrap;
  r_next.request_array_bcycles <= c.request_array_bcycles;
  r_next.request_array_size <= c.request_array_size;
  r_next.request_array_paddr <= c.request_array_paddr;
  r_next.request_array_data <= c.request_array_data;

  c.request_be        <= any_ones(c.request_sel and c.request_array_be);
  c.request_write     <= any_ones(c.request_sel and c.request_array_write);
  c.request_cacheable <= any_ones(c.request_sel and c.request_array_cacheable);
  c.request_priv      <= any_ones(c.request_sel and c.request_array_priv);
  c.request_inst      <= any_ones(c.request_sel and c.request_array_inst);
  c.request_burst     <= any_ones(c.request_sel and c.request_array_burst);
  c.request_bwrap     <= any_ones(c.request_sel and c.request_array_bwrap);

  request_size_mux : entity tech.mux_1hot(rtl)
    generic map (
      sel_bits => masters,
      data_bits => sys_transfer_size_bits
      )
    port map (
      din => c.request_array_size,
      sel => c.request_sel,
      dout => c.request_size
      );

  request_paddr_mux : entity tech.mux_1hot(rtl)
    generic map (
      sel_bits => masters,
      data_bits => sys_paddr_bits
      )
    port map (
      din => c.request_array_paddr,
      sel => c.request_sel,
      dout => c.request_paddr
      );

  request_data_mux : entity tech.mux_1hot(rtl)
    generic map (
      sel_bits => masters,
      data_bits => sys_bus_bits
      )
    port map (
      din => c.request_array_data,
      sel => c.request_sel,
      dout => c.request_data
      );
  
  request_bcycles_mux : entity tech.mux_1hot(rtl)
    generic map (
      sel_bits => masters,
      data_bits => sys_burst_cycles_bits
      )
    port map (
      din => c.request_array_bcycles,
      sel => c.request_sel,
      dout => c.request_bcycles
      );
  
  sys_master_ctrl_out_sys <= (
    request    => any_ones(c.request_sel),
    be         => c.request_be,
    write      => c.request_write,
    cacheable  => c.request_cacheable,
    priv       => c.request_priv,
    inst       => c.request_inst,
    burst      => c.request_burst,
    bwrap      => c.request_bwrap,
    bcycles    => c.request_bcycles
    );

  sys_master_dp_out_sys <= (
    size       => c.request_size,
    paddr      => c.request_paddr,
    data       => c.request_data
    );

  sys_slave_ctrl_out_master_loop : for n in masters-1 downto 0 generate
    sys_slave_ctrl_out_master(n) <= (
      ready => not c.pending(n),
      error => sys_slave_ctrl_out_sys.error
      );
  end generate;

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
