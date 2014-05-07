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

package cpu_or1knd_i5_pipe_pkg is

  -- control signals to datapath

  type cpu_or1knd_i5_alu_src1_sel_index_type is (
    cpu_or1knd_i5_alu_src1_sel_index_ra,
    cpu_or1knd_i5_alu_src1_sel_index_pc
    );
  type cpu_or1knd_i5_alu_src1_sel_type is
    array (cpu_or1knd_i5_alu_src1_sel_index_type range
           cpu_or1knd_i5_alu_src1_sel_index_type'high downto cpu_or1knd_i5_alu_src1_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_alu_src1_sel_ra : cpu_or1knd_i5_alu_src1_sel_type := "01";
  constant cpu_or1knd_i5_alu_src1_sel_pc : cpu_or1knd_i5_alu_src1_sel_type := "10";

  type cpu_or1knd_i5_alu_src2_sel_index_type is (
    cpu_or1knd_i5_alu_src2_sel_index_rb,
    cpu_or1knd_i5_alu_src2_sel_index_imm
    );
  type cpu_or1knd_i5_alu_src2_sel_type is
    array (cpu_or1knd_i5_alu_src2_sel_index_type range
           cpu_or1knd_i5_alu_src2_sel_index_type'high downto cpu_or1knd_i5_alu_src2_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_alu_src2_sel_rb         : cpu_or1knd_i5_alu_src2_sel_type := "01";
  constant cpu_or1knd_i5_alu_src2_sel_imm        : cpu_or1knd_i5_alu_src2_sel_type := "10";

  type cpu_or1knd_i5_bf_pc_sel_index_type is (
    cpu_or1knd_i5_bf_pc_sel_index_f,
    cpu_or1knd_i5_bf_pc_sel_index_f_pc_incr,
    cpu_or1knd_i5_bf_pc_sel_index_btb,
    cpu_or1knd_i5_bf_pc_sel_index_d,
    cpu_or1knd_i5_bf_pc_sel_index_e,
    cpu_or1knd_i5_bf_pc_sel_index_e_pc_incr,
    cpu_or1knd_i5_bf_pc_sel_index_e_toc_target,
    cpu_or1knd_i5_bf_pc_sel_index_epcr0,
    cpu_or1knd_i5_bf_pc_sel_index_m_exception_pc
    );
  type cpu_or1knd_i5_bf_pc_sel_type is
    array (cpu_or1knd_i5_bf_pc_sel_index_type range
           cpu_or1knd_i5_bf_pc_sel_index_type'high downto cpu_or1knd_i5_bf_pc_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_bf_pc_sel_f              : cpu_or1knd_i5_bf_pc_sel_type := "000000001";
  constant cpu_or1knd_i5_bf_pc_sel_f_pc_incr      : cpu_or1knd_i5_bf_pc_sel_type := "000000010";
  constant cpu_or1knd_i5_bf_pc_sel_btb            : cpu_or1knd_i5_bf_pc_sel_type := "000000100";
  constant cpu_or1knd_i5_bf_pc_sel_d              : cpu_or1knd_i5_bf_pc_sel_type := "000001000";
  constant cpu_or1knd_i5_bf_pc_sel_e              : cpu_or1knd_i5_bf_pc_sel_type := "000010000";
  constant cpu_or1knd_i5_bf_pc_sel_e_pc_incr      : cpu_or1knd_i5_bf_pc_sel_type := "000100000";
  constant cpu_or1knd_i5_bf_pc_sel_e_toc_target   : cpu_or1knd_i5_bf_pc_sel_type := "001000000";
  constant cpu_or1knd_i5_bf_pc_sel_epcr0          : cpu_or1knd_i5_bf_pc_sel_type := "010000000";
  constant cpu_or1knd_i5_bf_pc_sel_m_exception_pc : cpu_or1knd_i5_bf_pc_sel_type := "100000000";

  type cpu_or1knd_i5_imm_sel_index_type is (
    cpu_or1knd_i5_imm_sel_index_contig,
    cpu_or1knd_i5_imm_sel_index_split,
    cpu_or1knd_i5_imm_sel_index_shift,
    cpu_or1knd_i5_imm_sel_index_toc_offset
    );
  type cpu_or1knd_i5_imm_sel_type is
    array (cpu_or1knd_i5_imm_sel_index_type range
           cpu_or1knd_i5_imm_sel_index_type'high downto cpu_or1knd_i5_imm_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_imm_sel_contig     : cpu_or1knd_i5_imm_sel_type := "0001";
  constant cpu_or1knd_i5_imm_sel_split      : cpu_or1knd_i5_imm_sel_type := "0010";
  constant cpu_or1knd_i5_imm_sel_shift      : cpu_or1knd_i5_imm_sel_type := "0100";
  constant cpu_or1knd_i5_imm_sel_toc_offset : cpu_or1knd_i5_imm_sel_type := "1000";

  type cpu_or1knd_i5_alu_result_sel_index_type is (
    cpu_or1knd_i5_alu_result_sel_index_addsub,
    cpu_or1knd_i5_alu_result_sel_index_shifter,
    cpu_or1knd_i5_alu_result_sel_index_and,
    cpu_or1knd_i5_alu_result_sel_index_or,
    cpu_or1knd_i5_alu_result_sel_index_xor,
    cpu_or1knd_i5_alu_result_sel_index_cmov,
    cpu_or1knd_i5_alu_result_sel_index_ff1,
    cpu_or1knd_i5_alu_result_sel_index_fl1,
    cpu_or1knd_i5_alu_result_sel_index_ext,
    cpu_or1knd_i5_alu_result_sel_index_movhi
    );
  type cpu_or1knd_i5_alu_result_sel_type is
    array (cpu_or1knd_i5_alu_result_sel_index_type range
           cpu_or1knd_i5_alu_result_sel_index_type'high downto
           cpu_or1knd_i5_alu_result_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_alu_result_sel_addsub  : cpu_or1knd_i5_alu_result_sel_type := "0000000001";
  constant cpu_or1knd_i5_alu_result_sel_shifter : cpu_or1knd_i5_alu_result_sel_type := "0000000010";
  constant cpu_or1knd_i5_alu_result_sel_and     : cpu_or1knd_i5_alu_result_sel_type := "0000000100";
  constant cpu_or1knd_i5_alu_result_sel_or      : cpu_or1knd_i5_alu_result_sel_type := "0000001000";
  constant cpu_or1knd_i5_alu_result_sel_xor     : cpu_or1knd_i5_alu_result_sel_type := "0000010000";
  constant cpu_or1knd_i5_alu_result_sel_cmov    : cpu_or1knd_i5_alu_result_sel_type := "0000100000";
  constant cpu_or1knd_i5_alu_result_sel_ff1     : cpu_or1knd_i5_alu_result_sel_type := "0001000000";
  constant cpu_or1knd_i5_alu_result_sel_fl1     : cpu_or1knd_i5_alu_result_sel_type := "0010000000";
  constant cpu_or1knd_i5_alu_result_sel_ext     : cpu_or1knd_i5_alu_result_sel_type := "0100000000";
  constant cpu_or1knd_i5_alu_result_sel_movhi   : cpu_or1knd_i5_alu_result_sel_type := "1000000000";

  type cpu_or1knd_i5_rd_data_sel_index_type is (
    cpu_or1knd_i5_rd_data_sel_index_alu,
    cpu_or1knd_i5_rd_data_sel_index_load,
    cpu_or1knd_i5_rd_data_sel_index_mfspr,
    cpu_or1knd_i5_rd_data_sel_index_div,
    cpu_or1knd_i5_rd_data_sel_index_mul,
    cpu_or1knd_i5_rd_data_sel_index_pc_incr,
    cpu_or1knd_i5_rd_data_sel_index_maclo
    );
  type cpu_or1knd_i5_rd_data_sel_type is
    array (cpu_or1knd_i5_rd_data_sel_index_type range
           cpu_or1knd_i5_rd_data_sel_index_type'high downto cpu_or1knd_i5_rd_data_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_rd_data_sel_alu     : cpu_or1knd_i5_rd_data_sel_type := "0000001";
  constant cpu_or1knd_i5_rd_data_sel_load    : cpu_or1knd_i5_rd_data_sel_type := "0000010";
  constant cpu_or1knd_i5_rd_data_sel_mfspr   : cpu_or1knd_i5_rd_data_sel_type := "0000100";
  constant cpu_or1knd_i5_rd_data_sel_div     : cpu_or1knd_i5_rd_data_sel_type := "0001000";
  constant cpu_or1knd_i5_rd_data_sel_mul     : cpu_or1knd_i5_rd_data_sel_type := "0010000";
  constant cpu_or1knd_i5_rd_data_sel_pc_incr : cpu_or1knd_i5_rd_data_sel_type := "0100000";
  constant cpu_or1knd_i5_rd_data_sel_maclo   : cpu_or1knd_i5_rd_data_sel_type := "1000000";

  type cpu_or1knd_i5_e_fwd_alu_src_sel_index_type is (
    cpu_or1knd_i5_e_fwd_alu_src_sel_index_none,
    cpu_or1knd_i5_e_fwd_alu_src_sel_index_w_rd_data,
    cpu_or1knd_i5_e_fwd_alu_src_sel_index_m_alu_result
    );
  type cpu_or1knd_i5_e_fwd_alu_src_sel_type is
    array (cpu_or1knd_i5_e_fwd_alu_src_sel_index_type range
           cpu_or1knd_i5_e_fwd_alu_src_sel_index_type'high downto
           cpu_or1knd_i5_e_fwd_alu_src_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_e_fwd_alu_src_sel_none         : cpu_or1knd_i5_e_fwd_alu_src_sel_type := "001";
  constant cpu_or1knd_i5_e_fwd_alu_src_sel_w_rd_data    : cpu_or1knd_i5_e_fwd_alu_src_sel_type := "010";
  constant cpu_or1knd_i5_e_fwd_alu_src_sel_m_alu_result : cpu_or1knd_i5_e_fwd_alu_src_sel_type := "100";

  type cpu_or1knd_i5_e_fwd_st_data_sel_index_type is (
    cpu_or1knd_i5_e_fwd_st_data_sel_index_none,
    cpu_or1knd_i5_e_fwd_st_data_sel_index_w_rd_data,
    cpu_or1knd_i5_e_fwd_st_data_sel_index_m_rd_data
    );
  type cpu_or1knd_i5_e_fwd_st_data_sel_type is
    array (cpu_or1knd_i5_e_fwd_st_data_sel_index_type range
           cpu_or1knd_i5_e_fwd_st_data_sel_index_type'high downto
           cpu_or1knd_i5_e_fwd_st_data_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_e_fwd_st_data_sel_none      : cpu_or1knd_i5_e_fwd_st_data_sel_type := "001";
  constant cpu_or1knd_i5_e_fwd_st_data_sel_w_rd_data : cpu_or1knd_i5_e_fwd_st_data_sel_type := "010";
  constant cpu_or1knd_i5_e_fwd_st_data_sel_m_rd_data : cpu_or1knd_i5_e_fwd_st_data_sel_type := "100";

  type cpu_or1knd_i5_e_addr_sel_index_type is (
    cpu_or1knd_i5_e_addr_sel_index_ldst,
    cpu_or1knd_i5_e_addr_sel_index_spr
    );
  type cpu_or1knd_i5_e_addr_sel_type is
    array (cpu_or1knd_i5_e_addr_sel_index_type range
           cpu_or1knd_i5_e_addr_sel_index_spr downto cpu_or1knd_i5_e_addr_sel_index_ldst) of std_ulogic;
  constant cpu_or1knd_i5_e_addr_sel_ldst : cpu_or1knd_i5_e_addr_sel_type := "01";
  constant cpu_or1knd_i5_e_addr_sel_spr  : cpu_or1knd_i5_e_addr_sel_type := "10";
  
  type cpu_or1knd_i5_m_spr_sys_eear0_sel_index_type is (
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_init,
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_mtspr,
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_pc,
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_addr,
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_inst_bus_error_eear,
    cpu_or1knd_i5_m_spr_sys_eear0_sel_index_data_bus_error_eear
    );
  type cpu_or1knd_i5_m_spr_sys_eear0_sel_type is
    array (cpu_or1knd_i5_m_spr_sys_eear0_sel_index_type range
           cpu_or1knd_i5_m_spr_sys_eear0_sel_index_type'high downto cpu_or1knd_i5_m_spr_sys_eear0_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_m_spr_sys_eear0_sel_init                : cpu_or1knd_i5_m_spr_sys_eear0_sel_type := "000001";
  constant cpu_or1knd_i5_m_spr_sys_eear0_sel_mtspr               : cpu_or1knd_i5_m_spr_sys_eear0_sel_type := "000010";
  constant cpu_or1knd_i5_m_spr_sys_eear0_sel_pc                  : cpu_or1knd_i5_m_spr_sys_eear0_sel_type := "000100";
  constant cpu_or1knd_i5_m_spr_sys_eear0_sel_addr                : cpu_or1knd_i5_m_spr_sys_eear0_sel_type := "001000";
  constant cpu_or1knd_i5_m_spr_sys_eear0_sel_inst_bus_error_eear : cpu_or1knd_i5_m_spr_sys_eear0_sel_type := "010000";
  constant cpu_or1knd_i5_m_spr_sys_eear0_sel_data_bus_error_eear : cpu_or1knd_i5_m_spr_sys_eear0_sel_type := "100000";
  
  type cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_type is (
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_init,
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_mtspr,
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_f_pc,
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_d_pc,
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_e_pc,
    cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_m_pc
    );
  type cpu_or1knd_i5_m_spr_sys_epcr0_sel_type is
    array (cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_type range
           cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_type'high downto cpu_or1knd_i5_m_spr_sys_epcr0_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_m_spr_sys_epcr0_sel_init  : cpu_or1knd_i5_m_spr_sys_epcr0_sel_type := "000001";
  constant cpu_or1knd_i5_m_spr_sys_epcr0_sel_mtspr : cpu_or1knd_i5_m_spr_sys_epcr0_sel_type := "000010";
  constant cpu_or1knd_i5_m_spr_sys_epcr0_sel_f_pc  : cpu_or1knd_i5_m_spr_sys_epcr0_sel_type := "000100";
  constant cpu_or1knd_i5_m_spr_sys_epcr0_sel_d_pc  : cpu_or1knd_i5_m_spr_sys_epcr0_sel_type := "001000";
  constant cpu_or1knd_i5_m_spr_sys_epcr0_sel_e_pc  : cpu_or1knd_i5_m_spr_sys_epcr0_sel_type := "010000";
  constant cpu_or1knd_i5_m_spr_sys_epcr0_sel_m_pc  : cpu_or1knd_i5_m_spr_sys_epcr0_sel_type := "100000";

  type cpu_or1knd_i5_m_spr_mac_machi_sel_index_type is (
    cpu_or1knd_i5_m_spr_mac_machi_sel_index_mtspr,
    cpu_or1knd_i5_m_spr_mac_machi_sel_index_clear,
    cpu_or1knd_i5_m_spr_mac_machi_sel_index_madd
    );
  type cpu_or1knd_i5_m_spr_mac_machi_sel_type is
    array (cpu_or1knd_i5_m_spr_mac_machi_sel_index_type range
           cpu_or1knd_i5_m_spr_mac_machi_sel_index_madd downto cpu_or1knd_i5_m_spr_mac_machi_sel_index_mtspr) of std_ulogic;
  constant cpu_or1knd_i5_m_spr_mac_machi_sel_mtspr : cpu_or1knd_i5_m_spr_mac_machi_sel_type := "001";
  constant cpu_or1knd_i5_m_spr_mac_machi_sel_clear : cpu_or1knd_i5_m_spr_mac_machi_sel_type := "010";
  constant cpu_or1knd_i5_m_spr_mac_machi_sel_madd  : cpu_or1knd_i5_m_spr_mac_machi_sel_type := "100";
  
  type cpu_or1knd_i5_m_spr_mac_maclo_sel_index_type is (
    cpu_or1knd_i5_m_spr_mac_maclo_sel_index_mtspr,
    cpu_or1knd_i5_m_spr_mac_maclo_sel_index_clear,
    cpu_or1knd_i5_m_spr_mac_maclo_sel_index_madd
    );
  type cpu_or1knd_i5_m_spr_mac_maclo_sel_type is
    array (cpu_or1knd_i5_m_spr_mac_maclo_sel_index_type range
           cpu_or1knd_i5_m_spr_mac_maclo_sel_index_madd downto cpu_or1knd_i5_m_spr_mac_maclo_sel_index_mtspr) of std_ulogic;
  constant cpu_or1knd_i5_m_spr_mac_maclo_sel_mtspr : cpu_or1knd_i5_m_spr_mac_maclo_sel_type := "001";
  constant cpu_or1knd_i5_m_spr_mac_maclo_sel_clear : cpu_or1knd_i5_m_spr_mac_maclo_sel_type := "010";
  constant cpu_or1knd_i5_m_spr_mac_maclo_sel_madd  : cpu_or1knd_i5_m_spr_mac_maclo_sel_type := "100";
  
  type cpu_or1knd_i5_m_mfspr_data_sel_index_type is (
    cpu_or1knd_i5_m_mfspr_data_sel_index_ctrl,
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_vr,
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_upr,
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_cpucfgr,
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_dmmucfgr,
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_immucfgr,
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_dccfgr,
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_iccfgr,
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_eear0,
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_epcr0,
    cpu_or1knd_i5_m_mfspr_data_sel_index_sys_gpr,
    cpu_or1knd_i5_m_mfspr_data_sel_index_mac_maclo,
    cpu_or1knd_i5_m_mfspr_data_sel_index_mac_machi
    );
  type cpu_or1knd_i5_m_mfspr_data_sel_type is
    array (cpu_or1knd_i5_m_mfspr_data_sel_index_type range
           cpu_or1knd_i5_m_mfspr_data_sel_index_type'high downto cpu_or1knd_i5_m_mfspr_data_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_m_mfspr_data_sel_ctrl         : cpu_or1knd_i5_m_mfspr_data_sel_type := "0000000000001";
  constant cpu_or1knd_i5_m_mfspr_data_sel_sys_vr       : cpu_or1knd_i5_m_mfspr_data_sel_type := "0000000000010";
  constant cpu_or1knd_i5_m_mfspr_data_sel_sys_upr      : cpu_or1knd_i5_m_mfspr_data_sel_type := "0000000000100";
  constant cpu_or1knd_i5_m_mfspr_data_sel_sys_cpucfgr  : cpu_or1knd_i5_m_mfspr_data_sel_type := "0000000001000";
  constant cpu_or1knd_i5_m_mfspr_data_sel_sys_dmmucfgr : cpu_or1knd_i5_m_mfspr_data_sel_type := "0000000010000";
  constant cpu_or1knd_i5_m_mfspr_data_sel_sys_immucfgr : cpu_or1knd_i5_m_mfspr_data_sel_type := "0000000100000";
  constant cpu_or1knd_i5_m_mfspr_data_sel_sys_dccfgr   : cpu_or1knd_i5_m_mfspr_data_sel_type := "0000001000000";
  constant cpu_or1knd_i5_m_mfspr_data_sel_sys_iccfgr   : cpu_or1knd_i5_m_mfspr_data_sel_type := "0000010000000";
  constant cpu_or1knd_i5_m_mfspr_data_sel_sys_eear0    : cpu_or1knd_i5_m_mfspr_data_sel_type := "0000100000000";
  constant cpu_or1knd_i5_m_mfspr_data_sel_sys_epcr0    : cpu_or1knd_i5_m_mfspr_data_sel_type := "0001000000000";
  constant cpu_or1knd_i5_m_mfspr_data_sel_sys_gpr      : cpu_or1knd_i5_m_mfspr_data_sel_type := "0010000000000";
  constant cpu_or1knd_i5_m_mfspr_data_sel_mac_maclo    : cpu_or1knd_i5_m_mfspr_data_sel_type := "0100000000000";
  constant cpu_or1knd_i5_m_mfspr_data_sel_mac_machi    : cpu_or1knd_i5_m_mfspr_data_sel_type := "1000000000000";

  type cpu_or1knd_i5_m_exception_sel_index_type is (
    cpu_or1knd_i5_m_exception_sel_index_reset,
    cpu_or1knd_i5_m_exception_sel_index_bus,
    cpu_or1knd_i5_m_exception_sel_index_dpf,
    cpu_or1knd_i5_m_exception_sel_index_ipf,
    cpu_or1knd_i5_m_exception_sel_index_tti,
    cpu_or1knd_i5_m_exception_sel_index_align,
    cpu_or1knd_i5_m_exception_sel_index_ill,
    cpu_or1knd_i5_m_exception_sel_index_ext,
    cpu_or1knd_i5_m_exception_sel_index_dtlbmiss,
    cpu_or1knd_i5_m_exception_sel_index_itlbmiss,
    cpu_or1knd_i5_m_exception_sel_index_range,
    cpu_or1knd_i5_m_exception_sel_index_syscall,
    cpu_or1knd_i5_m_exception_sel_index_fp,
    cpu_or1knd_i5_m_exception_sel_index_trap
    );
  type cpu_or1knd_i5_m_exception_sel_type is
    array (cpu_or1knd_i5_m_exception_sel_index_type range
           cpu_or1knd_i5_m_exception_sel_index_trap downto cpu_or1knd_i5_m_exception_sel_index_reset) of std_ulogic;
  constant cpu_or1knd_i5_m_exception_sel_reset    : cpu_or1knd_i5_m_exception_sel_type := "00000000000001";
  constant cpu_or1knd_i5_m_exception_sel_bus      : cpu_or1knd_i5_m_exception_sel_type := "00000000000010";
  constant cpu_or1knd_i5_m_exception_sel_dpf      : cpu_or1knd_i5_m_exception_sel_type := "00000000000100";
  constant cpu_or1knd_i5_m_exception_sel_ipf      : cpu_or1knd_i5_m_exception_sel_type := "00000000001000";
  constant cpu_or1knd_i5_m_exception_sel_tti      : cpu_or1knd_i5_m_exception_sel_type := "00000000010000";
  constant cpu_or1knd_i5_m_exception_sel_align    : cpu_or1knd_i5_m_exception_sel_type := "00000000100000";
  constant cpu_or1knd_i5_m_exception_sel_ill      : cpu_or1knd_i5_m_exception_sel_type := "00000001000000";
  constant cpu_or1knd_i5_m_exception_sel_ext      : cpu_or1knd_i5_m_exception_sel_type := "00000010000000";
  constant cpu_or1knd_i5_m_exception_sel_dtlbmiss : cpu_or1knd_i5_m_exception_sel_type := "00000100000000";
  constant cpu_or1knd_i5_m_exception_sel_itlbmiss : cpu_or1knd_i5_m_exception_sel_type := "00001000000000";
  constant cpu_or1knd_i5_m_exception_sel_range    : cpu_or1knd_i5_m_exception_sel_type := "00010000000000";
  constant cpu_or1knd_i5_m_exception_sel_syscall  : cpu_or1knd_i5_m_exception_sel_type := "00100000000000";
  constant cpu_or1knd_i5_m_exception_sel_fp       : cpu_or1knd_i5_m_exception_sel_type := "01000000000000";
  constant cpu_or1knd_i5_m_exception_sel_trap     : cpu_or1knd_i5_m_exception_sel_type := "10000000000000";

  type cpu_or1knd_i5_spr_addr_sel_index_type is (
    cpu_or1knd_i5_spr_addr_sel_index_sys_vr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_upr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_cpucfgr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_dmmucfgr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_immucfgr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_dccfgr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_iccfgr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_dcfgr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_pccfgr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_aecr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_aesr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_npc,
    cpu_or1knd_i5_spr_addr_sel_index_sys_sr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_ppc,
    cpu_or1knd_i5_spr_addr_sel_index_sys_fpcsr,
    cpu_or1knd_i5_spr_addr_sel_index_sys_epcr0,
    cpu_or1knd_i5_spr_addr_sel_index_sys_eear0,
    cpu_or1knd_i5_spr_addr_sel_index_sys_esr0,
    cpu_or1knd_i5_spr_addr_sel_index_sys_gpr,
    cpu_or1knd_i5_spr_addr_sel_index_dmmu_dmmucr,
    cpu_or1knd_i5_spr_addr_sel_index_dmmu_dmmupr,
    cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbeir,
    cpu_or1knd_i5_spr_addr_sel_index_dmmu_datbmr,
    cpu_or1knd_i5_spr_addr_sel_index_dmmu_datbtr,
    cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbwmr,
    cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbwtr,
    cpu_or1knd_i5_spr_addr_sel_index_immu_immucr,
    cpu_or1knd_i5_spr_addr_sel_index_immu_immupr,
    cpu_or1knd_i5_spr_addr_sel_index_immu_itlbeir,
    cpu_or1knd_i5_spr_addr_sel_index_immu_iatbmr,
    cpu_or1knd_i5_spr_addr_sel_index_immu_iatbtr,
    cpu_or1knd_i5_spr_addr_sel_index_immu_itlbwmr,
    cpu_or1knd_i5_spr_addr_sel_index_immu_itlbwtr,
    cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbfr,
    cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbir,
    cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbwr,
    cpu_or1knd_i5_spr_addr_sel_index_icache_icbir,
    cpu_or1knd_i5_spr_addr_sel_index_mac_maclo,
    cpu_or1knd_i5_spr_addr_sel_index_mac_machi
    );
  type cpu_or1knd_i5_spr_addr_sel_type is
    array (cpu_or1knd_i5_spr_addr_sel_index_type range
           cpu_or1knd_i5_spr_addr_sel_index_type'high downto cpu_or1knd_i5_spr_addr_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_spr_addr_sel_sys_vr       : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_vr       => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_upr      : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_upr      => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_cpucfgr  : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_cpucfgr  => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_dmmucfgr : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_dmmucfgr => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_immucfgr : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_immucfgr => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_dccfgr   : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_dccfgr   => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_iccfgr   : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_iccfgr   => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_dcfgr    : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_dcfgr    => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_pccfgr   : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_pccfgr   => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_aecr     : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_aecr     => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_aesr     : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_aesr     => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_npc      : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_npc      => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_sr       : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_sr       => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_ppc      : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_ppc      => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_fpcsr    : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_fpcsr    => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_epcr0    : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_epcr0    => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_eear0    : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_eear0    => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_esr0     : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_esr0     => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_sys_gpr      : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_sys_gpr      => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_dmmu_dmmucr  : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_dmmu_dmmucr  => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_dmmu_dmmupr  : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_dmmu_dmmupr  => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_dmmu_dtlbeir : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbeir => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_dmmu_datbmr  : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_dmmu_datbmr  => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_dmmu_datbtr  : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_dmmu_datbtr  => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_dmmu_dtlbwmr : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbwmr => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_dmmu_dtlbwtr : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_dmmu_dtlbwtr => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_immu_immucr  : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_immu_immucr  => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_immu_immupr  : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_immu_immupr  => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_immu_itlbeir : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_immu_itlbeir => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_immu_iatbmr  : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_immu_iatbmr  => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_immu_iatbtr  : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_immu_iatbtr  => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_immu_itlbwmr : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_immu_itlbwmr => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_immu_itlbwtr : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_immu_itlbwtr => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_dcache_dcbfr : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbfr => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_dcache_dcbir : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbir => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_dcache_dcbwr : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_dcache_dcbwr => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_icache_icbir : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_icache_icbir => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_mac_maclo    : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_mac_maclo    => '1', others => '0');
  constant cpu_or1knd_i5_spr_addr_sel_mac_machi    : cpu_or1knd_i5_spr_addr_sel_type := (cpu_or1knd_i5_spr_addr_sel_index_mac_machi    => '1', others => '0');

  type cpu_or1knd_i5_regfile_raddr1_sel_index_type is (
    cpu_or1knd_i5_regfile_raddr1_sel_index_f_ra,
    cpu_or1knd_i5_regfile_raddr1_sel_index_d_ra,
    cpu_or1knd_i5_regfile_raddr1_sel_index_m_mfspr_sys_gpr
    );
  type cpu_or1knd_i5_regfile_raddr1_sel_type is
    array (cpu_or1knd_i5_regfile_raddr1_sel_index_type range
           cpu_or1knd_i5_regfile_raddr1_sel_index_m_mfspr_sys_gpr downto cpu_or1knd_i5_regfile_raddr1_sel_index_f_ra) of std_ulogic;
  constant cpu_or1knd_i5_regfile_raddr1_sel_f_ra            : cpu_or1knd_i5_regfile_raddr1_sel_type := "001";
  constant cpu_or1knd_i5_regfile_raddr1_sel_d_ra            : cpu_or1knd_i5_regfile_raddr1_sel_type := "010";
  constant cpu_or1knd_i5_regfile_raddr1_sel_m_mfspr_sys_gpr : cpu_or1knd_i5_regfile_raddr1_sel_type := "100";
  
  type cpu_or1knd_i5_regfile_raddr2_sel_index_type is (
    cpu_or1knd_i5_regfile_raddr2_sel_index_f_rb,
    cpu_or1knd_i5_regfile_raddr2_sel_index_d_rb
    );
  type cpu_or1knd_i5_regfile_raddr2_sel_type is
    array (cpu_or1knd_i5_regfile_raddr2_sel_index_type range
           cpu_or1knd_i5_regfile_raddr2_sel_index_d_rb downto cpu_or1knd_i5_regfile_raddr2_sel_index_f_rb) of std_ulogic;
  constant cpu_or1knd_i5_regfile_raddr2_sel_f_rb        : cpu_or1knd_i5_regfile_raddr2_sel_type := "01";
  constant cpu_or1knd_i5_regfile_raddr2_sel_d_rb        : cpu_or1knd_i5_regfile_raddr2_sel_type := "10";

  type cpu_or1knd_i5_regfile_w_sel_index_type is (
    cpu_or1knd_i5_regfile_w_sel_index_m_rd,
    cpu_or1knd_i5_regfile_w_sel_index_m_mtspr_sys_gpr
    );
  type cpu_or1knd_i5_regfile_w_sel_type is
    array (cpu_or1knd_i5_regfile_w_sel_index_type range
           cpu_or1knd_i5_regfile_w_sel_index_type'high downto
           cpu_or1knd_i5_regfile_w_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_regfile_w_sel_m_rd        : cpu_or1knd_i5_regfile_w_sel_type := "01";
  constant cpu_or1knd_i5_regfile_w_sel_m_mtspr_sys_gpr : cpu_or1knd_i5_regfile_w_sel_type := "10";

  type cpu_or1knd_i5_data_size_sel_index_type is (
    cpu_or1knd_i5_data_size_sel_index_byte,
    cpu_or1knd_i5_data_size_sel_index_half,
    cpu_or1knd_i5_data_size_sel_index_word
    );
  type cpu_or1knd_i5_data_size_sel_type is
    array (cpu_or1knd_i5_data_size_sel_index_type range
           cpu_or1knd_i5_data_size_sel_index_type'high downto
           cpu_or1knd_i5_data_size_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_data_size_sel_byte : cpu_or1knd_i5_data_size_sel_type := "001";
  constant cpu_or1knd_i5_data_size_sel_half : cpu_or1knd_i5_data_size_sel_type := "010";
  constant cpu_or1knd_i5_data_size_sel_word : cpu_or1knd_i5_data_size_sel_type := "100";

  type cpu_or1knd_i5_l1mem_inst_vaddr_sel_index_type is (
    cpu_or1knd_i5_l1mem_inst_vaddr_sel_index_bf_pc,
    cpu_or1knd_i5_l1mem_inst_vaddr_sel_index_m_mtspr_data
    );
  type cpu_or1knd_i5_l1mem_inst_vaddr_sel_type is
    array (cpu_or1knd_i5_l1mem_inst_vaddr_sel_index_type range
           cpu_or1knd_i5_l1mem_inst_vaddr_sel_index_type'high downto
           cpu_or1knd_i5_l1mem_inst_vaddr_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_l1mem_inst_vaddr_sel_bf_pc        : cpu_or1knd_i5_l1mem_inst_vaddr_sel_type := "01";
  constant cpu_or1knd_i5_l1mem_inst_vaddr_sel_m_mtspr_data : cpu_or1knd_i5_l1mem_inst_vaddr_sel_type := "10";
  
  type cpu_or1knd_i5_l1mem_data_vaddr_sel_index_type is (
    cpu_or1knd_i5_l1mem_data_vaddr_sel_index_e_ldst_addr,
    cpu_or1knd_i5_l1mem_data_vaddr_sel_index_m_mtspr_data
    );
  type cpu_or1knd_i5_l1mem_data_vaddr_sel_type is
    array (cpu_or1knd_i5_l1mem_data_vaddr_sel_index_type range
           cpu_or1knd_i5_l1mem_data_vaddr_sel_index_type'high downto
           cpu_or1knd_i5_l1mem_data_vaddr_sel_index_type'low) of std_ulogic;
  constant cpu_or1knd_i5_l1mem_data_vaddr_sel_e_ldst_addr  : cpu_or1knd_i5_l1mem_data_vaddr_sel_type := "01";
  constant cpu_or1knd_i5_l1mem_data_vaddr_sel_m_mtspr_data : cpu_or1knd_i5_l1mem_data_vaddr_sel_type := "10";
  
  type cpu_or1knd_i5_pipe_dp_in_ctrl_type is record
    
    fd_stall            : std_ulogic;
    emw_stall            : std_ulogic;
    
    bf_pc_sel          : cpu_or1knd_i5_bf_pc_sel_type;

    f_bpred_buffer_write  : std_ulogic;
    f_bpred_buffered      : std_ulogic;
    f_inst_buffer_write : std_ulogic;
    f_inst_buffered     : std_ulogic;
    
    d_rd_link          : std_ulogic;
    d_imm_sel          : cpu_or1knd_i5_imm_sel_type;
    d_imm_sext         : std_ulogic;
    d_alu_src1_sel     : cpu_or1knd_i5_alu_src1_sel_type;
    d_alu_src2_sel     : cpu_or1knd_i5_alu_src2_sel_type;

    e_sext             : std_ulogic;
    e_data_size_sel    : cpu_or1knd_i5_data_size_sel_type;
    e_fwd_alu_src1_sel : cpu_or1knd_i5_e_fwd_alu_src_sel_type;
    e_fwd_alu_src2_sel : cpu_or1knd_i5_e_fwd_alu_src_sel_type;
    e_fwd_st_data_sel  : cpu_or1knd_i5_e_fwd_st_data_sel_type;
    e_spr_sys_sr_f     : std_ulogic;
    e_alu_result_sel   : cpu_or1knd_i5_alu_result_sel_type;
    e_toc_indir        : std_ulogic;
    e_madd_acc_zero    : std_ulogic;
    e_addr_sel         : cpu_or1knd_i5_e_addr_sel_type;

    m_exception_sel    : cpu_or1knd_i5_m_exception_sel_type;
    m_mfspr_data       : or1k_word_type;
    m_mfspr_data_sel   : cpu_or1knd_i5_m_mfspr_data_sel_type;
    m_sext             : std_ulogic;
    m_rd_data_sel      : cpu_or1knd_i5_rd_data_sel_type;
    m_data_size_sel    : cpu_or1knd_i5_data_size_sel_type;

    m_load_buffer_write  : std_ulogic;
    m_load_data_buffered : std_ulogic;

    m_spr_sys_eear0_write : std_ulogic;
    m_spr_sys_eear0_sel   : cpu_or1knd_i5_m_spr_sys_eear0_sel_type;
    m_spr_sys_epcr0_write : std_ulogic;
    m_spr_sys_epcr0_sel   : cpu_or1knd_i5_m_spr_sys_epcr0_sel_type;

    m_spr_mac_machi_write : std_ulogic;
    m_spr_mac_machi_sel   : cpu_or1knd_i5_m_spr_mac_machi_sel_type;
    m_spr_mac_maclo_write : std_ulogic;
    m_spr_mac_maclo_sel   : cpu_or1knd_i5_m_spr_mac_maclo_sel_type;

    p_spr_sys_sr_eph : std_ulogic;
    
    regfile_raddr1_sel : cpu_or1knd_i5_regfile_raddr1_sel_type;
    regfile_raddr2_sel : cpu_or1knd_i5_regfile_raddr2_sel_type;
    regfile_w_sel  : cpu_or1knd_i5_regfile_w_sel_type;

    l1mem_inst_vaddr_sel : cpu_or1knd_i5_l1mem_inst_vaddr_sel_type;
    l1mem_data_vaddr_sel : cpu_or1knd_i5_l1mem_data_vaddr_sel_type;
    
  end record;
  
  type cpu_or1knd_i5_pipe_dp_out_ctrl_type is record

    f_inst           : or1k_inst_type;
    
    d_depends_ra_e   : std_ulogic;
    d_depends_rb_e   : std_ulogic;
    d_depends_ra_m   : std_ulogic;
    d_depends_rb_m   : std_ulogic;
    
    e_not_equal      : std_ulogic;
    e_lts            : std_ulogic;
    e_ltu            : std_ulogic;
    e_ldst_misaligned  : std_ulogic;
    e_spr_addr_sel   : cpu_or1knd_i5_spr_addr_sel_type;
    e_spr_addr_valid : std_ulogic;
    e_toc_target_misaligned : std_ulogic;
    e_btb_mispred    : std_ulogic;

    m_mtspr_data           : or1k_word_type;
    m_madd_result_hi_zeros : std_ulogic;
    m_madd_result_hi_ones  : std_ulogic;
    m_mul_result_msb       : std_ulogic;

  end record;

  type cpu_or1knd_i5_pipe_ctrl_out_misc_type is record
    e_addsub_sub      : std_ulogic;
    e_addsub_carryin  : std_ulogic;

    e_shifter_right   : std_ulogic;
    e_shifter_rot     : std_ulogic;
    e_shifter_unsgnd  : std_ulogic;
    
    e_mul_en          : std_ulogic;
    e_mul_unsgnd      : std_ulogic;
    e_madd_sub        : std_ulogic;

    e_div_en          : std_ulogic;
    e_div_unsgnd      : std_ulogic;

    regfile_we      : std_ulogic;
    regfile_re1     : std_ulogic;
    regfile_re2     : std_ulogic;
  end record;

  type cpu_or1knd_i5_pipe_ctrl_in_misc_type is record
    e_addsub_carryout : std_ulogic;
    e_addsub_overflow : std_ulogic;

    m_mul_valid       : std_ulogic;
    m_mul_overflow    : std_ulogic;
    m_madd_overflow   : std_ulogic;
    
    m_div_valid       : std_ulogic;
    m_div_dbz         : std_ulogic;
    m_div_overflow    : std_ulogic;
  end record;

  type cpu_or1knd_i5_pipe_dp_out_misc_type is record
    e_alu_src1     : std_ulogic_vector(or1k_word_bits-1 downto 0);
    e_alu_src2     : std_ulogic_vector(or1k_word_bits-1 downto 0);

    e_madd_acc     : std_ulogic_vector(2*or1k_word_bits-1 downto 0);

    regfile_waddr  : or1k_rfaddr_type;
    regfile_wdata  : or1k_word_type;
    regfile_raddr1 : or1k_rfaddr_type;
    regfile_raddr2 : or1k_rfaddr_type;
  end record;

  type cpu_or1knd_i5_pipe_dp_in_misc_type is record
    e_addsub_result  : std_ulogic_vector(or1k_word_bits-1 downto 0);

    e_shifter_result : std_ulogic_vector(or1k_word_bits-1 downto 0);

    m_madd_result_hi : std_ulogic_vector(or1k_word_bits-1 downto 0);
    m_mul_result     : std_ulogic_vector(or1k_word_bits-1 downto 0);
    
    m_div_result     : std_ulogic_vector(or1k_word_bits-1 downto 0);

    regfile_rdata1 : or1k_word_type;
    regfile_rdata2 : or1k_word_type;
  end record;

end package;
