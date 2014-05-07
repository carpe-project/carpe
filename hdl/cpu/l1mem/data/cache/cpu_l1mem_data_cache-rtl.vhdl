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

library sys;
use sys.sys_pkg.all;

library mem;
library tech;

use work.cpu_types_pkg.all;
use work.cpu_l1mem_data_types_pkg.all;
use work.cpu_l1mem_data_cache_pkg.all;
use work.cpu_l1mem_data_cache_config_pkg.all;
use work.cpu_l1mem_data_cache_replace_pkg.all;

architecture rtl of cpu_l1mem_data_cache is

  type comb_type is record
    cpu_l1mem_data_cache_ctrl_out_vram : cpu_l1mem_data_cache_ctrl_out_vram_type;
    cpu_l1mem_data_cache_ctrl_in_vram : cpu_l1mem_data_cache_ctrl_in_vram_type;
    cpu_l1mem_data_cache_dp_out_vram : cpu_l1mem_data_cache_dp_out_vram_type;
    
    cpu_l1mem_data_cache_ctrl_out_mram : cpu_l1mem_data_cache_ctrl_out_mram_type;
    cpu_l1mem_data_cache_ctrl_in_mram : cpu_l1mem_data_cache_ctrl_in_mram_type;
    cpu_l1mem_data_cache_dp_out_mram : cpu_l1mem_data_cache_dp_out_mram_type;
    
    cpu_l1mem_data_cache_ctrl_out_tram : cpu_l1mem_data_cache_ctrl_out_tram_type;
    cpu_l1mem_data_cache_dp_in_tram : cpu_l1mem_data_cache_dp_in_tram_type;
    cpu_l1mem_data_cache_dp_out_tram : cpu_l1mem_data_cache_dp_out_tram_type;
    
    cpu_l1mem_data_cache_ctrl_out_dram : cpu_l1mem_data_cache_ctrl_out_dram_type;
    cpu_l1mem_data_cache_dp_in_dram : cpu_l1mem_data_cache_dp_in_dram_type;
    cpu_l1mem_data_cache_dp_out_dram : cpu_l1mem_data_cache_dp_out_dram_type;
    
    cpu_l1mem_data_cache_dp_in_ctrl : cpu_l1mem_data_cache_dp_in_ctrl_type;
    cpu_l1mem_data_cache_dp_out_ctrl : cpu_l1mem_data_cache_dp_out_ctrl_type;

    cpu_l1mem_data_cache_replace_ctrl_out : cpu_l1mem_data_cache_replace_ctrl_out_type;
    cpu_l1mem_data_cache_replace_ctrl_in : cpu_l1mem_data_cache_replace_ctrl_in_type;
    cpu_l1mem_data_cache_replace_dp_in : cpu_l1mem_data_cache_replace_dp_in_type;
    cpu_l1mem_data_cache_replace_dp_out : cpu_l1mem_data_cache_replace_dp_out_type;

    cpu_l1mem_data_cache_ctrl_out : cpu_l1mem_data_cache_ctrl_out_type;
    cpu_l1mem_data_cache_dp_out : cpu_l1mem_data_cache_dp_out_type;
    
    sys_master_ctrl_out : sys_master_ctrl_out_type;
    sys_master_dp_out : sys_master_dp_out_type;
  end record;
  signal c : comb_type;

begin

  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      case cpu_l1mem_data_cache_ctrl_in.request is
        when cpu_l1mem_data_request_code_none |
             cpu_l1mem_data_request_code_load |
             cpu_l1mem_data_request_code_store |
             cpu_l1mem_data_request_code_invalidate |
             cpu_l1mem_data_request_code_flush |
             cpu_l1mem_data_request_code_writeback |
             cpu_l1mem_data_request_code_sync =>
          null;
        when others =>
          assert false
            report "cpu_l1mem_data_cache_ctrl_in.request invalid"
            severity failure;
      end case;
      case cpu_l1mem_data_cache_ctrl_in.request is
        when cpu_l1mem_data_request_code_load |
             cpu_l1mem_data_request_code_store =>
          assert not is_x(cpu_l1mem_data_cache_ctrl_in.cacheen)
            report "cpu_l1mem_data_cache_ctrl_in.cacheen invalid"
            severity failure;
        when others =>
          null;
      end case;
      case cpu_l1mem_data_cache_ctrl_in.request is
        when cpu_l1mem_data_request_code_load |
             cpu_l1mem_data_request_code_store |
             cpu_l1mem_data_request_code_invalidate |
             cpu_l1mem_data_request_code_flush |
             cpu_l1mem_data_request_code_writeback =>
          assert not is_x(cpu_l1mem_data_cache_ctrl_in.mmuen)
            report "cpu_l1mem_data_cache_ctrl_in.mmuen invalid"
            severity failure;
        when others =>
          null;
      end case;
      if cpu_l1mem_data_cache_ctrl_in.cacheen = '1' then
        case cpu_l1mem_data_cache_ctrl_in.request is
          when cpu_l1mem_data_request_code_load |
               cpu_l1mem_data_request_code_store =>
            assert not is_x(cpu_l1mem_data_cache_ctrl_in.be)
              report "cpu_l1mem_data_cache_ctrl_in.alloc invalid"
              severity failure;
            assert not is_x(cpu_l1mem_data_cache_ctrl_in.alloc)
              report "cpu_l1mem_data_cache_ctrl_in.alloc invalid"
              severity failure;
            assert not is_x(cpu_l1mem_data_cache_ctrl_in.writethrough)
              report "cpu_l1mem_data_cache_ctrl_in.writethrough invalid"
              severity failure;
          when others =>
            null;
        end case;
      end if;
    end if;
      
  end process;
  -- pragma translate_on
    
  ctrl : entity work.cpu_l1mem_data_cache_ctrl(rtl)
    port map (
      clk => clk,
      rstn => rstn,
      cpu_mmu_data_ctrl_in   => cpu_mmu_data_ctrl_in,
      cpu_mmu_data_ctrl_out   => cpu_mmu_data_ctrl_out,
    
      cpu_l1mem_data_cache_ctrl_out        => c.cpu_l1mem_data_cache_ctrl_out,
      cpu_l1mem_data_cache_ctrl_in         => cpu_l1mem_data_cache_ctrl_in,

      sys_master_ctrl_out             => c.sys_master_ctrl_out,
      sys_slave_ctrl_out              => sys_slave_ctrl_out,

      cpu_l1mem_data_cache_ctrl_out_vram => c.cpu_l1mem_data_cache_ctrl_out_vram,
      cpu_l1mem_data_cache_ctrl_in_vram => c.cpu_l1mem_data_cache_ctrl_in_vram,
      cpu_l1mem_data_cache_ctrl_out_mram => c.cpu_l1mem_data_cache_ctrl_out_mram,
      cpu_l1mem_data_cache_ctrl_in_mram => c.cpu_l1mem_data_cache_ctrl_in_mram,
      cpu_l1mem_data_cache_ctrl_out_tram => c.cpu_l1mem_data_cache_ctrl_out_tram,
      cpu_l1mem_data_cache_ctrl_out_dram => c.cpu_l1mem_data_cache_ctrl_out_dram,
      
      cpu_l1mem_data_cache_dp_in_ctrl => c.cpu_l1mem_data_cache_dp_in_ctrl,
      cpu_l1mem_data_cache_dp_out_ctrl => c.cpu_l1mem_data_cache_dp_out_ctrl,

      cpu_l1mem_data_cache_replace_ctrl_in => c.cpu_l1mem_data_cache_replace_ctrl_in,
      cpu_l1mem_data_cache_replace_ctrl_out => c.cpu_l1mem_data_cache_replace_ctrl_out
      );

  cpu_l1mem_data_cache_ctrl_out <= c.cpu_l1mem_data_cache_ctrl_out;
  sys_master_ctrl_out <= c.sys_master_ctrl_out;

  dp : entity work.cpu_l1mem_data_cache_dp(rtl)
    port map (
      clk => clk,
      rstn => rstn,
      cpu_mmu_data_dp_in   => cpu_mmu_data_dp_in,
      cpu_mmu_data_dp_out   => cpu_mmu_data_dp_out,
    
      cpu_l1mem_data_cache_dp_out        => c.cpu_l1mem_data_cache_dp_out,
      cpu_l1mem_data_cache_dp_in         => cpu_l1mem_data_cache_dp_in,

      sys_master_dp_out             => c.sys_master_dp_out,
      sys_slave_dp_out              => sys_slave_dp_out,

      cpu_l1mem_data_cache_dp_out_vram => c.cpu_l1mem_data_cache_dp_out_vram,
      cpu_l1mem_data_cache_dp_out_mram => c.cpu_l1mem_data_cache_dp_out_mram,
      cpu_l1mem_data_cache_dp_out_tram => c.cpu_l1mem_data_cache_dp_out_tram,
      cpu_l1mem_data_cache_dp_in_tram => c.cpu_l1mem_data_cache_dp_in_tram,
      cpu_l1mem_data_cache_dp_out_dram => c.cpu_l1mem_data_cache_dp_out_dram,
      cpu_l1mem_data_cache_dp_in_dram => c.cpu_l1mem_data_cache_dp_in_dram,
      
      cpu_l1mem_data_cache_dp_in_ctrl => c.cpu_l1mem_data_cache_dp_in_ctrl,
      cpu_l1mem_data_cache_dp_out_ctrl => c.cpu_l1mem_data_cache_dp_out_ctrl,

      cpu_l1mem_data_cache_replace_dp_in => c.cpu_l1mem_data_cache_replace_dp_in,
      cpu_l1mem_data_cache_replace_dp_out => c.cpu_l1mem_data_cache_replace_dp_out

      );

  cpu_l1mem_data_cache_dp_out <= c.cpu_l1mem_data_cache_dp_out;
  sys_master_dp_out <= c.sys_master_dp_out;

  replace : entity work.cpu_l1mem_data_cache_replace(rtl)
    port map (
      clk => clk,
      rstn => rstn,
      cpu_l1mem_data_cache_replace_ctrl_out => c.cpu_l1mem_data_cache_replace_ctrl_out,
      cpu_l1mem_data_cache_replace_ctrl_in => c.cpu_l1mem_data_cache_replace_ctrl_in,
      cpu_l1mem_data_cache_replace_dp_in => c.cpu_l1mem_data_cache_replace_dp_in,
      cpu_l1mem_data_cache_replace_dp_out => c.cpu_l1mem_data_cache_replace_dp_out
      );

  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      assert not is_x(c.cpu_l1mem_data_cache_replace_ctrl_in.re)
        report "replace re is invalid"
        severity failure;
      assert not is_x(c.cpu_l1mem_data_cache_replace_ctrl_in.we)
        report "replace we is invalid"
        severity failure;
      if c.cpu_l1mem_data_cache_replace_ctrl_in.re = '1' then
        assert not is_x(c.cpu_l1mem_data_cache_replace_dp_in.rindex)
          report "replace rindex is invalid"
          severity failure;
      end if;
      if c.cpu_l1mem_data_cache_replace_ctrl_in.we = '1' then
        assert not is_x(c.cpu_l1mem_data_cache_replace_dp_in.windex)
          report "replace windex is invalid"
          severity failure;
        assert not is_x(c.cpu_l1mem_data_cache_replace_dp_in.wstate)
          report "replace wstate is invalid"
          severity failure;
      end if;
    end if;
  end process;
  -- pragma translate_on

  vram : entity tech.syncram_1r1w(rtl)
    generic map (
      addr_bits => cpu_l1mem_data_cache_index_bits,
      data_bits => cpu_l1mem_data_cache_assoc
      )
    port map (
      clk => clk,
      re => c.cpu_l1mem_data_cache_ctrl_out_vram.re,
      we => c.cpu_l1mem_data_cache_ctrl_out_vram.we,
      raddr => c.cpu_l1mem_data_cache_dp_out_vram.raddr,
      rdata => c.cpu_l1mem_data_cache_ctrl_in_vram.rdata,
      waddr => c.cpu_l1mem_data_cache_dp_out_vram.waddr,
      wdata => c.cpu_l1mem_data_cache_ctrl_out_vram.wdata
      );

  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_vram.re)
        report "vram re is invalid"
        severity failure;
      assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_vram.we)
        report "vram we is invalid"
        severity failure;
      if c.cpu_l1mem_data_cache_ctrl_out_vram.re = '1' then
        assert not is_x(c.cpu_l1mem_data_cache_dp_out_vram.raddr)
          report "vram raddr is invalid"
          severity failure;
      end if;
      if c.cpu_l1mem_data_cache_ctrl_out_vram.we = '1' then
        assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_vram.wdata)
          report "vram wdata is invalid"
          severity failure;
        assert not is_x(c.cpu_l1mem_data_cache_dp_out_vram.waddr)
          report "vram waddr is invalid"
          severity failure;
      end if;
    end if;
  end process;
  -- pragma translate_on

  mram : entity tech.syncram_1r1w(rtl)
    generic map (
      addr_bits => cpu_l1mem_data_cache_index_bits,
      data_bits => cpu_l1mem_data_cache_assoc
      )
    port map (
      clk => clk,
      re => c.cpu_l1mem_data_cache_ctrl_out_mram.re,
      we => c.cpu_l1mem_data_cache_ctrl_out_mram.we,
      raddr => c.cpu_l1mem_data_cache_dp_out_mram.raddr,
      rdata => c.cpu_l1mem_data_cache_ctrl_in_mram.rdata,
      waddr => c.cpu_l1mem_data_cache_dp_out_mram.waddr,
      wdata => c.cpu_l1mem_data_cache_ctrl_out_mram.wdata
      );

  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_mram.re)
        report "mram re is invalid"
        severity failure;
      assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_mram.we)
        report "mram we is invalid"
        severity failure;
      if c.cpu_l1mem_data_cache_ctrl_out_mram.re = '1' then
        assert not is_x(c.cpu_l1mem_data_cache_dp_out_mram.raddr)
          report "mram raddr is invalid"
          severity failure;
      end if;
      if c.cpu_l1mem_data_cache_ctrl_out_mram.we = '1' then
        assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_mram.wdata)
          report "mram wdata is invalid"
          severity failure;
        assert not is_x(c.cpu_l1mem_data_cache_dp_out_mram.waddr)
          report "mram waddr is invalid"
          severity failure;
      end if;
    end if;
  end process;
  -- pragma translate_on

  tram : entity tech.syncram_banked_1rw(rtl)
    generic map (
      addr_bits => cpu_l1mem_data_cache_index_bits,
      word_bits => cpu_l1mem_data_cache_tag_bits,
      log2_banks => cpu_l1mem_data_cache_log2_assoc
      )
    port map (
      clk => clk,
      en => c.cpu_l1mem_data_cache_ctrl_out_tram.en,
      we => c.cpu_l1mem_data_cache_ctrl_out_tram.we,
      banken => c.cpu_l1mem_data_cache_ctrl_out_tram.banken,
      addr => c.cpu_l1mem_data_cache_dp_out_tram.addr,
      rdata => c.cpu_l1mem_data_cache_dp_in_tram.rdata,
      wdata => c.cpu_l1mem_data_cache_dp_out_tram.wdata
      );

  -- pragma translate_on
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_tram.en)
        report "tram en is invalid"
        severity failure;
      if c.cpu_l1mem_data_cache_ctrl_out_tram.en = '1' then
        assert not is_x(c.cpu_l1mem_data_cache_dp_out_tram.addr)
          report "tram addr is invalid"
          severity failure;
        assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_tram.banken)
          report "tram banken is invalid"
          severity failure;
        assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_tram.we)
          report "tram we is invalid"
          severity failure;
        if c.cpu_l1mem_data_cache_ctrl_out_tram.we = '1' then
          for n in cpu_l1mem_data_cache_assoc-1 downto 0 loop
            if c.cpu_l1mem_data_cache_ctrl_out_tram.banken(n) = '1' then
              assert not is_x(std_ulogic_vector2_slice2(c.cpu_l1mem_data_cache_dp_out_tram.wdata, n))
                report "tram wdata " & integer'image(n) & " is invalid"
                severity failure;
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process;
  -- pragma translate_on

  dram : entity tech.syncram_banked_1rw(rtl)
    generic map (
      addr_bits => cpu_l1mem_data_cache_index_bits + cpu_l1mem_data_cache_offset_bits - cpu_log2_word_bytes,
      word_bits => byte_bits,
      log2_banks => cpu_l1mem_data_cache_log2_assoc + cpu_log2_word_bytes
      )
    port map (
      clk => clk,
      en => c.cpu_l1mem_data_cache_ctrl_out_dram.en,
      we => c.cpu_l1mem_data_cache_ctrl_out_dram.we,
      banken => c.cpu_l1mem_data_cache_dp_out_dram.banken,
      addr => c.cpu_l1mem_data_cache_dp_out_dram.addr,
      rdata => c.cpu_l1mem_data_cache_dp_in_dram.rdata,
      wdata => c.cpu_l1mem_data_cache_dp_out_dram.wdata
      );

  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_dram.en)
        report "dram en is invalid"
        severity failure;
      if c.cpu_l1mem_data_cache_ctrl_out_dram.en = '1' then
        assert not is_x(c.cpu_l1mem_data_cache_dp_out_dram.addr)
          report "dram addr is invalid"
          severity failure;
        assert not is_x(c.cpu_l1mem_data_cache_dp_out_dram.banken)
          report "dram banken is invalid"
          severity failure;
        assert not is_x(c.cpu_l1mem_data_cache_ctrl_out_dram.we)
          report "dram we is invalid"
          severity failure;
        --if c.cpu_l1mem_data_cache_ctrl_out_dram.we = '1' then
        --  for n in cpu_l1mem_data_cache_assoc-1 downto 0 loop
        --    if c.cpu_l1mem_data_cache_ctrl_out_tram.banken(n) = '1' then
        --      assert not is_x(std_ulogic_vector2_slice2(c.cpu_l1mem_data_cache_dp_out_dram.wdata, n))
        --        report "dram wdata " & integer'image(n) & " is invalid"
        --        severity failure;
        --    end if;
        --  end loop;
        --end if;
      end if;
    end if;
  end process;
  -- pragma translate_on

  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      assert not is_x(sys_slave_ctrl_out.ready)
        report "sys_slave_ctrl_out.ready invalid"
        severity failure;
      if sys_slave_ctrl_out.ready = '1' then
        assert not is_x(sys_slave_ctrl_out.error)
          report "sys_slave_ctrl_out.error invalid"
          severity failure;
      end if;
      assert not is_x(c.sys_master_ctrl_out.request)
        report "sys_master_ctrl_out.request invalid"
        severity failure;
      if c.sys_master_ctrl_out.request = '1' then
        assert not is_x(c.sys_master_ctrl_out.be)
          report "sys_master_ctrl_out.be invalid"
          severity failure;
        assert not is_x(c.sys_master_ctrl_out.write)
          report "sys_master_ctrl_out.write invalid"
          severity failure;
        assert not is_x(c.sys_master_ctrl_out.cacheable)
          report "sys_master_ctrl_out.cacheable invalid"
          severity failure;
        assert not is_x(c.sys_master_ctrl_out.inst)
          report "sys_master_ctrl_out.inst invalid"
          severity failure;
        assert not is_x(c.sys_master_ctrl_out.burst)
          report "sys_master_ctrl_out.burst invalid"
          severity failure;
        if c.sys_master_ctrl_out.burst = '1' then
          assert not is_x(c.sys_master_ctrl_out.bwrap)
            report "sys_master_ctrl_out.bwrap invalid"
            severity failure;
          assert not is_x(c.sys_master_ctrl_out.bcycles)
            report "sys_master_ctrl_out.bcycles invalid"
            severity failure;
        end if;
        assert not is_x(c.sys_master_dp_out.paddr)
          report "sys_master_dp_out.paddr invalid"
          severity failure;
        assert not is_x(c.sys_master_dp_out.size)
          report "sys_master_dp_out.size invalid"
          severity failure;
      end if;
    end if;
  end process;
  -- pragma translate_on
  
end;
