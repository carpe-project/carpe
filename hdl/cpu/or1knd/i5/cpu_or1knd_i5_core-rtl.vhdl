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


library util;
use util.types_pkg.all;

library sys;
use sys.sys_pkg.all;

use work.cpu_or1knd_i5_mmu_inst_pkg.all;
use work.cpu_or1knd_i5_mmu_data_pkg.all;
use work.cpu_l1mem_inst_pkg.all;
use work.cpu_l1mem_data_pkg.all;
use work.cpu_or1knd_i5_pipe_pkg.all;

architecture rtl of cpu_or1knd_i5_core is

  type comb_type is record
    sys_master_ctrl_out_master : sys_master_ctrl_out_vector_type(1 downto 0);
    sys_master_dp_out_master   : sys_master_dp_out_vector_type(1 downto 0);
    sys_slave_ctrl_out_master  : sys_slave_ctrl_out_vector_type(1 downto 0);

    sys_master_ctrl_out : sys_master_ctrl_out_type;
    sys_master_dp_out   : sys_master_dp_out_type;
    
    cpu_l1mem_inst_ctrl_in       : cpu_l1mem_inst_ctrl_in_type;
    cpu_l1mem_inst_dp_in         : cpu_l1mem_inst_dp_in_type;
    cpu_l1mem_inst_ctrl_out        : cpu_l1mem_inst_ctrl_out_type;
    cpu_l1mem_inst_dp_out          : cpu_l1mem_inst_dp_out_type;

    cpu_l1mem_data_ctrl_in       : cpu_l1mem_data_ctrl_in_type;
    cpu_l1mem_data_dp_in         : cpu_l1mem_data_dp_in_type;
    cpu_l1mem_data_ctrl_out        : cpu_l1mem_data_ctrl_out_type;
    cpu_l1mem_data_dp_out          : cpu_l1mem_data_dp_out_type;
    
    cpu_or1knd_i5_mmu_inst_ctrl_in    : cpu_or1knd_i5_mmu_inst_ctrl_in_type;
    cpu_or1knd_i5_mmu_inst_dp_in      : cpu_or1knd_i5_mmu_inst_dp_in_type;
    cpu_or1knd_i5_mmu_inst_ctrl_out   : cpu_or1knd_i5_mmu_inst_ctrl_out_type;
    cpu_or1knd_i5_mmu_inst_dp_out     : cpu_or1knd_i5_mmu_inst_dp_out_type;
    
    cpu_or1knd_i5_mmu_data_ctrl_in    : cpu_or1knd_i5_mmu_data_ctrl_in_type;
    cpu_or1knd_i5_mmu_data_dp_in      : cpu_or1knd_i5_mmu_data_dp_in_type;
    cpu_or1knd_i5_mmu_data_ctrl_out   : cpu_or1knd_i5_mmu_data_ctrl_out_type;
    cpu_or1knd_i5_mmu_data_dp_out     : cpu_or1knd_i5_mmu_data_dp_out_type;

    cpu_or1knd_i5_mmu_inst_ctrl_in_pipe    : cpu_or1knd_i5_mmu_inst_ctrl_in_pipe_type;
    cpu_or1knd_i5_mmu_inst_dp_in_pipe      : cpu_or1knd_i5_mmu_inst_dp_in_pipe_type;
    cpu_or1knd_i5_mmu_inst_ctrl_out_pipe   : cpu_or1knd_i5_mmu_inst_ctrl_out_pipe_type;
    cpu_or1knd_i5_mmu_inst_dp_out_pipe     : cpu_or1knd_i5_mmu_inst_dp_out_pipe_type;
    
    cpu_or1knd_i5_mmu_data_ctrl_in_pipe    : cpu_or1knd_i5_mmu_data_ctrl_in_pipe_type;
    cpu_or1knd_i5_mmu_data_dp_in_pipe      : cpu_or1knd_i5_mmu_data_dp_in_pipe_type;
    cpu_or1knd_i5_mmu_data_ctrl_out_pipe   : cpu_or1knd_i5_mmu_data_ctrl_out_pipe_type;
    cpu_or1knd_i5_mmu_data_dp_out_pipe     : cpu_or1knd_i5_mmu_data_dp_out_pipe_type;

  end record;
  signal c : comb_type;
  
begin

  pipe : entity work.cpu_or1knd_i5_pipe(rtl)
    port map (
      clk                                  => clk,
      rstn                                 => rstn,
      
      cpu_l1mem_inst_ctrl_out      => c.cpu_l1mem_inst_ctrl_out,
      cpu_l1mem_data_ctrl_out      => c.cpu_l1mem_data_ctrl_out,
      cpu_l1mem_inst_dp_out        => c.cpu_l1mem_inst_dp_out,
      cpu_l1mem_data_dp_out        => c.cpu_l1mem_data_dp_out,
      cpu_l1mem_inst_ctrl_in     => c.cpu_l1mem_inst_ctrl_in,
      cpu_l1mem_data_ctrl_in     => c.cpu_l1mem_data_ctrl_in,
      cpu_l1mem_inst_dp_in       => c.cpu_l1mem_inst_dp_in,
      cpu_l1mem_data_dp_in       => c.cpu_l1mem_data_dp_in,
      cpu_or1knd_i5_mmu_inst_ctrl_in_pipe   => c.cpu_or1knd_i5_mmu_inst_ctrl_in_pipe,
      cpu_or1knd_i5_mmu_inst_dp_in_pipe     => c.cpu_or1knd_i5_mmu_inst_dp_in_pipe,
      cpu_or1knd_i5_mmu_inst_ctrl_out_pipe  => c.cpu_or1knd_i5_mmu_inst_ctrl_out_pipe,
      cpu_or1knd_i5_mmu_inst_dp_out_pipe    => c.cpu_or1knd_i5_mmu_inst_dp_out_pipe,
      cpu_or1knd_i5_mmu_data_ctrl_in_pipe   => c.cpu_or1knd_i5_mmu_data_ctrl_in_pipe,
      cpu_or1knd_i5_mmu_data_dp_in_pipe     => c.cpu_or1knd_i5_mmu_data_dp_in_pipe,
      cpu_or1knd_i5_mmu_data_ctrl_out_pipe  => c.cpu_or1knd_i5_mmu_data_ctrl_out_pipe,
      cpu_or1knd_i5_mmu_data_dp_out_pipe    => c.cpu_or1knd_i5_mmu_data_dp_out_pipe
      );

  l1mem_inst : entity work.cpu_l1mem_inst(rtl)
    port map (
      clk                                   => clk,
      rstn                                  => rstn,
      
      cpu_mmu_inst_ctrl_in => c.cpu_or1knd_i5_mmu_inst_ctrl_in,
      cpu_mmu_inst_dp_in   => c.cpu_or1knd_i5_mmu_inst_dp_in,
      cpu_mmu_inst_ctrl_out => c.cpu_or1knd_i5_mmu_inst_ctrl_out,
      cpu_mmu_inst_dp_out   => c.cpu_or1knd_i5_mmu_inst_dp_out,
      
      cpu_l1mem_inst_ctrl_in      => c.cpu_l1mem_inst_ctrl_in,
      cpu_l1mem_inst_dp_in        => c.cpu_l1mem_inst_dp_in,
      cpu_l1mem_inst_ctrl_out       => c.cpu_l1mem_inst_ctrl_out,
      cpu_l1mem_inst_dp_out         => c.cpu_l1mem_inst_dp_out,

      sys_master_ctrl_out           => c.sys_master_ctrl_out_master(0),
      sys_master_dp_out             => c.sys_master_dp_out_master(0),
      sys_slave_ctrl_out            => c.sys_slave_ctrl_out_master(0),
      sys_slave_dp_out              => sys_slave_dp_out
      );

  l1mem_data : entity work.cpu_l1mem_data(rtl)
    port map (
      clk                                   => clk,
      rstn                                  => rstn,
      
      cpu_mmu_data_ctrl_in => c.cpu_or1knd_i5_mmu_data_ctrl_in,
      cpu_mmu_data_dp_in   => c.cpu_or1knd_i5_mmu_data_dp_in,
      cpu_mmu_data_ctrl_out => c.cpu_or1knd_i5_mmu_data_ctrl_out,
      cpu_mmu_data_dp_out   => c.cpu_or1knd_i5_mmu_data_dp_out,
      
      cpu_l1mem_data_ctrl_in      => c.cpu_l1mem_data_ctrl_in,
      cpu_l1mem_data_dp_in        => c.cpu_l1mem_data_dp_in,
      cpu_l1mem_data_ctrl_out       => c.cpu_l1mem_data_ctrl_out,
      cpu_l1mem_data_dp_out         => c.cpu_l1mem_data_dp_out,

      sys_master_ctrl_out           => c.sys_master_ctrl_out_master(1),
      sys_master_dp_out             => c.sys_master_dp_out_master(1),
      sys_slave_ctrl_out            => c.sys_slave_ctrl_out_master(1),
      sys_slave_dp_out              => sys_slave_dp_out
      );

  mmu_inst : entity work.cpu_or1knd_i5_mmu_inst(rtl)
    port map (
      clk                                   => clk,
      rstn                                  => rstn,
      
      cpu_or1knd_i5_mmu_inst_ctrl_in   => c.cpu_or1knd_i5_mmu_inst_ctrl_in,
      cpu_or1knd_i5_mmu_inst_dp_in     => c.cpu_or1knd_i5_mmu_inst_dp_in,
      cpu_or1knd_i5_mmu_inst_ctrl_out  => c.cpu_or1knd_i5_mmu_inst_ctrl_out,
      cpu_or1knd_i5_mmu_inst_dp_out    => c.cpu_or1knd_i5_mmu_inst_dp_out,
      
      cpu_or1knd_i5_mmu_inst_ctrl_in_pipe   => c.cpu_or1knd_i5_mmu_inst_ctrl_in_pipe,
      cpu_or1knd_i5_mmu_inst_dp_in_pipe     => c.cpu_or1knd_i5_mmu_inst_dp_in_pipe,
      cpu_or1knd_i5_mmu_inst_ctrl_out_pipe  => c.cpu_or1knd_i5_mmu_inst_ctrl_out_pipe,
      cpu_or1knd_i5_mmu_inst_dp_out_pipe    => c.cpu_or1knd_i5_mmu_inst_dp_out_pipe
      );

  mmu_data : entity work.cpu_or1knd_i5_mmu_data(rtl)
    port map (
      clk                                   => clk,
      rstn                                  => rstn,
      
      cpu_or1knd_i5_mmu_data_ctrl_in   => c.cpu_or1knd_i5_mmu_data_ctrl_in,
      cpu_or1knd_i5_mmu_data_dp_in     => c.cpu_or1knd_i5_mmu_data_dp_in,
      cpu_or1knd_i5_mmu_data_ctrl_out  => c.cpu_or1knd_i5_mmu_data_ctrl_out,
      cpu_or1knd_i5_mmu_data_dp_out    => c.cpu_or1knd_i5_mmu_data_dp_out,
      
      cpu_or1knd_i5_mmu_data_ctrl_in_pipe   => c.cpu_or1knd_i5_mmu_data_ctrl_in_pipe,
      cpu_or1knd_i5_mmu_data_dp_in_pipe     => c.cpu_or1knd_i5_mmu_data_dp_in_pipe,
      cpu_or1knd_i5_mmu_data_ctrl_out_pipe  => c.cpu_or1knd_i5_mmu_data_ctrl_out_pipe,
      cpu_or1knd_i5_mmu_data_dp_out_pipe    => c.cpu_or1knd_i5_mmu_data_dp_out_pipe
      );

  arb : entity sys.sys_master_arb(rtl)
    generic map (
      masters => 2
      )
    port map (
      clk                        => clk,
      rstn                       => rstn,
      
      sys_master_ctrl_out_master => c.sys_master_ctrl_out_master,
      sys_master_dp_out_master   => c.sys_master_dp_out_master,
      sys_slave_ctrl_out_master  => c.sys_slave_ctrl_out_master,
      
      sys_slave_ctrl_out_sys         => sys_slave_ctrl_out,
      sys_master_ctrl_out_sys        => c.sys_master_ctrl_out,
      sys_master_dp_out_sys          => c.sys_master_dp_out
      );

  sys_master_ctrl_out <= c.sys_master_ctrl_out;
  sys_master_dp_out <= c.sys_master_dp_out;

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
        for n in sys_transfer_size_bits-1 downto 2 loop
          assert c.sys_master_dp_out.size(n) = '0'
            report "sys_master_dp_out.size invalid"
            severity failure;
        end loop;
        --case c.sys_master_dp_out.size(1 downto 0) is
        --  when "00" =>
        --    if c.sys_master_ctrl_out.write = '1' then
        --      assert not is_x(c.sys_master_dp_out.data(7 downto 0))
        --        report "sys_master_dp_out.data invalid"
        --        severity failure;
        --    end if;
        --  when "01" =>
        --    if c.sys_master_ctrl_out.write = '1' then
        --      assert not is_x(c.sys_master_dp_out.data(15 downto 0))
        --        report "sys_master_dp_out.data invalid"
        --        severity failure;
        --    end if;
        --  when "10" =>
        --    if c.sys_master_ctrl_out.write = '1' then
        --      assert not is_x(c.sys_master_dp_out.data(31 downto 0))
        --        report "sys_master_dp_out.data invalid"
        --        severity failure;
        --    end if;
        --  when others =>
        --    assert not false
        --      report "sys_master_dp_out.size invalid"
        --      severity failure;
        --end case;
      end if;
    end if;
  end process;
  -- pragma translate_on

end;
