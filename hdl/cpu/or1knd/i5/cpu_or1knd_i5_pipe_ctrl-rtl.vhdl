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

library isa;
use isa.or1k_pkg.all;

library util;
use util.logic_pkg.all;
use util.types_pkg.all;
-- pragma translate_off
use util.names_pkg.all;
-- pragma translate_on

library tech;

-- pragma translate_off
library sim;
use sim.options_pkg.all;
use sim.monitor_pkg.all;
-- pragma translate_on

use work.cpu_or1knd_i5_config_pkg.all;
use work.cpu_or1knd_i5_pipe_pkg.all;
use work.cpu_l1mem_inst_pkg.all;
use work.cpu_l1mem_inst_types_pkg.all;
use work.cpu_l1mem_data_pkg.all;
use work.cpu_l1mem_data_types_pkg.all;

architecture rtl of cpu_or1knd_i5_pipe_ctrl is

  type spr_sys_sr_type is record
    sumra : std_ulogic;
    eph   : std_ulogic;
    ove   : std_ulogic;
    ime   : std_ulogic;
    dme   : std_ulogic;
    ice   : std_ulogic;
    dce   : std_ulogic;
    iee   : std_ulogic;
    tee   : std_ulogic;
    sm    : std_ulogic;
  end record;
  constant spr_sys_sr_init : spr_sys_sr_type := (
    sumra => '0',
    eph   => '0',
    ove   => '0',
    ime   => '0',
    dme   => '0',
    ice   => '0',
    dce   => '0',
    iee   => '0',
    tee   => '0',
    sm    => '1'
    );
  constant spr_sys_sr_zero : spr_sys_sr_type := (
    sumra => '0',
    eph   => '0',
    ove   => '0',
    ime   => '0',
    dme   => '0',
    ice   => '0',
    dce   => '0',
    iee   => '0',
    tee   => '0',
    sm    => '0'
    );
  constant spr_sys_sr_x : spr_sys_sr_type := (
    sumra => 'X',
    eph   => 'X',
    ove   => 'X',
    ime   => 'X',
    dme   => 'X',
    ice   => 'X',
    dce   => 'X',
    iee   => 'X',
    tee   => 'X',
    sm    => 'X'
    );

  type spr_sys_sr_user_type is record
    f    : std_ulogic;
    cy   : std_ulogic;
    ov    : std_ulogic;
  end record;
  constant spr_sys_sr_user_init : spr_sys_sr_user_type := (
    f    => '0',
    cy   => '0',
    ov   => '0'
    );
  constant spr_sys_sr_user_x : spr_sys_sr_user_type := (
    f    => 'X',
    cy   => 'X',
    ov   => 'X'
    );

  -- instruction flags
  type inst_class_index_type is (
    inst_class_index_nop,
    inst_class_index_alu,
    inst_class_index_mul,
    inst_class_index_div,
    inst_class_index_toc,
    inst_class_index_load,
    inst_class_index_store,
    inst_class_index_mac,
    inst_class_index_macrc,
    inst_class_index_mfspr,
    inst_class_index_mtspr,
    inst_class_index_rfe,
    inst_class_index_syscall,
    inst_class_index_trap,
    inst_class_index_csync,
    inst_class_index_msync,
    inst_class_index_psync,
    inst_class_index_illegal
    );
  type inst_class_type is array (inst_class_index_type range inst_class_index_illegal downto inst_class_index_nop) of std_ulogic;
  constant inst_class_nop     : inst_class_type := "000000000000000001";
  constant inst_class_alu     : inst_class_type := "000000000000000010";
  constant inst_class_mul     : inst_class_type := "000000000000000100";
  constant inst_class_div     : inst_class_type := "000000000000001000";
  constant inst_class_toc     : inst_class_type := "000000000000010000";
  constant inst_class_load    : inst_class_type := "000000000000100000";
  constant inst_class_store   : inst_class_type := "000000000001000000";
  constant inst_class_mac     : inst_class_type := "000000000010000000";
  constant inst_class_macrc   : inst_class_type := "000000000100000000";
  constant inst_class_mfspr   : inst_class_type := "000000001000000000";
  constant inst_class_mtspr   : inst_class_type := "000000010000000000";
  constant inst_class_rfe     : inst_class_type := "000000100000000000";
  constant inst_class_syscall : inst_class_type := "000001000000000000";
  constant inst_class_trap    : inst_class_type := "000010000000000000";
  constant inst_class_csync   : inst_class_type := "000100000000000000";
  constant inst_class_msync   : inst_class_type := "001000000000000000";
  constant inst_class_psync   : inst_class_type := "010000000000000000";
  constant inst_class_illegal : inst_class_type := "100000000000000000";

  type ra_dep_index_type is (
    ra_dep_index_none, -- ra is not needed
    ra_dep_index_e_alu  -- ra is needed before alu
    );
  type ra_dep_type is array (ra_dep_index_type range ra_dep_index_e_alu downto ra_dep_index_none) of std_ulogic;
  constant ra_dep_none : ra_dep_type := "01";
  constant ra_dep_e_alu  : ra_dep_type := "10";
  
  type rb_dep_index_type is (
    rb_dep_index_none,  -- rb is not needed
    rb_dep_index_e_alu,   -- rb is needed before alu
    rb_dep_index_e_store -- rb is needed before store
    );
  type rb_dep_type is array (rb_dep_index_type range rb_dep_index_e_store downto rb_dep_index_none) of std_ulogic;
  constant rb_dep_none  : rb_dep_type := "001";
  constant rb_dep_e_alu   : rb_dep_type := "010";
  constant rb_dep_e_store : rb_dep_type := "100";

  type set_spr_sys_sr_f_index_type is (
    set_spr_sys_sr_f_index_none,
    set_spr_sys_sr_f_index_eq,
    set_spr_sys_sr_f_index_ne,
    set_spr_sys_sr_f_index_gtu,
    set_spr_sys_sr_f_index_geu,
    set_spr_sys_sr_f_index_ltu,
    set_spr_sys_sr_f_index_leu,
    set_spr_sys_sr_f_index_gts,
    set_spr_sys_sr_f_index_ges,
    set_spr_sys_sr_f_index_lts,
    set_spr_sys_sr_f_index_les
    );
  type set_spr_sys_sr_f_type is array (set_spr_sys_sr_f_index_type range set_spr_sys_sr_f_index_les downto set_spr_sys_sr_f_index_none) of std_ulogic;
  constant set_spr_sys_sr_f_none : set_spr_sys_sr_f_type := "00000000001";
  constant set_spr_sys_sr_f_eq   : set_spr_sys_sr_f_type := "00000000010";
  constant set_spr_sys_sr_f_ne   : set_spr_sys_sr_f_type := "00000000100";
  constant set_spr_sys_sr_f_gtu  : set_spr_sys_sr_f_type := "00000001000";
  constant set_spr_sys_sr_f_geu  : set_spr_sys_sr_f_type := "00000010000";
  constant set_spr_sys_sr_f_ltu  : set_spr_sys_sr_f_type := "00000100000";
  constant set_spr_sys_sr_f_leu  : set_spr_sys_sr_f_type := "00001000000";
  constant set_spr_sys_sr_f_gts  : set_spr_sys_sr_f_type := "00010000000";
  constant set_spr_sys_sr_f_ges  : set_spr_sys_sr_f_type := "00100000000";
  constant set_spr_sys_sr_f_lts  : set_spr_sys_sr_f_type := "01000000000";
  constant set_spr_sys_sr_f_les  : set_spr_sys_sr_f_type := "10000000000";

  type set_spr_sys_sr_cy_index_type is (
    set_spr_sys_sr_cy_index_none,
    set_spr_sys_sr_cy_index_e_add, -- e stage
    set_spr_sys_sr_cy_index_m_mulu, -- m stage
    set_spr_sys_sr_cy_index_m_macuadd -- m stage
    );
  type set_spr_sys_sr_cy_type is array (set_spr_sys_sr_cy_index_type range set_spr_sys_sr_cy_index_m_macuadd downto set_spr_sys_sr_cy_index_none) of std_ulogic;
  constant set_spr_sys_sr_cy_none      : set_spr_sys_sr_cy_type  := "0001";
  constant set_spr_sys_sr_cy_e_add     : set_spr_sys_sr_cy_type  := "0010";
  constant set_spr_sys_sr_cy_m_mulu    : set_spr_sys_sr_cy_type  := "0100";
  constant set_spr_sys_sr_cy_m_macuadd : set_spr_sys_sr_cy_type := "1000";
  
  type set_spr_sys_sr_ov_index_type is (
    set_spr_sys_sr_ov_index_none,
    set_spr_sys_sr_ov_index_e_add,
    set_spr_sys_sr_ov_index_m_mul,
    set_spr_sys_sr_ov_index_m_macadd,
    set_spr_sys_sr_ov_index_m_div
    );
  type set_spr_sys_sr_ov_type is array (set_spr_sys_sr_ov_index_type range
                                        set_spr_sys_sr_ov_index_type'high downto
                                        set_spr_sys_sr_ov_index_type'low) of std_ulogic;
  constant set_spr_sys_sr_ov_none     : set_spr_sys_sr_ov_type := "00001";
  constant set_spr_sys_sr_ov_e_add    : set_spr_sys_sr_ov_type := "00010";
  constant set_spr_sys_sr_ov_m_mul    : set_spr_sys_sr_ov_type := "00100";
  constant set_spr_sys_sr_ov_m_macadd : set_spr_sys_sr_ov_type := "01000";
  constant set_spr_sys_sr_ov_m_div    : set_spr_sys_sr_ov_type := "10000";

  type m_spr_sys_sr_new_sel_index_type is (
    m_spr_sys_sr_new_sel_index_init,
    m_spr_sys_sr_new_sel_index_old,
    m_spr_sys_sr_new_sel_index_except,
    m_spr_sys_sr_new_sel_index_mtspr,
    m_spr_sys_sr_new_sel_index_esr0
    );
  type m_spr_sys_sr_new_sel_type is array (m_spr_sys_sr_new_sel_index_type range
                                           m_spr_sys_sr_new_sel_index_type'high downto
                                           m_spr_sys_sr_new_sel_index_type'low) of std_ulogic;
  constant m_spr_sys_sr_new_sel_init    : m_spr_sys_sr_new_sel_type := "00001";
  constant m_spr_sys_sr_new_sel_old     : m_spr_sys_sr_new_sel_type := "00010";
  constant m_spr_sys_sr_new_sel_except  : m_spr_sys_sr_new_sel_type := "00100";
  constant m_spr_sys_sr_new_sel_mtspr   : m_spr_sys_sr_new_sel_type := "01000";
  constant m_spr_sys_sr_new_sel_esr0    : m_spr_sys_sr_new_sel_type := "10000";

  -- assuming no stalls, SR (user part) is written by these cases
  -- old: keep old value (exception other than ALU range exception)
  -- default: CY, OV, F bits as normally set by instruction; no exception other than ALU range instruction caused
  -- mtspr: mtspr instruction with SR
  -- esr: rfe instruction
  type m_spr_sys_sr_user_new_sel_index_type is (
    m_spr_sys_sr_user_new_sel_index_init,
    m_spr_sys_sr_user_new_sel_index_old,
    m_spr_sys_sr_user_new_sel_index_default,
    m_spr_sys_sr_user_new_sel_index_mtspr,
    m_spr_sys_sr_user_new_sel_index_esr0
    );
  type m_spr_sys_sr_user_new_sel_type is
    array (m_spr_sys_sr_user_new_sel_index_type range
           m_spr_sys_sr_user_new_sel_index_type'high downto
           m_spr_sys_sr_user_new_sel_index_type'low) of std_ulogic;
  constant m_spr_sys_sr_user_new_sel_init    : m_spr_sys_sr_user_new_sel_type := "00001";
  constant m_spr_sys_sr_user_new_sel_old     : m_spr_sys_sr_user_new_sel_type := "00010";
  constant m_spr_sys_sr_user_new_sel_default : m_spr_sys_sr_user_new_sel_type := "00100";
  constant m_spr_sys_sr_user_new_sel_mtspr   : m_spr_sys_sr_user_new_sel_type := "01000";
  constant m_spr_sys_sr_user_new_sel_esr0    : m_spr_sys_sr_user_new_sel_type := "10000";
  
  type m_spr_sys_esr0_sel_index_type is (
    m_spr_sys_esr0_sel_index_old,
    m_spr_sys_esr0_sel_index_init,
    m_spr_sys_esr0_sel_index_mtspr,
    m_spr_sys_esr0_sel_index_sys_sr
    );
  type m_spr_sys_esr0_sel_type is
    array (m_spr_sys_esr0_sel_index_type range
           m_spr_sys_esr0_sel_index_type'high downto m_spr_sys_esr0_sel_index_type'low) of std_ulogic;
  constant m_spr_sys_esr0_sel_old    : m_spr_sys_esr0_sel_type := "0001";
  constant m_spr_sys_esr0_sel_init   : m_spr_sys_esr0_sel_type := "0010";
  constant m_spr_sys_esr0_sel_mtspr  : m_spr_sys_esr0_sel_type := "0100";
  constant m_spr_sys_esr0_sel_sys_sr : m_spr_sys_esr0_sel_type := "1000";

  type spr_sys_aecsr_index_type is (
    spr_sys_aecsr_index_cyadde,
    spr_sys_aecsr_index_ovadde,
    spr_sys_aecsr_index_cymule,
    spr_sys_aecsr_index_ovmule,
    spr_sys_aecsr_index_dbze,
    spr_sys_aecsr_index_cymacadde,
    spr_sys_aecsr_index_ovmacadde
    );
  type spr_sys_aecsr_type is
    array(spr_sys_aecsr_index_type range
          spr_sys_aecsr_index_cyadde to spr_sys_aecsr_index_ovmacadde)
    of std_ulogic;
  constant spr_sys_aecsr_init_aecr : spr_sys_aecsr_type := (
    spr_sys_aecsr_index_cyadde => '0',
    spr_sys_aecsr_index_ovadde => '1',
    spr_sys_aecsr_index_cymule => '0',
    spr_sys_aecsr_index_ovmule => '1',
    spr_sys_aecsr_index_dbze   => '1',
    spr_sys_aecsr_index_cymacadde => '0',
    spr_sys_aecsr_index_ovmacadde => '1'
    );
  constant spr_sys_aecsr_init_aesr : spr_sys_aecsr_type := (
    spr_sys_aecsr_index_cyadde => '0',
    spr_sys_aecsr_index_ovadde => '0',
    spr_sys_aecsr_index_cymule => '0',
    spr_sys_aecsr_index_ovmule => '0',
    spr_sys_aecsr_index_dbze   => '0',
    spr_sys_aecsr_index_cymacadde => '0',
    spr_sys_aecsr_index_ovmacadde => '0'
    );

  type m_spr_sys_aesr_new_sel_index_type is (
    m_spr_sys_aesr_new_sel_index_old,
    m_spr_sys_aesr_new_sel_index_mtspr,
    m_spr_sys_aesr_new_sel_index_except
    );
  type m_spr_sys_aesr_new_sel_type is
    array (m_spr_sys_aesr_new_sel_index_type range
           m_spr_sys_aesr_new_sel_index_type'high downto
           m_spr_sys_aesr_new_sel_index_type'low) of std_ulogic;
  constant m_spr_sys_aesr_new_sel_old    : m_spr_sys_aesr_new_sel_type := "001";
  constant m_spr_sys_aesr_new_sel_mtspr  : m_spr_sys_aesr_new_sel_type := "010";
  constant m_spr_sys_aesr_new_sel_except : m_spr_sys_aesr_new_sel_type := "100";

  type m_mfspr_data_dp_sel_index_type is (
    m_mfspr_data_dp_sel_index_sys_sr,
    m_mfspr_data_dp_sel_index_sys_esr0,
    m_mfspr_data_dp_sel_index_sys_aecr,
    m_mfspr_data_dp_sel_index_sys_aesr
    );
  type m_mfspr_data_dp_sel_type is
    array (m_mfspr_data_dp_sel_index_type range
           m_mfspr_data_dp_sel_index_type'high downto
           m_mfspr_data_dp_sel_index_type'low) of std_ulogic;
  constant m_mfspr_data_dp_sel_sys_sr   : m_mfspr_data_dp_sel_type := "0001";
  constant m_mfspr_data_dp_sel_sys_esr0 : m_mfspr_data_dp_sel_type := "0010";
  constant m_mfspr_data_dp_sel_sys_aecr : m_mfspr_data_dp_sel_type := "0100";
  constant m_mfspr_data_dp_sel_sys_aesr : m_mfspr_data_dp_sel_type := "1000";

  type inst_flags_type is record

    class              : inst_class_type;
    
    ra_dep             : ra_dep_type;
    rb_dep             : rb_dep_type;

    toc_indir          : std_ulogic;
    toc_cond           : std_ulogic;
    toc_not_flag       : std_ulogic;
    toc_call           : std_ulogic;

    imm_sel            : cpu_or1knd_i5_imm_sel_type;
    imm_sext           : std_ulogic;

    alu_src1_sel       : cpu_or1knd_i5_alu_src1_sel_type;
    alu_src2_sel       : cpu_or1knd_i5_alu_src2_sel_type;

    addsub_sub         : std_ulogic;
    addsub_use_carryin : std_ulogic;

    shifter_right      : std_ulogic;
    shifter_unsgnd     : std_ulogic;
    shifter_rot        : std_ulogic;

    mul_unsgnd         : std_ulogic;
    
    madd_unsgnd        : std_ulogic;
    madd_sub           : std_ulogic;
    madd_acc_zero      : std_ulogic;

    div_unsgnd         : std_ulogic;

    set_spr_sys_sr_f   : set_spr_sys_sr_f_type;
    set_spr_sys_sr_cy  : set_spr_sys_sr_cy_type;
    set_spr_sys_sr_ov  : set_spr_sys_sr_ov_type;
    
    alu_result_sel     : cpu_or1knd_i5_alu_result_sel_type;

    rd_write           : std_ulogic;
    rd_data_sel        : cpu_or1knd_i5_rd_data_sel_type;
    
    sext               : std_ulogic;
    data_size_sel      : cpu_or1knd_i5_data_size_sel_type;

    zero               : std_ulogic;
    
    aecsr_exceptions   : spr_sys_aecsr_type;
    
  end record;
  constant inst_flags_nop : inst_flags_type := (
    class              => inst_class_nop,
    ra_dep             => ra_dep_none,
    rb_dep             => rb_dep_none,
    toc_indir          => 'X',
    toc_cond           => 'X',
    toc_not_flag       => 'X',
    toc_call           => 'X',
    imm_sel            => (others => 'X'),
    imm_sext           => 'X',
    alu_src1_sel       => (others => 'X'),
    alu_src2_sel       => (others => 'X'),
    addsub_sub         => 'X',
    addsub_use_carryin => 'X',
    shifter_right      => 'X',
    shifter_unsgnd     => 'X',
    shifter_rot        => 'X',
    mul_unsgnd         => 'X',
    madd_unsgnd        => 'X',
    madd_sub           => 'X',
    madd_acc_zero      => 'X',
    div_unsgnd         => 'X',
    set_spr_sys_sr_f   => set_spr_sys_sr_f_none,
    set_spr_sys_sr_cy  => set_spr_sys_sr_cy_none,
    set_spr_sys_sr_ov  => set_spr_sys_sr_ov_none,
    alu_result_sel     => (others => 'X'),
    rd_write           => '0',
    rd_data_sel        => (others => 'X'),
    sext               => 'X',
    data_size_sel      => (others => 'X'),
    zero               => '0',
    aecsr_exceptions   => (others => 'X')
    );
  constant inst_flags_x : inst_flags_type := (
    class              => (others => 'X'),
    ra_dep             => (others => 'X'),
    rb_dep             => (others => 'X'),
    toc_indir          => 'X',
    toc_cond           => 'X',
    toc_not_flag       => 'X',
    toc_call           => 'X',
    imm_sel            => (others => 'X'),
    imm_sext           => 'X',
    alu_src1_sel       => (others => 'X'),
    alu_src2_sel       => (others => 'X'),
    addsub_sub         => 'X',
    addsub_use_carryin => 'X',
    shifter_right      => 'X',
    shifter_unsgnd     => 'X',
    shifter_rot        => 'X',
    mul_unsgnd         => 'X',
    madd_unsgnd        => 'X',
    madd_sub           => 'X',
    madd_acc_zero      => 'X',
    div_unsgnd         => 'X',
    set_spr_sys_sr_f   => (others => 'X'),
    set_spr_sys_sr_cy  => (others => 'X'),
    set_spr_sys_sr_ov  => (others => 'X'),
    alu_result_sel     => (others => 'X'),
    rd_write           => 'X',
    rd_data_sel        => (others => 'X'),
    sext               => 'X',
    data_size_sel      => (others => 'X'),
    zero               => 'X',
    aecsr_exceptions   => (others => 'X')
    );

  type reg_f_type is record
    inst_requested : std_ulogic;
    bpred_requested : std_ulogic;
    inst_fetch_direction : cpu_l1mem_inst_fetch_direction_type;
  end record;
  constant reg_f_init : reg_f_type := (
    inst_requested => '0',
    bpred_requested => '0',
    inst_fetch_direction => (others => 'X')
    );
  
  type reg_d_type is record
    valid : std_ulogic;
    btb_valid : std_ulogic;
    toc_pred_taken : std_ulogic;
    inst  : or1k_inst_type;
    inst_pf_exception_raised : std_ulogic;
    inst_tlbmiss_exception_raised : std_ulogic;
    inst_bus_exception_raised : std_ulogic;
  end record;
  constant reg_d_nop : reg_d_type := (
    valid => '0',
    btb_valid => 'X',
    toc_pred_taken => 'X',
    inst  => (others => 'X'),
    inst_pf_exception_raised => 'X',
    inst_tlbmiss_exception_raised => 'X',
    inst_bus_exception_raised => 'X'
    );
  constant reg_d_x : reg_d_type := (
    valid => 'X',
    btb_valid => 'X',
    toc_pred_taken => 'X',
    inst  => (others => 'X'),
    inst_pf_exception_raised => 'X',
    inst_tlbmiss_exception_raised => 'X',
    inst_bus_exception_raised => 'X'
    );

  type reg_e_type is record
    valid : std_ulogic;
    btb_valid : std_ulogic;
    inst_flags : inst_flags_type;
    toc_pred_taken : std_ulogic;
    fwd_alu_src1_sel : cpu_or1knd_i5_e_fwd_alu_src_sel_type;
    fwd_alu_src2_sel : cpu_or1knd_i5_e_fwd_alu_src_sel_type;
    fwd_st_data_sel : cpu_or1knd_i5_e_fwd_st_data_sel_type;
    inst_pf_exception_raised : std_ulogic;
    inst_tlbmiss_exception_raised : std_ulogic;
    inst_bus_exception_raised : std_ulogic;
  end record;
  constant reg_e_nop : reg_e_type := (
    valid => '0',
    btb_valid => 'X',
    inst_flags => inst_flags_x,
    toc_pred_taken => 'X',
    fwd_alu_src1_sel => (others => 'X'),
    fwd_alu_src2_sel => (others => 'X'),
    fwd_st_data_sel => (others => 'X'),
    inst_pf_exception_raised => 'X',
    inst_tlbmiss_exception_raised => 'X',
    inst_bus_exception_raised => 'X'
    );
  constant reg_e_x : reg_e_type := (
    valid => 'X',
    btb_valid => 'X',
    inst_flags => inst_flags_x,
    toc_pred_taken => 'X',
    fwd_alu_src1_sel => (others => 'X'),
    fwd_alu_src2_sel => (others => 'X'),
    fwd_st_data_sel => (others => 'X'),
    inst_pf_exception_raised => 'X',
    inst_tlbmiss_exception_raised => 'X',
    inst_bus_exception_raised => 'X'
    );

  type reg_m_type is record
    valid : std_ulogic;
    inst_flags : inst_flags_type;
    spr_sys_sr_user : spr_sys_sr_user_type;
    spr_addr_sel : cpu_or1knd_i5_spr_addr_sel_type;
    spr_addr_valid : std_ulogic;
    inst_pf_exception_raised : std_ulogic;
    inst_tlbmiss_exception_raised : std_ulogic;
    inst_bus_exception_raised : std_ulogic;
    toc_align_exception_raised : std_ulogic;
    data_align_exception_raised : std_ulogic;
  end record;
  constant reg_m_init : reg_m_type := (
    valid          => '0',
    inst_flags     => inst_flags_x,
    spr_sys_sr_user => spr_sys_sr_user_x,
    spr_addr_sel       => (others => 'X'),
    spr_addr_valid  => 'X',
    inst_pf_exception_raised => 'X',
    inst_tlbmiss_exception_raised => 'X',
    inst_bus_exception_raised => 'X',
    toc_align_exception_raised => 'X',
    data_align_exception_raised => 'X'
    );
  constant reg_m_x : reg_m_type := (
    valid          => 'X',
    inst_flags     => inst_flags_x,
    spr_sys_sr_user => spr_sys_sr_user_x,
    spr_addr_sel       => (others => 'X'),
    spr_addr_valid  => 'X',
    inst_pf_exception_raised => 'X',
    inst_tlbmiss_exception_raised => 'X',
    inst_bus_exception_raised => 'X',
    toc_align_exception_raised => 'X',
    data_align_exception_raised => 'X'
    );

  -- when an mfspr instruction that reads a GPR is in the m stage,
  -- it will stay there for 2 cycles:
  --   first cycle, initiate the read, cancelling the read for the instruction
  --     in f
  --   second cycle, initiate write of just-read register to register file, and
  --     initiate reread of the register for the instruction in d stage
  --   third cycle, F and D stages are stalled an additional cycle so that the
  --     instruction in D can use just-read register

  type reg_p_type is record
    init               : std_ulogic;
    inst_fetch_enabled : std_ulogic;
    spr_sys_sr         : spr_sys_sr_type;
    spr_sys_sr_user    : spr_sys_sr_user_type;
    spr_sys_esr0       : spr_sys_sr_type;
    spr_sys_esr0_user  : spr_sys_sr_user_type;
    spr_sys_aecr       : spr_sys_aecsr_type;
    spr_sys_aesr       : spr_sys_aecsr_type;
    mfspr_sys_gpr_status : std_ulogic;
    mtspr_icache_icbir_status : std_ulogic;
    mtspr_dcache_dcbxr_status : std_ulogic;
    f_bpred_buffered     : std_ulogic;
    f_bpb_taken_buffer : std_ulogic;
    f_btb_valid_buffer : std_ulogic;
    f_inst_buffered    : std_ulogic;
    m_load_data_buffered : std_ulogic;
  end record;
  constant reg_p_init : reg_p_type := (
    init               => '1',
    inst_fetch_enabled => '0',
    spr_sys_sr         => spr_sys_sr_init,
    spr_sys_sr_user    => spr_sys_sr_user_init,
    spr_sys_esr0       => spr_sys_sr_init,
    spr_sys_esr0_user  => spr_sys_sr_user_init,
    spr_sys_aecr       => spr_sys_aecsr_init_aecr,
    spr_sys_aesr       => spr_sys_aecsr_init_aesr,
    mfspr_sys_gpr_status   => '0',
    mtspr_icache_icbir_status => '0',
    mtspr_dcache_dcbxr_status => '0',
    f_bpred_buffered   => '0',
    f_bpb_taken_buffer => 'X',
    f_btb_valid_buffer => 'X',
    f_inst_buffered    => '0',
    m_load_data_buffered => '0'
    );
  
  type reg_type is record
    f : reg_f_type;
    d : reg_d_type;
    e : reg_e_type;
    m : reg_m_type;
    p : reg_p_type;
  end record;
  constant r_init : reg_type := (
    f => reg_f_init,
    d => reg_d_nop,
    e => reg_e_nop,
    m => reg_m_init,
    p => reg_p_init
    );

  type comb_type is record
    f_flush, d_flush, e_flush       : std_ulogic;
    d_stall                         : std_ulogic;
    e_stall                         : std_ulogic;
    m_stall                         : std_ulogic;
    fd_stall                        : std_ulogic;
    emw_stall                       : std_ulogic;

    bf_refetching                   : std_ulogic;
    bf_pc_sel                       : cpu_or1knd_i5_bf_pc_sel_type;
    bf_pc_sel_unpri                 : std_ulogic_vector(9 downto 0);
    bf_pc_sel_pri                   : std_ulogic_vector(9 downto 0);
    bf_inst_request                 : std_ulogic;
    bf_inst_fetch_direction         : cpu_l1mem_inst_fetch_direction_type;

    f_valid                         : std_ulogic;
    f_bpred_buffer_write            : std_ulogic;
    f_btb_valid                     : std_ulogic;
    f_bpb_taken                     : std_ulogic;
    f_inst_buffer_write             : std_ulogic;
    f_inst                          : or1k_inst_type;
    f_toc_pred_taken                : std_ulogic;
    f_inst_pf_exception_raised      : std_ulogic;
    f_inst_tlbmiss_exception_raised : std_ulogic;
    f_inst_bus_exception_raised     : std_ulogic;

    d_inst_fetch_exception_raised   : std_ulogic;
    d_all_cancel                    : std_ulogic;
    d_inst_flags                    : inst_flags_type;
    d_rd_link                       : std_ulogic;
    d_alu_data_hazard               : std_ulogic;
    d_spr_sr_cy_hazard              : std_ulogic;
    d_hazard                        : std_ulogic;
    d_e_fwd_alu_src1_m_alu_result   : std_ulogic;
    d_e_fwd_alu_src1_w_rd_data      : std_ulogic;
    d_e_fwd_alu_src1_sel            : cpu_or1knd_i5_e_fwd_alu_src_sel_type;
    d_e_fwd_alu_src1_sel_1hot_unpri : std_ulogic_vector(2 downto 0);
    d_e_fwd_alu_src1_sel_1hot       : std_ulogic_vector(2 downto 0);
    d_e_fwd_alu_src2_m_alu_result   : std_ulogic;
    d_e_fwd_alu_src2_w_rd_data      : std_ulogic;
    d_e_fwd_alu_src2_sel            : cpu_or1knd_i5_e_fwd_alu_src_sel_type;
    d_e_fwd_alu_src2_sel_1hot_unpri : std_ulogic_vector(2 downto 0);
    d_e_fwd_alu_src2_sel_1hot       : std_ulogic_vector(2 downto 0);
    d_e_fwd_st_data_m_rd_data       : std_ulogic;
    d_e_fwd_st_data_w_rd_data       : std_ulogic;
    d_e_fwd_st_data_sel             : cpu_or1knd_i5_e_fwd_st_data_sel_type;
    d_e_fwd_st_data_sel_1hot_unpri  : std_ulogic_vector(2 downto 0);
    d_e_fwd_st_data_sel_1hot        : std_ulogic_vector(2 downto 0);

    e_spr_sys_sr_user               : spr_sys_sr_user_type;
    e_spr_sys_sr_user_new           : spr_sys_sr_user_type;

    e_inst_fetch_exception_raised   : std_ulogic;
    e_all_cancel                    : std_ulogic;
    e_ldst_cancel                   : std_ulogic;

    e_load_stall                    : std_ulogic;
    e_store_stall                   : std_ulogic;
    e_msync_stall                   : std_ulogic;

    e_ldst_request                  : std_ulogic;
    e_ldst_write                    : std_ulogic;
    e_toc_taken                     : std_ulogic;
    e_toc_mispred                   : std_ulogic;
    e_toc_flush                     : std_ulogic;
    e_bpred_write                   : std_ulogic;
    e_toc_align_exception_raised    : std_ulogic;
    e_data_align_exception_raised   : std_ulogic;
    e_addr_sel                      : cpu_or1knd_i5_e_addr_sel_type;
    e_mul_en                        : std_ulogic;
    e_madd_en                       : std_ulogic;
    e_div_en                        : std_ulogic;

    m_reset_exception_raised        : std_ulogic;
    m_ext_exception_raised          : std_ulogic;
    m_tti_exception_raised          : std_ulogic;
    m_priv_inst_exception_raised    : std_ulogic;
    m_inst_ill_exception_raised     : std_ulogic;
    m_alu_range_exception_raised    : std_ulogic;
    m_data_pf_exception_raised      : std_ulogic;
    m_data_tlbmiss_exception_raised : std_ulogic;
    m_data_bus_exception_raised     : std_ulogic;
    m_syscall_exception_raised      : std_ulogic;
    m_trap_exception_raised         : std_ulogic;
    m_fp_exception_raised           : std_ulogic;
    m_inst_fetch_exception_raised   : std_ulogic;
    m_any_exception                 : std_ulogic;
    m_exception_sel                 : cpu_or1knd_i5_m_exception_sel_type;
    m_exception_sel_1hot_unpri      : std_ulogic_vector(12 downto 0);
    m_exception_sel_1hot            : std_ulogic_vector(12 downto 0);
    m_alu_range_exception           : std_ulogic;
    m_all_cancel                    : std_ulogic;
    m_ldst_cancel                   : std_ulogic;
    
    m_reg_write_cancel              : std_ulogic;
    m_reg_write_div_cancel          : std_ulogic;

    m_load_ready                    : std_ulogic;
    m_load_buffer_write             : std_ulogic;
    m_load_stall                    : std_ulogic;
    m_store_stall                   : std_ulogic;
    m_msync_stall                   : std_ulogic;
    m_mul_stall                     : std_ulogic;
    m_madd_stall                    : std_ulogic;
    m_div_stall                     : std_ulogic;

    m_mfspr_stall                   : std_ulogic;
    m_mfspr_sys_gpr                     : std_ulogic;
    m_mfspr_data_sys_sr             : or1k_word_type;
    m_mfspr_data_sys_esr0           : or1k_word_type;
    m_mfspr_data_sys_aecr           : or1k_word_type;
    m_mfspr_data_sys_aesr           : or1k_word_type;
    m_mfspr_data_dp_sel             : m_mfspr_data_dp_sel_type;
    m_mfspr_data_dp                 : or1k_word_type;
    m_mfspr_data_sel                : cpu_or1knd_i5_m_mfspr_data_sel_type;

    m_mtspr_stall                   : std_ulogic;
    m_mtspr_sys_sr                  : std_ulogic;
    m_mtspr_sys_epcr0               : std_ulogic;
    m_mtspr_sys_eear0               : std_ulogic;
    m_mtspr_sys_esr0                : std_ulogic;
    m_mtspr_sys_gpr                 : std_ulogic;
    m_mtspr_sys_aecr                : std_ulogic;
    m_mtspr_sys_aesr                : std_ulogic;
    m_mtspr_icache_icbir            : std_ulogic;
    m_mtspr_dcache_dcbfr            : std_ulogic;
    m_mtspr_dcache_dcbir            : std_ulogic;
    m_mtspr_dcache_dcbwr            : std_ulogic;
    m_mtspr_dcache_dcbxr            : std_ulogic;
    m_mtspr_mac_machi               : std_ulogic;
    m_mtspr_mac_maclo               : std_ulogic;

    m_mtspr_user_illegal            : std_ulogic;
    m_mfspr_user_illegal            : std_ulogic;

    m_mtspr_data_sys_sr             : spr_sys_sr_type;
    m_mtspr_data_sys_sr_user        : spr_sys_sr_user_type;
    m_mtspr_data_sys_aecsr          : spr_sys_aecsr_type;

    m_cy_mulu                       : std_ulogic;
    m_cy_macuadd                    : std_ulogic;
    m_ov_mul                        : std_ulogic;
    m_ov_macadd                     : std_ulogic;
    m_ov_div                        : std_ulogic;
    
    m_spr_sys_sr_user_new_sel       : m_spr_sys_sr_user_new_sel_type;
    m_spr_sys_sr_user_new_default   : spr_sys_sr_user_type;
    m_spr_sys_sr_user_new           : spr_sys_sr_user_type;
    m_spr_sys_sr_new_sel            : m_spr_sys_sr_new_sel_type;
    m_spr_sys_sr_new_except         : spr_sys_sr_type;
    m_spr_sys_sr_new                : spr_sys_sr_type;
    
    m_spr_sys_esr0_sel              : m_spr_sys_esr0_sel_type;
    m_spr_sys_esr0_new              : spr_sys_sr_type;
    m_spr_sys_esr0_user_new         : spr_sys_sr_user_type;
    m_spr_sys_eear0_write           : std_ulogic;
    m_spr_sys_eear0_sel             : cpu_or1knd_i5_m_spr_sys_eear0_sel_type;
    m_spr_sys_epcr0_write           : std_ulogic;
    m_spr_sys_epcr0_sel_next_pc     : std_ulogic;
    m_spr_sys_epcr0_sel             : cpu_or1knd_i5_m_spr_sys_epcr0_sel_type;
    m_spr_sys_aecr_write            : std_ulogic;
    m_spr_sys_aecr_new              : spr_sys_aecsr_type;
    m_spr_sys_aesr_new_except       : spr_sys_aecsr_type;
    m_spr_sys_aesr_new_sel          : m_spr_sys_aesr_new_sel_type;
    m_spr_sys_aesr_new              : spr_sys_aecsr_type;
    m_spr_mac_maclo_write           : std_ulogic;
    m_spr_mac_maclo_sel             : cpu_or1knd_i5_m_spr_mac_maclo_sel_type;
    m_spr_mac_machi_write           : std_ulogic;
    m_spr_mac_machi_sel             : cpu_or1knd_i5_m_spr_mac_machi_sel_type;

    m_exception_flush               : std_ulogic;
    m_mtspr_flush                   : std_ulogic;
    m_rfe_flush                     : std_ulogic;
    m_full_flush                    : std_ulogic;

    m_reg_write                     : std_ulogic;

    regfile_re1                     : std_ulogic;
    regfile_raddr1_sel_unpri        : std_ulogic_vector(3 downto 0);
    regfile_raddr1_sel_pri          : std_ulogic_vector(3 downto 0);
    regfile_raddr1_sel              : cpu_or1knd_i5_regfile_raddr1_sel_type;
    regfile_re2                     : std_ulogic;
    regfile_raddr2_sel_unpri        : std_ulogic_vector(2 downto 0);
    regfile_raddr2_sel_pri          : std_ulogic_vector(2 downto 0);
    regfile_raddr2_sel              : cpu_or1knd_i5_regfile_raddr2_sel_type;
    regfile_we                      : std_ulogic;
    regfile_w_sel                   : cpu_or1knd_i5_regfile_w_sel_type;

    l1mem_inst_vaddr_sel            : cpu_or1knd_i5_l1mem_inst_vaddr_sel_type;
    l1mem_data_vaddr_sel            : cpu_or1knd_i5_l1mem_data_vaddr_sel_type;
    l1mem_data_alloc                : std_ulogic;
    l1mem_data_writethrough         : std_ulogic;
    l1mem_data_cacheen              : std_ulogic;
    l1mem_data_mmuen                : std_ulogic;
    l1mem_data_priv                 : std_ulogic;

  end record;
  
  signal r, r_next : reg_type;
  signal c : comb_type;

  pure function decode_inst_flags(inst : in or1k_inst_type) return inst_flags_type is

    variable l_add    : std_ulogic;
    variable l_addc   : std_ulogic;
    variable l_addi   : std_ulogic;
    variable l_addic  : std_ulogic;
    variable l_and    : std_ulogic;
    variable l_andi   : std_ulogic;
    variable l_bf     : std_ulogic;
    variable l_bnf    : std_ulogic;
    variable l_cmov   : std_ulogic;
    variable l_csync  : std_ulogic;
    variable l_div    : std_ulogic;
    variable l_divu   : std_ulogic;
    variable l_extbs  : std_ulogic;
    variable l_extbz  : std_ulogic;
    variable l_exths  : std_ulogic;
    variable l_exthz  : std_ulogic;
    variable l_extws  : std_ulogic;
    variable l_extwz  : std_ulogic;
    variable l_ff1    : std_ulogic;
    variable l_fl1    : std_ulogic;
    variable l_j      : std_ulogic;
    variable l_jal    : std_ulogic;
    variable l_jalr   : std_ulogic;
    variable l_jr     : std_ulogic;
    variable l_lbs    : std_ulogic;
    variable l_lbz    : std_ulogic;
    variable l_lhs    : std_ulogic;
    variable l_lhz    : std_ulogic;
    variable l_lws    : std_ulogic;
    variable l_lwz    : std_ulogic;
    variable l_mac    : std_ulogic;
    variable l_maci   : std_ulogic;
    variable l_macrc  : std_ulogic;
    variable l_macu   : std_ulogic;
    variable l_mfspr  : std_ulogic;
    variable l_movhi  : std_ulogic;
    variable l_msb    : std_ulogic;
    variable l_msbu   : std_ulogic;
    variable l_msync  : std_ulogic;
    variable l_mtspr  : std_ulogic;
    variable l_mul    : std_ulogic;
    variable l_muld   : std_ulogic;
    variable l_muldu  : std_ulogic;
    variable l_muli   : std_ulogic;
    variable l_mulu   : std_ulogic;
    variable l_nop    : std_ulogic;
    variable l_or     : std_ulogic;
    variable l_ori    : std_ulogic;
    variable l_psync  : std_ulogic;
    variable l_rfe    : std_ulogic;
    variable l_ror    : std_ulogic;
    variable l_rori   : std_ulogic;
    variable l_sb     : std_ulogic;
    variable l_sfeq   : std_ulogic;
    variable l_sfeqi  : std_ulogic;
    variable l_sfges  : std_ulogic;
    variable l_sfgesi : std_ulogic;
    variable l_sfgeu  : std_ulogic;
    variable l_sfgeui : std_ulogic;
    variable l_sfgts  : std_ulogic;
    variable l_sfgtsi : std_ulogic;
    variable l_sfgtu  : std_ulogic;
    variable l_sfgtui : std_ulogic;
    variable l_sfles  : std_ulogic;
    variable l_sflesi : std_ulogic;
    variable l_sfleu  : std_ulogic;
    variable l_sfleui : std_ulogic;
    variable l_sflts  : std_ulogic;
    variable l_sfltsi : std_ulogic;
    variable l_sfltu  : std_ulogic;
    variable l_sfltui : std_ulogic;
    variable l_sfne   : std_ulogic;
    variable l_sfnei  : std_ulogic;
    variable l_sh     : std_ulogic;
    variable l_sll    : std_ulogic;
    variable l_slli   : std_ulogic;
    variable l_sra    : std_ulogic;
    variable l_srai   : std_ulogic;
    variable l_srl    : std_ulogic;
    variable l_srli   : std_ulogic;
    variable l_sub    : std_ulogic;
    variable l_sw     : std_ulogic;
    variable l_sys    : std_ulogic;
    variable l_trap   : std_ulogic;
    variable l_xor    : std_ulogic;
    variable l_xori   : std_ulogic;
    
    variable ret : inst_flags_type;
  begin

    l_j         := logic_eq(inst and "11111100000000000000000000000000", "00000000000000000000000000000000");
    l_jal       := logic_eq(inst and "11111100000000000000000000000000", "00000100000000000000000000000000");
    l_bnf       := logic_eq(inst and "11111100000000000000000000000000", "00001100000000000000000000000000");
    l_bf        := logic_eq(inst and "11111100000000000000000000000000", "00010000000000000000000000000000");
    l_nop       := logic_eq(inst and "11111111000000000000000000000000", "00010101000000000000000000000000");
    l_movhi     := logic_eq(inst and "11111100000000010000000000000000", "00011000000000000000000000000000");
    if cpu_or1knd_i5_madd_enable then
      l_macrc     := logic_eq(inst and "11111100000000011111111111111111", "00011000000000010000000000000000");
    end if;
    l_sys       := logic_eq(inst and "11111111111111110000000000000000", "00100000000000000000000000000000");
    l_trap      := logic_eq(inst and "11111111111111110000000000000000", "00100001000000000000000000000000");
    l_msync     := logic_eq(inst and "11111111111111111111111111111111", "00100010000000000000000000000000");
    l_psync     := logic_eq(inst and "11111111111111111111111111111111", "00100010100000000000000000000000");
    l_csync     := logic_eq(inst and "11111111111111111111111111111111", "00100011000000000000000000000000");
    l_rfe       := logic_eq(inst and "11111100000000000000000000000000", "00100100000000000000000000000000");
    l_jr        := logic_eq(inst and "11111100000000000000000000000000", "01000100000000000000000000000000");
    l_jalr      := logic_eq(inst and "11111100000000000000000000000000", "01001000000000000000000000000000");
    if cpu_or1knd_i5_madd_enable then
      l_maci      := logic_eq(inst and "11111100000000000000000000000000", "01001100000000000000000000000000");
    end if;
    l_lwz       := logic_eq(inst and "11111100000000000000000000000000", "10000100000000000000000000000000");
    l_lws       := logic_eq(inst and "11111100000000000000000000000000", "10001000000000000000000000000000");
    l_lbz       := logic_eq(inst and "11111100000000000000000000000000", "10001100000000000000000000000000");
    l_lbs       := logic_eq(inst and "11111100000000000000000000000000", "10010000000000000000000000000000");
    l_lhz       := logic_eq(inst and "11111100000000000000000000000000", "10010100000000000000000000000000");
    l_lhs       := logic_eq(inst and "11111100000000000000000000000000", "10011000000000000000000000000000");
    l_addi      := logic_eq(inst and "11111100000000000000000000000000", "10011100000000000000000000000000");
    l_addic     := logic_eq(inst and "11111100000000000000000000000000", "10100000000000000000000000000000");
    l_andi      := logic_eq(inst and "11111100000000000000000000000000", "10100100000000000000000000000000");
    l_ori       := logic_eq(inst and "11111100000000000000000000000000", "10101000000000000000000000000000");
    l_xori      := logic_eq(inst and "11111100000000000000000000000000", "10101100000000000000000000000000");
    l_muli      := logic_eq(inst and "11111100000000000000000000000000", "10110000000000000000000000000000");
    l_mfspr     := logic_eq(inst and "11111100000000000000000000000000", "10110100000000000000000000000000");
    l_slli      := logic_eq(inst and "11111100000000000000000011000000", "10111000000000000000000000000000");
    l_srli      := logic_eq(inst and "11111100000000000000000011000000", "10111000000000000000000001000000");
    l_srai      := logic_eq(inst and "11111100000000000000000011000000", "10111000000000000000000010000000");
    l_rori      := logic_eq(inst and "11111100000000000000000011000000", "10111000000000000000000011000000");
    l_sfeqi     := logic_eq(inst and "11111111111000000000000000000000", "10111100000000000000000000000000");
    l_sfnei     := logic_eq(inst and "11111111111000000000000000000000", "10111100001000000000000000000000");
    l_sfgtui    := logic_eq(inst and "11111111111000000000000000000000", "10111100010000000000000000000000");
    l_sfgeui    := logic_eq(inst and "11111111111000000000000000000000", "10111100011000000000000000000000");
    l_sfltui    := logic_eq(inst and "11111111111000000000000000000000", "10111100100000000000000000000000");
    l_sfleui    := logic_eq(inst and "11111111111000000000000000000000", "10111100101000000000000000000000");
    l_sfgtsi    := logic_eq(inst and "11111111111000000000000000000000", "10111101010000000000000000000000");
    l_sfgesi    := logic_eq(inst and "11111111111000000000000000000000", "10111101011000000000000000000000");
    l_sfltsi    := logic_eq(inst and "11111111111000000000000000000000", "10111101100000000000000000000000");
    l_sflesi    := logic_eq(inst and "11111111111000000000000000000000", "10111101101000000000000000000000");
    l_mtspr     := logic_eq(inst and "11111100000000000000000000000000", "11000000000000000000000000000000");
    if cpu_or1knd_i5_madd_enable then
      l_mac       := logic_eq(inst and "11111100000000000000000000001111", "11000100000000000000000000000001");
      l_macu      := logic_eq(inst and "11111100000000000000000000001111", "11000100000000000000000000000011");
      l_msb       := logic_eq(inst and "11111100000000000000000000001111", "11000100000000000000000000000010");
      l_msbu      := logic_eq(inst and "11111100000000000000000000001111", "11000100000000000000000000000100");
    end if;
    l_sw        := logic_eq(inst and "11111100000000000000000000000000", "11010100000000000000000000000000");
    l_sb        := logic_eq(inst and "11111100000000000000000000000000", "11011000000000000000000000000000");
    l_sh        := logic_eq(inst and "11111100000000000000000000000000", "11011100000000000000000000000000");
    l_exths     := logic_eq(inst and "11111100000000000000001111001111", "11100000000000000000000000001100");
    l_extws     := logic_eq(inst and "11111100000000000000001111001111", "11100000000000000000000000001101");
    l_extbs     := logic_eq(inst and "11111100000000000000001111001111", "11100000000000000000000001001100");
    l_extwz     := logic_eq(inst and "11111100000000000000001111001111", "11100000000000000000000001001101");
    l_exthz     := logic_eq(inst and "11111100000000000000001111001111", "11100000000000000000000010001100");
    l_extbz     := logic_eq(inst and "11111100000000000000001111001111", "11100000000000000000000011001100");
    l_add       := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000000000000000");
    l_addc      := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000000000000001");
    l_sub       := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000000000000010");
    l_and       := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000000000000011");
    l_or        := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000000000000100");
    l_xor       := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000000000000101");
    l_cmov      := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000000000001110");
    l_ff1       := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000000000001111");
    l_sll       := logic_eq(inst and "11111100000000000000001111001111", "11100000000000000000000000001000");
    l_srl       := logic_eq(inst and "11111100000000000000001111001111", "11100000000000000000000001001000");
    l_sra       := logic_eq(inst and "11111100000000000000001111001111", "11100000000000000000000010001000");
    l_ror       := logic_eq(inst and "11111100000000000000001111001111", "11100000000000000000000011001000");
    l_fl1       := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000000100001111");
    l_mul       := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000001100000110");
    if cpu_or1knd_i5_madd_enable then
      l_muld      := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000001100000111");
    end if;
    l_div       := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000001100001001");
    l_divu      := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000001100001010");
    l_mulu      := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000001100001011");
    if cpu_or1knd_i5_madd_enable then
      l_muldu     := logic_eq(inst and "11111100000000000000001100001111", "11100000000000000000001100001100");
    end if;
    l_sfeq      := logic_eq(inst and "11111111111000000000000000000000", "11100100000000000000000000000000");
    l_sfne      := logic_eq(inst and "11111111111000000000000000000000", "11100100001000000000000000000000");
    l_sfgtu     := logic_eq(inst and "11111111111000000000000000000000", "11100100010000000000000000000000");
    l_sfgeu     := logic_eq(inst and "11111111111000000000000000000000", "11100100011000000000000000000000");
    l_sfltu     := logic_eq(inst and "11111111111000000000000000000000", "11100100100000000000000000000000");
    l_sfleu     := logic_eq(inst and "11111111111000000000000000000000", "11100100101000000000000000000000");
    l_sfgts     := logic_eq(inst and "11111111111000000000000000000000", "11100101010000000000000000000000");
    l_sfges     := logic_eq(inst and "11111111111000000000000000000000", "11100101011000000000000000000000");
    l_sflts     := logic_eq(inst and "11111111111000000000000000000000", "11100101100000000000000000000000");
    l_sfles     := logic_eq(inst and "11111111111000000000000000000000", "11100101101000000000000000000000");

    ret.class(inst_class_index_nop)     := l_nop;
    ret.class(inst_class_index_alu)     := (
      l_movhi or
      l_addi or
      l_addic or
      l_andi or
      l_ori or
      l_xori or
      l_slli or
      l_srli or
      l_srai or
      l_rori or
      l_sfeqi or
      l_sfnei or
      l_sfgtui or
      l_sfgeui or
      l_sfltui or
      l_sfleui or
      l_sfgtsi or
      l_sfgesi or
      l_sfltsi or
      l_sflesi or
      l_exths or
      l_extws or
      l_extbs or
      l_extwz or
      l_exthz or
      l_extbz or
      l_add or
      l_addc or
      l_sub or
      l_and or
      l_or or
      l_xor or
      l_cmov or
      l_ff1 or
      l_sll or
      l_srl or
      l_sra or
      l_ror or
      l_fl1 or
      l_sfeq or
      l_sfne or
      l_sfgtu or
      l_sfgeu or
      l_sfltu or
      l_sfleu or
      l_sfgts or
      l_sfges or
      l_sflts or
      l_sfles
      );
    ret.class(inst_class_index_mul)     := (
      l_muli or
      l_mul or
      l_mulu
      );
    ret.class(inst_class_index_div)     := (
      l_div or
      l_divu
      );
    ret.class(inst_class_index_toc)     := (
      l_j or
      l_jal or
      l_bnf or
      l_bf or
      l_jr or
      l_jalr
      );
    ret.class(inst_class_index_load)    := (
      l_lwz or
      l_lws or
      l_lbz or
      l_lbs or
      l_lhz or
      l_lhs
      );
    ret.class(inst_class_index_store)   := (
      l_sw or
      l_sb or
      l_sh
      );
    if cpu_or1knd_i5_madd_enable then
      ret.class(inst_class_index_mac)     := (
        l_maci or
        l_mac or
        l_macu or
        l_msb or
        l_msbu or
        l_muld or
        l_muldu
        );
      ret.class(inst_class_index_macrc)   := l_macrc;
    else
      ret.class(inst_class_index_mac)     := '0';
      ret.class(inst_class_index_macrc)   := '0';
    end if;
    ret.class(inst_class_index_mfspr)   := l_mfspr;
    ret.class(inst_class_index_mtspr)   := l_mtspr;
    ret.class(inst_class_index_rfe)     := l_rfe;
    ret.class(inst_class_index_syscall) := l_sys;
    ret.class(inst_class_index_trap)    := l_trap;
    ret.class(inst_class_index_csync)    := l_csync;
    ret.class(inst_class_index_msync)    := l_msync;
    ret.class(inst_class_index_psync)    := l_psync;
    if cpu_or1knd_i5_madd_enable then
      ret.class(inst_class_index_illegal) := (
        not ret.class(inst_class_index_nop) and
        not ret.class(inst_class_index_alu) and
        not ret.class(inst_class_index_mul) and
        not ret.class(inst_class_index_div) and
        not ret.class(inst_class_index_toc) and
        not ret.class(inst_class_index_load) and
        not ret.class(inst_class_index_store) and
        not ret.class(inst_class_index_mac) and
        not ret.class(inst_class_index_macrc) and
        not ret.class(inst_class_index_mfspr) and
        not ret.class(inst_class_index_mtspr) and
        not ret.class(inst_class_index_rfe) and
        not ret.class(inst_class_index_syscall) and
        not ret.class(inst_class_index_trap) and
        not ret.class(inst_class_index_csync) and
        not ret.class(inst_class_index_msync) and
        not ret.class(inst_class_index_psync)
      );
    else
      ret.class(inst_class_index_illegal) := (
        not ret.class(inst_class_index_nop) and
        not ret.class(inst_class_index_alu) and
        not ret.class(inst_class_index_mul) and
        not ret.class(inst_class_index_div) and
        not ret.class(inst_class_index_toc) and
        not ret.class(inst_class_index_load) and
        not ret.class(inst_class_index_store) and
        not ret.class(inst_class_index_mfspr) and
        not ret.class(inst_class_index_mtspr) and
        not ret.class(inst_class_index_rfe) and
        not ret.class(inst_class_index_syscall) and
        not ret.class(inst_class_index_trap) and
        not ret.class(inst_class_index_csync) and
        not ret.class(inst_class_index_msync) and
        not ret.class(inst_class_index_psync)
      );
    end if;

    if cpu_or1knd_i5_madd_enable then
      ret.ra_dep(ra_dep_index_e_alu) := (
        l_maci or
        l_lwz or
        l_lws or
        l_lbz or
        l_lbs or
        l_lhz or
        l_lhs or
        l_addi or
        l_addic or
        l_andi or
        l_ori or
        l_xori or
        l_muli or
        l_mfspr or
        l_slli or
        l_srli or
        l_srai or
        l_rori or
        l_sfeqi or
        l_sfnei or
        l_sfgtui or
        l_sfgeui or
        l_sfltui or
        l_sfleui or
        l_sfgtsi or
        l_sfgesi or
        l_sfltsi or
        l_sflesi or
        l_mtspr or
        l_mac or
        l_macu or
        l_msb or
        l_msbu or
        l_sw or
        l_sb or
        l_sh or
        l_exths or
        l_extws or
        l_extbs or
        l_extwz or
        l_exthz or
        l_add or
        l_addc or
        l_sub or
        l_and or
        l_or or
        l_xor or
        l_cmov or
        l_ff1 or
        l_sll or
        l_srl or
        l_sra or
        l_ror or
        l_fl1 or
        l_mul or
        l_muld or
        l_div or
        l_divu or
        l_mulu or
        l_muldu or
        l_sfeq or
        l_sfne or
        l_sfgtu or
        l_sfgeu or
        l_sfltu or
        l_sfleu or
        l_sfgts or
        l_sfges or
        l_sflts or
        l_sfles
        );
    else
      ret.ra_dep(ra_dep_index_e_alu) := (
        l_lwz or
        l_lws or
        l_lbz or
        l_lbs or
        l_lhz or
        l_lhs or
        l_addi or
        l_addic or
        l_andi or
        l_ori or
        l_xori or
        l_muli or
        l_mfspr or
        l_slli or
        l_srli or
        l_srai or
        l_rori or
        l_sfeqi or
        l_sfnei or
        l_sfgtui or
        l_sfgeui or
        l_sfltui or
        l_sfleui or
        l_sfgtsi or
        l_sfgesi or
        l_sfltsi or
        l_sflesi or
        l_mtspr or
        l_sw or
        l_sb or
        l_sh or
        l_exths or
        l_extws or
        l_extbs or
        l_extwz or
        l_exthz or
        l_add or
        l_addc or
        l_sub or
        l_and or
        l_or or
        l_xor or
        l_cmov or
        l_ff1 or
        l_sll or
        l_srl or
        l_sra or
        l_ror or
        l_fl1 or
        l_mul or
        l_div or
        l_divu or
        l_mulu or
        l_sfeq or
        l_sfne or
        l_sfgtu or
        l_sfgeu or
        l_sfltu or
        l_sfleu or
        l_sfgts or
        l_sfges or
        l_sflts or
        l_sfles
        );
    end if;
    ret.ra_dep(ra_dep_index_none)  := (not ret.ra_dep(ra_dep_index_e_alu));

    if cpu_or1knd_i5_madd_enable then
      ret.rb_dep(rb_dep_index_e_alu) := (
        l_jr or
        l_jalr or
        l_mac or
        l_macu or
        l_msb or
        l_msbu or
        l_add or
        l_addc or
        l_sub or
        l_and or
        l_or or
        l_xor or
        l_cmov or
        l_sll or
        l_srl or
        l_sra or
        l_ror or
        l_mul or
        l_muld or
        l_div or
        l_divu or
        l_mulu or
        l_muldu or
        l_sfeq or
        l_sfne or
        l_sfgtu or
        l_sfgeu or
        l_sfltu or
        l_sfgts or
        l_sfges or
        l_sflts or
        l_sfles
        );
    else
      ret.rb_dep(rb_dep_index_e_alu) := (
        l_jr or
        l_jalr or
        l_add or
        l_addc or
        l_sub or
        l_and or
        l_or or
        l_xor or
        l_cmov or
        l_sll or
        l_srl or
        l_sra or
        l_ror or
        l_mul or
        l_div or
        l_divu or
        l_mulu or
        l_sfeq or
        l_sfne or
        l_sfgtu or
        l_sfgeu or
        l_sfltu or
        l_sfgts or
        l_sfges or
        l_sflts or
        l_sfles
        );
    end if;
    ret.rb_dep(rb_dep_index_e_store) := (
      l_sw or
      l_sb or
      l_sh or
      l_mfspr
      );
    ret.rb_dep(rb_dep_index_none) := (
      not ret.rb_dep(rb_dep_index_e_alu) and
      not ret.rb_dep(rb_dep_index_e_store)
      );

    ret.toc_indir := (l_jr or
                      l_jalr
                      );
    ret.toc_cond := (l_bf or
                     l_bnf
                     );
    ret.toc_not_flag := (l_bnf
                         );
    ret.toc_call := (l_jal or
                     l_jalr
                     );

    if cpu_or1knd_i5_madd_enable then
      ret.imm_sel(cpu_or1knd_i5_imm_sel_index_contig) := (
        l_nop or
        l_movhi or
        l_maci or
        l_lwz or
        l_lws or
        l_lbz or
        l_lbs or
        l_lhz or
        l_lhs or
        l_addi or
        l_addic or
        l_andi or
        l_ori or
        l_xori or
        l_muli or
        l_mfspr or
        l_sfeqi or
        l_sfnei or
        l_sfgtui or
        l_sfgeui or
        l_sfltui or
        l_sfleui or
        l_sfgtsi or
        l_sfgesi or
        l_sfltsi or
        l_sflesi
        );
    else
      ret.imm_sel(cpu_or1knd_i5_imm_sel_index_contig) := (
        l_nop or
        l_movhi or
        l_lwz or
        l_lws or
        l_lbz or
        l_lbs or
        l_lhz or
        l_lhs or
        l_addi or
        l_addic or
        l_andi or
        l_ori or
        l_xori or
        l_muli or
        l_mfspr or
        l_sfeqi or
        l_sfnei or
        l_sfgtui or
        l_sfgeui or
        l_sfltui or
        l_sfleui or
        l_sfgtsi or
        l_sfgesi or
        l_sfltsi or
        l_sflesi
        );
    end if;
    ret.imm_sel(cpu_or1knd_i5_imm_sel_index_split) := (
      l_mtspr or
      l_sw or
      l_sb or
      l_sh
      );
    ret.imm_sel(cpu_or1knd_i5_imm_sel_index_shift) := (
      l_slli or
      l_srli or
      l_srai or
      l_rori
      );
    ret.imm_sel(cpu_or1knd_i5_imm_sel_index_toc_offset) := (
      l_j or
      l_jal or
      l_bnf or
      l_bf
      );
    
    ret.imm_sext := (
      l_lwz or
      l_lws or
      l_lbz or
      l_lbs or
      l_lhz or
      l_lhs or
      l_addi or
      l_addic or
      l_xori or
      l_muli or
      l_sfeqi or
      l_sfnei or
      l_sfgtui or
      l_sfgeui or
      l_sfltui or
      l_sfleui or
      l_sfgtsi or
      l_sfgesi or
      l_sfltsi or
      l_sflesi or
      l_sw or
      l_sb or
      l_sh
      );
    
    if cpu_or1knd_i5_madd_enable then
      ret.alu_src1_sel(cpu_or1knd_i5_alu_src1_sel_index_ra) := (
        l_maci or
        l_lwz or
        l_lws or
        l_lbz or
        l_lbs or
        l_lhz or
        l_lhs or
        l_addi or
        l_addic or
        l_andi or
        l_ori or
        l_xori or
        l_muli or
        l_mfspr or
        l_slli or
        l_srli or
        l_srai or
        l_rori or
        l_sfeqi or
        l_sfnei or
        l_sfgtui or
        l_sfgeui or
        l_sfltui or
        l_sfleui or
        l_sfgtsi or
        l_sfgesi or
        l_sfltsi or
        l_sflesi or
        l_mtspr or
        l_mac or
        l_macu or
        l_msb or
        l_msbu or
        l_sw or
        l_sb or
        l_sh or
        l_exths or
        l_extws or
        l_extbs or
        l_extwz or
        l_exthz or
        l_extbz or
        l_add or
        l_addc or
        l_sub or
        l_and or
        l_or or
        l_xor or
        l_cmov or
        l_ff1 or
        l_sll or
        l_srl or
        l_sra or
        l_ror or
        l_fl1 or
        l_mul or
        l_muld or
        l_div or
        l_divu or
        l_mulu or
        l_muldu or
        l_sfeq or
        l_sfne or
        l_sfgtu or
        l_sfgeu or
        l_sfltu or
        l_sfleu or
        l_sfgts or
        l_sfges or
        l_sflts or
        l_sfles
        );
    else
      ret.alu_src1_sel(cpu_or1knd_i5_alu_src1_sel_index_ra) := (
        l_lwz or
        l_lws or
        l_lbz or
        l_lbs or
        l_lhz or
        l_lhs or
        l_addi or
        l_addic or
        l_andi or
        l_ori or
        l_xori or
        l_muli or
        l_mfspr or
        l_slli or
        l_srli or
        l_srai or
        l_rori or
        l_sfeqi or
        l_sfnei or
        l_sfgtui or
        l_sfgeui or
        l_sfltui or
        l_sfleui or
        l_sfgtsi or
        l_sfgesi or
        l_sfltsi or
        l_sflesi or
        l_mtspr or
        l_sw or
        l_sb or
        l_sh or
        l_exths or
        l_extws or
        l_extbs or
        l_extwz or
        l_exthz or
        l_extbz or
        l_add or
        l_addc or
        l_sub or
        l_and or
        l_or or
        l_xor or
        l_cmov or
        l_ff1 or
        l_sll or
        l_srl or
        l_sra or
        l_ror or
        l_fl1 or
        l_mul or
        l_div or
        l_divu or
        l_mulu or
        l_sfeq or
        l_sfne or
        l_sfgtu or
        l_sfgeu or
        l_sfltu or
        l_sfleu or
        l_sfgts or
        l_sfges or
        l_sflts or
        l_sfles
        );
    end if;
    ret.alu_src1_sel(cpu_or1knd_i5_alu_src1_sel_index_pc) := (
      l_j or
      l_jal or
      l_bnf or
      l_bf
      );

    if cpu_or1knd_i5_madd_enable then
      ret.alu_src2_sel(cpu_or1knd_i5_alu_src2_sel_index_rb) := (
        l_jr or
        l_jalr or
        l_mac or
        l_macu or
        l_msb or
        l_msbu or
        l_add or
        l_addc or
        l_sub or
        l_and or
        l_or or
        l_xor or
        l_cmov or
        l_sll or
        l_srl or
        l_sra or
        l_ror or
        l_mul or
        l_muld or
        l_div or
        l_divu or
        l_mulu or
        l_muldu or
        l_sfeq or
        l_sfne or
        l_sfgtu or
        l_sfgeu or
        l_sfltu or
        l_sfleu or
        l_sfgts or
        l_sfges or
        l_sflts or
        l_sfles
        );
      ret.alu_src2_sel(cpu_or1knd_i5_alu_src2_sel_index_imm) := (
        l_j or
        l_jal or
        l_bnf or
        l_bf or
        l_movhi or
        l_maci or
        l_lwz or
        l_lws or
        l_lbz or
        l_lbs or
        l_lhz or
        l_lhs or
        l_addi or
        l_addic or
        l_andi or
        l_ori or
        l_xori or
        l_muli or
        l_mfspr or
        l_slli or
        l_srli or
        l_srai or
        l_rori or
        l_sfeqi or
        l_sfnei or
        l_sfgtui or
        l_sfgeui or
        l_sfltui or
        l_sfleui or
        l_sfgtsi or
        l_sfgesi or
        l_sfltsi or
        l_sflesi or
        l_mtspr or
        l_sw or
        l_sb or
        l_sh
        );
      else
      ret.alu_src2_sel(cpu_or1knd_i5_alu_src2_sel_index_rb) := (
        l_jr or
        l_jalr or
        l_add or
        l_addc or
        l_sub or
        l_and or
        l_or or
        l_xor or
        l_cmov or
        l_sll or
        l_srl or
        l_sra or
        l_ror or
        l_mul or
        l_div or
        l_divu or
        l_mulu or
        l_sfeq or
        l_sfne or
        l_sfgtu or
        l_sfgeu or
        l_sfltu or
        l_sfleu or
        l_sfgts or
        l_sfges or
        l_sflts or
        l_sfles
        );
      ret.alu_src2_sel(cpu_or1knd_i5_alu_src2_sel_index_imm) := (
        l_j or
        l_jal or
        l_bnf or
        l_bf or
        l_movhi or
        l_lwz or
        l_lws or
        l_lbz or
        l_lbs or
        l_lhz or
        l_lhs or
        l_addi or
        l_addic or
        l_andi or
        l_ori or
        l_xori or
        l_muli or
        l_mfspr or
        l_slli or
        l_srli or
        l_srai or
        l_rori or
        l_sfeqi or
        l_sfnei or
        l_sfgtui or
        l_sfgeui or
        l_sfltui or
        l_sfleui or
        l_sfgtsi or
        l_sfgesi or
        l_sfltsi or
        l_sflesi or
        l_mtspr or
        l_sw or
        l_sb or
        l_sh
        );
      end if;

    ret.addsub_sub := (
      l_sub or
      l_sfgtui or
      l_sfgeui or
      l_sfltui or
      l_sfleui or
      l_sfgtsi or
      l_sfgesi or
      l_sfltsi or
      l_sflesi or
      l_sfgtu or
      l_sfgeu or
      l_sfltu or
      l_sfleu or
      l_sfgts or
      l_sfges or
      l_sflts or
      l_sfles
      );
    ret.addsub_use_carryin := (
      l_addic or
      l_addc
      );

    ret.shifter_right := (
      l_srli or
      l_srl  or
      l_srai or
      l_sra  or
      l_rori or
      l_ror
      );
    ret.shifter_unsgnd := (
      l_slli or
      l_sll or
      l_srli or
      l_srl
      );
    ret.shifter_rot := (
      l_rori or
      l_ror
      );

    if cpu_or1knd_i5_madd_enable then
      ret.mul_unsgnd := (
        l_macu  or
        l_msbu  or
        l_mulu  or
        l_muldu
        );
    else
      ret.mul_unsgnd := (
        l_mulu
        );
    end if;
    
    if cpu_or1knd_i5_madd_enable then
      ret.madd_unsgnd := (
        l_macu  or
        l_msbu  or
        l_mulu  or
        l_muldu
        );
      ret.madd_sub := (
        l_msb  or
        l_msbu
        );
      ret.madd_acc_zero := (
        l_muli or
        l_mul or
        l_muld or
        l_mulu or
        l_muldu
        );
    else
      ret.madd_unsgnd := 'X';
      ret.madd_sub := 'X';
      ret.madd_acc_zero := 'X';
    end if;

    ret.div_unsgnd := (
      l_divu
      );

    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_eq) := (
      l_sfeqi or
      l_sfeq
      );
    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_ne) := (
      l_sfnei or
      l_sfne
      );
    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_gtu) := (
      l_sfgtui or
      l_sfgtu
      );
    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_geu) := (
      l_sfgeui or
      l_sfgeu
      );
    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_ltu) := (
      l_sfltui or
      l_sfltu
      );
    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_leu) := (
      l_sfleui or
      l_sfleu
      );
    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_gts) := (
      l_sfgtsi or
      l_sfgts
      );
    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_ges) := (
      l_sfgesi or
      l_sfges
      );
    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_lts) := (
      l_sfltsi or
      l_sflts
      );
    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_les) := (
      l_sflesi or
      l_sfles
      );
    ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_none) := (
      not ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_eq) and
      not ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_ne) and
      not ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_gtu) and
      not ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_geu) and
      not ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_ltu) and
      not ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_leu) and
      not ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_gts) and
      not ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_ges) and
      not ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_lts) and
      not ret.set_spr_sys_sr_f(set_spr_sys_sr_f_index_les)
      );
    
    ret.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_e_add) := (
      l_addi or
      l_addic or
      l_add or
      l_addc or
      l_sub
      );
    ret.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_mulu) := (
      l_mulu
      );
    if cpu_or1knd_i5_madd_enable then
      ret.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_macuadd) := (
        l_macu or
        l_msbu
        );
    else
      ret.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_macuadd) := '0';
    end if;
    ret.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_none) := (
      not (ret.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_e_add) or
           ret.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_mulu) or
           ret.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_macuadd))
      );
    
    ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_e_add) := (
      l_addi or
      l_addic or
      l_add or
      l_addc or
      l_sub
      );
    ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_div) := (
      l_div or
      l_divu
      );
    ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_mul) := (
      l_mul
      );
    if cpu_or1knd_i5_madd_enable then
      ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_macadd) := (
        l_mac or
        l_msb
        );
      ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_none) := (
        not ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_e_add) and
        not ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_mul) and
        not ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_macadd) and
        not ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_div)
        );
    else
      ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_macadd) := '0';
      ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_none) := (
        not ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_e_add) and
        not ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_mul) and
        not ret.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_div)
        );
    end if;
    
    ret.alu_result_sel(cpu_or1knd_i5_alu_result_sel_index_addsub) := (
      l_addi or
      l_addic or
      l_add or
      l_addc or
      l_sub
      );
    ret.alu_result_sel(cpu_or1knd_i5_alu_result_sel_index_shifter) := (
      l_slli or
      l_srli or
      l_srai or
      l_rori or
      l_sll or
      l_srl or
      l_sra or
      l_ror
      );
    ret.alu_result_sel(cpu_or1knd_i5_alu_result_sel_index_and) := (
      l_andi or
      l_and
      );
    ret.alu_result_sel(cpu_or1knd_i5_alu_result_sel_index_or) := (
      l_ori or
      l_or
      );
    ret.alu_result_sel(cpu_or1knd_i5_alu_result_sel_index_xor) := (
      l_xori or
      l_xor
      );
    ret.alu_result_sel(cpu_or1knd_i5_alu_result_sel_index_cmov) := (
      l_cmov
      );
    ret.alu_result_sel(cpu_or1knd_i5_alu_result_sel_index_ff1) := (
      l_ff1
      );
    ret.alu_result_sel(cpu_or1knd_i5_alu_result_sel_index_fl1) := (
      l_fl1
      );
    ret.alu_result_sel(cpu_or1knd_i5_alu_result_sel_index_ext) := (
      l_exths or
      l_extws or
      l_extbs or
      l_extwz or
      l_exthz or
      l_extbz
      );
    ret.alu_result_sel(cpu_or1knd_i5_alu_result_sel_index_movhi) := (
      l_movhi
      );

    ret.sext := (
      l_lbs or
      l_lhs or
      l_lws or
      l_exths or
      l_extbs or
      l_extws
      );
    
    if cpu_or1knd_i5_madd_enable then
      ret.rd_write := (
        l_jal or
        l_movhi or
        l_macrc or
        l_jalr or
        l_lwz or
        l_lws or
        l_lbz or
        l_lbs or
        l_lhz or
        l_lhs or
        l_addi or
        l_addic or
        l_andi or
        l_ori or
        l_xori or
        l_muli or
        l_mfspr or
        l_slli or
        l_srli or
        l_srai or
        l_rori or
        l_exths or
        l_extws or
        l_extbs or
        l_extwz or
        l_exthz or
        l_extbz or
        l_add or
        l_addc or
        l_sub or
        l_and or
        l_or or
        l_xor or
        l_cmov or
        l_ff1 or
        l_sll or
        l_srl or
        l_sra or
        l_ror or
        l_fl1 or
        l_mul or
        l_div or
        l_divu or
        l_mulu
        );
    else
      ret.rd_write := (
        l_jal or
        l_movhi or
        l_jalr or
        l_lwz or
        l_lws or
        l_lbz or
        l_lbs or
        l_lhz or
        l_lhs or
        l_addi or
        l_addic or
        l_andi or
        l_ori or
        l_xori or
        l_muli or
        l_mfspr or
        l_slli or
        l_srli or
        l_srai or
        l_rori or
        l_exths or
        l_extws or
        l_extbs or
        l_extwz or
        l_exthz or
        l_extbz or
        l_add or
        l_addc or
        l_sub or
        l_and or
        l_or or
        l_xor or
        l_cmov or
        l_ff1 or
        l_sll or
        l_srl or
        l_sra or
        l_ror or
        l_fl1 or
        l_mul or
        l_div or
        l_divu or
        l_mulu
        );
    end if;
    ret.rd_data_sel(cpu_or1knd_i5_rd_data_sel_index_alu) := (
      l_movhi or
      l_addi or
      l_addic or
      l_andi or
      l_ori or
      l_xori or
      l_slli or
      l_srli or
      l_srai or
      l_rori or
      l_exths or
      l_extws or
      l_extbs or
      l_extwz or
      l_exthz or
      l_extbz or
      l_add or
      l_addc or
      l_sub or
      l_and or
      l_or or
      l_xor or
      l_cmov or
      l_ff1 or
      l_sll or
      l_srl or
      l_sra or
      l_ror or
      l_fl1 or
      (not ret.rd_write and 'X')
      );
    ret.rd_data_sel(cpu_or1knd_i5_rd_data_sel_index_load) := (
      l_lwz or
      l_lws or
      l_lbz or
      l_lbs or
      l_lhz or
      l_lhs or
      (not ret.rd_write and 'X')
      );
    ret.rd_data_sel(cpu_or1knd_i5_rd_data_sel_index_mfspr) := (
      l_mfspr or
      (not ret.rd_write and 'X')
      );
    ret.rd_data_sel(cpu_or1knd_i5_rd_data_sel_index_mul) := (
      l_mul    or
      l_muli   or
      l_mulu   or
      (not ret.rd_write and 'X')
      );
    ret.rd_data_sel(cpu_or1knd_i5_rd_data_sel_index_div) := (
      l_div or
      l_divu or
      (not ret.rd_write and 'X')
      );
    ret.rd_data_sel(cpu_or1knd_i5_rd_data_sel_index_pc_incr) := (
      l_jal or
      l_jalr or
      (not ret.rd_write and 'X')
      );
    if cpu_or1knd_i5_madd_enable then
      ret.rd_data_sel(cpu_or1knd_i5_rd_data_sel_index_maclo) := (
        l_macrc or
        (not ret.rd_write and 'X')
        );
    else
      ret.rd_data_sel(cpu_or1knd_i5_rd_data_sel_index_maclo) := '0';
    end if;

    ret.data_size_sel(cpu_or1knd_i5_data_size_sel_index_byte) := (
      l_lbs or
      l_lbz or
      l_sb or
      l_extbs or
      l_extbz
      );
    ret.data_size_sel(cpu_or1knd_i5_data_size_sel_index_half) := (
      l_lhs or
      l_lhz or
      l_sh or
      l_exths or
      l_exthz
      );
    ret.data_size_sel(cpu_or1knd_i5_data_size_sel_index_word) := (
      l_lws or
      l_lwz or
      l_sw or
      l_extws or
      l_extwz
      );

    ret.zero := all_zeros(inst);

    ret.aecsr_exceptions(spr_sys_aecsr_index_cyadde) := (
      l_addi or
      l_addic or
      l_add or
      l_addc or
      l_sub
      );
    ret.aecsr_exceptions(spr_sys_aecsr_index_ovadde) := (
      l_addi or
      l_addic or
      l_add or
      l_addc or
      l_sub
      );
    ret.aecsr_exceptions(spr_sys_aecsr_index_cymule) := (
      l_mulu
      );
    ret.aecsr_exceptions(spr_sys_aecsr_index_ovmule) := (
      l_muli or
      l_mul
      );
    ret.aecsr_exceptions(spr_sys_aecsr_index_dbze) := (
      l_div or
      l_divu
      );
    if cpu_or1knd_i5_madd_enable then
      ret.aecsr_exceptions(spr_sys_aecsr_index_cymacadde) := (
        l_macu or
        l_msbu
        );
      ret.aecsr_exceptions(spr_sys_aecsr_index_ovmacadde) := (
        l_maci or
        l_mac or
        l_msb
        );
    else
      ret.aecsr_exceptions(spr_sys_aecsr_index_cymacadde) := '0';
      ret.aecsr_exceptions(spr_sys_aecsr_index_ovmacadde) := '0';
    end if;
    
    return ret;
    
  end function;
  
begin

  ---------------------
  -- writeback stage --
  ---------------------
  
  ------------------
  -- memory stage --
  ------------------

  -- some mtspr/mfspr stuff
  c.m_mtspr_sys_sr    <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_sr);
  c.m_mtspr_sys_eear0 <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_eear0);
  c.m_mtspr_sys_epcr0 <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_epcr0);
  c.m_mtspr_sys_esr0  <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_esr0);
  c.m_mtspr_sys_gpr   <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_gpr);
  c.m_mtspr_sys_aecr  <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aecr);
  c.m_mtspr_sys_aesr  <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aesr);
  m_mtspr_mac_gen : if cpu_or1knd_i5_madd_enable generate
    c.m_mtspr_mac_machi <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_mac_machi);
    c.m_mtspr_mac_maclo <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_mac_maclo);
  end generate;
  c.m_mtspr_icache_icbir <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_icache_icbir);
  c.m_mtspr_dcache_dcbfr <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbfr);
  c.m_mtspr_dcache_dcbir <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbir);
  c.m_mtspr_dcache_dcbwr <= r.m.inst_flags.class(inst_class_index_mtspr) and r.m.spr_addr_valid and r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbwr);
  c.m_mtspr_dcache_dcbxr <= (
    c.m_mtspr_dcache_dcbfr or
    c.m_mtspr_dcache_dcbir or
    c.m_mtspr_dcache_dcbwr
    );

  c.m_mfspr_user_illegal <= (r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_sr) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_eear0) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_epcr0) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_esr0) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_gpr) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aecr) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aesr) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_icache_icbir) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbfr) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbir) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbwr)
                             );
  c.m_mtspr_user_illegal <= (r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_sr) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_eear0) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_epcr0) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_esr0) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_gpr) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aecr) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aesr) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_icache_icbir) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbfr) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbir) or
                             r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbwr)
                             );

  -- default SR user flags
  -- assumes no exception other than ALU range exception
  m_cy_ov_madd_enable_gen : if cpu_or1knd_i5_madd_enable generate
    c.m_cy_mulu    <= not cpu_or1knd_i5_pipe_dp_out_ctrl.m_madd_result_hi_zeros;
    c.m_ov_mul     <= ((not cpu_or1knd_i5_pipe_dp_out_ctrl.m_mul_result_msb and not cpu_or1knd_i5_pipe_dp_out_ctrl.m_madd_result_hi_zeros) or
                       (    cpu_or1knd_i5_pipe_dp_out_ctrl.m_mul_result_msb and not cpu_or1knd_i5_pipe_dp_out_ctrl.m_madd_result_hi_ones));
    c.m_cy_macuadd <= cpu_or1knd_i5_pipe_ctrl_in_misc.m_madd_overflow;
    c.m_ov_macadd  <= cpu_or1knd_i5_pipe_ctrl_in_misc.m_madd_overflow;
  end generate;
  m_cy_macuadd_madd_disable_gen : if cpu_or1knd_i5_mul_enable generate
    c.m_cy_mulu    <= cpu_or1knd_i5_pipe_ctrl_in_misc.m_mul_overflow;
    c.m_ov_mul     <= cpu_or1knd_i5_pipe_ctrl_in_misc.m_mul_overflow;
    c.m_cy_macuadd <= '0';
    c.m_ov_macadd  <= '0';
  end generate;
  c.m_ov_div <= cpu_or1knd_i5_pipe_ctrl_in_misc.m_div_overflow or cpu_or1knd_i5_pipe_ctrl_in_misc.m_div_dbz;
  
  c.m_spr_sys_sr_user_new_default <= (
    f  => ((r.m.inst_flags.set_spr_sys_sr_f(set_spr_sys_sr_f_index_none)     and r.p.spr_sys_sr_user.f) or
           (not r.m.inst_flags.set_spr_sys_sr_f(set_spr_sys_sr_f_index_none) and r.m.spr_sys_sr_user.f)
           ),
    cy => ((r.m.inst_flags.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_e_add)     and r.m.spr_sys_sr_user.cy) or
           (r.m.inst_flags.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_mulu)    and c.m_cy_mulu) or
           (r.m.inst_flags.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_macuadd) and c.m_cy_macuadd) or
           (r.m.inst_flags.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_none)      and r.p.spr_sys_sr_user.cy)
           ),
    ov => ((r.m.inst_flags.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_e_add)     and r.m.spr_sys_sr_user.ov) or
           (r.m.inst_flags.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_mul)     and c.m_ov_mul) or
           (r.m.inst_flags.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_macadd)  and c.m_ov_macadd) or
           (r.m.inst_flags.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_m_div)     and c.m_ov_div) or
           (r.m.inst_flags.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_none)      and r.p.spr_sys_sr_user.ov)
           )
    );
  
  -- check for exceptions

  -- all instructions may cause instruction fetch exceptions
  
  -- inst_class_alu: only causes range exception if ov_exception = '1'
  -- inst_class_cmov: never causes exception
  -- inst_class_toc: can cause align exception
  -- inst_class_load, inst_class_store: can cause data pf/but/align exceptions
  -- inst_class_mac: only causes range exception if ov_exception = '1'
  -- inst_class_macrc: never causes exceptions
  -- inst_class_mfspr, inst_class_mtspr: can cause illegal instruction exception
  -- inst_class_rfe: can cause illegal instruction exception
  -- inst_class_syscall: always causes syscall exception
  -- inst_class_trap: always causes trap exception
  -- inst_class_illegal: always causes illegal exception

  c.m_reset_exception_raised <= r.p.init;
  c.m_ext_exception_raised <= '0';
  c.m_tti_exception_raised <= '0';
  
  c.m_alu_range_exception_raised    <= (r.p.spr_sys_sr.ove and
                                        ((c.m_spr_sys_sr_user_new_default.cy and
                                          ((r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_cyadde) and
                                            r.p.spr_sys_aecr(spr_sys_aecsr_index_cyadde)) or
                                           (r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_cymule) and
                                            r.p.spr_sys_aecr(spr_sys_aecsr_index_cymule)) or
                                           (r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_cymacadde) and
                                            r.p.spr_sys_aecr(spr_sys_aecsr_index_cymacadde)))) or
                                         (c.m_spr_sys_sr_user_new_default.ov and
                                          ((r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_ovadde) and
                                            r.p.spr_sys_aecr(spr_sys_aecsr_index_ovadde)) or
                                           (r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_ovmule) and
                                            r.p.spr_sys_aecr(spr_sys_aecsr_index_ovmule)) or
                                           (r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_dbze) and
                                            r.p.spr_sys_aecr(spr_sys_aecsr_index_dbze)) or
                                           (r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_ovmacadde) and
                                            r.p.spr_sys_aecr(spr_sys_aecsr_index_ovmacadde))))
                                         ));
  
  c.m_fp_exception_raised           <= '0'; -- TODO
  
  c.m_data_pf_exception_raised      <= ((r.m.inst_flags.class(inst_class_index_load) or
                                         r.m.inst_flags.class(inst_class_index_store)) and
                                        cpu_l1mem_data_ctrl_out.ready and
                                        cpu_l1mem_data_ctrl_out.result(cpu_l1mem_data_result_code_index_pf));
  c.m_data_tlbmiss_exception_raised <= ((r.m.inst_flags.class(inst_class_index_load) or
                                         r.m.inst_flags.class(inst_class_index_store)) and
                                        cpu_l1mem_data_ctrl_out.ready and
                                        cpu_l1mem_data_ctrl_out.result(cpu_l1mem_data_result_code_index_pf));
  c.m_data_bus_exception_raised     <= ((r.m.inst_flags.class(inst_class_index_load) or
                                         r.m.inst_flags.class(inst_class_index_store)) and
                                        cpu_l1mem_data_ctrl_out.ready and
                                        cpu_l1mem_data_ctrl_out.result(cpu_l1mem_data_result_code_index_error));
  c.m_priv_inst_exception_raised    <= (not r.p.spr_sys_sr.sm and
                                        (r.m.inst_flags.class(inst_class_index_rfe) or
                                         (r.m.inst_flags.class(inst_class_index_mtspr) and c.m_mtspr_user_illegal) or
                                         (r.m.inst_flags.class(inst_class_index_mfspr) and c.m_mfspr_user_illegal)
                                         )
                                        );
  c.m_inst_ill_exception_raised     <= (r.m.inst_flags.class(inst_class_index_illegal) or
                                        (not r.p.spr_sys_sr.sm and (r.m.inst_flags.class(inst_class_index_rfe) or
                                                                    (r.m.inst_flags.class(inst_class_index_mtspr) and c.m_mtspr_user_illegal) or
                                                                    (r.m.inst_flags.class(inst_class_index_mfspr) and c.m_mfspr_user_illegal))));
  
  c.m_syscall_exception_raised      <= r.m.inst_flags.class(inst_class_index_syscall);
  c.m_trap_exception_raised         <= r.m.inst_flags.class(inst_class_index_trap);

  c.m_inst_fetch_exception_raised <= (r.m.inst_tlbmiss_exception_raised or
                                      r.m.inst_pf_exception_raised or
                                      r.m.inst_bus_exception_raised
                                      );
  
  -- prioritization of interrupts
  -- order taken from OpenRISC Architecture Manual
  c.m_exception_sel_1hot_unpri <= (12 => c.m_reset_exception_raised,
                                   11 => r.m.valid and r.m.inst_tlbmiss_exception_raised,
                                   10 => r.m.valid and r.m.inst_pf_exception_raised,
                                   9 => r.m.valid and r.m.inst_bus_exception_raised,
                                   8 => r.m.valid and (c.m_inst_ill_exception_raised or c.m_priv_inst_exception_raised),
                                   7 => r.m.valid and (r.m.toc_align_exception_raised or r.m.data_align_exception_raised),
                                   6 => r.m.valid and (c.m_data_tlbmiss_exception_raised or c.m_syscall_exception_raised or c.m_trap_exception_raised),
                                   5 => r.m.valid and c.m_data_pf_exception_raised,
                                   4 => r.m.valid and c.m_data_bus_exception_raised,
                                   3 => r.m.valid and c.m_alu_range_exception_raised,
                                   2 => r.m.valid and c.m_fp_exception_raised,
                                   1 => c.m_ext_exception_raised or c.m_tti_exception_raised,
                                   0 => '1'
                                   );

  m_exception_sel_1hot_prioritizer : entity tech.prioritizer(rtl)
    generic map (
      input_bits => 13
      )
    port map (
      datain  => c.m_exception_sel_1hot_unpri,
      dataout => c.m_exception_sel_1hot
      );
  c.m_any_exception <= not c.m_exception_sel_1hot(0);
  
  c.m_alu_range_exception <= c.m_exception_sel_1hot(2);
  
  c.m_exception_sel <= (cpu_or1knd_i5_m_exception_sel_index_reset    => c.m_exception_sel_1hot(12),
                        cpu_or1knd_i5_m_exception_sel_index_bus      => c.m_exception_sel_1hot(9) or c.m_exception_sel_1hot(4),
                        cpu_or1knd_i5_m_exception_sel_index_dpf      => c.m_exception_sel_1hot(5),
                        cpu_or1knd_i5_m_exception_sel_index_ipf      => c.m_exception_sel_1hot(10),
                        cpu_or1knd_i5_m_exception_sel_index_tti      => c.m_exception_sel_1hot(1) and c.m_tti_exception_raised,
                        cpu_or1knd_i5_m_exception_sel_index_align    => c.m_exception_sel_1hot(7),
                        cpu_or1knd_i5_m_exception_sel_index_ill      => c.m_exception_sel_1hot(8),
                        cpu_or1knd_i5_m_exception_sel_index_ext      => c.m_exception_sel_1hot(1) and c.m_ext_exception_raised,
                        cpu_or1knd_i5_m_exception_sel_index_dtlbmiss => c.m_exception_sel_1hot(6) and c.m_data_tlbmiss_exception_raised,
                        cpu_or1knd_i5_m_exception_sel_index_itlbmiss => c.m_exception_sel_1hot(11),
                        cpu_or1knd_i5_m_exception_sel_index_range    => c.m_exception_sel_1hot(3),
                        cpu_or1knd_i5_m_exception_sel_index_syscall  => c.m_exception_sel_1hot(6) and c.m_syscall_exception_raised,
                        cpu_or1knd_i5_m_exception_sel_index_fp       => c.m_exception_sel_1hot(2),
                        cpu_or1knd_i5_m_exception_sel_index_trap     => c.m_exception_sel_1hot(6) and c.m_trap_exception_raised
                        );
  
  c.m_all_cancel <= c.m_inst_fetch_exception_raised;
  
  -- load/store
  c.m_ldst_cancel <= (c.m_all_cancel or
                      c.m_data_tlbmiss_exception_raised or
                      c.m_data_pf_exception_raised or
                      c.m_data_bus_exception_raised or
                      r.m.data_align_exception_raised
                      );
  
  -- setup mfspr data
  c.m_mfspr_sys_gpr <= (r.m.inst_flags.class(inst_class_index_mfspr) and
                        r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_gpr) and
                        not c.m_all_cancel);
  
  c.m_mfspr_data_sel <= (
    cpu_or1knd_i5_m_mfspr_data_sel_index_ctrl        => (r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_sr) or
                                                         r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_esr0) or
                                                         r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aecr) or
                                                         r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aesr)
                                                         ),
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_vr      => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_vr),
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_upr     => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_upr),
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_cpucfgr => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_cpucfgr),
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_dmmucfgr => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dmmucfgr),
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_immucfgr => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_immucfgr),
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_dccfgr => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_dccfgr),
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_iccfgr => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_iccfgr),
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_eear0   => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_eear0),
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_epcr0   => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_epcr0),
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_gpr     => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_gpr),
    cpu_or1knd_i5_m_mfspr_data_sel_index_mac_maclo   => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_mac_maclo),
    cpu_or1knd_i5_m_mfspr_data_sel_index_mac_machi   => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_mac_machi)
    );

  c.m_mfspr_data_sys_sr <= (
    or1k_spr_field_sys_sr_sm    => r.p.spr_sys_sr.sm,
    or1k_spr_field_sys_sr_tee   => r.p.spr_sys_sr.tee,
    or1k_spr_field_sys_sr_iee   => r.p.spr_sys_sr.iee,
    or1k_spr_field_sys_sr_dce   => r.p.spr_sys_sr.dce and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_dcp),
    or1k_spr_field_sys_sr_ice   => r.p.spr_sys_sr.ice and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_icp),
    or1k_spr_field_sys_sr_dme   => r.p.spr_sys_sr.dme and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_dmp),
    or1k_spr_field_sys_sr_ime   => r.p.spr_sys_sr.ime and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_imp),
    or1k_spr_field_sys_sr_f     => r.p.spr_sys_sr_user.f,
    or1k_spr_field_sys_sr_cy    => r.p.spr_sys_sr_user.cy,
    or1k_spr_field_sys_sr_ov    => r.p.spr_sys_sr_user.ov,
    or1k_spr_field_sys_sr_ove   => r.p.spr_sys_sr.ove,
    or1k_spr_field_sys_sr_eph   => r.p.spr_sys_sr.eph,
    or1k_spr_field_sys_sr_fo    => '1',
    or1k_spr_field_sys_sr_sumra => r.p.spr_sys_sr.sumra,
    others => '0'
    );
  c.m_mfspr_data_sys_esr0 <= (
    or1k_spr_field_sys_sr_sm    => r.p.spr_sys_esr0.sm,
    or1k_spr_field_sys_sr_tee   => r.p.spr_sys_esr0.tee,
    or1k_spr_field_sys_sr_iee   => r.p.spr_sys_esr0.iee,
    or1k_spr_field_sys_sr_dce   => r.p.spr_sys_esr0.dce and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_dcp),
    or1k_spr_field_sys_sr_ice   => r.p.spr_sys_esr0.ice and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_icp),
    or1k_spr_field_sys_sr_dme   => r.p.spr_sys_esr0.dme and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_dmp),
    or1k_spr_field_sys_sr_ime   => r.p.spr_sys_esr0.ime and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_imp),
    or1k_spr_field_sys_sr_f     => r.p.spr_sys_esr0_user.f,
    or1k_spr_field_sys_sr_cy    => r.p.spr_sys_esr0_user.cy,
    or1k_spr_field_sys_sr_ov    => r.p.spr_sys_esr0_user.ov,
    or1k_spr_field_sys_sr_ove   => r.p.spr_sys_esr0.ove,
    or1k_spr_field_sys_sr_eph   => r.p.spr_sys_esr0.eph,
    or1k_spr_field_sys_sr_fo    => '1',
    or1k_spr_field_sys_sr_sumra => r.p.spr_sys_esr0.sumra,
    others => '0'
    );
  c.m_mfspr_data_sys_aecr <= (
    or1k_spr_field_sys_aecsr_cyadde    => r.p.spr_sys_aecr(spr_sys_aecsr_index_cyadde),
    or1k_spr_field_sys_aecsr_ovadde    => r.p.spr_sys_aecr(spr_sys_aecsr_index_ovadde),
    or1k_spr_field_sys_aecsr_cymule    => r.p.spr_sys_aecr(spr_sys_aecsr_index_cymule),
    or1k_spr_field_sys_aecsr_ovmule    => r.p.spr_sys_aecr(spr_sys_aecsr_index_ovmule),
    or1k_spr_field_sys_aecsr_dbze      => r.p.spr_sys_aecr(spr_sys_aecsr_index_dbze),
    or1k_spr_field_sys_aecsr_cymacadde => r.p.spr_sys_aecr(spr_sys_aecsr_index_cymacadde),
    or1k_spr_field_sys_aecsr_ovmacadde => r.p.spr_sys_aecr(spr_sys_aecsr_index_ovmacadde),
    others => '0'
    );
  c.m_mfspr_data_sys_aesr <= (
    or1k_spr_field_sys_aecsr_cyadde    => r.p.spr_sys_aesr(spr_sys_aecsr_index_cyadde),
    or1k_spr_field_sys_aecsr_ovadde    => r.p.spr_sys_aesr(spr_sys_aecsr_index_ovadde),
    or1k_spr_field_sys_aecsr_cymule    => r.p.spr_sys_aesr(spr_sys_aecsr_index_cymule),
    or1k_spr_field_sys_aecsr_ovmule    => r.p.spr_sys_aesr(spr_sys_aecsr_index_ovmule),
    or1k_spr_field_sys_aecsr_dbze      => r.p.spr_sys_aesr(spr_sys_aecsr_index_dbze),
    or1k_spr_field_sys_aecsr_cymacadde => r.p.spr_sys_aesr(spr_sys_aecsr_index_cymacadde),
    or1k_spr_field_sys_aecsr_ovmacadde => r.p.spr_sys_aesr(spr_sys_aecsr_index_ovmacadde),
    others => '0'
    );

  c.m_mfspr_data_dp_sel <= (
    m_mfspr_data_dp_sel_index_sys_sr   => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_sr),
    m_mfspr_data_dp_sel_index_sys_esr0 => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_esr0),
    m_mfspr_data_dp_sel_index_sys_aecr => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aecr),
    m_mfspr_data_dp_sel_index_sys_aesr => r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_aesr)
    );
  with c.m_mfspr_data_dp_sel select
    c.m_mfspr_data_dp <= c.m_mfspr_data_sys_sr   when m_mfspr_data_dp_sel_sys_sr,
                         c.m_mfspr_data_sys_esr0 when m_mfspr_data_dp_sel_sys_esr0,
                         c.m_mfspr_data_sys_aecr when m_mfspr_data_dp_sel_sys_aecr,
                         c.m_mfspr_data_sys_aesr when m_mfspr_data_dp_sel_sys_aesr,
                         (others => 'X')         when others;
  
  
  c.m_load_ready <= cpu_l1mem_data_ctrl_out.ready or r.p.m_load_data_buffered;
  c.m_load_stall  <= (not c.m_ldst_cancel and
                      r.m.inst_flags.class(inst_class_index_load) and
                      not c.m_load_ready);
  c.m_store_stall <= (not c.m_ldst_cancel and
                      r.m.inst_flags.class(inst_class_index_store) and
                      not cpu_l1mem_data_ctrl_out.ready);
  c.m_msync_stall <= (not c.m_all_cancel and
                      (r.m.inst_flags.class(inst_class_index_csync) or
                       r.m.inst_flags.class(inst_class_index_msync)
                       ) and
                      not cpu_l1mem_data_ctrl_out.ready);

  m_mul_madd_stall_mul : if cpu_or1knd_i5_mul_enable generate
    c.m_mul_stall <= (not c.m_all_cancel and
                      (r.m.inst_flags.class(inst_class_index_mul) and
                       not cpu_or1knd_i5_pipe_ctrl_in_misc.m_mul_valid));
    c.m_madd_stall <= '0';
  end generate;
  m_mul_madd_stall_madd : if cpu_or1knd_i5_madd_enable generate
    c.m_mul_stall <= '0';
    c.m_madd_stall <= (not c.m_all_cancel and
                       ((r.m.inst_flags.class(inst_class_index_mac) or
                         r.m.inst_flags.class(inst_class_index_mul)) and
                        not cpu_or1knd_i5_pipe_ctrl_in_misc.m_mul_valid));
  end generate;
  
  c.m_div_stall <= (not c.m_all_cancel and
                    (r.m.inst_flags.class(inst_class_index_div) and
                     not cpu_or1knd_i5_pipe_ctrl_in_misc.m_div_valid));
  
  c.m_mfspr_stall <= (not c.m_all_cancel and
                      r.m.inst_flags.class(inst_class_index_mfspr) and
                      (r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_sys_gpr) and not r.p.mfspr_sys_gpr_status)
                      );

  c.m_mtspr_stall <= (not c.m_all_cancel and
                      r.m.inst_flags.class(inst_class_index_mtspr) and
                      ((r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_icache_icbir) and not r.p.mtspr_icache_icbir_status) or
                       ((r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbfr) or
                         r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbir) or
                         r.m.spr_addr_sel(cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbwr)
                         ) and
                        not r.p.mtspr_dcache_dcbxr_status
                        )
                       )
                      );

  -- write to sprs
  -- setup mtspr data
  c.m_mtspr_data_sys_sr <= (
    sumra => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_sumra),
    eph   => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_eph),
    ove   => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_ove),
    ime   => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_ime) and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_imp),
    dme   => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_dme) and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_dmp),
    ice   => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_ice) and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_icp),
    dce   => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_dce) and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_dcp),
    iee   => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_iee),
    tee   => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_tee) and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_ttp),
    sm    => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_sm)
    );
  c.m_mtspr_data_sys_sr_user <= (
    f  => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_f),
    cy => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_cy),
    ov => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_sr_ov)
    );
  
  c.m_mtspr_data_sys_aecsr <= (
    spr_sys_aecsr_index_cyadde    => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_aecsr_cyadde),
    spr_sys_aecsr_index_ovadde    => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_aecsr_ovadde),
    spr_sys_aecsr_index_cymule    => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_aecsr_cymule),
    spr_sys_aecsr_index_ovmule    => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_aecsr_ovmule),
    spr_sys_aecsr_index_dbze      => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_aecsr_dbze),
    spr_sys_aecsr_index_cymacadde => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_aecsr_cymacadde),
    spr_sys_aecsr_index_ovmacadde => cpu_or1knd_i5_pipe_dp_out_ctrl.m_mtspr_data(or1k_spr_field_sys_aecsr_ovmacadde)
    );
  
  -- write user SR bits
  -- user SR bits are written every cycle, so must make sure inst is valid
  -- and no exceptions occurred
  -- SR user bits can be written in memory stage by mtspr or mac operations
  
  -- f flag can only be written by mtspr on SR register
  
  -- write non-user SR bits and exception related sprs
  
  -- default SR flags
  -- set SM bit if exception raised
  c.m_spr_sys_sr_new_except <= (
    sumra => r.p.spr_sys_sr.sumra,
    eph   => r.p.spr_sys_sr.eph,
    ove   => r.p.spr_sys_sr.ove,
    ime   => '0',
    dme   => '0',
    ice   => r.p.spr_sys_sr.ice and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_icp),
    dce   => r.p.spr_sys_sr.dce and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_dcp),
    iee   => '0',
    tee   => '0',
    sm    => '1'
    );

  c.m_spr_sys_sr_new_sel <= (
    m_spr_sys_sr_new_sel_index_init   => r.p.init,
    m_spr_sys_sr_new_sel_index_old    => (not c.m_any_exception and
                                          not (r.m.valid and (r.m.inst_flags.class(inst_class_index_rfe) or c.m_mtspr_sys_sr))),
    m_spr_sys_sr_new_sel_index_except => not r.p.init and c.m_any_exception,
    m_spr_sys_sr_new_sel_index_mtspr  => not c.m_any_exception and r.m.valid and c.m_mtspr_sys_sr,
    m_spr_sys_sr_new_sel_index_esr0   => not c.m_any_exception and r.m.valid and r.m.inst_flags.class(inst_class_index_rfe)
    );
  
  c.m_spr_sys_sr_user_new_sel <= (
    m_spr_sys_sr_user_new_sel_index_init    => r.p.init,
    m_spr_sys_sr_user_new_sel_index_old     => (not r.p.init and
                                                (not r.m.valid or
                                                 (c.m_any_exception and not c.m_alu_range_exception))),
    m_spr_sys_sr_user_new_sel_index_default => (c.m_alu_range_exception or
                                                (r.m.valid and
                                                 not c.m_any_exception and
                                                 not c.m_mtspr_sys_sr and
                                                 not r.m.inst_flags.class(inst_class_index_rfe))),
    m_spr_sys_sr_user_new_sel_index_mtspr   => (not c.m_any_exception and
                                                r.m.valid and c.m_mtspr_sys_sr),
    m_spr_sys_sr_user_new_sel_index_esr0    => (not c.m_any_exception and
                                                r.m.valid and r.m.inst_flags.class(inst_class_index_rfe))
    );

  with c.m_spr_sys_sr_new_sel select
    c.m_spr_sys_sr_new <= spr_sys_sr_init           when m_spr_sys_sr_new_sel_init,
                          r.p.spr_sys_sr            when m_spr_sys_sr_new_sel_old,
                          c.m_spr_sys_sr_new_except when m_spr_sys_sr_new_sel_except,
                          c.m_mtspr_data_sys_sr     when m_spr_sys_sr_new_sel_mtspr,
                          r.p.spr_sys_esr0          when m_spr_sys_sr_new_sel_esr0,
                          spr_sys_sr_x              when others;
  
  with c.m_spr_sys_sr_user_new_sel select
      c.m_spr_sys_sr_user_new <= spr_sys_sr_user_init            when m_spr_sys_sr_user_new_sel_init,
                                 r.p.spr_sys_sr_user             when m_spr_sys_sr_user_new_sel_old,
                                 c.m_spr_sys_sr_user_new_default when m_spr_sys_sr_user_new_sel_default,
                                 c.m_mtspr_data_sys_sr_user      when m_spr_sys_sr_user_new_sel_mtspr,
                                 r.p.spr_sys_esr0_user           when m_spr_sys_sr_user_new_sel_esr0,
                                 spr_sys_sr_user_x               when others;
  
  c.m_spr_sys_esr0_sel <= (
    m_spr_sys_esr0_sel_index_old     => not c.m_any_exception and not (r.m.valid and c.m_mtspr_sys_esr0),
    m_spr_sys_esr0_sel_index_init    => r.p.init,
    m_spr_sys_esr0_sel_index_mtspr   => not c.m_any_exception and r.m.valid and c.m_mtspr_sys_esr0,
    m_spr_sys_esr0_sel_index_sys_sr  => not r.p.init and c.m_any_exception
    );
  with c.m_spr_sys_esr0_sel select
    c.m_spr_sys_esr0_new <= r.p.spr_sys_esr0      when m_spr_sys_esr0_sel_old,
                            spr_sys_sr_init       when m_spr_sys_esr0_sel_init,
                            c.m_mtspr_data_sys_sr when m_spr_sys_esr0_sel_mtspr,
                            r.p.spr_sys_sr        when m_spr_sys_esr0_sel_sys_sr,
                            spr_sys_sr_x          when others;
  
  with c.m_spr_sys_esr0_sel select
    c.m_spr_sys_esr0_user_new <= r.p.spr_sys_esr0_user      when m_spr_sys_esr0_sel_old,
                                 spr_sys_sr_user_init       when m_spr_sys_esr0_sel_init,
                                 c.m_mtspr_data_sys_sr_user when m_spr_sys_esr0_sel_mtspr,
                                 r.p.spr_sys_sr_user        when m_spr_sys_esr0_sel_sys_sr,
                                 spr_sys_sr_user_x          when others;

  c.m_spr_sys_eear0_sel <= (
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_init    => r.p.init,
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_mtspr   => not c.m_any_exception and c.m_mtspr_sys_eear0,
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_pc      => (c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_ipf) or
                                                        (c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_align) and r.m.toc_align_exception_raised) or
                                                        c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_ill) or
                                                        c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_itlbmiss)
                                                        ),
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_addr    => (c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_dpf) or
                                                        (c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_align) and not r.m.toc_align_exception_raised) or
                                                        c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_dtlbmiss)
                                                        ),
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_inst_bus_error_eear => (c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_bus) and
                                                                    r.m.inst_bus_exception_raised),
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_data_bus_error_eear => (c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_bus) and
                                                                    c.m_data_bus_exception_raised)
    );
  c.m_spr_sys_eear0_write <= (r.p.init or
                              c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_bus) or
                              c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_dpf) or
                              c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_ipf) or
                              c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_align) or
                              c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_ill) or
                              c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_dtlbmiss) or
                              c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_itlbmiss) or
                              (r.m.valid and not c.m_all_cancel and c.m_mtspr_sys_eear0)
                              );
  
  -- these exception save the PC of the next-not-executed instruction
  c.m_spr_sys_epcr0_sel_next_pc <= (c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_tti) or
                                    c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_ext) or
                                    c.m_exception_sel(cpu_or1knd_i5_m_exception_sel_index_syscall));
  
  c.m_spr_sys_epcr0_sel <= (
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_init    => r.p.init,
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_mtspr   => not c.m_any_exception and c.m_mtspr_sys_epcr0,
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_m_pc    => not r.p.init and c.m_any_exception and not c.m_spr_sys_epcr0_sel_next_pc,
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_e_pc    => not r.p.init and c.m_any_exception and c.m_spr_sys_epcr0_sel_next_pc and r.e.valid,
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_d_pc    => not r.p.init and c.m_any_exception and c.m_spr_sys_epcr0_sel_next_pc and not r.e.valid and r.d.valid,
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_f_pc    => not r.p.init and c.m_any_exception and c.m_spr_sys_epcr0_sel_next_pc and not r.e.valid and not r.d.valid
    );
  c.m_spr_sys_epcr0_write <= (c.m_any_exception or
                              (r.m.valid and not c.m_all_cancel and c.m_mtspr_sys_epcr0)
                              );


  -- aecsr
  c.m_spr_sys_aecr_write <= r.m.valid and not c.m_all_cancel and c.m_mtspr_sys_aecr;
  with c.m_spr_sys_aecr_write select
    c.m_spr_sys_aecr_new <= c.m_mtspr_data_sys_aecsr when '1',
                            r.p.spr_sys_aecr         when '0',
                            (others => 'X')          when others;

  c.m_spr_sys_aesr_new_except <= (
    spr_sys_aecsr_index_cyadde    => c.m_spr_sys_sr_user_new_default.cy and r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_cyadde) and r.p.spr_sys_aecr(spr_sys_aecsr_index_cyadde),
    spr_sys_aecsr_index_ovadde    => c.m_spr_sys_sr_user_new_default.ov and r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_ovadde) and r.p.spr_sys_aecr(spr_sys_aecsr_index_ovadde),
    spr_sys_aecsr_index_cymule    => c.m_spr_sys_sr_user_new_default.cy and r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_cymule) and r.p.spr_sys_aecr(spr_sys_aecsr_index_cymule),
    spr_sys_aecsr_index_ovmule    => c.m_spr_sys_sr_user_new_default.ov and r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_ovmule) and r.p.spr_sys_aecr(spr_sys_aecsr_index_ovmule),
    spr_sys_aecsr_index_dbze      => c.m_spr_sys_sr_user_new_default.ov and r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_dbze)   and r.p.spr_sys_aecr(spr_sys_aecsr_index_dbze),
    spr_sys_aecsr_index_cymacadde => c.m_spr_sys_sr_user_new_default.cy and r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_cymacadde) and r.p.spr_sys_aecr(spr_sys_aecsr_index_cymacadde),
    spr_sys_aecsr_index_ovmacadde => c.m_spr_sys_sr_user_new_default.ov and r.m.inst_flags.aecsr_exceptions(spr_sys_aecsr_index_ovmacadde) and r.p.spr_sys_aecr(spr_sys_aecsr_index_ovmacadde)
    );
  c.m_spr_sys_aesr_new_sel <= (
    m_spr_sys_aesr_new_sel_index_old    => ((not r.m.valid or c.m_all_cancel or not c.m_mtspr_sys_aesr) and
                                            not c.m_alu_range_exception),
    m_spr_sys_aesr_new_sel_index_mtspr  => r.m.valid and not c.m_all_cancel and c.m_mtspr_sys_aesr,
    m_spr_sys_aesr_new_sel_index_except => c.m_alu_range_exception
    );
  with c.m_spr_sys_aesr_new_sel select
    c.m_spr_sys_aesr_new <= r.p.spr_sys_aesr            when m_spr_sys_aesr_new_sel_old,
                            c.m_mtspr_data_sys_aecsr    when m_spr_sys_aesr_new_sel_mtspr,
                            c.m_spr_sys_aesr_new_except when m_spr_sys_aesr_new_sel_except,
                            (others => 'X')             when others;
  
  m_spr_mac_gen : if cpu_or1knd_i5_madd_enable generate
    -- maclo
    c.m_spr_mac_maclo_sel <= (
      cpu_or1knd_i5_m_spr_mac_maclo_sel_index_mtspr   => r.m.inst_flags.class(inst_class_index_mtspr),
      cpu_or1knd_i5_m_spr_mac_maclo_sel_index_clear   => r.m.inst_flags.class(inst_class_index_macrc),
      cpu_or1knd_i5_m_spr_mac_maclo_sel_index_madd    => r.m.inst_flags.class(inst_class_index_mac)
      );
    c.m_spr_mac_maclo_write <= (r.m.valid and
                                not c.m_all_cancel and
                                (c.m_mtspr_mac_maclo or
                                 r.m.inst_flags.class(inst_class_index_macrc) or
                                 r.m.inst_flags.class(inst_class_index_mac)
                                 ));

    -- machi
    c.m_spr_mac_machi_sel <= (
      cpu_or1knd_i5_m_spr_mac_machi_sel_index_mtspr   => r.m.inst_flags.class(inst_class_index_mtspr),
      cpu_or1knd_i5_m_spr_mac_machi_sel_index_clear   => r.m.inst_flags.class(inst_class_index_macrc),
      cpu_or1knd_i5_m_spr_mac_machi_sel_index_madd    => r.m.inst_flags.class(inst_class_index_mac)
      );
    c.m_spr_mac_machi_write <= (r.m.valid and
                                not c.m_all_cancel and
                                (c.m_mtspr_mac_machi or
                                 r.m.inst_flags.class(inst_class_index_macrc) or
                                 r.m.inst_flags.class(inst_class_index_mac)
                                 ));
  end generate;

  c.m_reg_write_div_cancel <= r.m.inst_flags.class(inst_class_index_div) and r.m.spr_sys_sr_user.ov;
  c.m_reg_write_cancel <= ((c.m_any_exception and not c.m_alu_range_exception) or
                           c.m_reg_write_div_cancel);
  
  c.m_reg_write <= ((r.m.inst_flags.rd_write or
                     c.m_mtspr_sys_gpr) and
                    not c.m_reg_write_cancel);

  -------------------
  -- execute stage --
  -------------------
  
  -- read sr flags
  -- start with early values from mem cycle; we would have stalled if this
  -- isn't possible (e.g. a mul in m stage that will write cy, followed
  -- immediately by an addc that reads cy)
  with r.m.valid select
    c.e_spr_sys_sr_user <= r.m.spr_sys_sr_user when '1',
                           r.p.spr_sys_sr_user when '0',
                           spr_sys_sr_user_x   when others;
  
  -- resolve branch outcome
  c.e_toc_taken <= ((not r.e.inst_flags.toc_cond) or
                    (r.e.inst_flags.toc_not_flag xor c.e_spr_sys_sr_user.f));
  c.e_toc_align_exception_raised <= (r.e.inst_flags.class(inst_class_index_toc) and
                                     cpu_or1knd_i5_pipe_dp_out_ctrl.e_toc_target_misaligned);
  c.e_toc_mispred <= (c.e_toc_taken xor r.e.toc_pred_taken) or (r.e.btb_valid and cpu_or1knd_i5_pipe_dp_out_ctrl.e_btb_mispred);
  
  -- write sr flags
  -- initially use previous flag values

  -- setflag instructions
  with r.e.inst_flags.set_spr_sys_sr_f select
    c.e_spr_sys_sr_user_new.f <= c.e_spr_sys_sr_user.f                                                                   when set_spr_sys_sr_f_none,
                                 not cpu_or1knd_i5_pipe_dp_out_ctrl.e_not_equal                                          when set_spr_sys_sr_f_eq,
                                 cpu_or1knd_i5_pipe_dp_out_ctrl.e_not_equal                                              when set_spr_sys_sr_f_ne,
                                 not cpu_or1knd_i5_pipe_dp_out_ctrl.e_ltu and cpu_or1knd_i5_pipe_dp_out_ctrl.e_not_equal when set_spr_sys_sr_f_gtu,
                                 not cpu_or1knd_i5_pipe_dp_out_ctrl.e_ltu                                                when set_spr_sys_sr_f_geu,
                                 cpu_or1knd_i5_pipe_dp_out_ctrl.e_ltu                                                    when set_spr_sys_sr_f_ltu,
                                 cpu_or1knd_i5_pipe_dp_out_ctrl.e_ltu or not cpu_or1knd_i5_pipe_dp_out_ctrl.e_not_equal  when set_spr_sys_sr_f_leu,
                                 not cpu_or1knd_i5_pipe_dp_out_ctrl.e_lts and cpu_or1knd_i5_pipe_dp_out_ctrl.e_not_equal when set_spr_sys_sr_f_gts,
                                 not cpu_or1knd_i5_pipe_dp_out_ctrl.e_lts                                                when set_spr_sys_sr_f_ges,
                                 cpu_or1knd_i5_pipe_dp_out_ctrl.e_lts                                                    when set_spr_sys_sr_f_lts,
                                 cpu_or1knd_i5_pipe_dp_out_ctrl.e_lts or not cpu_or1knd_i5_pipe_dp_out_ctrl.e_not_equal  when set_spr_sys_sr_f_les,
                                 'X'                                                                                     when others;

  -- carry flag
  -- only operation that sets cy flag in e is add
  c.e_spr_sys_sr_user_new.cy <= ((r.e.inst_flags.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_e_add)     and cpu_or1knd_i5_pipe_ctrl_in_misc.e_addsub_carryout) or
                                 (not r.e.inst_flags.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_e_add) and c.e_spr_sys_sr_user.cy));

  -- overflow flag
  -- only operations that set ov flag in e are add and div
  c.e_spr_sys_sr_user_new.ov <= ((r.e.inst_flags.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_e_add) and cpu_or1knd_i5_pipe_ctrl_in_misc.e_addsub_overflow) or
                                 (not (r.e.inst_flags.set_spr_sys_sr_ov(set_spr_sys_sr_ov_index_e_add)) and c.e_spr_sys_sr_user.ov));
  
  -- select address to pass to m stage
  c.e_addr_sel(cpu_or1knd_i5_e_addr_sel_index_spr)  <= r.e.inst_flags.class(inst_class_index_mfspr) or r.e.inst_flags.class(inst_class_index_mtspr);
  c.e_addr_sel(cpu_or1knd_i5_e_addr_sel_index_ldst) <= r.e.inst_flags.class(inst_class_index_load)  or r.e.inst_flags.class(inst_class_index_store);

  -- cancellable effects
  c.e_inst_fetch_exception_raised <= (r.e.inst_pf_exception_raised or
                                      r.e.inst_tlbmiss_exception_raised or
                                      r.e.inst_bus_exception_raised);
  c.e_all_cancel <= c.e_inst_fetch_exception_raised;

  c.e_bpred_write <= r.e.valid and r.e.inst_flags.class(inst_class_index_toc) and not r.e.inst_flags.toc_indir and not c.e_all_cancel;
  
  -- outputs to madd unit
  e_madd_en_gen : if cpu_or1knd_i5_madd_enable generate
    c.e_mul_en <= (r.e.valid and
                   (r.e.inst_flags.class(inst_class_index_mac) or
                    r.e.inst_flags.class(inst_class_index_mul)) and
                   not c.e_all_cancel);
  end generate;

  e_mul_en_gen : if cpu_or1knd_i5_mul_enable generate
    c.e_mul_en <= (r.e.valid and
                   (r.e.inst_flags.class(inst_class_index_mul)) and
                    not c.e_all_cancel);
  end generate;
  
  -- outputs to div unit
  c.e_div_en <= (r.e.valid and
                 r.e.inst_flags.class(inst_class_index_div) and
                 not c.e_all_cancel
                 );
  
  -- outputs to load/store unit
  c.e_data_align_exception_raised <= ((r.e.inst_flags.class(inst_class_index_load) or
                                       r.e.inst_flags.class(inst_class_index_store)) and
                                      cpu_or1knd_i5_pipe_dp_out_ctrl.e_ldst_misaligned);
  c.e_ldst_cancel <= c.e_all_cancel or cpu_or1knd_i5_pipe_dp_out_ctrl.e_ldst_misaligned;
  c.e_ldst_request <= (r.e.valid and
                       (r.e.inst_flags.class(inst_class_index_load) or
                        r.e.inst_flags.class(inst_class_index_store)) and
                       not (c.e_all_cancel or cpu_or1knd_i5_pipe_dp_out_ctrl.e_ldst_misaligned));
  c.e_ldst_write   <= r.e.inst_flags.class(inst_class_index_store);
  
  c.e_load_stall  <= (
    r.e.inst_flags.class(inst_class_index_load) and
    not c.e_all_cancel and
    not cpu_l1mem_data_ctrl_out.ready
    );
  c.e_store_stall <= (
    r.e.inst_flags.class(inst_class_index_store) and
    not c.e_all_cancel and
    not cpu_l1mem_data_ctrl_out.ready
    );
  c.e_msync_stall <= (
    (r.e.inst_flags.class(inst_class_index_msync) or
     r.e.inst_flags.class(inst_class_index_csync)
     ) and
    not c.e_all_cancel and
    not cpu_l1mem_data_ctrl_out.ready
    );

  ------------------
  -- decode stage --
  ------------------
  c.d_inst_fetch_exception_raised <= (r.d.inst_pf_exception_raised or
                                      r.d.inst_tlbmiss_exception_raised or
                                      r.d.inst_bus_exception_raised);
  c.d_all_cancel <= c.d_inst_fetch_exception_raised;

  c.d_inst_flags <= decode_inst_flags(r.d.inst);

  c.d_rd_link <= c.d_inst_flags.toc_call;
  
  -- data cannot be forward to the alu unless it comes from the alu
  c.d_alu_data_hazard <= ((((c.d_inst_flags.ra_dep(ra_dep_index_e_alu) and cpu_or1knd_i5_pipe_dp_out_ctrl.d_depends_ra_e) or
                            (c.d_inst_flags.rb_dep(rb_dep_index_e_alu) and cpu_or1knd_i5_pipe_dp_out_ctrl.d_depends_rb_e)) and
                           r.e.valid and
                           r.e.inst_flags.rd_write and
                           not r.e.inst_flags.rd_data_sel(cpu_or1knd_i5_rd_data_sel_index_alu)
                           )
                          );

  -- can only forward the CY flag from addc to addc
  c.d_spr_sr_cy_hazard <=  (c.d_inst_flags.addsub_use_carryin and
                            ((r.e.valid and (r.m.inst_flags.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_mulu) or
                                             r.m.inst_flags.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_macuadd))) or
                             (r.m.valid and (r.m.inst_flags.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_mulu) or
                                             r.m.inst_flags.set_spr_sys_sr_cy(set_spr_sys_sr_cy_index_m_macuadd)))));
  
  c.d_hazard <= c.d_alu_data_hazard or c.d_spr_sr_cy_hazard;
  
  -- forward alu_src1
  -- check if inst in d has RAW dependency from ra that can be forwarded
  c.d_e_fwd_alu_src1_m_alu_result <= (c.d_inst_flags.alu_src1_sel(cpu_or1knd_i5_alu_src1_sel_index_ra) and
                                      r.e.valid and
                                      r.e.inst_flags.rd_write and
                                      cpu_or1knd_i5_pipe_dp_out_ctrl.d_depends_ra_e
                                      );
  
  -- RAW between instructions in d and m
  c.d_e_fwd_alu_src1_w_rd_data <= (c.d_inst_flags.alu_src1_sel(cpu_or1knd_i5_alu_src1_sel_index_ra) and
                                   r.m.valid and
                                   r.m.inst_flags.rd_write and
                                   cpu_or1knd_i5_pipe_dp_out_ctrl.d_depends_ra_m
                                   );
  
  c.d_e_fwd_alu_src1_sel_1hot_unpri <= (2 => c.d_e_fwd_alu_src1_m_alu_result,
                                        1 => c.d_e_fwd_alu_src1_w_rd_data,
                                        0 => '1'
                                        );
  d_e_fwd_alu_src1_sel_1hot_prioritizer : entity tech.prioritizer(rtl)
    generic map (
      input_bits => 3
      )
    port map (
      datain  => c.d_e_fwd_alu_src1_sel_1hot_unpri,
      dataout => c.d_e_fwd_alu_src1_sel_1hot
      );
  
  c.d_e_fwd_alu_src1_sel(cpu_or1knd_i5_e_fwd_alu_src_sel_index_m_alu_result) <= c.d_e_fwd_alu_src1_sel_1hot(2);
  c.d_e_fwd_alu_src1_sel(cpu_or1knd_i5_e_fwd_alu_src_sel_index_w_rd_data)    <= c.d_e_fwd_alu_src1_sel_1hot(1);
  c.d_e_fwd_alu_src1_sel(cpu_or1knd_i5_e_fwd_alu_src_sel_index_none)         <= c.d_e_fwd_alu_src1_sel_1hot(0);

  -- forward alu_src2
  -- check if inst in d has RAW dependency from ra that can be forwarded
  c.d_e_fwd_alu_src2_m_alu_result <= (c.d_inst_flags.alu_src2_sel(cpu_or1knd_i5_alu_src2_sel_index_rb) and
                                      r.e.valid and
                                      r.e.inst_flags.rd_write and
                                      cpu_or1knd_i5_pipe_dp_out_ctrl.d_depends_rb_e
                                      );
  
  c.d_e_fwd_alu_src2_w_rd_data <= (c.d_inst_flags.alu_src2_sel(cpu_or1knd_i5_alu_src2_sel_index_rb) and
                                   r.m.valid and
                                   r.m.inst_flags.rd_write and
                                   cpu_or1knd_i5_pipe_dp_out_ctrl.d_depends_rb_m);
  
  c.d_e_fwd_alu_src2_sel_1hot_unpri <= (2 => c.d_e_fwd_alu_src2_m_alu_result,
                                        1 => c.d_e_fwd_alu_src2_w_rd_data,
                                        0 => '1'
                                        );
  d_e_fwd_alu_src2_sel_1hot_prioritizer : entity tech.prioritizer(rtl)
    generic map (
      input_bits => 3
      )
    port map (
      datain  => c.d_e_fwd_alu_src2_sel_1hot_unpri,
      dataout => c.d_e_fwd_alu_src2_sel_1hot
      );

  c.d_e_fwd_alu_src2_sel(cpu_or1knd_i5_e_fwd_alu_src_sel_index_m_alu_result) <= c.d_e_fwd_alu_src2_sel_1hot(2);
  c.d_e_fwd_alu_src2_sel(cpu_or1knd_i5_e_fwd_alu_src_sel_index_w_rd_data)    <= c.d_e_fwd_alu_src2_sel_1hot(1);
  c.d_e_fwd_alu_src2_sel(cpu_or1knd_i5_e_fwd_alu_src_sel_index_none)         <= c.d_e_fwd_alu_src2_sel_1hot(0);

  -- forward st_data
  -- check if inst in d has RAW dependency from ra that can be forwarded
  c.d_e_fwd_st_data_m_rd_data <= (r.e.valid and
                                  r.e.inst_flags.rd_write and
                                  cpu_or1knd_i5_pipe_dp_out_ctrl.d_depends_rb_e
                                  );
  c.d_e_fwd_st_data_w_rd_data <= (r.m.valid and
                                  r.m.inst_flags.rd_write and
                                  cpu_or1knd_i5_pipe_dp_out_ctrl.d_depends_rb_m
                                  );
  
  c.d_e_fwd_st_data_sel_1hot_unpri <= (2 => c.d_e_fwd_st_data_m_rd_data,
                                       1 => c.d_e_fwd_st_data_w_rd_data,
                                       0 => '1'
                                       );
  d_e_fwd_st_data_sel_1hot_prioritizer : entity tech.prioritizer(rtl)
    generic map (
      input_bits => 3
      )
    port map (
      datain  => c.d_e_fwd_st_data_sel_1hot_unpri,
      dataout => c.d_e_fwd_st_data_sel_1hot
      );
  
  c.d_e_fwd_st_data_sel(cpu_or1knd_i5_e_fwd_st_data_sel_index_m_rd_data) <= c.d_e_fwd_st_data_sel_1hot(2);
  c.d_e_fwd_st_data_sel(cpu_or1knd_i5_e_fwd_st_data_sel_index_w_rd_data) <= c.d_e_fwd_st_data_sel_1hot(1);
  c.d_e_fwd_st_data_sel(cpu_or1knd_i5_e_fwd_st_data_sel_index_none)      <= c.d_e_fwd_st_data_sel_1hot(0);

  -----------------
  -- fetch stage --
  -----------------
  c.f_valid <= ((cpu_l1mem_inst_ctrl_out.ready or r.p.f_inst_buffered) and
                r.f.inst_requested);

  c.f_inst  <= cpu_or1knd_i5_pipe_dp_out_ctrl.f_inst;
  
  with r.p.f_bpred_buffered select
    c.f_bpb_taken <= cpu_bpb_ctrl_out.rtaken when '0',
                     r.p.f_bpb_taken_buffer  when '1',
                     'X'                     when others;

  with r.p.f_bpred_buffered select
    c.f_btb_valid <= cpu_btb_ctrl_out.rvalid when '0',
                     r.p.f_btb_valid_buffer  when '1',
                     'X'                     when others;
  
  c.f_inst_pf_exception_raised      <= cpu_l1mem_data_ctrl_out.result(cpu_l1mem_data_result_code_index_pf);
  c.f_inst_tlbmiss_exception_raised <= cpu_l1mem_data_ctrl_out.result(cpu_l1mem_data_result_code_index_tlbmiss); -- TODO
  c.f_inst_bus_exception_raised     <= cpu_l1mem_data_ctrl_out.result(cpu_l1mem_data_result_code_index_error);
  
  c.f_toc_pred_taken <= c.f_btb_valid and c.f_bpb_taken;
  
  ------------------------
  -- stalls and flushes --
  ------------------------    
  -- stall required for e/m/w stages
  c.e_stall <= r.e.valid and (c.e_load_stall or c.e_store_stall or c.e_msync_stall);
  c.m_stall <= r.m.valid and (c.m_mfspr_stall or c.m_mtspr_stall or c.m_load_stall or c.m_store_stall or c.m_msync_stall or c.m_mul_stall or c.m_madd_stall or c.m_div_stall);
  c.emw_stall <= c.e_stall or c.m_stall;

  -- instruction in f never stalls, an invalid instruction is passed down instead
  c.d_stall <= (r.d.valid and c.d_hazard and not c.d_all_cancel) or (r.m.valid and c.m_mfspr_sys_gpr);
  c.fd_stall <= c.emw_stall or c.d_stall;

  -- check for flushes
  c.m_exception_flush <= c.m_any_exception;

  c.m_mtspr_flush <= not c.m_all_cancel and r.m.inst_flags.class(inst_class_index_mtspr) and not c.m_mtspr_stall;
  c.m_rfe_flush   <= not c.m_all_cancel and r.m.inst_flags.class(inst_class_index_rfe);

  c.m_full_flush <= (r.p.init or
                     (r.m.valid and
                      (c.m_mtspr_flush or
                       c.m_rfe_flush)) or
                     c.m_exception_flush
                     );
  c.e_toc_flush <= r.e.valid and r.e.inst_flags.class(inst_class_index_toc) and c.e_toc_mispred and not c.m_stall;
  
  c.e_flush <= c.m_full_flush;
  c.d_flush <= c.m_full_flush or c.e_toc_flush;
  c.f_flush <= c.m_full_flush or c.e_toc_flush;

  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      assert not is_x(c.fd_stall)
        report "stall signal invalid"
        severity failure;
      assert not is_x(c.m_full_flush)
        report "full flush signal invalid"
        severity failure;
      assert not is_x(c.e_toc_flush)
        report "toc flush signal invalid"
        severity failure;
      assert c.m_full_flush = '0' or c.m_stall = '0'
        report "full flush but M stage is stalling"
        severity failure;
    end if;
  end process;
  -- pragma translate_on
  
  ------------------------
  -- before fetch stage --
  ------------------------

  -- generate priority selector 1hot for next pc to fetch

  -- first detect which of the possible cases are true:

  -- case 9
  -- exception raised by instruction in m
  -- f, d, e will be flushed
  -- no stall is possible from m (due to exception)
  -- will select m_exception_pc
  c.bf_pc_sel_unpri(9) <= c.m_any_exception;
  
  -- case 8
  -- rfe instruction in m
  -- f, d, e will be flushed
  -- rfe never stalls
  -- will select epcr
  c.bf_pc_sel_unpri(8) <= r.m.valid and r.m.inst_flags.class(inst_class_index_rfe);

  -- case 7, 6, 5
  -- flush pipeline due to mtspr instruction at m
  -- oldest instruction after m is at e => case 7
  -- oldest instruction after m is at d => case 6
  -- oldest instruction after m is at f => case 5
  -- stalls must not happen
  -- will select pc at e
  c.bf_pc_sel_unpri(7) <= r.m.valid and c.m_mtspr_flush and r.e.valid;
  -- will select pc at d
  c.bf_pc_sel_unpri(6) <= r.m.valid and c.m_mtspr_flush and r.d.valid;
  -- will select pc at f
  c.bf_pc_sel_unpri(5) <= r.m.valid and c.m_mtspr_flush;

  -- case 4, 3
  -- flush pipeline due to branch misprediction
  -- should not have been taken => case 4
  -- should have been taken     => case 3
  -- if stall happens at bf, then e will stall as well
  -- will select e_toc_target
  c.bf_pc_sel_unpri(4) <= r.e.valid and r.e.inst_flags.class(inst_class_index_toc) and c.e_toc_taken and not r.e.toc_pred_taken;
  -- will select e_pc_incr
  c.bf_pc_sel_unpri(3) <= r.e.valid and (not r.e.inst_flags.class(inst_class_index_toc) or not c.e_toc_taken) and r.e.toc_pred_taken;

  -- case 2, 1
  -- normal fetch, using branch predictor
  -- branch predictor hit & predicted taken and f has valid instruction    => case 2
  -- branch predictor miss/predicted not taken and f has valid instruction => case 1
  -- will select btb_pc
  c.bf_pc_sel_unpri(2) <= not c.fd_stall and c.f_valid and c.f_toc_pred_taken;
  -- will select f_pc_incr
  c.bf_pc_sel_unpri(1) <= not c.fd_stall and c.f_valid;
  
  -- case 0
  -- instruction in f is not valid, or there was a stall in d
  c.bf_pc_sel_unpri(0) <= '1';

  -- prioritize the cases
  bf_pc_sel_prioritizer : entity tech.prioritizer(rtl)
    generic map (
      input_bits => 10
      )
    port map (
      datain  => c.bf_pc_sel_unpri,
      dataout => c.bf_pc_sel_pri
      );
  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      assert not is_x(c.bf_pc_sel_pri)
        report "invalid pc selector"
        severity failure;
    end if;
  end process;
  -- pragma translate_on

  -- true if we are refetching the pc in F
  c.bf_refetching <= (
    not c.m_full_flush and
    not c.e_toc_flush and
    (c.fd_stall or
     not c.f_valid)
    );
  c.bf_inst_request <= (
    r.p.inst_fetch_enabled and
    (c.m_full_flush or
     c.e_toc_flush or
     not c.fd_stall)
    );
  
  -- generate final selector based on prioritization of cases
  c.bf_pc_sel <= (
    cpu_or1knd_i5_bf_pc_sel_index_m_exception_pc => c.bf_pc_sel_pri(9),
    cpu_or1knd_i5_bf_pc_sel_index_epcr0          => c.bf_pc_sel_pri(8),
    cpu_or1knd_i5_bf_pc_sel_index_e              => c.bf_pc_sel_pri(7),
    cpu_or1knd_i5_bf_pc_sel_index_d              => c.bf_pc_sel_pri(6),
    cpu_or1knd_i5_bf_pc_sel_index_f              => c.bf_pc_sel_pri(5) or c.bf_pc_sel_pri(0),
    cpu_or1knd_i5_bf_pc_sel_index_e_toc_target   => c.bf_pc_sel_pri(4),
    cpu_or1knd_i5_bf_pc_sel_index_e_pc_incr      => c.bf_pc_sel_pri(3),
    cpu_or1knd_i5_bf_pc_sel_index_btb            => c.bf_pc_sel_pri(2),
    cpu_or1knd_i5_bf_pc_sel_index_f_pc_incr      => c.bf_pc_sel_pri(1)
    );

  with c.bf_refetching select
    c.bf_inst_fetch_direction <=
      (cpu_l1mem_inst_fetch_direction_index_seq   => not c.m_full_flush and not c.e_toc_flush and not c.f_toc_pred_taken,
       cpu_l1mem_inst_fetch_direction_index_dir   => not c.m_full_flush and not c.e_toc_flush and c.f_toc_pred_taken,
       cpu_l1mem_inst_fetch_direction_index_indir => c.m_full_flush or c.e_toc_flush
       ) when '0',
      r.f.inst_fetch_direction when '1',
      (others => 'X') when others;
  
  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and rstn = '1' then
      case c.bf_inst_fetch_direction is
        when cpu_l1mem_inst_fetch_direction_seq |
             cpu_l1mem_inst_fetch_direction_dir |
             cpu_l1mem_inst_fetch_direction_indir => null;
        when others =>
          assert false
            report "invalid fetch direction"
            severity failure;
      end case;
    end if;
  end process;
  -- pragma translate_on
  
  ------------------------
  -- pipeline registers --
  ------------------------
  r_next.p.init <= '0';
  r_next.p.inst_fetch_enabled <= ((r.p.inst_fetch_enabled and
                                   not (r.m.valid and
                                        not c.m_any_exception and
                                        r.m.inst_flags.zero)) or
                                  c.m_full_flush);

  with c.emw_stall select
    r_next.p.spr_sys_sr_user   <= c.m_spr_sys_sr_user_new   when '0',
                                  r.p.spr_sys_sr_user       when '1',
                                  spr_sys_sr_user_x         when others;
  
  with c.emw_stall select
    r_next.p.spr_sys_sr        <= c.m_spr_sys_sr_new        when '0',
                                  r.p.spr_sys_sr            when '1',
                                  spr_sys_sr_x              when others;
  
  with c.emw_stall select
    r_next.p.spr_sys_esr0_user <= c.m_spr_sys_esr0_user_new when '0',
                                  r.p.spr_sys_esr0_user     when '1',
                                  spr_sys_sr_user_x         when others;
  
  with c.emw_stall select
    r_next.p.spr_sys_esr0      <= c.m_spr_sys_esr0_new      when '0',
                                  r.p.spr_sys_esr0          when '1',
                                  spr_sys_sr_x              when others;
  
  with c.emw_stall select
    r_next.p.spr_sys_aecr      <= c.m_spr_sys_aecr_new      when '0',
                                  r.p.spr_sys_aecr          when '1',
                                  (others => 'X')           when others;
  
  with c.emw_stall select
    r_next.p.spr_sys_aesr      <= c.m_spr_sys_aesr_new      when '0',
                                  r.p.spr_sys_aesr          when '1',
                                  (others => 'X')           when others;

  r_next.p.mfspr_sys_gpr_status <= c.m_mfspr_sys_gpr;
  r_next.p.mtspr_icache_icbir_status <= r.m.valid and c.m_mtspr_icache_icbir and cpu_l1mem_inst_ctrl_out.ready;
  r_next.p.mtspr_dcache_dcbxr_status <= r.m.valid and c.m_mtspr_dcache_dcbxr and cpu_l1mem_data_ctrl_out.ready;

  -- even though a load that completes will not stall, if the instruction in e stalls we have to save the load result
  c.m_load_buffer_write <= c.e_stall and r.m.inst_flags.class(inst_class_index_load) and cpu_l1mem_data_ctrl_out.ready and not r.p.m_load_data_buffered;
  r_next.p.m_load_data_buffered <= ((r.p.m_load_data_buffered or (r.m.inst_flags.class(inst_class_index_load) and cpu_l1mem_data_ctrl_out.ready)) and
                                    c.e_stall);
  
  c.f_inst_buffer_write <= (r.f.inst_requested and
                            cpu_l1mem_inst_ctrl_out.ready and
                            c.bf_refetching and
                            not r.p.f_inst_buffered
                            );
  r_next.p.f_inst_buffered <= ((r.p.f_inst_buffered or
                                (r.f.inst_requested and
                                 cpu_l1mem_inst_ctrl_out.ready
                                 )) and
                               c.bf_refetching
                               );

  c.f_bpred_buffer_write <= r.f.bpred_requested and c.bf_refetching;
  r_next.p.f_bpred_buffered <= (r.p.f_bpred_buffered or r.f.bpred_requested) and c.bf_refetching;

  with c.f_bpred_buffer_write select
    r_next.p.f_bpb_taken_buffer <= cpu_bpb_ctrl_out.rtaken  when '1',
                                   r.p.f_bpb_taken_buffer   when '0',
                                   'X'                      when others;
  
  with c.f_bpred_buffer_write select
    r_next.p.f_btb_valid_buffer <= cpu_btb_ctrl_out.rvalid  when '1',
                                   r.p.f_btb_valid_buffer   when '0',
                                   'X'                      when others;

  with c.emw_stall select
    r_next.m <= r.m when '1',
                (valid                         => r.e.valid and not c.e_flush,
                 inst_flags                    => r.e.inst_flags,
                 spr_sys_sr_user               => c.e_spr_sys_sr_user_new,
                 spr_addr_sel                  => cpu_or1knd_i5_pipe_dp_out_ctrl.e_spr_addr_sel,
                 spr_addr_valid                => cpu_or1knd_i5_pipe_dp_out_ctrl.e_spr_addr_valid,
                 inst_pf_exception_raised      => r.e.inst_pf_exception_raised,
                 inst_tlbmiss_exception_raised => r.e.inst_tlbmiss_exception_raised,
                 inst_bus_exception_raised     => r.e.inst_bus_exception_raised,
                 toc_align_exception_raised    => c.e_toc_align_exception_raised,
                 data_align_exception_raised   => c.e_data_align_exception_raised
                 ) when '0',
                reg_m_x  when others;

  with c.emw_stall select
    r_next.e <= (valid                         => r.e.valid and not c.e_flush,
                 btb_valid                     => r.e.btb_valid,
                 inst_flags                    => r.e.inst_flags,
                 toc_pred_taken                => r.e.toc_pred_taken,
                 fwd_alu_src1_sel              => r.e.fwd_alu_src1_sel,
                 fwd_alu_src2_sel              => r.e.fwd_alu_src2_sel,
                 fwd_st_data_sel               => r.e.fwd_st_data_sel,
                 inst_pf_exception_raised      => r.e.inst_pf_exception_raised,
                 inst_tlbmiss_exception_raised => r.e.inst_tlbmiss_exception_raised,
                 inst_bus_exception_raised     => r.e.inst_bus_exception_raised
                 ) when '1',
                (valid                         => not c.fd_stall and not c.d_flush and r.d.valid,
                 btb_valid                     => r.d.btb_valid,
                 inst_flags                    => c.d_inst_flags,
                 toc_pred_taken                => r.d.toc_pred_taken,
                 fwd_alu_src1_sel              => c.d_e_fwd_alu_src1_sel,
                 fwd_alu_src2_sel              => c.d_e_fwd_alu_src2_sel,
                 fwd_st_data_sel               => c.d_e_fwd_st_data_sel,
                 inst_pf_exception_raised      => r.d.inst_pf_exception_raised,
                 inst_tlbmiss_exception_raised => r.d.inst_tlbmiss_exception_raised,
                 inst_bus_exception_raised     => r.d.inst_bus_exception_raised
                 ) when '0',
                reg_e_x when others;

  with c.fd_stall select
    r_next.d <= (valid                         => r.d.valid and not c.d_flush,
                 btb_valid                     => r.d.btb_valid,
                 toc_pred_taken                => r.d.toc_pred_taken,
                 inst                          => r.d.inst,
                 inst_pf_exception_raised      => r.d.inst_pf_exception_raised,
                 inst_tlbmiss_exception_raised => r.d.inst_tlbmiss_exception_raised,
                 inst_bus_exception_raised     => r.d.inst_bus_exception_raised
                 ) when '1',
                (valid => c.f_valid and not c.f_flush,
                 btb_valid => c.f_btb_valid,
                 toc_pred_taken => c.f_toc_pred_taken,
                 inst => c.f_inst,
                 inst_pf_exception_raised => c.f_inst_pf_exception_raised,
                 inst_tlbmiss_exception_raised => c.f_inst_tlbmiss_exception_raised,
                 inst_bus_exception_raised => c.f_inst_bus_exception_raised
                 ) when '0',
                reg_d_x when others;
  
  r_next.f <= (
    inst_requested => (c.bf_inst_request and cpu_l1mem_inst_ctrl_out.ready) or (r.f.inst_requested and c.bf_refetching),
    bpred_requested => c.bf_inst_request or (r.f.bpred_requested and c.bf_refetching),
    inst_fetch_direction => c.bf_inst_fetch_direction
    );

  ---------------------------
  -- register file outputs --
  ---------------------------
  c.regfile_raddr1_sel_unpri <= (
    3 => r.m.valid and c.m_mfspr_sys_gpr and not r.p.mfspr_sys_gpr_status, -- mfspr of gpr is in m stage and hasn't read yet
    2 => r.d.valid and not c.d_flush and c.fd_stall,    -- decode stage is stalled, reread regfile
    1 => c.f_valid and not c.f_flush and not c.fd_stall, -- valid instruction in f that's not being flushed and not stalled
    0 => '1'
    );
  c.regfile_raddr1_sel_pri <= prioritize(c.regfile_raddr1_sel_unpri);
  
  c.regfile_raddr1_sel(cpu_or1knd_i5_regfile_raddr1_sel_index_m_mfspr_sys_gpr) <= c.regfile_raddr1_sel_pri(3);
  c.regfile_raddr1_sel(cpu_or1knd_i5_regfile_raddr1_sel_index_d_ra)        <= c.regfile_raddr1_sel_pri(2);
  c.regfile_raddr1_sel(cpu_or1knd_i5_regfile_raddr1_sel_index_f_ra)        <= c.regfile_raddr1_sel_pri(1);
  c.regfile_re1                                                            <= not c.regfile_raddr1_sel_pri(0);

  c.regfile_raddr2_sel_unpri <= (
    2 => r.d.valid and not c.d_flush and c.fd_stall,    -- decode stage is stalled, reread regfile
    1 => c.f_valid and not c.f_flush and not c.fd_stall, -- valid instruction in f that's not being flushed and not stalled
    0 => '1'
    );
  c.regfile_raddr2_sel_pri <= prioritize(c.regfile_raddr2_sel_unpri);
  
  c.regfile_raddr2_sel(cpu_or1knd_i5_regfile_raddr2_sel_index_d_rb)        <= c.regfile_raddr2_sel_pri(2);
  c.regfile_raddr2_sel(cpu_or1knd_i5_regfile_raddr2_sel_index_f_rb)        <= c.regfile_raddr2_sel_pri(1);
  c.regfile_re2                                                            <= not c.regfile_raddr2_sel_pri(0);
  
  c.regfile_we <= r.m.valid and c.m_reg_write and not c.emw_stall;
  c.regfile_w_sel <= (
    cpu_or1knd_i5_regfile_w_sel_index_m_rd            => not c.m_mtspr_sys_gpr,
    cpu_or1knd_i5_regfile_w_sel_index_m_mtspr_sys_gpr =>     c.m_mtspr_sys_gpr
    );

  c.l1mem_inst_vaddr_sel <= (
    cpu_or1knd_i5_l1mem_inst_vaddr_sel_index_bf_pc => not r.m.valid or not c.m_mtspr_icache_icbir or r.p.mtspr_icache_icbir_status,
    cpu_or1knd_i5_l1mem_inst_vaddr_sel_index_m_mtspr_data => r.m.valid and c.m_mtspr_icache_icbir and not r.p.mtspr_icache_icbir_status
    );

  c.l1mem_data_vaddr_sel <= (
    cpu_or1knd_i5_l1mem_data_vaddr_sel_index_e_ldst_addr  => not r.m.valid or not c.m_mtspr_dcache_dcbxr or r.p.mtspr_dcache_dcbxr_status,
    cpu_or1knd_i5_l1mem_data_vaddr_sel_index_m_mtspr_data => r.m.valid and c.m_mtspr_dcache_dcbxr and not r.p.mtspr_dcache_dcbxr_status
    );
  
  l1mem_data_write_alloc_true_gen : if cpu_or1knd_i5_l1mem_data_write_alloc generate
    c.l1mem_data_alloc <= '1';
  end generate;
  l1mem_data_write_alloc_false_gen : if not cpu_or1knd_i5_l1mem_data_write_alloc generate
    c.l1mem_data_alloc <= not c.e_ldst_write;
  end generate;
  c.l1mem_data_writethrough <= not cpu_or1knd_i5_spr_sys_dccfgr(or1k_spr_field_sys_dccfgr_cws);
  c.l1mem_data_cacheen <= r.p.spr_sys_sr.dce and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_dcp);
  c.l1mem_data_mmuen <= r.p.spr_sys_sr.dme and cpu_or1knd_i5_spr_sys_upr(or1k_spr_field_sys_upr_dmp);
  c.l1mem_data_priv <= r.p.spr_sys_sr.sm;
  
  -------------------
  -- other outputs --
  -------------------
  cpu_bpb_ctrl_in <= (
    ren => c.bf_inst_request and not (c.bf_refetching and r.f.bpred_requested),
    wen => c.e_bpred_write and not c.emw_stall,
    wtaken => c.e_toc_taken
    );

  cpu_btb_ctrl_in <= (
    ren => c.bf_inst_request and not (c.bf_refetching and r.f.bpred_requested),
    wen => c.e_bpred_write and not c.emw_stall
    );

  cpu_or1knd_i5_pipe_dp_in_ctrl <= (
    fd_stall              => c.fd_stall,
    emw_stall             => c.emw_stall,
    bf_pc_sel             => c.bf_pc_sel,
    f_bpred_buffer_write  => c.f_bpred_buffer_write,
    f_bpred_buffered      => r.p.f_bpred_buffered,
    f_inst_buffered       => r.p.f_inst_buffered,
    f_inst_buffer_write   => c.f_inst_buffer_write,
    d_rd_link             => c.d_rd_link,
    d_imm_sel             => c.d_inst_flags.imm_sel,
    d_imm_sext            => c.d_inst_flags.imm_sext,
    d_alu_src1_sel        => c.d_inst_flags.alu_src1_sel,
    d_alu_src2_sel        => c.d_inst_flags.alu_src2_sel,
    e_fwd_alu_src1_sel    => r.e.fwd_alu_src1_sel,
    e_fwd_alu_src2_sel    => r.e.fwd_alu_src2_sel,
    e_fwd_st_data_sel     => r.e.fwd_st_data_sel,
    e_alu_result_sel      => r.e.inst_flags.alu_result_sel,
    e_toc_indir           => r.e.inst_flags.toc_indir,
    e_spr_sys_sr_f        => c.e_spr_sys_sr_user.f,
    e_madd_acc_zero       => r.e.inst_flags.madd_acc_zero,
    e_addr_sel            => c.e_addr_sel,
    e_sext                => r.e.inst_flags.sext,
    e_data_size_sel       => r.e.inst_flags.data_size_sel,
    m_exception_sel       => c.m_exception_sel,
    m_sext                => r.m.inst_flags.sext,
    m_rd_data_sel         => r.m.inst_flags.rd_data_sel,
    m_data_size_sel       => r.m.inst_flags.data_size_sel,
    m_mfspr_data          => c.m_mfspr_data_dp,
    m_mfspr_data_sel      => c.m_mfspr_data_sel,
    m_load_data_buffered  => r.p.m_load_data_buffered,
    m_load_buffer_write    => c.m_load_buffer_write,
    m_spr_sys_eear0_write  => c.m_spr_sys_eear0_write and not c.e_stall,
    m_spr_sys_eear0_sel    => c.m_spr_sys_eear0_sel,
    m_spr_sys_epcr0_write  => c.m_spr_sys_epcr0_write and not c.e_stall,
    m_spr_sys_epcr0_sel    => c.m_spr_sys_epcr0_sel,
    m_spr_mac_maclo_write => c.m_spr_mac_maclo_write and not c.e_stall,
    m_spr_mac_maclo_sel   => c.m_spr_mac_maclo_sel,
    m_spr_mac_machi_write => c.m_spr_mac_machi_write and not c.e_stall,
    m_spr_mac_machi_sel   => c.m_spr_mac_machi_sel,
    p_spr_sys_sr_eph      => r.p.spr_sys_sr.eph,
    regfile_raddr1_sel    => c.regfile_raddr1_sel,
    regfile_raddr2_sel    => c.regfile_raddr2_sel,
    regfile_w_sel         => c.regfile_w_sel,
    l1mem_inst_vaddr_sel  => c.l1mem_inst_vaddr_sel,
    l1mem_data_vaddr_sel  => c.l1mem_data_vaddr_sel
    );

  cpu_or1knd_i5_pipe_ctrl_out_misc <= (
    e_addsub_sub     => r.e.inst_flags.addsub_sub,
    e_addsub_carryin => r.e.inst_flags.addsub_use_carryin and c.e_spr_sys_sr_user.cy,

    e_shifter_right  => r.e.inst_flags.shifter_right,
    e_shifter_rot    => r.e.inst_flags.shifter_rot,
    e_shifter_unsgnd => r.e.inst_flags.shifter_unsgnd,
    
    e_mul_en        => c.e_mul_en,
    e_mul_unsgnd    => r.e.inst_flags.mul_unsgnd,
    e_madd_sub       => r.e.inst_flags.madd_sub,

    e_div_en         => c.e_div_en,
    e_div_unsgnd     => r.e.inst_flags.div_unsgnd,

    regfile_re1      => c.regfile_re1,
    regfile_re2      => c.regfile_re2,
    regfile_we       => c.regfile_we
    );

  cpu_l1mem_inst_ctrl_in <= (
    request => (
      cpu_l1mem_inst_request_code_index_none => (
        not c.bf_inst_request and
        not (r.m.valid and
             c.m_mtspr_icache_icbir and
             not r.p.mtspr_icache_icbir_status)
        ),
      cpu_l1mem_inst_request_code_index_fetch => (
        c.bf_inst_request and
        not (r.m.valid and
             c.m_mtspr_icache_icbir and
             not r.p.mtspr_icache_icbir_status)
        ),
      cpu_l1mem_inst_request_code_index_invalidate => (
        r.m.valid and
        c.m_mtspr_icache_icbir and
        not r.p.mtspr_icache_icbir_status
        ),
      cpu_l1mem_inst_request_code_index_sync => '0'
      ),
     cacheen => r.p.spr_sys_sr.ice,
     mmuen => r.p.spr_sys_sr.ime,
     direction => c.bf_inst_fetch_direction,
     priv => r.p.spr_sys_sr.sm,
     alloc => '1'
     );
  
  cpu_l1mem_data_ctrl_in <= (
    request => (
      cpu_l1mem_data_request_code_index_none => (
        not ((c.e_ldst_request or
              (r.e.valid and
               (r.e.inst_flags.class(inst_class_index_msync) or
                r.e.inst_flags.class(inst_class_index_csync)
                )
               )
              ) and
             not c.m_stall and
             not c.e_flush
             ) and
        not (r.m.valid and c.m_mtspr_dcache_dcbxr and not r.p.mtspr_dcache_dcbxr_status)
        ),
      cpu_l1mem_data_request_code_index_load => (
        c.e_ldst_request and
        not c.m_stall and
        not c.e_flush and
        not c.e_ldst_write and
        not (r.m.valid and c.m_mtspr_dcache_dcbxr)
        ),
      cpu_l1mem_data_request_code_index_store => (
        c.e_ldst_request and
        not c.m_stall and
        not c.e_flush and
        c.e_ldst_write and
        not (r.m.valid and c.m_mtspr_dcache_dcbxr)
        ),
      cpu_l1mem_data_request_code_index_invalidate => (
        r.m.valid and c.m_mtspr_dcache_dcbir and not r.p.mtspr_dcache_dcbxr_status
        ),
      cpu_l1mem_data_request_code_index_flush => (
        r.m.valid and c.m_mtspr_dcache_dcbfr and not r.p.mtspr_dcache_dcbxr_status
        ),
      cpu_l1mem_data_request_code_index_writeback => (
        r.m.valid and c.m_mtspr_dcache_dcbwr and not r.p.mtspr_dcache_dcbxr_status
        ),
      cpu_l1mem_data_request_code_index_sync => (
        r.e.valid and
        (r.e.inst_flags.class(inst_class_index_msync) or
         r.e.inst_flags.class(inst_class_index_csync)
         ) and
        not c.m_stall and
        not c.e_flush
        )
      ),
    be => '1',
    alloc => c.l1mem_data_alloc,
    writethrough => c.l1mem_data_writethrough,
    cacheen => c.l1mem_data_cacheen,
    mmuen => c.l1mem_data_mmuen,
    priv => c.l1mem_data_priv
    );

  seq : process (clk) is
  begin

    if rising_edge(clk) then
      if rstn = '1' then
        r <= r_next;
      else
        r <= r_init;
      end if;
    end if;
    
  end process;

  -- pragma translate_off
  monitor : block
    
    -- watch for l.nop NOP_EXIT in decode stage, and follow it down the pipe.

    type monitor_comb_type is record
      d_nop_exit : std_ulogic;
      m_commit : std_ulogic_vector(0 downto 0);
    end record;

    type monitor_reg_e_type is record
      nop_exit : std_ulogic;
    end record;

    type monitor_reg_m_type is record
      nop_exit : std_ulogic;
    end record;

    type monitor_reg_type is record
      e : monitor_reg_e_type;
      m : monitor_reg_m_type;
    end record;
    
    signal mc : monitor_comb_type;
    signal mr, mr_next : monitor_reg_type;
    
  begin

    -- detect commit of l.nop NOP_EXIT or l.nop NOP_EXIT_SILENT
    mc.m_commit <= (
      0 => not c.emw_stall and r.m.valid
      );
    
    mc.d_nop_exit <= (
      logic_eq(r.d.inst(31 downto 24), "00010101") and
      (logic_eq(r.d.inst(15 downto 0), "0000000000000001") or
       logic_eq(r.d.inst(15 downto 0), "0000000000001100")
       )
      );

    with c.emw_stall select
      mr_next.e <= mr.e when '1',
                   (nop_exit => mc.d_nop_exit
                    ) when '0',
                   (nop_exit => 'X'
                    ) when others;

    with c.emw_stall select
      mr_next.m <= mr.m when '1',
                   (nop_exit => mr.e.nop_exit
                    ) when '0',
                   (nop_exit => 'X'
                    ) when others;

    seq : process (clk) is
    begin

      if rising_edge(clk) then
        mr <= mr_next;
      end if;

    end process;

    emit_exit_event : process is
      variable enable : boolean;
      variable source : monitor_event_source_id_type;
    begin

      wait until options_ready and monitor_enable;

      if option(entity_path_name(cpu_or1knd_i5_pipe_ctrl'path_name) & ":monitor_exit") = "true" then

        if option("verbose") = "true" then
          report entity_path_name(cpu_or1knd_i5_pipe_ctrl'path_name) & " exit monitor enabled";
        end if;

        source := monitor_event_source(entity_path_name(cpu_or1knd_i5_pipe_ctrl'path_name), monitor_event_code_exit, "");
      
        loop
          wait until rising_edge(clk);
          if mc.m_commit = "1" and mr.m.nop_exit = '1' then
            monitor_event(source, "");
          end if;
        end loop;

      else

        if option("verbose") = "true" then
          report entity_path_name(cpu_or1knd_i5_pipe_ctrl'path_name) & " exit monitor disabled";
        end if;
      
      end if;

      wait;
      
    end process;

    m_commit_watch : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_or1knd_i5_pipe_ctrl'path_name),
        name => "m_commit",
        data_bits => 1
        )
      port map (
        clk => clk,
        data => mc.m_commit
        );
    
  end block;
  -- pragma translate_on
  
end;
