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


use work.cpu_types_pkg.all;
use work.cpu_btb_cache_pkg.all;
use work.cpu_btb_cache_config_pkg.all;
use work.cpu_btb_cache_replace_pkg.all;

library util;
use util.types_pkg.all;
use util.logic_pkg.all;
use util.numeric_pkg.all;

library mem;
library tech;

architecture rtl of cpu_btb_cache is

  constant state_way_lsb           : natural := cpu_btb_cache_assoc + cpu_btb_cache_replace_state_bits;
  constant state_replace_way_lsb   : natural := cpu_btb_cache_replace_state_bits;
  constant state_replace_state_lsb : natural := 0;

  type way_tags_type is array (cpu_btb_cache_assoc-1 downto 0) of std_ulogic_vector(cpu_ivaddr_bits-1 downto cpu_btb_cache_index_bits);

  type comb_type is record

    wstate_way : std_ulogic_vector(cpu_btb_cache_assoc-1 downto 0);
    wstate_replace_way : std_ulogic_vector(cpu_btb_cache_assoc-1 downto 0);
    wstate_replace_state : cpu_btb_cache_replace_state_type;
    
    rway_tags : way_tags_type;
    rway_unpri : std_ulogic_vector(cpu_btb_cache_assoc downto 0);
    rway_pri : std_ulogic_vector(cpu_btb_cache_assoc downto 0);
    rway : std_ulogic_vector(cpu_btb_cache_assoc-1 downto 0);
    rhit : std_ulogic;
    rtarget : cpu_ivaddr_type;

    whit : std_ulogic;

    cache_we : std_ulogic;
    cache_wway : std_ulogic_vector(cpu_btb_cache_assoc-1 downto 0);
    cache_wtagen : std_ulogic;
    cache_wdataen : std_ulogic;
    cache_windex : std_ulogic_vector(cpu_btb_cache_index_bits-1 downto 0);
    cache_wtag : std_ulogic_vector(cpu_ivaddr_bits-1 downto cpu_btb_cache_index_bits);
    cache_wdata  : std_ulogic_vector(cpu_ivaddr_bits-1 downto 0);

    cache_re : std_ulogic;
    cache_rway : std_ulogic_vector(cpu_btb_cache_assoc-1 downto 0);
    cache_rtagen : std_ulogic;
    cache_rdataen : std_ulogic;
    cache_rindex : std_ulogic_vector(cpu_btb_cache_index_bits-1 downto 0);
    cache_rtag : std_ulogic_vector2(cpu_btb_cache_assoc-1 downto 0, cpu_ivaddr_bits-1 downto cpu_btb_cache_index_bits);
    cache_rdata : std_ulogic_vector2(cpu_btb_cache_assoc-1 downto 0, cpu_ivaddr_bits-1 downto 0);

    replace_re     : std_ulogic;
    replace_rindex : std_ulogic_vector(cpu_btb_cache_index_bits-1 downto 0);
    replace_rway   : std_ulogic_vector(cpu_btb_cache_assoc-1 downto 0);
    replace_rstate : cpu_btb_cache_replace_state_type;
    
    replace_we : std_ulogic;
    replace_windex : std_ulogic_vector(cpu_btb_cache_index_bits-1 downto 0);
    replace_wway : std_ulogic_vector(cpu_btb_cache_assoc-1 downto 0);
    replace_wstate : cpu_btb_cache_replace_state_type;

    rtag_write : std_ulogic;

    cpu_btb_cache_replace_ctrl_in : cpu_btb_cache_replace_ctrl_in_type;
    cpu_btb_cache_replace_dp_in : cpu_btb_cache_replace_dp_in_type;
    cpu_btb_cache_replace_dp_out : cpu_btb_cache_replace_dp_out_type;
  end record;

  type reg_type is record
    rrequested : std_ulogic;
    rtag : std_ulogic_vector(cpu_ivaddr_bits-1 downto cpu_btb_cache_index_bits);
  end record;
  constant reg_init : reg_type := (
    rrequested => '0',
    rtag => (others => 'X')
    );
  constant reg_x : reg_type := (
    rrequested => 'X',
    rtag => (others => 'X')
    );

  signal c : comb_type;
  signal r, r_next : reg_type;

begin

  c.wstate_way         <= cpu_btb_cache_dp_in.wstate(state_way_lsb+cpu_btb_cache_assoc-1 downto
                                                     state_way_lsb);
  c.wstate_replace_way <= cpu_btb_cache_dp_in.wstate(state_replace_way_lsb+cpu_btb_cache_assoc-1 downto
                                                     state_replace_way_lsb);
  c.wstate_replace_state <= cpu_btb_cache_dp_in.wstate(state_replace_state_lsb+cpu_btb_cache_replace_state_bits-1 downto
                                                       state_replace_state_lsb);

  c.whit              <= reduce_or(c.wstate_way);
  c.cache_we          <= cpu_btb_cache_ctrl_in.wen and not c.whit;
  c.cache_wway        <= c.wstate_replace_way;
  c.cache_wtagen      <= cpu_btb_cache_ctrl_in.wen;
  c.cache_wdataen     <= cpu_btb_cache_ctrl_in.wen;
  c.cache_windex      <= cpu_btb_cache_dp_in.waddr(cpu_btb_cache_index_bits-1 downto 0);
  c.cache_wtag        <= cpu_btb_cache_dp_in.waddr(cpu_ivaddr_bits-1 downto cpu_btb_cache_index_bits);
  c.cache_wdata       <= cpu_btb_cache_dp_in.wtarget;

  c.replace_we        <= cpu_btb_cache_ctrl_in.wen;
  c.replace_windex    <= cpu_btb_cache_dp_in.waddr(cpu_btb_cache_index_bits-1 downto 0);
  with c.whit select
    c.replace_wway    <= c.wstate_replace_way                      when '0',
                         c.wstate_way                              when '1',
                         (others => 'X')                           when others;
  c.replace_wstate    <= c.wstate_replace_state;
  
  c.cache_re          <= cpu_btb_cache_ctrl_in.ren;
  c.cache_rway        <= (others => '1');
  c.cache_rtagen      <= cpu_btb_cache_ctrl_in.ren;
  c.cache_rdataen     <= cpu_btb_cache_ctrl_in.ren;
  c.cache_rindex      <= cpu_btb_cache_dp_in.raddr(cpu_btb_cache_index_bits-1 downto 0);

  c.replace_re        <= cpu_btb_cache_ctrl_in.ren;
  c.replace_rindex    <= cpu_btb_cache_dp_in.raddr(cpu_btb_cache_index_bits-1 downto 0);

  r_next.rrequested <= c.cache_re;

  c.rtag_write <= c.cache_re;
  with c.rtag_write select
    r_next.rtag <= cpu_btb_cache_dp_in.raddr(cpu_ivaddr_bits-1 downto cpu_btb_cache_index_bits) when '1',
                   r.rtag                                                                       when '0',
                   (others => 'X')                                                              when others;
  
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

  way_loop : for n in cpu_btb_cache_assoc-1 downto 0 generate
    ivaddr_bit_loop : for m in cpu_ivaddr_bits-1 downto cpu_btb_cache_index_bits generate
      c.rway_tags(n)(m) <= c.cache_rtag(n, m);
    end generate;
    c.rway_unpri(n) <= logic_eq(c.rway_tags(n), r.rtag);
  end generate;
  -- need to prioritize because we might get multiple hits, since we don't keep valid bits
  c.rway_unpri(cpu_btb_cache_assoc) <= '1';
  c.rway_pri <= prioritize_least(c.rway_unpri);
  c.rway <= c.rway_pri(cpu_btb_cache_assoc-1 downto 0);
  c.rhit <= any_ones(c.rway);

  c.replace_rway   <= c.cpu_btb_cache_replace_dp_out.rway;
  c.replace_rstate <= c.cpu_btb_cache_replace_dp_out.rstate;

  c.cpu_btb_cache_replace_ctrl_in <= (
    re     => c.replace_re,
    we     => c.replace_we
    );
  c.cpu_btb_cache_replace_dp_in <= (
    rindex => c.replace_rindex,
    windex => c.replace_windex,
    wway   => c.replace_wway,
    wstate => c.replace_wstate
    );

  cpu_btb_cache_ctrl_out <= (
    rvalid => c.rhit
    );

  cpu_btb_cache_dp_out.rstate <= (
    c.rway         &
    c.replace_rway &
    c.replace_rstate
    );

  rtarget_mux : entity tech.mux_1hot(rtl)
    generic map (
      data_bits => cpu_ivaddr_bits,
      sel_bits  => cpu_btb_cache_assoc
      )
    port map (
      din  => c.cache_rdata,
      sel  => c.rway,
      dout => cpu_btb_cache_dp_out.rtarget
      );

  replace : entity work.cpu_btb_cache_replace(rtl)
    port map (
      clk                            => clk,
      rstn                           => rstn,
      cpu_btb_cache_replace_ctrl_in  => c.cpu_btb_cache_replace_ctrl_in,
      cpu_btb_cache_replace_dp_in    => c.cpu_btb_cache_replace_dp_in,
      cpu_btb_cache_replace_dp_out   => c.cpu_btb_cache_replace_dp_out
      );

  cache : entity mem.cache_core_1r1w(rtl)
    generic map (
      log2_assoc  => cpu_btb_cache_log2_assoc,
      word_bits   => cpu_ivaddr_bits,
      index_bits  => cpu_btb_cache_index_bits,
      offset_bits => 0,
      tag_bits    => cpu_ivaddr_bits - cpu_btb_cache_index_bits,
      write_first => true
      )
    port map (
      clk      => clk,
      rstn     => rstn,
      we       => c.cache_we,
      wway     => c.cache_wway,
      wtagen   => c.cache_wtagen,
      wdataen  => c.cache_wdataen,
      windex   => c.cache_windex,
      woffset  => "",
      wtag     => c.cache_wtag,
      wdata    => c.cache_wdata,
      re       => c.cache_re,
      rway     => c.cache_rway,
      rtagen   => c.cache_rtagen,
      rdataen  => c.cache_rdataen,
      rindex   => c.cache_rindex,
      roffset  => "",
      rtag     => c.cache_rtag,
      rdata    => c.cache_rdata
      );

end;
