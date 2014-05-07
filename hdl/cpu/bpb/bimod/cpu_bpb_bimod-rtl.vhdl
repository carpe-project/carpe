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
use ieee.numeric_std.all;

library util;
use util.logic_pkg.all;

library tech;

use work.cpu_bpb_bimod_pkg.all;
use work.cpu_bpb_bimod_config_pkg.all;

architecture rtl of cpu_bpb_bimod is

  -- weakly not taken.  0xxx is not taken, 1xxx is taken
  constant wnt : cpu_bpb_bimod_state_type := (cpu_bpb_bimod_state_bits-1 => '0', others => '1');

  type comb_type is record
    syncram_we    : std_ulogic;
    syncram_waddr : std_ulogic_vector(cpu_bpb_bimod_index_bits-1 downto 0);
    syncram_wdata : cpu_bpb_bimod_state_type;
    syncram_re    : std_ulogic;
    syncram_raddr : std_ulogic_vector(cpu_bpb_bimod_index_bits-1 downto 0);
    syncram_rdata : cpu_bpb_bimod_state_type;

    wstate_sat0 : std_ulogic;
    wstate_sat1 : std_ulogic;
    wstate_sel  : std_ulogic_vector(2 downto 0);
    wstate      : cpu_bpb_bimod_state_type;
  end record;
  signal c : comb_type;

begin

  -- saturating counter increment
  c.wstate_sat0 <= all_zeros(cpu_bpb_bimod_dp_in.wstate);
  c.wstate_sat1 <= all_ones(cpu_bpb_bimod_dp_in.wstate);

  c.wstate_sel <= (
    2 => cpu_bpb_bimod_ctrl_in.wtaken,
    1 => c.wstate_sat1,
    0 => c.wstate_sat0
    );

  with c.wstate_sel select
    c.wstate <= std_ulogic_vector(unsigned(cpu_bpb_bimod_dp_in.wstate) + to_unsigned(1, cpu_bpb_bimod_state_bits)) when "100" | "101", -- taken, not saturated
                (others => '1')                                                                                    when "110",         -- taken, saturated
                std_ulogic_vector(unsigned(cpu_bpb_bimod_dp_in.wstate) - to_unsigned(1, cpu_bpb_bimod_state_bits)) when "000" | "010", -- not taken, not saturated
                (others => '0')                                                                                    when "001",         -- not taken, saturated
                (others => 'X')                                                                                    when others;

  c.syncram_we    <= cpu_bpb_bimod_ctrl_in.wen;
  c.syncram_waddr <= cpu_bpb_bimod_dp_in.waddr(cpu_bpb_bimod_index_bits-1 downto 0);
  c.syncram_wdata <= c.wstate;
  
  c.syncram_re    <= cpu_bpb_bimod_ctrl_in.ren;
  c.syncram_raddr <= cpu_bpb_bimod_dp_in.raddr(cpu_bpb_bimod_index_bits-1 downto 0);

  -- bpb outputs
  cpu_bpb_bimod_ctrl_out <= (
    rtaken => c.syncram_rdata(cpu_bpb_bimod_state_bits-1)
    );
  cpu_bpb_bimod_dp_out <= (
    rstate => c.syncram_rdata
    );

  sram : entity tech.syncram_1r1w(rtl)
    generic map (
      addr_bits   => cpu_bpb_bimod_index_bits,
      data_bits   => cpu_bpb_bimod_state_bits,
      write_first => true
      )
    port map (
      clk         => clk,
      we          => c.syncram_we,
      waddr       => c.syncram_waddr,
      wdata       => c.syncram_wdata,
      re          => c.syncram_re,
      raddr       => c.syncram_raddr,
      rdata       => c.syncram_rdata
      );
  
end;

