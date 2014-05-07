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
use util.numeric_pkg.all;
use util.types_pkg.all;
-- pragma translate_off
use util.names_pkg.all;
-- pragma translate_on

library isa;
use isa.or1k_pkg.all;

-- pragma translate_off
library sim;
use sim.monitor_pkg.all;
-- pragma translate_on

use work.cpu_or1knd_i5_pkg.all;
use work.cpu_or1knd_i5_config_pkg.all;
use work.cpu_or1knd_i5_pipe_pkg.all;
use work.cpu_bpb_pkg.all;
use work.cpu_btb_pkg.all;

architecture rtl of cpu_or1knd_i5_pipe_dp is

  type spr_type is record
    sys_eear0 : or1k_vaddr_type;
    sys_epcr0 : or1k_ivaddr_type;
    mac_maclo : or1k_spr_data_type;
    mac_machi : or1k_spr_data_type;
  end record;
  constant spr_init : spr_type := (
    sys_eear0 => (others => '0'),
    sys_epcr0 => (others => '0'),
    mac_maclo => (others => '0'),
    mac_machi => (others => '0')
    );

  type reg_f_type is record
    pc : or1k_ivaddr_type;
  end record;
  
  type reg_d_type is record
    pc : or1k_ivaddr_type;
    pc_incr : or1k_ivaddr_type;
    inst_bus_error_eear : or1k_ipaddr_type;
    inst : or1k_inst_type;
    bpb_state : cpu_bpb_state_type;
    btb_state : cpu_btb_state_type;
    btb_target : or1k_ivaddr_type;
  end record;
  constant reg_d_x : reg_d_type := (
    pc => (others => 'X'),
    pc_incr => (others => 'X'),
    inst_bus_error_eear => (others => 'X'),
    inst => (others => 'X'),
    bpb_state => (others => 'X'),
    btb_state => (others => 'X'),
    btb_target => (others => 'X')
    );
  
  type reg_e_type is record
    pc : or1k_ivaddr_type;
    pc_incr : or1k_ivaddr_type;
    inst_bus_error_eear : or1k_ipaddr_type;
    inst : or1k_inst_type;
    bpb_state : cpu_bpb_state_type;
    btb_state : cpu_btb_state_type;
    btb_target : or1k_ivaddr_type;
    ra : or1k_rfaddr_type;
    rb : or1k_rfaddr_type;
    rd : or1k_rfaddr_type;
    alu_src1 : or1k_word_type;
    alu_src2 : or1k_word_type;
    st_data : or1k_word_type;
  end record;
  constant reg_e_x : reg_e_type := (
    pc => (others => 'X'),
    pc_incr => (others => 'X'),
    inst_bus_error_eear => (others => 'X'),
    inst => (others => 'X'),
    bpb_state => (others => 'X'),
    btb_state => (others => 'X'),
    btb_target => (others => 'X'),
    ra => (others => 'X'),
    rb => (others => 'X'),
    rd => (others => 'X'),
    alu_src1 => (others => 'X'),
    alu_src2 => (others => 'X'),
    st_data => (others => 'X')
    );

  type reg_m_type is record
    pc : or1k_ivaddr_type;
    pc_incr : or1k_ivaddr_type;
    inst_bus_error_eear : or1k_ipaddr_type;
    inst : or1k_inst_type;
    ra : or1k_rfaddr_type;
    rb : or1k_rfaddr_type;
    rd : or1k_rfaddr_type;
    addr : or1k_vaddr_type;
    alu_result : or1k_word_type;
    mtspr_data : or1k_spr_data_type;
  end record;
  constant reg_m_x : reg_m_type := (
    pc => (others => 'X'),
    pc_incr => (others => 'X'),
    inst_bus_error_eear => (others => 'X'),
    inst => (others => 'X'),
    ra => (others => 'X'),
    rb => (others => 'X'),
    rd => (others => 'X'),
    addr => (others => 'X'),
    alu_result => (others => 'X'),
    mtspr_data => (others => 'X')
    );

  type reg_w_type is record
    rd_data : or1k_word_type;
  end record;
  constant reg_w_x : reg_w_type := (
    rd_data => (others => 'X')
    );

  type reg_p_type is record
    spr : spr_type;
    f_btb_target_buffer  : or1k_ivaddr_type;
    f_inst_buffer : or1k_inst_type;
    f_btb_state_buffer : cpu_btb_state_type;
    f_bpb_state_buffer : cpu_bpb_state_type;
    f_inst_bus_error_eear_buffer : or1k_ipaddr_type;
    m_load_buffer : or1k_word_type;
    m_data_bus_error_eear_buffer : or1k_paddr_type;
  end record;
  constant reg_p_init : reg_p_type := (
    spr => (
      sys_eear0  => (others => '0'),
      sys_epcr0 => (others => '0'),
      mac_maclo => (others => 'X'),
      mac_machi => (others => 'X')
      ),
    f_btb_target_buffer  => (others => 'X'),
    f_inst_buffer => (others => 'X'),
    f_btb_state_buffer => (others => 'X'),
    f_bpb_state_buffer => (others => 'X'),
    f_inst_bus_error_eear_buffer => (others => 'X'),
    m_load_buffer => (others => 'X'),
    m_data_bus_error_eear_buffer => (others => 'X')
    );
      
  type reg_type is record
    f : reg_f_type;
    d : reg_d_type;
    e : reg_e_type;
    m : reg_m_type;
    w : reg_w_type;
    p : reg_p_type;
  end record;

  type comb_type is record
    bf_pc                        : or1k_ivaddr_type;

    f_pc_incr                    : or1k_ivaddr_type;
    f_btb_target                 : or1k_ivaddr_type;
    f_btb_state                  : cpu_btb_state_type;
    f_bpb_state                  : cpu_bpb_state_type;
    f_inst                       : or1k_inst_type;
    f_ra                         : or1k_rfaddr_type;
    f_rb                         : or1k_rfaddr_type;
    f_inst_bus_error_eear        : or1k_ipaddr_type;

    d_ra                         : or1k_rfaddr_type;
    d_rb                         : or1k_rfaddr_type;
    d_rd                         : or1k_rfaddr_type;
    d_ra_data                    : or1k_word_type;
    d_rb_data                    : or1k_word_type;
    d_depends_ra_e               : std_ulogic;
    d_depends_rb_e               : std_ulogic;
    d_depends_ra_m               : std_ulogic;
    d_depends_rb_m               : std_ulogic;
    d_imm_contig                 : or1k_imm_type;
    d_imm_split                  : or1k_imm_type;
    d_imm_toc_offset             : or1k_toc_offset_type;
    d_imm                        : or1k_word_type;
    d_alu_src1                   : or1k_word_type;
    d_alu_src2                   : or1k_word_type;
    d_st_data                    : or1k_word_type;

    e_alu_src1                   : or1k_word_type;
    e_alu_src2                   : or1k_word_type;
    e_cmov_result                : or1k_word_type;
    e_ff1_result                 : or1k_word_type;
    e_fl1_result                 : or1k_word_type;
    e_ext_result                 : or1k_word_type;
    e_alu_result                 : or1k_word_type;
    e_ldst_size                  : cpu_or1knd_i5_data_size_type;
    e_ldst_addr                  : or1k_vaddr_type;
    e_ldst_misaligned            : std_ulogic;
    e_madd_acc                   : or1k_dword_type;
    e_st_data                    : or1k_word_type;
    e_not_equal                  : std_ulogic;
    e_lt_tmp                     : std_ulogic;
    e_lts                        : std_ulogic;
    e_ltu                        : std_ulogic;
    e_direct_toc_target          : or1k_ivaddr_type;
    e_indir_toc_target           : or1k_ivaddr_type;
    e_toc_target                 : or1k_ivaddr_type;
    e_toc_target_misaligned      : std_ulogic;
    e_btb_mispred         : std_ulogic;

    e_mtspr_data                 : or1k_spr_data_type;
    e_addr                       : or1k_vaddr_type;
    e_spr_addr                   : or1k_word_type;
    e_spr_group                  : or1k_spr_group_type;
    e_spr_index                  : or1k_spr_index_type;
    e_spr_group_sys              : std_ulogic;
    e_spr_group_dmmu             : std_ulogic;
    e_spr_group_immu             : std_ulogic;
    e_spr_group_dcache           : std_ulogic;
    e_spr_group_icache           : std_ulogic;
    e_spr_group_mac              : std_ulogic;
    e_spr_index_sys_vr           : std_ulogic;
    e_spr_index_sys_upr          : std_ulogic;
    e_spr_index_sys_cpucfgr      : std_ulogic;
    e_spr_index_sys_dmmucfgr     : std_ulogic;
    e_spr_index_sys_immucfgr     : std_ulogic;
    e_spr_index_sys_dccfgr       : std_ulogic;
    e_spr_index_sys_iccfgr       : std_ulogic;
    e_spr_index_sys_dcfgr        : std_ulogic;
    e_spr_index_sys_pccfgr       : std_ulogic;
    e_spr_index_sys_npc          : std_ulogic;
    e_spr_index_sys_aecr         : std_ulogic;
    e_spr_index_sys_aesr         : std_ulogic;
    e_spr_index_sys_sr           : std_ulogic;
    e_spr_index_sys_ppc          : std_ulogic;
    e_spr_index_sys_fpcsr        : std_ulogic;
    e_spr_index_sys_epcr0        : std_ulogic;
    e_spr_index_sys_eear0        : std_ulogic;
    e_spr_index_sys_esr0         : std_ulogic;
    e_spr_index_sys_gpr          : std_ulogic;
    e_spr_index_dmmu_dmmucr      : std_ulogic;
    e_spr_index_dmmu_dmmupr      : std_ulogic;
    e_spr_index_dmmu_dtlbeir     : std_ulogic;
    e_spr_index_dmmu_datbmr      : std_ulogic;
    e_spr_index_dmmu_datbtr      : std_ulogic;
    e_spr_index_dmmu_dtlbwmr_way : std_ulogic_vector(or1k_tlb_ways-1 downto 0);
    e_spr_index_dmmu_dtlbwtr_way : std_ulogic_vector(or1k_tlb_ways-1 downto 0);
    e_spr_index_dmmu_dtlbwmr     : std_ulogic;
    e_spr_index_dmmu_dtlbwtr     : std_ulogic;
    e_spr_index_immu_immucr      : std_ulogic;
    e_spr_index_immu_immupr      : std_ulogic;
    e_spr_index_immu_itlbeir     : std_ulogic;
    e_spr_index_immu_iatbmr      : std_ulogic;
    e_spr_index_immu_iatbtr      : std_ulogic;
    e_spr_index_immu_itlbwmr_way : std_ulogic_vector(or1k_tlb_ways-1 downto 0);
    e_spr_index_immu_itlbwtr_way : std_ulogic_vector(or1k_tlb_ways-1 downto 0);
    e_spr_index_immu_itlbwmr     : std_ulogic;
    e_spr_index_immu_itlbwtr     : std_ulogic;
    e_spr_index_dcache_dcbfr     : std_ulogic;
    e_spr_index_dcache_dcbir     : std_ulogic;
    e_spr_index_dcache_dcbwr     : std_ulogic;
    e_spr_index_icache_icbir     : std_ulogic;
    e_spr_index_mac_maclo        : std_ulogic;
    e_spr_index_mac_machi        : std_ulogic;

    e_spr_atb_index              : or1k_atb_index_type;
    e_spr_tlb_way                : or1k_tlb_way_type;
    
    e_spr_addr_sel               : cpu_or1knd_i5_spr_addr_sel_type;
    e_spr_addr_valid             : std_ulogic;

    m_load_data                  : or1k_word_type;
    m_load_data_prebuffer        : or1k_word_type;
    m_data_bus_error_eear        : or1k_paddr_type;
    m_rd_data                    : or1k_word_type;
    m_spr_sys_eear0              : or1k_vaddr_type;
    m_spr_sys_epcr0              : or1k_ivaddr_type;
    m_spr_mac_maclo              : or1k_spr_data_type;
    m_spr_mac_machi              : or1k_spr_data_type;
    m_madd_result_hi_zeros               : std_ulogic;
    m_madd_result_hi_ones                : std_ulogic;
    m_mul_result_msb                 : std_ulogic;
    m_mfspr_data                 : or1k_spr_data_type;
    m_exception                  : or1k_exception_type;
    m_exception_pc               : or1k_ivaddr_type;

    regfile_raddr1               : or1k_rfaddr_type;
    regfile_raddr2               : or1k_rfaddr_type;
    regfile_waddr                : or1k_rfaddr_type;
    regfile_wdata                : or1k_word_type;

    l1mem_inst_vaddr             : or1k_ivaddr_type;
    l1mem_data_vaddr             : or1k_vaddr_type;
    l1mem_data_size              : cpu_or1knd_i5_data_size_type;
    
  end record;

  signal r, r_next : reg_type;
  signal c : comb_type;

  pure function ff1(v : or1k_word_type) return or1k_word_type is
    variable ret : or1k_word_type;
  begin
    ret := std_ulogic_vector(to_unsigned(0, or1k_word_bits));
    for n in 0 to or1k_word_bits-1 loop
      case v(n) is
        when '0' =>
        when '1' =>
          ret := std_ulogic_vector(to_unsigned(n+1, or1k_word_bits));
          exit;
        when others =>
          ret := (others => 'X');
          exit;
      end case;
    end loop;
    return ret;
  end function;

  pure function fl1(v : or1k_word_type) return or1k_word_type is
    variable ret : or1k_word_type;
  begin
    ret := std_ulogic_vector(to_unsigned(0, or1k_word_bits));
    for n in or1k_word_bits-1 downto 0 loop
      case v(n) is
        when '0' =>
        when '1' =>
          ret := std_ulogic_vector(to_unsigned(n+1, or1k_word_bits));
          exit;
        when others =>
          ret := (others => 'X');
          exit;
      end case;
    end loop;
    return ret;
  end function;

begin

  ------------------
  -- memory stage --
  ------------------
  with cpu_or1knd_i5_pipe_dp_in_ctrl.m_exception_sel select
    c.m_exception <= or1k_exception_reset    when cpu_or1knd_i5_m_exception_sel_reset,
                     or1k_exception_bus      when cpu_or1knd_i5_m_exception_sel_bus,
                     or1k_exception_dpf      when cpu_or1knd_i5_m_exception_sel_dpf,
                     or1k_exception_ipf      when cpu_or1knd_i5_m_exception_sel_ipf,
                     or1k_exception_tti      when cpu_or1knd_i5_m_exception_sel_tti,
                     or1k_exception_align    when cpu_or1knd_i5_m_exception_sel_align,
                     or1k_exception_ill      when cpu_or1knd_i5_m_exception_sel_ill,
                     or1k_exception_ext      when cpu_or1knd_i5_m_exception_sel_ext,
                     or1k_exception_dtlbmiss when cpu_or1knd_i5_m_exception_sel_dtlbmiss,
                     or1k_exception_itlbmiss when cpu_or1knd_i5_m_exception_sel_itlbmiss,
                     or1k_exception_range    when cpu_or1knd_i5_m_exception_sel_range,
                     or1k_exception_syscall  when cpu_or1knd_i5_m_exception_sel_syscall,
                     or1k_exception_fp       when cpu_or1knd_i5_m_exception_sel_fp,
                     or1k_exception_trap     when cpu_or1knd_i5_m_exception_sel_trap,
                     (others => 'X')         when others;
    
  c.m_exception_pc <= ((29 => cpu_or1knd_i5_pipe_dp_in_ctrl.p_spr_sys_sr_eph,
                        28 downto 10 => '0'
                        ) &
                       c.m_exception &
                       (5 downto 0 => '0')
                       );

  m_mfspr_data_madd_enable_gen : if cpu_or1knd_i5_madd_enable generate
    with cpu_or1knd_i5_pipe_dp_in_ctrl.m_mfspr_data_sel select
      c.m_mfspr_data <= cpu_or1knd_i5_pipe_dp_in_ctrl.m_mfspr_data                   when cpu_or1knd_i5_m_mfspr_data_sel_ctrl,
                        cpu_or1knd_i5_spr_sys_vr                                     when cpu_or1knd_i5_m_mfspr_data_sel_sys_vr,
                        cpu_or1knd_i5_spr_sys_upr                                    when cpu_or1knd_i5_m_mfspr_data_sel_sys_upr,
                        cpu_or1knd_i5_spr_sys_cpucfgr                                when cpu_or1knd_i5_m_mfspr_data_sel_sys_cpucfgr,
                        cpu_or1knd_i5_spr_sys_dmmucfgr                               when cpu_or1knd_i5_m_mfspr_data_sel_sys_dmmucfgr,
                        cpu_or1knd_i5_spr_sys_immucfgr                               when cpu_or1knd_i5_m_mfspr_data_sel_sys_immucfgr,
                        cpu_or1knd_i5_spr_sys_dccfgr                                 when cpu_or1knd_i5_m_mfspr_data_sel_sys_dccfgr,
                        cpu_or1knd_i5_spr_sys_iccfgr                                 when cpu_or1knd_i5_m_mfspr_data_sel_sys_iccfgr,
                        r.p.spr.sys_eear0                                            when cpu_or1knd_i5_m_mfspr_data_sel_sys_eear0,
                        r.p.spr.sys_epcr0 & (or1k_log2_inst_bytes-1 downto 0 => '0') when cpu_or1knd_i5_m_mfspr_data_sel_sys_epcr0,
                        cpu_or1knd_i5_pipe_dp_in_misc.regfile_rdata1                 when cpu_or1knd_i5_m_mfspr_data_sel_sys_gpr,
                        r.p.spr.mac_maclo                                            when cpu_or1knd_i5_m_mfspr_data_sel_mac_maclo,
                        r.p.spr.mac_machi                                            when cpu_or1knd_i5_m_mfspr_data_sel_mac_machi,
                        (others => 'X')                                              when others;
  end generate;

  m_mfspr_data_madd_disable_gen : if not cpu_or1knd_i5_madd_enable generate
    with cpu_or1knd_i5_pipe_dp_in_ctrl.m_mfspr_data_sel select
      c.m_mfspr_data <= cpu_or1knd_i5_pipe_dp_in_ctrl.m_mfspr_data                   when cpu_or1knd_i5_m_mfspr_data_sel_ctrl,
                        cpu_or1knd_i5_spr_sys_vr                                     when cpu_or1knd_i5_m_mfspr_data_sel_sys_vr,
                        cpu_or1knd_i5_spr_sys_upr                                    when cpu_or1knd_i5_m_mfspr_data_sel_sys_upr,
                        cpu_or1knd_i5_spr_sys_cpucfgr                                when cpu_or1knd_i5_m_mfspr_data_sel_sys_cpucfgr,
                        cpu_or1knd_i5_spr_sys_dmmucfgr                               when cpu_or1knd_i5_m_mfspr_data_sel_sys_dmmucfgr,
                        cpu_or1knd_i5_spr_sys_immucfgr                               when cpu_or1knd_i5_m_mfspr_data_sel_sys_immucfgr,
                        cpu_or1knd_i5_spr_sys_dccfgr                                 when cpu_or1knd_i5_m_mfspr_data_sel_sys_dccfgr,
                        cpu_or1knd_i5_spr_sys_iccfgr                                 when cpu_or1knd_i5_m_mfspr_data_sel_sys_iccfgr,
                        r.p.spr.sys_eear0                                            when cpu_or1knd_i5_m_mfspr_data_sel_sys_eear0,
                        r.p.spr.sys_epcr0 & (or1k_log2_inst_bytes-1 downto 0 => '0') when cpu_or1knd_i5_m_mfspr_data_sel_sys_epcr0,
                        cpu_or1knd_i5_pipe_dp_in_misc.regfile_rdata1                 when cpu_or1knd_i5_m_mfspr_data_sel_sys_gpr,
                        (others => 'X')                                              when others;
  end generate;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.m_data_size_sel select
    c.m_load_data_prebuffer <= ((31 downto 8  => cpu_l1mem_data_dp_out.data(7) and cpu_or1knd_i5_pipe_dp_in_ctrl.m_sext) &
                                cpu_l1mem_data_dp_out.data(7 downto 0)
                                ) when cpu_or1knd_i5_data_size_sel_byte,
                               ((31 downto 16 => cpu_l1mem_data_dp_out.data(15) and cpu_or1knd_i5_pipe_dp_in_ctrl.m_sext) &
                                cpu_l1mem_data_dp_out.data(15 downto 0)
                                ) when cpu_or1knd_i5_data_size_sel_half,
                               cpu_l1mem_data_dp_out.data when cpu_or1knd_i5_data_size_sel_word,
                               (others => 'X') when others;
  
  with cpu_or1knd_i5_pipe_dp_in_ctrl.m_load_data_buffered select
    c.m_load_data <= c.m_load_data_prebuffer when '0',
                     r.p.m_load_buffer       when '1',
                     (others => 'X')         when others;
  with cpu_or1knd_i5_pipe_dp_in_ctrl.m_load_data_buffered select
    c.m_data_bus_error_eear <= cpu_l1mem_data_dp_out.paddr      when '0',
                               r.p.m_data_bus_error_eear_buffer when '1',
                               (others => 'X')                  when others;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.m_rd_data_sel select
    c.m_rd_data <= r.m.alu_result                                         when cpu_or1knd_i5_rd_data_sel_alu,
                   c.m_load_data                                          when cpu_or1knd_i5_rd_data_sel_load,
                   c.m_mfspr_data                                         when cpu_or1knd_i5_rd_data_sel_mfspr,
                   cpu_or1knd_i5_pipe_dp_in_misc.m_mul_result             when cpu_or1knd_i5_rd_data_sel_mul,
                   cpu_or1knd_i5_pipe_dp_in_misc.m_div_result             when cpu_or1knd_i5_rd_data_sel_div,
                   r.m.pc_incr & (or1k_log2_inst_bytes-1 downto 0 => '0') when cpu_or1knd_i5_rd_data_sel_pc_incr,
                   r.p.spr.mac_maclo                                      when cpu_or1knd_i5_rd_data_sel_maclo,
                   (others => 'X')                                        when others;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.m_spr_sys_eear0_sel select
    c.m_spr_sys_eear0 <= (others => '0')                                     when cpu_or1knd_i5_m_spr_sys_eear0_sel_init,
                         r.m.mtspr_data                                      when cpu_or1knd_i5_m_spr_sys_eear0_sel_mtspr,
                         r.m.pc & (or1k_log2_inst_bytes-1 downto 0 => '0')   when cpu_or1knd_i5_m_spr_sys_eear0_sel_pc,
                         r.m.addr                                            when cpu_or1knd_i5_m_spr_sys_eear0_sel_addr,
                         (c.f_inst_bus_error_eear(or1k_spr_data_bits-or1k_log2_inst_bytes-1 downto 0) &
                          (or1k_log2_inst_bytes-1 downto 0 => '0'))          when cpu_or1knd_i5_m_spr_sys_eear0_sel_inst_bus_error_eear,
                         c.m_data_bus_error_eear(or1k_spr_data_bits-1 downto 0)   when cpu_or1knd_i5_m_spr_sys_eear0_sel_data_bus_error_eear,
                         (others => 'X')                                     when others;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.m_spr_sys_epcr0_sel select
    c.m_spr_sys_epcr0 <= (others => '0')                                              when cpu_or1knd_i5_m_spr_sys_epcr0_sel_init,
                         r.m.mtspr_data(or1k_word_bits-1 downto or1k_log2_inst_bytes) when cpu_or1knd_i5_m_spr_sys_epcr0_sel_mtspr,
                         r.f.pc                                                       when cpu_or1knd_i5_m_spr_sys_epcr0_sel_f_pc,
                         r.d.pc                                                       when cpu_or1knd_i5_m_spr_sys_epcr0_sel_d_pc,
                         r.e.pc                                                       when cpu_or1knd_i5_m_spr_sys_epcr0_sel_e_pc,
                         r.m.pc                                                       when cpu_or1knd_i5_m_spr_sys_epcr0_sel_m_pc,
                         (others => 'X') when others;

  m_madd_result_enabled_gen : if cpu_or1knd_i5_madd_enable generate
    with cpu_or1knd_i5_pipe_dp_in_ctrl.m_spr_mac_maclo_sel select
      c.m_spr_mac_maclo <= r.m.mtspr_data                             when cpu_or1knd_i5_m_spr_mac_maclo_sel_mtspr,
                           (others => '0')                            when cpu_or1knd_i5_m_spr_mac_maclo_sel_clear,
                           cpu_or1knd_i5_pipe_dp_in_misc.m_mul_result when cpu_or1knd_i5_m_spr_mac_maclo_sel_madd,
                           (others => 'X')                            when others;
      
    with cpu_or1knd_i5_pipe_dp_in_ctrl.m_spr_mac_machi_sel select
      c.m_spr_mac_machi <= r.m.mtspr_data                                 when cpu_or1knd_i5_m_spr_mac_machi_sel_mtspr,
                           (others => '0')                                when cpu_or1knd_i5_m_spr_mac_machi_sel_clear,
                           cpu_or1knd_i5_pipe_dp_in_misc.m_madd_result_hi when cpu_or1knd_i5_m_spr_mac_machi_sel_madd,
                           (others => 'X')                                when others;

    c.m_madd_result_hi_zeros <= all_zeros(cpu_or1knd_i5_pipe_dp_in_misc.m_madd_result_hi);
    c.m_madd_result_hi_ones  <= all_ones(cpu_or1knd_i5_pipe_dp_in_misc.m_madd_result_hi);
    c.m_mul_result_msb   <= cpu_or1knd_i5_pipe_dp_in_misc.m_mul_result(or1k_word_bits-1);
  end generate;

  -------------------
  -- execute stage --
  -------------------
  with cpu_or1knd_i5_pipe_dp_in_ctrl.e_fwd_alu_src1_sel select
    c.e_alu_src1 <= r.e.alu_src1    when cpu_or1knd_i5_e_fwd_alu_src_sel_none,
                    r.m.alu_result  when cpu_or1knd_i5_e_fwd_alu_src_sel_m_alu_result,
                    r.w.rd_data     when cpu_or1knd_i5_e_fwd_alu_src_sel_w_rd_data,
                    (others => 'X') when others;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.e_fwd_alu_src2_sel select
    c.e_alu_src2 <= r.e.alu_src2    when cpu_or1knd_i5_e_fwd_alu_src_sel_none,
                    r.m.alu_result  when cpu_or1knd_i5_e_fwd_alu_src_sel_m_alu_result,
                    r.w.rd_data     when cpu_or1knd_i5_e_fwd_alu_src_sel_w_rd_data,
                    (others => 'X') when others;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.e_fwd_st_data_sel select
    c.e_st_data <= r.e.st_data     when cpu_or1knd_i5_e_fwd_st_data_sel_none,
                   c.m_rd_data     when cpu_or1knd_i5_e_fwd_st_data_sel_m_rd_data,
                   r.w.rd_data     when cpu_or1knd_i5_e_fwd_st_data_sel_w_rd_data,
                   (others => 'X') when others;

  c.e_cmov_result <= logic_if(cpu_or1knd_i5_pipe_dp_in_ctrl.e_spr_sys_sr_f, c.e_alu_src1, c.e_alu_src2);
  c.e_ff1_result <= ff1(c.e_alu_src1);
  c.e_fl1_result <= fl1(c.e_alu_src1);

  with cpu_or1knd_i5_pipe_dp_in_ctrl.e_data_size_sel select
    c.e_ext_result <= ((31 downto 8 => cpu_or1knd_i5_pipe_dp_in_ctrl.e_sext and c.e_alu_src1(7)) &
                       c.e_alu_src1(7 downto 0)
                       ) when cpu_or1knd_i5_data_size_sel_byte,
                      ((31 downto 16 => cpu_or1knd_i5_pipe_dp_in_ctrl.e_sext and c.e_alu_src1(15)) &
                       c.e_alu_src1(15 downto 0)
                       ) when cpu_or1knd_i5_data_size_sel_half,
                      c.e_alu_src1 when cpu_or1knd_i5_data_size_sel_word,
                      (others => 'X') when others;

  c.e_not_equal             <= any_ones(c.e_alu_src1 xor c.e_alu_src2);

  c.e_lt_tmp <= (not (c.e_alu_src1(or1k_word_bits-1) xor c.e_alu_src2(or1k_word_bits-1))) and cpu_or1knd_i5_pipe_dp_in_misc.e_addsub_result(or1k_word_bits-1);
  c.e_ltu <= ((not c.e_alu_src1(or1k_word_bits-1)) and c.e_alu_src2(or1k_word_bits-1)) or c.e_lt_tmp;
  c.e_lts <= (c.e_alu_src1(or1k_word_bits-1) and (not c.e_alu_src2(or1k_word_bits-1))) or c.e_lt_tmp;
  
  -- need to drop the *top* two bits from the adder result, because we
  -- dropped the bottom two bits *before* feeding into the adder
  c.e_direct_toc_target     <= cpu_or1knd_i5_pipe_dp_in_misc.e_addsub_result(or1k_ivaddr_bits-1 downto 0);
  c.e_indir_toc_target      <= c.e_alu_src2(or1k_vaddr_bits-1 downto or1k_log2_inst_bytes);
  c.e_toc_target_misaligned <= cpu_or1knd_i5_pipe_dp_in_ctrl.e_toc_indir and any_ones(c.e_alu_src2(or1k_log2_inst_bytes-1 downto 0));

  with cpu_or1knd_i5_pipe_dp_in_ctrl.e_toc_indir select
    c.e_toc_target <= c.e_direct_toc_target when '0',
                      c.e_indir_toc_target  when '1',
                      (others => 'X')       when others;
  c.e_btb_mispred <= logic_ne(r.e.btb_target, c.e_toc_target);

  with cpu_or1knd_i5_pipe_dp_in_ctrl.e_alu_result_sel select
    c.e_alu_result <= cpu_or1knd_i5_pipe_dp_in_misc.e_addsub_result      when cpu_or1knd_i5_alu_result_sel_addsub,
                      cpu_or1knd_i5_pipe_dp_in_misc.e_shifter_result     when cpu_or1knd_i5_alu_result_sel_shifter,
                      c.e_alu_src1 and c.e_alu_src2                      when cpu_or1knd_i5_alu_result_sel_and,
                      c.e_alu_src1 or c.e_alu_src2                       when cpu_or1knd_i5_alu_result_sel_or,
                      c.e_alu_src1 xor c.e_alu_src2                      when cpu_or1knd_i5_alu_result_sel_xor,
                      c.e_cmov_result                                    when cpu_or1knd_i5_alu_result_sel_cmov,
                      c.e_ff1_result                                     when cpu_or1knd_i5_alu_result_sel_ff1,
                      c.e_fl1_result                                     when cpu_or1knd_i5_alu_result_sel_fl1,
                      c.e_ext_result                                     when cpu_or1knd_i5_alu_result_sel_ext,
                      r.e.alu_src2(15 downto 0) & (15 downto 0 => '0')   when cpu_or1knd_i5_alu_result_sel_movhi,
                      (others => 'X')                                    when others;

    -- load/store always uses immediate second argument, no forwarding
  with cpu_or1knd_i5_pipe_dp_in_ctrl.e_data_size_sel select
    c.e_ldst_size <= "00" when cpu_or1knd_i5_data_size_sel_byte,
                     "01" when cpu_or1knd_i5_data_size_sel_half,
                     "10" when cpu_or1knd_i5_data_size_sel_word,
                     "XX" when others;
  c.e_ldst_addr <= std_ulogic_vector(signed(c.e_alu_src1) + signed((or1k_word_bits-1 downto 16 => r.e.alu_src2(15)) & r.e.alu_src2(15 downto 0)));
  c.e_ldst_misaligned <= (
      (cpu_or1knd_i5_pipe_dp_in_ctrl.e_data_size_sel(cpu_or1knd_i5_data_size_sel_index_half) and c.e_ldst_addr(0)) or
      (cpu_or1knd_i5_pipe_dp_in_ctrl.e_data_size_sel(cpu_or1knd_i5_data_size_sel_index_word) and (c.e_ldst_addr(0) or c.e_ldst_addr(1)))
      );

  -- SPR access always uses immediate second argument, no forwarding
  c.e_spr_addr <= c.e_alu_src1 or ((or1k_word_bits-1 downto 16 => '0') & r.e.alu_src2(15 downto 0));
  c.e_spr_group <= c.e_spr_addr(or1k_spr_addr_bits-1 downto or1k_spr_index_bits);
  c.e_spr_index <= c.e_spr_addr(or1k_spr_index_bits-1 downto 0);

  -- decode SPR address
  c.e_spr_group_sys          <= logic_eq(c.e_spr_group, or1k_spr_group_sys);
  c.e_spr_group_dmmu         <= logic_eq(c.e_spr_group, or1k_spr_group_dmmu);
  c.e_spr_group_immu         <= logic_eq(c.e_spr_group, or1k_spr_group_immu);
  c.e_spr_group_dcache       <= logic_eq(c.e_spr_group, or1k_spr_group_dcache);
  c.e_spr_group_icache       <= logic_eq(c.e_spr_group, or1k_spr_group_icache);
  c.e_spr_group_mac          <= logic_eq(c.e_spr_group, or1k_spr_group_mac);

  c.e_spr_index_sys_vr       <= logic_eq(c.e_spr_index, or1k_spr_index_sys_vr);
  c.e_spr_index_sys_upr      <= logic_eq(c.e_spr_index, or1k_spr_index_sys_upr);
  c.e_spr_index_sys_cpucfgr  <= logic_eq(c.e_spr_index, or1k_spr_index_sys_cpucfgr);
  c.e_spr_index_sys_dmmucfgr <= logic_eq(c.e_spr_index, or1k_spr_index_sys_dmmucfgr);
  c.e_spr_index_sys_immucfgr <= logic_eq(c.e_spr_index, or1k_spr_index_sys_immucfgr);
  c.e_spr_index_sys_dccfgr   <= logic_eq(c.e_spr_index, or1k_spr_index_sys_dccfgr);
  c.e_spr_index_sys_iccfgr   <= logic_eq(c.e_spr_index, or1k_spr_index_sys_iccfgr);
  c.e_spr_index_sys_dcfgr    <= logic_eq(c.e_spr_index, or1k_spr_index_sys_dcfgr);
  c.e_spr_index_sys_pccfgr   <= logic_eq(c.e_spr_index, or1k_spr_index_sys_pccfgr);
  c.e_spr_index_sys_aecr     <= logic_eq(c.e_spr_index, or1k_spr_index_sys_aecr);
  c.e_spr_index_sys_aesr     <= logic_eq(c.e_spr_index, or1k_spr_index_sys_aesr);
  c.e_spr_index_sys_npc      <= logic_eq(c.e_spr_index, or1k_spr_index_sys_npc);
  c.e_spr_index_sys_sr       <= logic_eq(c.e_spr_index, or1k_spr_index_sys_sr);
  c.e_spr_index_sys_ppc      <= logic_eq(c.e_spr_index, or1k_spr_index_sys_ppc);
  c.e_spr_index_sys_fpcsr    <= logic_eq(c.e_spr_index, or1k_spr_index_sys_fpcsr);
  c.e_spr_index_sys_epcr0    <= logic_eq(c.e_spr_index,
                                         (or1k_spr_index_sys_epcr_base(or1k_spr_index_bits-1 downto or1k_spr_index_sys_epcr_index_bits) &
                                          std_ulogic_vector(to_unsigned(0, or1k_spr_index_sys_epcr_index_bits))));
  c.e_spr_index_sys_eear0    <= logic_eq(c.e_spr_index,
                                         (or1k_spr_index_sys_eear_base(or1k_spr_index_bits-1 downto or1k_spr_index_sys_eear_index_bits) &
                                          std_ulogic_vector(to_unsigned(0, or1k_spr_index_sys_eear_index_bits))));
  c.e_spr_index_sys_esr0     <= logic_eq(c.e_spr_index,
                                         (or1k_spr_index_sys_esr_base(or1k_spr_index_bits-1 downto or1k_spr_index_sys_esr_index_bits) &
                                          std_ulogic_vector(to_unsigned(0, or1k_spr_index_sys_esr_index_bits))));
  c.e_spr_index_sys_gpr      <= logic_eq(c.e_spr_index(or1k_spr_index_bits-1 downto or1k_rfaddr_bits),
                                         (or1k_spr_index_sys_gpr_base(or1k_spr_index_bits-1 downto or1k_spr_index_sys_gpr_index_bits) &
                                          (or1k_spr_index_sys_gpr_index_bits-1 downto or1k_rfaddr_bits => '0')));

  c.e_spr_index_dmmu_dmmucr  <= logic_eq(c.e_spr_index, or1k_spr_index_dmmu_dmmucr);
  c.e_spr_index_dmmu_dmmupr  <= logic_eq(c.e_spr_index, or1k_spr_index_dmmu_dmmupr);
  c.e_spr_index_dmmu_dtlbeir <= logic_eq(c.e_spr_index, or1k_spr_index_dmmu_dtlbeir);
  c.e_spr_index_dmmu_datbmr  <= logic_eq(c.e_spr_index(or1k_spr_index_bits-1 downto or1k_spr_index_dmmu_datbmr_index_bits),
                                         or1k_spr_index_dmmu_datbmr_base(or1k_spr_index_bits-1 downto or1k_spr_index_dmmu_datbmr_index_bits));
  c.e_spr_index_dmmu_datbtr  <= logic_eq(c.e_spr_index(or1k_spr_index_bits-1 downto or1k_spr_index_dmmu_datbtr_index_bits),
                                         or1k_spr_index_dmmu_datbtr_base(or1k_spr_index_bits-1 downto or1k_spr_index_dmmu_datbtr_index_bits));
  spr_dmmu_loop : for w in 0 to or1k_tlb_ways-1 generate
    c.e_spr_index_dmmu_dtlbwmr_way(w) <= logic_eq(c.e_spr_index(or1k_spr_index_bits-1 downto or1k_spr_index_dmmu_dtlbwmr_index_bits),
                                                  std_ulogic_vector(unsigned(or1k_spr_index_dmmu_dtlbwmr_base(or1k_spr_index_bits-1 downto or1k_tlb_index_bits)) +
                                                                    unsigned((or1k_spr_index_bits-1 downto or1k_tlb_way_bits+or1k_tlb_index_bits+1 => '0') &
                                                                             to_unsigned(w, or1k_tlb_way_bits) &
                                                                             '0')));
    c.e_spr_index_dmmu_dtlbwtr_way(w) <= logic_eq(c.e_spr_index(or1k_spr_index_bits-1 downto or1k_spr_index_dmmu_dtlbwtr_index_bits),
                                                  std_ulogic_vector(unsigned(or1k_spr_index_dmmu_dtlbwtr_base(or1k_spr_index_bits-1 downto or1k_tlb_index_bits)) +
                                                                    unsigned((or1k_spr_index_bits-1 downto or1k_tlb_way_bits+or1k_tlb_index_bits+1 => '0') &
                                                                             to_unsigned(w, or1k_tlb_way_bits) &
                                                                             '0')));
  end generate;
  c.e_spr_index_dmmu_dtlbwmr <= reduce_or(c.e_spr_index_dmmu_dtlbwmr_way);
  c.e_spr_index_dmmu_dtlbwtr <= reduce_or(c.e_spr_index_dmmu_dtlbwtr_way);

  c.e_spr_index_immu_immucr  <= logic_eq(c.e_spr_index, or1k_spr_index_immu_immucr);
  c.e_spr_index_immu_immupr  <= logic_eq(c.e_spr_index, or1k_spr_index_immu_immupr);
  c.e_spr_index_immu_itlbeir <= logic_eq(c.e_spr_index, or1k_spr_index_immu_itlbeir);
  c.e_spr_index_immu_iatbmr  <= logic_eq(c.e_spr_index(or1k_spr_index_bits-1 downto or1k_spr_index_immu_iatbmr_index_bits),
                                         or1k_spr_index_immu_iatbmr_base(or1k_spr_index_bits-1 downto or1k_spr_index_immu_iatbmr_index_bits));
  c.e_spr_index_immu_iatbtr  <= logic_eq(c.e_spr_index(or1k_spr_index_bits-1 downto or1k_spr_index_immu_iatbtr_index_bits),
                                         or1k_spr_index_immu_iatbtr_base(or1k_spr_index_bits-1 downto or1k_spr_index_immu_iatbtr_index_bits));
  spr_immu_loop : for w in 0 to or1k_tlb_ways-1 generate
    c.e_spr_index_immu_itlbwmr_way(w) <= logic_eq(c.e_spr_index(or1k_spr_index_bits-1 downto or1k_spr_index_immu_itlbwmr_index_bits),
                                                  std_ulogic_vector(unsigned(or1k_spr_index_immu_itlbwmr_base(or1k_spr_index_bits-1 downto or1k_tlb_index_bits)) +
                                                                    unsigned((or1k_spr_index_bits-1 downto or1k_tlb_way_bits+or1k_tlb_index_bits+1 => '0') &
                                                                             to_unsigned(w, or1k_tlb_way_bits) &
                                                                             '0')));
    c.e_spr_index_immu_itlbwtr_way(w) <= logic_eq(c.e_spr_index(or1k_spr_index_bits-1 downto or1k_spr_index_immu_itlbwtr_index_bits),
                                                  std_ulogic_vector(unsigned(or1k_spr_index_immu_itlbwtr_base(or1k_spr_index_bits-1 downto or1k_tlb_index_bits)) +
                                                                    unsigned((or1k_spr_index_bits-1 downto or1k_tlb_way_bits+or1k_tlb_index_bits+1 => '0') &
                                                                             to_unsigned(w, or1k_tlb_way_bits) &
                                                                             '0')));
  end generate;
  c.e_spr_index_immu_itlbwmr <= reduce_or(c.e_spr_index_immu_itlbwmr_way);
  c.e_spr_index_immu_itlbwtr <= reduce_or(c.e_spr_index_immu_itlbwtr_way);

  c.e_spr_index_dcache_dcbfr <= logic_eq(c.e_spr_index, or1k_spr_index_dcache_dcbfr);
  c.e_spr_index_dcache_dcbir <= logic_eq(c.e_spr_index, or1k_spr_index_dcache_dcbir);
  c.e_spr_index_dcache_dcbwr <= logic_eq(c.e_spr_index, or1k_spr_index_dcache_dcbwr);
  
  c.e_spr_index_icache_icbir <= logic_eq(c.e_spr_index, or1k_spr_index_icache_icbir);
  
  e_spr_index_mac_gen : if cpu_or1knd_i5_madd_enable generate
    c.e_spr_index_mac_maclo    <= logic_eq(c.e_spr_index, or1k_spr_index_mac_maclo);
    c.e_spr_index_mac_machi    <= logic_eq(c.e_spr_index, or1k_spr_index_mac_machi);
  end generate;
  
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_vr)       <= (c.e_spr_group_sys    and c.e_spr_index_sys_vr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_upr)      <= (c.e_spr_group_sys    and c.e_spr_index_sys_upr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_cpucfgr)  <= (c.e_spr_group_sys    and c.e_spr_index_sys_cpucfgr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dmmucfgr) <= (c.e_spr_group_sys    and c.e_spr_index_sys_dmmucfgr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_immucfgr) <= (c.e_spr_group_sys    and c.e_spr_index_sys_immucfgr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dccfgr)   <= (c.e_spr_group_sys    and c.e_spr_index_sys_dccfgr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_iccfgr)   <= (c.e_spr_group_sys    and c.e_spr_index_sys_iccfgr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dcfgr)    <= (c.e_spr_group_sys    and c.e_spr_index_sys_dcfgr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_pccfgr)   <= (c.e_spr_group_sys    and c.e_spr_index_sys_pccfgr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aecr)     <= (c.e_spr_group_sys    and c.e_spr_index_sys_aecr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aesr)     <= (c.e_spr_group_sys    and c.e_spr_index_sys_aesr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_npc)      <= (c.e_spr_group_sys    and c.e_spr_index_sys_npc);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_sr)       <= (c.e_spr_group_sys    and c.e_spr_index_sys_sr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_ppc)      <= (c.e_spr_group_sys    and c.e_spr_index_sys_ppc);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_fpcsr)    <= (c.e_spr_group_sys    and c.e_spr_index_sys_fpcsr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_epcr0)    <= (c.e_spr_group_sys    and c.e_spr_index_sys_epcr0);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_eear0)    <= (c.e_spr_group_sys    and c.e_spr_index_sys_eear0);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_esr0)     <= (c.e_spr_group_sys    and c.e_spr_index_sys_esr0);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_gpr)      <= (c.e_spr_group_sys    and c.e_spr_index_sys_gpr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dmmucr)  <= (c.e_spr_group_dmmu   and c.e_spr_index_dmmu_dmmucr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dmmupr)  <= (c.e_spr_group_dmmu   and c.e_spr_index_dmmu_dmmupr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbeir) <= (c.e_spr_group_dmmu   and c.e_spr_index_dmmu_dtlbeir);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_datbmr)  <= (c.e_spr_group_dmmu   and c.e_spr_index_dmmu_datbmr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_datbtr)  <= (c.e_spr_group_dmmu   and c.e_spr_index_dmmu_datbtr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbwmr) <= (c.e_spr_group_dmmu   and c.e_spr_index_dmmu_dtlbwmr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbwtr) <= (c.e_spr_group_dmmu   and c.e_spr_index_dmmu_dtlbwtr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_immucr)  <= (c.e_spr_group_immu   and c.e_spr_index_immu_immucr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_immupr)  <= (c.e_spr_group_immu   and c.e_spr_index_immu_immupr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_itlbeir) <= (c.e_spr_group_immu   and c.e_spr_index_immu_itlbeir);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_iatbmr)  <= (c.e_spr_group_immu   and c.e_spr_index_immu_iatbmr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_iatbtr)  <= (c.e_spr_group_immu   and c.e_spr_index_immu_iatbtr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_itlbwmr) <= (c.e_spr_group_immu   and c.e_spr_index_immu_itlbwmr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_itlbwtr) <= (c.e_spr_group_immu   and c.e_spr_index_immu_itlbwtr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbfr) <= (c.e_spr_group_dcache and c.e_spr_index_dcache_dcbfr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbir) <= (c.e_spr_group_dcache and c.e_spr_index_dcache_dcbir);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbwr) <= (c.e_spr_group_dcache and c.e_spr_index_dcache_dcbwr);
  c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_icache_icbir) <= (c.e_spr_group_icache and c.e_spr_index_icache_icbir);
  e_spr_addr_sel_madd_enable_gen : if cpu_or1knd_i5_madd_enable generate
    c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_mac_maclo)    <= (c.e_spr_group_mac    and c.e_spr_index_mac_maclo);
    c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_mac_machi)    <= (c.e_spr_group_mac    and c.e_spr_index_mac_machi);
    c.e_spr_addr_valid <= (all_zeros(c.e_spr_addr(or1k_word_bits-1 downto or1k_spr_addr_bits)) and
                           (c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_vr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_upr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_cpucfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dmmucfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_immucfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dccfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_iccfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dcfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_pccfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_npc) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_sr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_ppc) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_fpcsr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_epcr0) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_eear0) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_esr0) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_gpr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dmmucr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dmmupr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbeir) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_datbmr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_datbtr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbwmr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbwtr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_immucr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_immupr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_itlbeir) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_iatbmr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_iatbtr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_itlbwmr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_itlbwtr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbfr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbir) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbwr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_icache_icbir) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_mac_maclo) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_mac_machi)
                            ));
    end generate;
  e_spr_addr_sel_madd_disable_gen : if not cpu_or1knd_i5_madd_enable generate
    c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_mac_maclo)    <= '0';
    c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_mac_machi)    <= '0';
    c.e_spr_addr_valid <= (all_zeros(c.e_spr_addr(or1k_word_bits-1 downto or1k_spr_addr_bits)) and
                           (c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_vr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_upr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_cpucfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dmmucfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_immucfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dccfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_iccfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dcfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_pccfgr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_npc) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_sr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_ppc) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_fpcsr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_epcr0) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_eear0) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_esr0) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_gpr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dmmucr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dmmupr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbeir) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_datbmr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_datbtr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbwmr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbwtr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_immucr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_immupr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_itlbeir) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_iatbmr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_iatbtr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_itlbwmr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_immu_itlbwtr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbfr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbir) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbwr) or
                            c.e_spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_icache_icbir)
                            ));
  end generate;

  c.e_mtspr_data <= c.e_st_data;
  
  with cpu_or1knd_i5_pipe_dp_in_ctrl.e_addr_sel select
    c.e_addr <= c.e_ldst_addr   when cpu_or1knd_i5_e_addr_sel_ldst,
                c.e_spr_addr    when cpu_or1knd_i5_e_addr_sel_spr,
                (others => 'X') when others;

  e_madd_acc_gen : if cpu_or1knd_i5_madd_enable generate
    c.e_madd_acc <= ((r.p.spr.mac_machi & r.p.spr.mac_maclo) and
                     (2*or1k_word_bits-1 downto 0 => not cpu_or1knd_i5_pipe_dp_in_ctrl.e_madd_acc_zero));
  end generate;
  
  ------------------
  -- decode stage --
  ------------------
  c.d_ra <= or1k_inst_ra(r.d.inst);
  c.d_rb <= or1k_inst_rb(r.d.inst);
  with cpu_or1knd_i5_pipe_dp_in_ctrl.d_rd_link select
    c.d_rd <= "01001" when '1',
              or1k_inst_rd(r.d.inst) when '0',
              (others => 'X') when others;
    
  c.d_ra_data <= cpu_or1knd_i5_pipe_dp_in_misc.regfile_rdata1;
  c.d_rb_data <= cpu_or1knd_i5_pipe_dp_in_misc.regfile_rdata2;

  c.d_depends_ra_e <= not reduce_or(c.d_ra xor r.e.rd);
  c.d_depends_rb_e <= not reduce_or(c.d_rb xor r.e.rd);
  c.d_depends_ra_m <= not reduce_or(c.d_ra xor r.m.rd);
  c.d_depends_rb_m <= not reduce_or(c.d_rb xor r.m.rd);

  c.d_imm_contig <= or1k_inst_imm_contig(r.d.inst);
  c.d_imm_split  <= or1k_inst_imm_split(r.d.inst);
  c.d_imm_toc_offset <= or1k_inst_toc_offset(r.d.inst);

  with cpu_or1knd_i5_pipe_dp_in_ctrl.d_imm_sel select
    c.d_imm <= ((or1k_word_bits-1 downto or1k_imm_bits => cpu_or1knd_i5_pipe_dp_in_ctrl.d_imm_sext and c.d_imm_contig(or1k_imm_bits-1)) &
                c.d_imm_contig
                ) when cpu_or1knd_i5_imm_sel_contig,
               ((or1k_word_bits-1 downto or1k_imm_bits => cpu_or1knd_i5_pipe_dp_in_ctrl.d_imm_sext and c.d_imm_split(or1k_imm_bits-1)) &
                c.d_imm_split
                ) when cpu_or1knd_i5_imm_sel_split,
               ((or1k_word_bits-1 downto or1k_shift_bits => '0') &
                or1k_inst_shift(r.d.inst)
                ) when cpu_or1knd_i5_imm_sel_shift,
               ((or1k_word_bits-1 downto or1k_word_bits-or1k_log2_inst_bytes => '0') &
                (or1k_word_bits-or1k_log2_inst_bytes-1 downto or1k_toc_offset_bits => c.d_imm_toc_offset(or1k_toc_offset_bits-1)) &
                c.d_imm_toc_offset
                ) when cpu_or1knd_i5_imm_sel_toc_offset,
               (others => 'X') when others;
    
  -- PC and TOC offset are fed to ALU, with the bottom 2 zeros dropped, and
  -- with 2 zeros appended to the top.
  -- this seems counterintuitive but may improve timing
    
  with cpu_or1knd_i5_pipe_dp_in_ctrl.d_alu_src1_sel select
    c.d_alu_src1 <= c.d_ra_data     when cpu_or1knd_i5_alu_src1_sel_ra,
                    "00" & r.d.pc   when cpu_or1knd_i5_alu_src1_sel_pc,
                    (others => 'X') when others;
    
  with cpu_or1knd_i5_pipe_dp_in_ctrl.d_alu_src2_sel select
    c.d_alu_src2 <= c.d_rb_data        when cpu_or1knd_i5_alu_src2_sel_rb,
                    c.d_imm            when cpu_or1knd_i5_alu_src2_sel_imm,
                    (others => 'X') when others;

  c.d_st_data <= c.d_rb_data;
    
  -----------------
  -- fetch stage --
  -----------------
  with cpu_or1knd_i5_pipe_dp_in_ctrl.f_inst_buffered select
    c.f_inst <= cpu_l1mem_inst_dp_out.data when '0',
                r.p.f_inst_buffer                  when '1',
                (others => 'X')                    when others;
  with cpu_or1knd_i5_pipe_dp_in_ctrl.f_inst_buffered select
    c.f_inst_bus_error_eear <= cpu_l1mem_inst_dp_out.paddr when '0',
                               r.p.f_inst_bus_error_eear_buffer when '1',
                               (others => 'X') when others;
  with cpu_or1knd_i5_pipe_dp_in_ctrl.f_bpred_buffered select
    c.f_btb_target <= cpu_btb_dp_out.rtarget  when '0',
                      r.p.f_btb_target_buffer when '1',
                      (others => 'X')         when others;
  with cpu_or1knd_i5_pipe_dp_in_ctrl.f_bpred_buffered select
    c.f_btb_state  <= cpu_btb_dp_out.rstate   when '0',
                      r.p.f_btb_state_buffer  when '1',
                      (others => 'X')         when others;
  with cpu_or1knd_i5_pipe_dp_in_ctrl.f_bpred_buffered select
    c.f_bpb_state  <= cpu_bpb_dp_out.rstate   when '0',
                      r.p.f_bpb_state_buffer  when '1',
                      (others => 'X')         when others;
    
  c.f_ra <= or1k_inst_ra(c.f_inst);
  c.f_rb <= or1k_inst_rb(c.f_inst);
  c.f_pc_incr <= std_ulogic_vector(unsigned(r.f.pc) + to_unsigned(1, or1k_ivaddr_bits));

  ------------------------
  -- before fetch stage --
  ------------------------
  with cpu_or1knd_i5_pipe_dp_in_ctrl.bf_pc_sel select
    c.bf_pc <= r.f.pc                 when cpu_or1knd_i5_bf_pc_sel_f,
               c.f_pc_incr            when cpu_or1knd_i5_bf_pc_sel_f_pc_incr,
               c.f_btb_target         when cpu_or1knd_i5_bf_pc_sel_btb,
               r.d.pc                 when cpu_or1knd_i5_bf_pc_sel_d,
               r.e.pc                 when cpu_or1knd_i5_bf_pc_sel_e,
               r.e.pc_incr            when cpu_or1knd_i5_bf_pc_sel_e_pc_incr,
               c.e_toc_target         when cpu_or1knd_i5_bf_pc_sel_e_toc_target,
               c.m_exception_pc       when cpu_or1knd_i5_bf_pc_sel_m_exception_pc,
               r.p.spr.sys_epcr0      when cpu_or1knd_i5_bf_pc_sel_epcr0,
               (others => 'X')        when others;
    
  ---------------
  -- registers --
  ---------------
  with cpu_or1knd_i5_pipe_dp_in_ctrl.emw_stall select
    r_next.w <= r.w                      when '1',
                (rd_data => c.m_rd_data) when '0',
                reg_w_x                  when others;
  
  with cpu_or1knd_i5_pipe_dp_in_ctrl.emw_stall select
    r_next.m <= r.m when '1',
                (pc => r.e.pc,
                 pc_incr => r.e.pc_incr,
                 inst_bus_error_eear => r.e.inst_bus_error_eear,
                 inst => r.e.inst,
                 ra => r.e.ra,
                 rb => r.e.rb,
                 rd => r.e.rd,
                 addr => c.e_addr,
                 alu_result => c.e_alu_result,
                 mtspr_data => c.e_mtspr_data
                 )  when '0',
                reg_m_x when others;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.emw_stall select
    r_next.e <= r.e when '1',
                (pc => r.d.pc,
                 pc_incr => r.d.pc_incr,
                 inst_bus_error_eear => r.d.inst_bus_error_eear,
                 inst => r.d.inst,
                 bpb_state => r.d.bpb_state,
                 btb_state => r.d.btb_state,
                 btb_target => r.d.btb_target,
                 ra => c.d_ra,
                 rb => c.d_rb,
                 rd => c.d_rd,
                 alu_src1 => c.d_alu_src1,
                 alu_src2 => c.d_alu_src2,
                 st_data => c.d_st_data
                 ) when '0',
                reg_e_x when others;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.fd_stall select
    r_next.d <= r.d when '1',
                (inst => c.f_inst,
                 pc => r.f.pc,
                 pc_incr => c.f_pc_incr,
                 inst_bus_error_eear => c.f_inst_bus_error_eear,
                 bpb_state => c.f_bpb_state,
                 btb_state => c.f_btb_state,
                 btb_target => c.f_btb_target
                 ) when '0',
                reg_d_x when others;
  
  r_next.f <= (
    pc => c.bf_pc
    );
    
  with cpu_or1knd_i5_pipe_dp_in_ctrl.m_spr_sys_eear0_write select
    r_next.p.spr.sys_eear0 <= c.m_spr_sys_eear0 when '1',
                              r.p.spr.sys_eear0 when '0',
                              (others => 'X')   when others;
    
  with cpu_or1knd_i5_pipe_dp_in_ctrl.m_spr_sys_epcr0_write select
    r_next.p.spr.sys_epcr0 <= c.m_spr_sys_epcr0 when '1',
                              r.p.spr.sys_epcr0 when '0',
                              (others => 'X')   when others;

  r_next_madd_gen : if cpu_or1knd_i5_madd_enable generate
    with cpu_or1knd_i5_pipe_dp_in_ctrl.m_spr_mac_maclo_write select
      r_next.p.spr.mac_maclo <= c.m_spr_mac_maclo when '1',
                                r.p.spr.mac_maclo when '0',
                                (others => 'X')   when others;
    
    with cpu_or1knd_i5_pipe_dp_in_ctrl.m_spr_mac_machi_write select
      r_next.p.spr.mac_machi <= c.m_spr_mac_machi when '1',
                                r.p.spr.mac_machi when '0',
                                (others => 'X')   when others;
  end generate;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.f_bpred_buffer_write select
    r_next.p.f_btb_target_buffer <= cpu_btb_dp_out.rtarget  when '1',
                                    r.p.f_btb_target_buffer when '0',
                                    (others => 'X')         when others;
  with cpu_or1knd_i5_pipe_dp_in_ctrl.f_bpred_buffer_write select
    r_next.p.f_btb_state_buffer <= cpu_btb_dp_out.rstate  when '1',
                                   r.p.f_btb_state_buffer when '0',
                                   (others => 'X')        when others;
  with cpu_or1knd_i5_pipe_dp_in_ctrl.f_bpred_buffer_write select
    r_next.p.f_bpb_state_buffer <= cpu_bpb_dp_out.rstate  when '1',
                                    r.p.f_bpb_state_buffer when '0',
                                    (others => 'X')        when others;
  with cpu_or1knd_i5_pipe_dp_in_ctrl.f_inst_buffer_write select
    r_next.p.f_inst_buffer <= cpu_l1mem_inst_dp_out.data when '1',
                              r.p.f_inst_buffer                  when '0',
                              (others => 'X')                    when others;
  with cpu_or1knd_i5_pipe_dp_in_ctrl.m_load_buffer_write select
    r_next.p.m_load_buffer <= c.m_load_data_prebuffer when '1',
                              r.p.m_load_buffer       when '0',
                              (others => 'X')         when others;
  
  
  -------------------
  -- register file --
  -------------------
  with cpu_or1knd_i5_pipe_dp_in_ctrl.regfile_raddr1_sel select
    c.regfile_raddr1 <= c.f_ra                                when cpu_or1knd_i5_regfile_raddr1_sel_f_ra,
                        c.d_ra                                when cpu_or1knd_i5_regfile_raddr1_sel_d_ra,
                        r.m.addr(or1k_rfaddr_bits-1 downto 0) when cpu_or1knd_i5_regfile_raddr1_sel_m_mfspr_sys_gpr,
                        (others => 'X')                       when others;
  
  with cpu_or1knd_i5_pipe_dp_in_ctrl.regfile_raddr2_sel select
    c.regfile_raddr2 <= c.f_rb          when cpu_or1knd_i5_regfile_raddr2_sel_f_rb,
                        c.d_rb          when cpu_or1knd_i5_regfile_raddr2_sel_d_rb,
                        (others => 'X') when others;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.regfile_w_sel select
    c.regfile_waddr <= r.m.rd                                when cpu_or1knd_i5_regfile_w_sel_m_rd,
                       r.m.addr(or1k_rfaddr_bits-1 downto 0) when cpu_or1knd_i5_regfile_w_sel_m_mtspr_sys_gpr,
                       (others => 'X')                       when others;
  
  with cpu_or1knd_i5_pipe_dp_in_ctrl.regfile_w_sel select
    c.regfile_wdata <= c.m_rd_data     when cpu_or1knd_i5_regfile_w_sel_m_rd,
                       r.m.mtspr_data  when cpu_or1knd_i5_regfile_w_sel_m_mtspr_sys_gpr,
                       (others => 'X') when others;

  with cpu_or1knd_i5_pipe_dp_in_ctrl.l1mem_inst_vaddr_sel select
    c.l1mem_inst_vaddr <= c.bf_pc                                                       when cpu_or1knd_i5_l1mem_inst_vaddr_sel_bf_pc,
                          r.m.mtspr_data(or1k_vaddr_bits-1 downto or1k_log2_inst_bytes) when cpu_or1knd_i5_l1mem_inst_vaddr_sel_m_mtspr_data,
                          (others => 'X')                                               when others;

  c.l1mem_data_size <= c.e_ldst_size;
  
  with cpu_or1knd_i5_pipe_dp_in_ctrl.l1mem_data_vaddr_sel select
    c.l1mem_data_vaddr <= c.e_ldst_addr   when cpu_or1knd_i5_l1mem_data_vaddr_sel_e_ldst_addr,
                          r.m.mtspr_data  when cpu_or1knd_i5_l1mem_data_vaddr_sel_m_mtspr_data,
                          (others => 'X') when others;
  
  -------------
  -- outputs --
  -------------
  cpu_bpb_dp_in <= (
    raddr => c.bf_pc,
    waddr => r.e.pc,
    wstate => r.e.bpb_state
    );
  
  cpu_btb_dp_in <= (
    raddr => c.bf_pc,
    waddr => r.e.pc,
    wstate => r.e.btb_state,
    wtarget => c.e_direct_toc_target
    );
  
  cpu_or1knd_i5_pipe_dp_out_ctrl <= (
    f_inst => c.f_inst,
    d_depends_ra_e => c.d_depends_ra_e,
    d_depends_rb_e => c.d_depends_rb_e,
    d_depends_ra_m => c.d_depends_ra_m,
    d_depends_rb_m => c.d_depends_rb_m,
    e_not_equal => c.e_not_equal,
    e_lts => c.e_lts,
    e_ltu => c.e_ltu,
    e_spr_addr_sel => c.e_spr_addr_sel,
    e_spr_addr_valid => c.e_spr_addr_valid,
    e_ldst_misaligned => c.e_ldst_misaligned,
    e_toc_target_misaligned => c.e_toc_target_misaligned,
    e_btb_mispred => c.e_btb_mispred,
    m_mtspr_data => r.m.mtspr_data,
    m_madd_result_hi_zeros => c.m_madd_result_hi_zeros,
    m_madd_result_hi_ones  => c.m_madd_result_hi_ones,
    m_mul_result_msb => c.m_mul_result_msb
    );
  
  cpu_or1knd_i5_pipe_dp_out_misc <= (
    e_alu_src1     => c.e_alu_src1,
    e_alu_src2     => c.e_alu_src2,
    
    e_madd_acc    => c.e_madd_acc,

    regfile_waddr  => c.regfile_waddr,
    regfile_wdata  => c.regfile_wdata,
    regfile_raddr1 => c.regfile_raddr1,
    regfile_raddr2 => c.regfile_raddr2
    );
  
  cpu_l1mem_inst_dp_in <= (
    vaddr => c.l1mem_inst_vaddr
    );

  cpu_l1mem_data_dp_in <= (
    size => c.l1mem_data_size,
    vaddr => c.l1mem_data_vaddr,
    data => c.e_st_data
    );

  seq : process (clk) is
  begin

    if rising_edge(clk) then
      r <= r_next;
    end if;
    
  end process;

  -- pragma translate_off
  monitor : block
  begin

    m_pc_watch : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_or1knd_i5_pipe_dp'path_name),
        name => "m_pc",
        data_bits => or1k_ivaddr_bits
        )
      port map (
        clk => clk,
        data => r.m.pc
        );
    
    m_inst_watch : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_or1knd_i5_pipe_dp'path_name),
        name => "m_inst",
        data_bits => or1k_inst_bits
        )
      port map (
        clk => clk,
        data => r.m.inst
        );
    
  end block;
  -- pragma translate_on
  
end;
