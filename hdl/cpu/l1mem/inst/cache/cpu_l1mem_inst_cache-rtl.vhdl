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

library mem;
library tech;

use work.cpu_types_pkg.all;
use work.cpu_l1mem_inst_cache_pkg.all;
use work.cpu_l1mem_inst_cache_config_pkg.all;
use work.cpu_l1mem_inst_cache_replace_pkg.all;

architecture rtl of cpu_l1mem_inst_cache is

  type comb_type is record
    cpu_l1mem_inst_cache_ctrl_out_vram : cpu_l1mem_inst_cache_ctrl_out_vram_type;
    cpu_l1mem_inst_cache_ctrl_in_vram : cpu_l1mem_inst_cache_ctrl_in_vram_type;
    cpu_l1mem_inst_cache_dp_out_vram : cpu_l1mem_inst_cache_dp_out_vram_type;
    
    cpu_l1mem_inst_cache_ctrl_out_tram : cpu_l1mem_inst_cache_ctrl_out_tram_type;
    cpu_l1mem_inst_cache_dp_in_tram : cpu_l1mem_inst_cache_dp_in_tram_type;
    cpu_l1mem_inst_cache_dp_out_tram : cpu_l1mem_inst_cache_dp_out_tram_type;
    
    cpu_l1mem_inst_cache_ctrl_out_dram : cpu_l1mem_inst_cache_ctrl_out_dram_type;
    cpu_l1mem_inst_cache_dp_in_dram : cpu_l1mem_inst_cache_dp_in_dram_type;
    cpu_l1mem_inst_cache_dp_out_dram : cpu_l1mem_inst_cache_dp_out_dram_type;
    
    cpu_l1mem_inst_cache_dp_in_ctrl : cpu_l1mem_inst_cache_dp_in_ctrl_type;
    cpu_l1mem_inst_cache_dp_out_ctrl : cpu_l1mem_inst_cache_dp_out_ctrl_type;

    cpu_l1mem_inst_cache_replace_ctrl_in : cpu_l1mem_inst_cache_replace_ctrl_in_type;
    cpu_l1mem_inst_cache_replace_ctrl_out : cpu_l1mem_inst_cache_replace_ctrl_out_type;
    cpu_l1mem_inst_cache_replace_dp_in : cpu_l1mem_inst_cache_replace_dp_in_type;
    cpu_l1mem_inst_cache_replace_dp_out : cpu_l1mem_inst_cache_replace_dp_out_type;
  end record;
  signal c : comb_type;
begin

  ctrl : entity work.cpu_l1mem_inst_cache_ctrl(rtl)
    port map (
      clk => clk,
      rstn => rstn,
      cpu_mmu_inst_ctrl_in   => cpu_mmu_inst_ctrl_in,
      cpu_mmu_inst_ctrl_out   => cpu_mmu_inst_ctrl_out,
    
      cpu_l1mem_inst_cache_ctrl_out        => cpu_l1mem_inst_cache_ctrl_out,
      cpu_l1mem_inst_cache_ctrl_in         => cpu_l1mem_inst_cache_ctrl_in,

      sys_master_ctrl_out             => sys_master_ctrl_out,
      sys_slave_ctrl_out              => sys_slave_ctrl_out,

      cpu_l1mem_inst_cache_ctrl_in_vram => c.cpu_l1mem_inst_cache_ctrl_in_vram,
      cpu_l1mem_inst_cache_ctrl_out_vram => c.cpu_l1mem_inst_cache_ctrl_out_vram,
      cpu_l1mem_inst_cache_ctrl_out_tram => c.cpu_l1mem_inst_cache_ctrl_out_tram,
      cpu_l1mem_inst_cache_ctrl_out_dram => c.cpu_l1mem_inst_cache_ctrl_out_dram,

      cpu_l1mem_inst_cache_dp_in_ctrl => c.cpu_l1mem_inst_cache_dp_in_ctrl,
      cpu_l1mem_inst_cache_dp_out_ctrl => c.cpu_l1mem_inst_cache_dp_out_ctrl,

      cpu_l1mem_inst_cache_replace_ctrl_in => c.cpu_l1mem_inst_cache_replace_ctrl_in,
      cpu_l1mem_inst_cache_replace_ctrl_out => c.cpu_l1mem_inst_cache_replace_ctrl_out

      );

  dp : entity work.cpu_l1mem_inst_cache_dp(rtl)
    port map (
      clk => clk,
      rstn => rstn,
      cpu_mmu_inst_dp_in   => cpu_mmu_inst_dp_in,
      cpu_mmu_inst_dp_out   => cpu_mmu_inst_dp_out,
    
      cpu_l1mem_inst_cache_dp_out        => cpu_l1mem_inst_cache_dp_out,
      cpu_l1mem_inst_cache_dp_in         => cpu_l1mem_inst_cache_dp_in,

      sys_master_dp_out             => sys_master_dp_out,
      sys_slave_dp_out              => sys_slave_dp_out,

      cpu_l1mem_inst_cache_dp_out_vram => c.cpu_l1mem_inst_cache_dp_out_vram,
      cpu_l1mem_inst_cache_dp_in_tram => c.cpu_l1mem_inst_cache_dp_in_tram,
      cpu_l1mem_inst_cache_dp_out_tram => c.cpu_l1mem_inst_cache_dp_out_tram,
      cpu_l1mem_inst_cache_dp_in_dram => c.cpu_l1mem_inst_cache_dp_in_dram,
      cpu_l1mem_inst_cache_dp_out_dram => c.cpu_l1mem_inst_cache_dp_out_dram,

      cpu_l1mem_inst_cache_dp_in_ctrl=> c.cpu_l1mem_inst_cache_dp_in_ctrl,
      cpu_l1mem_inst_cache_dp_out_ctrl=> c.cpu_l1mem_inst_cache_dp_out_ctrl,

      cpu_l1mem_inst_cache_replace_dp_in => c.cpu_l1mem_inst_cache_replace_dp_in,
      cpu_l1mem_inst_cache_replace_dp_out => c.cpu_l1mem_inst_cache_replace_dp_out

      );

  replace : entity work.cpu_l1mem_inst_cache_replace(rtl)
    port map (
      clk => clk,
      rstn => rstn,
      cpu_l1mem_inst_cache_replace_ctrl_out => c.cpu_l1mem_inst_cache_replace_ctrl_out,
      cpu_l1mem_inst_cache_replace_ctrl_in => c.cpu_l1mem_inst_cache_replace_ctrl_in,
      cpu_l1mem_inst_cache_replace_dp_in => c.cpu_l1mem_inst_cache_replace_dp_in,
      cpu_l1mem_inst_cache_replace_dp_out => c.cpu_l1mem_inst_cache_replace_dp_out
      );

  vram : entity tech.syncram_1r1w(rtl)
    generic map (
      addr_bits => cpu_l1mem_inst_cache_index_bits,
      data_bits => cpu_l1mem_inst_cache_assoc
      )
    port map (
      clk => clk,
      re => c.cpu_l1mem_inst_cache_ctrl_out_vram.re,
      raddr => c.cpu_l1mem_inst_cache_dp_out_vram.raddr,
      rdata => c.cpu_l1mem_inst_cache_ctrl_in_vram.rdata,
      we => c.cpu_l1mem_inst_cache_ctrl_out_vram.we,
      waddr => c.cpu_l1mem_inst_cache_dp_out_vram.waddr,
      wdata => c.cpu_l1mem_inst_cache_ctrl_out_vram.wdata
      );

  tram : entity tech.syncram_banked_1rw(rtl)
    generic map (
      addr_bits => cpu_l1mem_inst_cache_index_bits,
      word_bits => cpu_l1mem_inst_cache_tag_bits,
      log2_banks => cpu_l1mem_inst_cache_log2_assoc
      )
    port map (
      clk => clk,
      en => c.cpu_l1mem_inst_cache_ctrl_out_tram.en,
      we => c.cpu_l1mem_inst_cache_ctrl_out_tram.we,
      banken => c.cpu_l1mem_inst_cache_ctrl_out_tram.banken,
      addr => c.cpu_l1mem_inst_cache_dp_out_tram.addr,
      rdata => c.cpu_l1mem_inst_cache_dp_in_tram.rdata,
      wdata => c.cpu_l1mem_inst_cache_dp_out_tram.wdata
      );

  dram : entity tech.syncram_banked_1rw(rtl)
    generic map (
      addr_bits => cpu_l1mem_inst_cache_index_bits + cpu_l1mem_inst_cache_offset_bits,
      word_bits => cpu_inst_bits,
      log2_banks => cpu_l1mem_inst_cache_log2_assoc
      )
    port map (
      clk => clk,
      en => c.cpu_l1mem_inst_cache_ctrl_out_dram.en,
      we => c.cpu_l1mem_inst_cache_ctrl_out_dram.we,
      banken => c.cpu_l1mem_inst_cache_ctrl_out_dram.banken,
      addr => c.cpu_l1mem_inst_cache_dp_out_dram.addr,
      rdata => c.cpu_l1mem_inst_cache_dp_in_dram.rdata,
      wdata => c.cpu_l1mem_inst_cache_dp_out_dram.wdata
      );

  

end;
