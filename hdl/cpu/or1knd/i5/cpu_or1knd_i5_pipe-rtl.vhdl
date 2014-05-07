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

library tech;

-- pragma translate_off
library sim;
-- pragma translate_on

use work.cpu_bpb_pkg.all;
use work.cpu_btb_pkg.all;
use work.cpu_or1knd_i5_config_pkg.all;
use work.cpu_or1knd_i5_pipe_pkg.all;

architecture rtl of cpu_or1knd_i5_pipe is

  signal cpu_or1knd_i5_pipe_ctrl_in_misc  : cpu_or1knd_i5_pipe_ctrl_in_misc_type;
  signal cpu_or1knd_i5_pipe_ctrl_out_misc : cpu_or1knd_i5_pipe_ctrl_out_misc_type;

  signal cpu_or1knd_i5_pipe_dp_in_ctrl  : cpu_or1knd_i5_pipe_dp_in_ctrl_type;
  signal cpu_or1knd_i5_pipe_dp_out_ctrl : cpu_or1knd_i5_pipe_dp_out_ctrl_type;
  signal cpu_or1knd_i5_pipe_dp_in_misc  : cpu_or1knd_i5_pipe_dp_in_misc_type;
  signal cpu_or1knd_i5_pipe_dp_out_misc : cpu_or1knd_i5_pipe_dp_out_misc_type;

  signal cpu_bpb_ctrl_in                : cpu_bpb_ctrl_in_type;
  signal cpu_bpb_dp_in                  : cpu_bpb_dp_in_type;
  signal cpu_bpb_ctrl_out               : cpu_bpb_ctrl_out_type;
  signal cpu_bpb_dp_out                 : cpu_bpb_dp_out_type;

  signal cpu_btb_ctrl_in                : cpu_btb_ctrl_in_type;
  signal cpu_btb_dp_in                  : cpu_btb_dp_in_type;
  signal cpu_btb_ctrl_out               : cpu_btb_ctrl_out_type;
  signal cpu_btb_dp_out                 : cpu_btb_dp_out_type;

  type comb_type is record
    shifter_shift : std_ulogic_vector(or1k_shift_bits downto 0);
    m_madd_result : std_ulogic_vector(2*or1k_word_bits-1 downto 0);
  end record;
  signal c : comb_type;

begin

  c.shifter_shift <= '0' & cpu_or1knd_i5_pipe_dp_out_misc.e_alu_src2(or1k_shift_bits-1 downto 0);

  bpb : entity work.cpu_bpb(rtl)
    port map (
      clk                              => clk,
      rstn                             => rstn,
      cpu_bpb_ctrl_in                  => cpu_bpb_ctrl_in,
      cpu_bpb_dp_in                    => cpu_bpb_dp_in,
      cpu_bpb_ctrl_out                 => cpu_bpb_ctrl_out,
      cpu_bpb_dp_out                   => cpu_bpb_dp_out
      );

  btb : entity work.cpu_btb(rtl)
    port map (
      clk                              => clk,
      rstn                             => rstn,
      cpu_btb_ctrl_in                  => cpu_btb_ctrl_in,
      cpu_btb_dp_in                    => cpu_btb_dp_in,
      cpu_btb_ctrl_out                 => cpu_btb_ctrl_out,
      cpu_btb_dp_out                   => cpu_btb_dp_out
      );

  ctrl : entity work.cpu_or1knd_i5_pipe_ctrl(rtl)
    port map (
      clk                              => clk,
      rstn                             => rstn,
      cpu_or1knd_i5_pipe_ctrl_in_misc    => cpu_or1knd_i5_pipe_ctrl_in_misc,
      cpu_or1knd_i5_pipe_ctrl_out_misc   => cpu_or1knd_i5_pipe_ctrl_out_misc,
      cpu_or1knd_i5_pipe_dp_in_ctrl    => cpu_or1knd_i5_pipe_dp_in_ctrl,
      cpu_or1knd_i5_pipe_dp_out_ctrl   => cpu_or1knd_i5_pipe_dp_out_ctrl,
      cpu_l1mem_inst_ctrl_out  => cpu_l1mem_inst_ctrl_out,
      cpu_l1mem_inst_ctrl_in => cpu_l1mem_inst_ctrl_in,
      cpu_l1mem_data_ctrl_out  => cpu_l1mem_data_ctrl_out,
      cpu_l1mem_data_ctrl_in => cpu_l1mem_data_ctrl_in,
      cpu_or1knd_i5_mmu_inst_ctrl_out_pipe => cpu_or1knd_i5_mmu_inst_ctrl_out_pipe,
      cpu_or1knd_i5_mmu_inst_ctrl_in_pipe => cpu_or1knd_i5_mmu_inst_ctrl_in_pipe,
      cpu_or1knd_i5_mmu_data_ctrl_out_pipe => cpu_or1knd_i5_mmu_data_ctrl_out_pipe,
      cpu_or1knd_i5_mmu_data_ctrl_in_pipe => cpu_or1knd_i5_mmu_data_ctrl_in_pipe,
      cpu_bpb_ctrl_in                  => cpu_bpb_ctrl_in,
      cpu_bpb_ctrl_out                 => cpu_bpb_ctrl_out,
      cpu_btb_ctrl_in                  => cpu_btb_ctrl_in,
      cpu_btb_ctrl_out                 => cpu_btb_ctrl_out
      );

  dp : entity work.cpu_or1knd_i5_pipe_dp(rtl)
    port map (
      clk                              => clk,
      cpu_or1knd_i5_pipe_dp_in_ctrl    => cpu_or1knd_i5_pipe_dp_in_ctrl,
      cpu_or1knd_i5_pipe_dp_out_ctrl   => cpu_or1knd_i5_pipe_dp_out_ctrl,
      cpu_or1knd_i5_pipe_dp_in_misc    => cpu_or1knd_i5_pipe_dp_in_misc,
      cpu_or1knd_i5_pipe_dp_out_misc   => cpu_or1knd_i5_pipe_dp_out_misc,
      cpu_l1mem_inst_dp_out    => cpu_l1mem_inst_dp_out,
      cpu_l1mem_inst_dp_in   => cpu_l1mem_inst_dp_in,
      cpu_l1mem_data_dp_out    => cpu_l1mem_data_dp_out,
      cpu_l1mem_data_dp_in   => cpu_l1mem_data_dp_in,
      cpu_or1knd_i5_mmu_inst_dp_out_pipe => cpu_or1knd_i5_mmu_inst_dp_out_pipe,
      cpu_or1knd_i5_mmu_inst_dp_in_pipe => cpu_or1knd_i5_mmu_inst_dp_in_pipe,
      cpu_or1knd_i5_mmu_data_dp_out_pipe => cpu_or1knd_i5_mmu_data_dp_out_pipe,
      cpu_or1knd_i5_mmu_data_dp_in_pipe => cpu_or1knd_i5_mmu_data_dp_in_pipe,
      cpu_bpb_dp_in                    => cpu_bpb_dp_in,
      cpu_bpb_dp_out                   => cpu_bpb_dp_out,
      cpu_btb_dp_in                    => cpu_btb_dp_in,
      cpu_btb_dp_out                   => cpu_btb_dp_out
      );

  addsub : entity tech.addsub(rtl)
    generic map (
      src_bits => or1k_word_bits
      )
    port map (
      sub     => cpu_or1knd_i5_pipe_ctrl_out_misc.e_addsub_sub,
      carryin => cpu_or1knd_i5_pipe_ctrl_out_misc.e_addsub_carryin,
      src1    => cpu_or1knd_i5_pipe_dp_out_misc.e_alu_src1,
      src2    => cpu_or1knd_i5_pipe_dp_out_misc.e_alu_src2,
      result    => cpu_or1knd_i5_pipe_dp_in_misc.e_addsub_result,
      carryout => cpu_or1knd_i5_pipe_ctrl_in_misc.e_addsub_carryout,
      overflow => cpu_or1knd_i5_pipe_ctrl_in_misc.e_addsub_overflow
      );

  shifter : entity tech.shifter(rtl)
    generic map (
      src_bits   => or1k_word_bits,
      shift_bits => or1k_shift_bits
      )
    port map (
      right  => cpu_or1knd_i5_pipe_ctrl_out_misc.e_shifter_right,
      rot    => cpu_or1knd_i5_pipe_ctrl_out_misc.e_shifter_rot,
      unsgnd => cpu_or1knd_i5_pipe_ctrl_out_misc.e_shifter_unsgnd,
      src    => cpu_or1knd_i5_pipe_dp_out_misc.e_alu_src1,
      shift  => c.shifter_shift,
      shift_unsgnd => '1',
      result => cpu_or1knd_i5_pipe_dp_in_misc.e_shifter_result
      );

  madd_enable_gen : if cpu_or1knd_i5_madd_enable generate
    madd : entity tech.madd_seq(rtl)
      generic map (
        latency => cpu_or1knd_i5_madd_latency,
        src1_bits => or1k_word_bits,
        src2_bits => or1k_word_bits
        )
      port map (
        clk => clk,
        rstn => rstn,
        en => cpu_or1knd_i5_pipe_ctrl_out_misc.e_mul_en,
        unsgnd => cpu_or1knd_i5_pipe_ctrl_out_misc.e_mul_unsgnd,
        sub => cpu_or1knd_i5_pipe_ctrl_out_misc.e_madd_sub,
        acc => cpu_or1knd_i5_pipe_dp_out_misc.e_madd_acc,
        src1 => cpu_or1knd_i5_pipe_dp_out_misc.e_alu_src1,
        src2 => cpu_or1knd_i5_pipe_dp_out_misc.e_alu_src2,
        valid => cpu_or1knd_i5_pipe_ctrl_in_misc.m_mul_valid,
        result => c.m_madd_result,
        overflow => cpu_or1knd_i5_pipe_ctrl_in_misc.m_madd_overflow
        );
    cpu_or1knd_i5_pipe_dp_in_misc.m_mul_result <= c.m_madd_result(or1k_word_bits-1 downto 0);
    cpu_or1knd_i5_pipe_dp_in_misc.m_madd_result_hi <= c.m_madd_result(2*or1k_word_bits-1 downto or1k_word_bits);
  end generate;
  
  mul_enable_gen : if cpu_or1knd_i5_mul_enable generate
    mul : entity tech.mul_trunc_seq(rtl)
      generic map (
        latency => cpu_or1knd_i5_mul_latency,
        src_bits => or1k_word_bits
        )
      port map (
        clk => clk,
        rstn => rstn,
        en => cpu_or1knd_i5_pipe_ctrl_out_misc.e_mul_en,
        unsgnd => cpu_or1knd_i5_pipe_ctrl_out_misc.e_mul_unsgnd,
        src1 => cpu_or1knd_i5_pipe_dp_out_misc.e_alu_src1,
        src2 => cpu_or1knd_i5_pipe_dp_out_misc.e_alu_src2,
        valid => cpu_or1knd_i5_pipe_ctrl_in_misc.m_mul_valid,
        overflow => cpu_or1knd_i5_pipe_ctrl_in_misc.m_mul_overflow,
        result => cpu_or1knd_i5_pipe_dp_in_misc.m_mul_result
        );
  end generate;

  div : entity tech.div_seq(rtl)
    generic map (
      latency => cpu_or1knd_i5_div_latency,
      src1_bits => or1k_word_bits,
      src2_bits => or1k_word_bits
      )
    port map (
      clk => clk,
      rstn => rstn,
      en => cpu_or1knd_i5_pipe_ctrl_out_misc.e_div_en,
      unsgnd => cpu_or1knd_i5_pipe_ctrl_out_misc.e_div_unsgnd,
      src1 => cpu_or1knd_i5_pipe_dp_out_misc.e_alu_src1,
      src2 => cpu_or1knd_i5_pipe_dp_out_misc.e_alu_src2,
      valid => cpu_or1knd_i5_pipe_ctrl_in_misc.m_div_valid,
      dbz => cpu_or1knd_i5_pipe_ctrl_in_misc.m_div_dbz,
      overflow => cpu_or1knd_i5_pipe_ctrl_in_misc.m_div_overflow,
      result => cpu_or1knd_i5_pipe_dp_in_misc.m_div_result
      );

  regfile : entity tech.syncram_2r1w(rtl)
    generic map (
      addr_bits => or1k_rfaddr_bits,
      data_bits => or1k_word_bits,
      write_first => true
      )
    port map (
      clk => clk,
      we => cpu_or1knd_i5_pipe_ctrl_out_misc.regfile_we,
      waddr => cpu_or1knd_i5_pipe_dp_out_misc.regfile_waddr,
      wdata => cpu_or1knd_i5_pipe_dp_out_misc.regfile_wdata,
      re1 => cpu_or1knd_i5_pipe_ctrl_out_misc.regfile_re1,
      raddr1 => cpu_or1knd_i5_pipe_dp_out_misc.regfile_raddr1,
      rdata1 => cpu_or1knd_i5_pipe_dp_in_misc.regfile_rdata1,
      re2 => cpu_or1knd_i5_pipe_ctrl_out_misc.regfile_re2,
      raddr2 => cpu_or1knd_i5_pipe_dp_out_misc.regfile_raddr2,
      rdata2 => cpu_or1knd_i5_pipe_dp_in_misc.regfile_rdata2
      );

-- pragma translate_off
  regfile_we_watch : block
    signal watch_data : std_ulogic_vector(0 downto 0);
  begin
    watch_data <= (0 => cpu_or1knd_i5_pipe_ctrl_out_misc.regfile_we);
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => cpu_or1knd_i5_pipe'path_name,
        name => "regfile_we",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;

  regfile_waddr_watch : block
    signal watch_data : std_ulogic_vector(cpu_or1knd_i5_pipe_dp_out_misc.regfile_waddr'length-1 downto 0);
  begin
    watch_data <= cpu_or1knd_i5_pipe_dp_out_misc.regfile_waddr;
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => cpu_or1knd_i5_pipe'path_name,
        name => "regfile_waddr",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;

  regfile_wdata_watch : block
    signal watch_data : std_ulogic_vector(cpu_or1knd_i5_pipe_dp_out_misc.regfile_wdata'length-1 downto 0);
  begin
    watch_data <= cpu_or1knd_i5_pipe_dp_out_misc.regfile_wdata;
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => cpu_or1knd_i5_pipe'path_name,
        name => "regfile_wdata",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;
  
  regfile_re1_watch : block
    signal watch_data : std_ulogic_vector(0 downto 0);
  begin
    watch_data <= (0 => cpu_or1knd_i5_pipe_ctrl_out_misc.regfile_re1);
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => cpu_or1knd_i5_pipe'path_name,
        name => "regfile_re1",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;

  regfile_raddr1_watch : block
    signal watch_data : std_ulogic_vector(cpu_or1knd_i5_pipe_dp_out_misc.regfile_raddr1'length-1 downto 0);
  begin
    watch_data <= cpu_or1knd_i5_pipe_dp_out_misc.regfile_raddr1;
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => cpu_or1knd_i5_pipe'path_name,
        name => "regfile_raddr1",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;

  regfile_rdata1_watch : block
    signal watch_data : std_ulogic_vector(cpu_or1knd_i5_pipe_dp_in_misc.regfile_rdata1'length-1 downto 0);
  begin
    watch_data <= cpu_or1knd_i5_pipe_dp_in_misc.regfile_rdata1;
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => cpu_or1knd_i5_pipe'path_name,
        name => "regfile_rdata1",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;
  
  regfile_re2_watch : block
    signal watch_data : std_ulogic_vector(0 downto 0);
  begin
    watch_data <= (0 => cpu_or1knd_i5_pipe_ctrl_out_misc.regfile_re2);
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => cpu_or1knd_i5_pipe'path_name,
        name => "regfile_re2",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;

  regfile_raddr2_watch : block
    signal watch_data : std_ulogic_vector(cpu_or1knd_i5_pipe_dp_out_misc.regfile_raddr2'length-1 downto 0);
  begin
    watch_data <= cpu_or1knd_i5_pipe_dp_out_misc.regfile_raddr2;
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => cpu_or1knd_i5_pipe'path_name,
        name => "regfile_raddr2",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;

  regfile_rdata2_watch : block
    signal watch_data : std_ulogic_vector(cpu_or1knd_i5_pipe_dp_in_misc.regfile_rdata2'length-1 downto 0);
  begin
    watch_data <= cpu_or1knd_i5_pipe_dp_in_misc.regfile_rdata2;
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => cpu_or1knd_i5_pipe'path_name,
        name => "regfile_rdata2",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;
  
-- pragma translate_on
    
end;
