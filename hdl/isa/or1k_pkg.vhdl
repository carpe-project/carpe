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
use util.types_pkg.all;
use util.numeric_pkg.all;

package or1k_pkg is

  constant or1k_vaddr_bits : natural := 32;
  constant or1k_paddr_bits : natural := 35;
  constant or1k_log2_word_bytes : natural := 2;
  constant or1k_word_bytes : natural := 2**or1k_log2_word_bytes;
  constant or1k_log2_inst_bytes : natural := 2;
  constant or1k_inst_bytes : natural := 2**or1k_log2_inst_bytes;
  constant or1k_rfaddr_bits : natural := 5;
  constant or1k_wmask_bits : natural := 4; -- word mask, one bit per byte in word
  constant or1k_poffset_bits : natural := 13;
  constant or1k_vpn_bits : natural := or1k_vaddr_bits - or1k_poffset_bits;
  constant or1k_ppn_bits : natural := or1k_paddr_bits - or1k_poffset_bits;
  constant or1k_word_bits : natural := or1k_word_bytes * byte_bits;
  constant or1k_inst_bits : natural := or1k_inst_bytes * byte_bits;
  constant or1k_shift_bits : natural := log2ceil(or1k_word_bits);
  
  -- the number of bits required to encode the size of a data request.
  -- for example, is word_bytes is 4 or 8, then we need 2 bits.
  -- 00 -> 1 byte request,
  -- 01 -> 2 byte request,
  -- 10 -> 4 byte request,
  -- 11 -> 8 byte request.
  constant or1k_log2_data_size_bits : natural := bitsize(or1k_log2_word_bytes);
  
  constant or1k_wvaddr_bits : natural := or1k_vaddr_bits - or1k_log2_word_bytes;
  constant or1k_ivaddr_bits : natural := or1k_vaddr_bits - or1k_log2_inst_bytes;
  constant or1k_wpaddr_bits : natural := or1k_paddr_bits - or1k_log2_word_bytes;
  constant or1k_ipaddr_bits : natural := or1k_paddr_bits - or1k_log2_inst_bytes;
  constant or1k_wpoffset_bits : natural := or1k_poffset_bits - or1k_log2_word_bytes;
  constant or1k_ipoffset_bits : natural := or1k_poffset_bits - or1k_log2_inst_bytes;
  
  constant or1k_inst_endianness : endianness_type := big_endian;

  subtype or1k_vaddr_type is std_ulogic_vector(or1k_vaddr_bits-1 downto 0);
  subtype or1k_paddr_type is std_ulogic_vector(or1k_paddr_bits-1 downto 0);
  subtype or1k_wvaddr_type is std_ulogic_vector(or1k_wvaddr_bits-1 downto 0);
  subtype or1k_ivaddr_type is std_ulogic_vector(or1k_ivaddr_bits-1 downto 0);
  subtype or1k_wpaddr_type is std_ulogic_vector(or1k_wpaddr_bits-1 downto 0);
  subtype or1k_ipaddr_type is std_ulogic_vector(or1k_ipaddr_bits-1 downto 0);
  subtype or1k_poffset_type is std_ulogic_vector(or1k_poffset_bits-1 downto 0);
  subtype or1k_ipoffset_type is std_ulogic_vector(or1k_ipoffset_bits-1 downto 0);
  subtype or1k_wpoffset_type is std_ulogic_vector(or1k_wpoffset_bits-1 downto 0);
  subtype or1k_vpn_type is std_ulogic_vector(or1k_vpn_bits-1 downto 0);
  subtype or1k_ppn_type is std_ulogic_vector(or1k_ppn_bits-1 downto 0);
  
  subtype or1k_word_bytes_type is std_ulogic_vector2(or1k_word_bytes-1 downto 0, byte_bits-1 downto 0);
  subtype or1k_word_type is std_ulogic_vector(or1k_word_bits-1 downto 0);
  subtype or1k_dword_type is std_ulogic_vector(2*or1k_word_bits-1 downto 0);
  subtype or1k_inst_bytes_type is std_ulogic_vector2(or1k_inst_bytes-1 downto 0, byte_bits-1 downto 0);
  subtype or1k_inst_type is std_ulogic_vector(or1k_inst_bits-1 downto 0);
  subtype or1k_rfaddr_type is std_ulogic_vector(or1k_rfaddr_bits-1 downto 0);
  subtype or1k_shift_type is std_ulogic_vector(or1k_shift_bits-1 downto 0);
  subtype or1k_wmask_type is std_ulogic_vector(or1k_wmask_bits-1 downto 0);
  subtype or1k_log2_data_size_type is std_ulogic_vector(or1k_log2_data_size_bits-1 downto 0);
  
  constant or1k_cid_bits : natural := 4;
  subtype or1k_cid_type is std_ulogic_vector(or1k_cid_bits-1 downto 0);
  constant or1k_atb_index_bits : natural := 2;
  subtype or1k_atb_index_type is std_ulogic_vector(or1k_atb_index_bits-1 downto 0);
  constant or1k_tlb_index_bits : natural := 7;
  subtype or1k_tlb_index_type is std_ulogic_vector(or1k_tlb_index_bits-1 downto 0);
  constant or1k_tlb_way_bits : natural := 2;
  constant or1k_atb_entries : natural := 2**or1k_atb_index_bits;
  constant or1k_tlb_sets : natural := 2**or1k_tlb_index_bits;
  constant or1k_tlb_ways : natural := 2**or1k_tlb_way_bits;
  subtype or1k_tlb_way_type is std_ulogic_vector(or1k_tlb_way_bits-1 downto 0);
  constant or1k_cache_way_mask_bits : natural := 8;
  subtype or1k_cache_way_mask_type is std_ulogic_vector(or1k_cache_way_mask_bits-1 downto 0);

  constant or1k_contexts : natural := 2**or1k_cid_bits;

  constant or1k_exception_bits : natural := 4;
  subtype or1k_exception_type is std_ulogic_vector(or1k_exception_bits-1 downto 0);
  constant or1k_exception_none     : or1k_exception_type := "0000";
  constant or1k_exception_reset    : or1k_exception_type := "0001";
  constant or1k_exception_bus      : or1k_exception_type := "0010";
  constant or1k_exception_dpf      : or1k_exception_type := "0011";
  constant or1k_exception_ipf      : or1k_exception_type := "0100";
  constant or1k_exception_tti      : or1k_exception_type := "0101";
  constant or1k_exception_align    : or1k_exception_type := "0110";
  constant or1k_exception_ill      : or1k_exception_type := "0111";
  constant or1k_exception_ext      : or1k_exception_type := "1000";
  constant or1k_exception_dtlbmiss : or1k_exception_type := "1001";
  constant or1k_exception_itlbmiss : or1k_exception_type := "1010";
  constant or1k_exception_range    : or1k_exception_type := "1011";
  constant or1k_exception_syscall  : or1k_exception_type := "1100";
  constant or1k_exception_fp       : or1k_exception_type := "1110";
  constant or1k_exception_trap     : or1k_exception_type := "1110";

  constant or1k_spr_data_bits : natural := 32;
  subtype or1k_spr_data_type is std_ulogic_vector(or1k_spr_data_bits-1 downto 0);
  
  pure function or1k_spr_mask(lsb, msb : natural) return or1k_spr_data_type;

  constant or1k_spr_group_bits : natural := 6;
  subtype or1k_spr_group_type is std_ulogic_vector(or1k_spr_group_bits-1 downto 0);
  constant or1k_spr_index_bits : natural := 11;
  subtype or1k_spr_index_type is std_ulogic_vector(or1k_spr_index_bits-1 downto 0);
  constant or1k_spr_addr_bits : natural := or1k_spr_group_bits + or1k_spr_index_bits;
  subtype or1k_spr_addr_type is std_ulogic_vector(or1k_spr_addr_bits-1 downto 0);
  
  constant or1k_spr_group_sys    : or1k_spr_group_type := "000000";
  constant or1k_spr_group_dmmu   : or1k_spr_group_type := "000001";
  constant or1k_spr_group_immu   : or1k_spr_group_type := "000010";
  constant or1k_spr_group_dcache : or1k_spr_group_type := "000011";
  constant or1k_spr_group_icache : or1k_spr_group_type := "000100";
  constant or1k_spr_group_mac    : or1k_spr_group_type := "000101";
  constant or1k_spr_group_debug  : or1k_spr_group_type := "000110";
  constant or1k_spr_group_perf   : or1k_spr_group_type := "000111";
  constant or1k_spr_group_power  : or1k_spr_group_type := "001000";
  constant or1k_spr_group_pic    : or1k_spr_group_type := "001001";
  constant or1k_spr_group_tick   : or1k_spr_group_type := "001010";
  constant or1k_spr_group_fpu    : or1k_spr_group_type := "001011";

  constant or1k_spr_index_sys_vr       : or1k_spr_index_type := "00000000000";
  constant or1k_spr_index_sys_upr      : or1k_spr_index_type := "00000000001";
  constant or1k_spr_index_sys_cpucfgr  : or1k_spr_index_type := "00000000010";
  constant or1k_spr_index_sys_dmmucfgr : or1k_spr_index_type := "00000000011";
  constant or1k_spr_index_sys_immucfgr : or1k_spr_index_type := "00000000100";
  constant or1k_spr_index_sys_dccfgr   : or1k_spr_index_type := "00000000101";
  constant or1k_spr_index_sys_iccfgr   : or1k_spr_index_type := "00000000110";
  constant or1k_spr_index_sys_dcfgr    : or1k_spr_index_type := "00000000111";
  constant or1k_spr_index_sys_pccfgr   : or1k_spr_index_type := "00000001000";
  constant or1k_spr_index_sys_vr2      : or1k_spr_index_type := "00000001001";
  constant or1k_spr_index_sys_avr      : or1k_spr_index_type := "00000001010";
  constant or1k_spr_index_sys_evbar    : or1k_spr_index_type := "00000001011";
  constant or1k_spr_index_sys_aecr     : or1k_spr_index_type := "00000001100";
  constant or1k_spr_index_sys_aesr     : or1k_spr_index_type := "00000001101";
  constant or1k_spr_index_sys_npc      : or1k_spr_index_type := "00000010000";
  constant or1k_spr_index_sys_sr       : or1k_spr_index_type := "00000010001";
  constant or1k_spr_index_sys_ppc      : or1k_spr_index_type := "00000010010";
  constant or1k_spr_index_sys_fpcsr    : or1k_spr_index_type := "00000010100";
  constant or1k_spr_index_sys_epcr_base : or1k_spr_index_type := "00000100000";
  constant or1k_spr_index_sys_epcr_index_bits : natural := or1k_cid_bits;
  pure function or1k_spr_index_sys_epcr (n : natural range 0 to or1k_contexts-1) return or1k_spr_index_type;
  constant or1k_spr_index_sys_eear_base : or1k_spr_index_type := "00000110000";
  constant or1k_spr_index_sys_eear_index_bits : natural := or1k_cid_bits;
  pure function or1k_spr_index_sys_eear (n : natural range 0 to or1k_contexts-1) return or1k_spr_index_type;
  constant or1k_spr_index_sys_esr_base : or1k_spr_index_type := "00001000000";
  constant or1k_spr_index_sys_esr_index_bits : natural := or1k_cid_bits;
  pure function or1k_spr_index_sys_esr (n : natural range 0 to or1k_contexts-1) return or1k_spr_index_type;
  constant or1k_spr_index_sys_gpr_base : or1k_spr_index_type := "10000000000";
  constant or1k_spr_index_sys_gpr_index_bits : natural := 9;
  pure function or1k_spr_index_sys_gpr (n : natural range 0 to 2**or1k_spr_index_sys_gpr_index_bits-1) return or1k_spr_index_type;

  constant or1k_spr_index_dmmu_dmmucr  : or1k_spr_index_type := "00000000000";
  constant or1k_spr_index_dmmu_dmmupr  : or1k_spr_index_type := "00000000001";
  constant or1k_spr_index_dmmu_dtlbeir : or1k_spr_index_type := "00000000010";
  constant or1k_spr_index_dmmu_datbmr_base : or1k_spr_index_type := "00000000100";
  constant or1k_spr_index_dmmu_datbmr_index_bits : natural := or1k_atb_index_bits;
  pure function or1k_spr_index_dmmu_datbmr (n : natural range 0 to or1k_atb_entries-1) return or1k_spr_index_type;
  constant or1k_spr_index_dmmu_datbtr_base : or1k_spr_index_type := "00000001000";
  constant or1k_spr_index_dmmu_datbtr_index_bits : natural := or1k_atb_index_bits;
  pure function or1k_spr_index_dmmu_datbtr (n : natural range 0 to or1k_atb_entries-1) return or1k_spr_index_type;
  constant or1k_spr_index_dmmu_dtlbwmr_base : or1k_spr_index_type := "01000000000";
  constant or1k_spr_index_dmmu_dtlbwmr_way_bits : natural := or1k_tlb_way_bits;
  constant or1k_spr_index_dmmu_dtlbwmr_index_bits : natural := or1k_tlb_index_bits;
  pure function or1k_spr_index_dmmu_dtlbwmr (w : natural range 0 to or1k_tlb_ways-1;
                                             n : natural range 0 to or1k_tlb_sets-1) return or1k_spr_index_type;
  constant or1k_spr_index_dmmu_dtlbwtr_base : or1k_spr_index_type := "01010000000";
  constant or1k_spr_index_dmmu_dtlbwtr_way_bits : natural := or1k_tlb_way_bits;
  constant or1k_spr_index_dmmu_dtlbwtr_index_bits : natural := or1k_tlb_index_bits;
  pure function or1k_spr_index_dmmu_dtlbwtr (w : natural range 0 to or1k_tlb_ways-1;
                                             n : natural range 0 to or1k_tlb_sets-1) return or1k_spr_index_type;

  constant or1k_spr_index_immu_immucr  : or1k_spr_index_type := "00000000000";
  constant or1k_spr_index_immu_immupr  : or1k_spr_index_type := "00000000001";
  constant or1k_spr_index_immu_itlbeir : or1k_spr_index_type := "00000000010";
  constant or1k_spr_index_immu_iatbmr_base : or1k_spr_index_type := "00000000100";
  constant or1k_spr_index_immu_iatbmr_index_bits : natural := or1k_atb_index_bits;
  pure function or1k_spr_index_immu_iatbmr (n : natural range 0 to or1k_atb_entries-1) return or1k_spr_index_type;
  constant or1k_spr_index_immu_iatbtr_base : or1k_spr_index_type := "00000001000";
  constant or1k_spr_index_immu_iatbtr_index_bits : natural := or1k_atb_index_bits;
  pure function or1k_spr_index_immu_iatbtr (n : natural range 0 to or1k_atb_entries-1) return or1k_spr_index_type;
  constant or1k_spr_index_immu_itlbwmr_base : or1k_spr_index_type := "01000000000";
  constant or1k_spr_index_immu_itlbwmr_way_bits : natural := or1k_tlb_way_bits;
  constant or1k_spr_index_immu_itlbwmr_index_bits : natural := or1k_tlb_index_bits;
  pure function or1k_spr_index_immu_itlbwmr (w : natural range 0 to or1k_tlb_ways-1;
                                             n : natural range 0 to or1k_tlb_sets-1) return or1k_spr_index_type;
  constant or1k_spr_index_immu_itlbwtr_base : or1k_spr_index_type := "01010000000";
  constant or1k_spr_index_immu_itlbwtr_way_bits : natural := or1k_tlb_way_bits;
  constant or1k_spr_index_immu_itlbwtr_index_bits : natural := or1k_tlb_index_bits;
  pure function or1k_spr_index_immu_itlbwtr (w : natural range 0 to or1k_tlb_ways-1;
                                             n : natural range 0 to or1k_tlb_sets-1) return or1k_spr_index_type;

  constant or1k_spr_index_mac_maclo    : or1k_spr_index_type := "00000000001";
  constant or1k_spr_index_mac_machi    : or1k_spr_index_type := "00000000010";

  constant or1k_spr_index_dcache_dccr  : or1k_spr_index_type := "00000000000";
  constant or1k_spr_index_dcache_dcbpr : or1k_spr_index_type := "00000000001";
  constant or1k_spr_index_dcache_dcbfr : or1k_spr_index_type := "00000000010";
  constant or1k_spr_index_dcache_dcbir : or1k_spr_index_type := "00000000011";
  constant or1k_spr_index_dcache_dcbwr : or1k_spr_index_type := "00000000100";
  constant or1k_spr_index_dcache_dcblr : or1k_spr_index_type := "00000000101";

  constant or1k_spr_index_icache_iccr  : or1k_spr_index_type := "00000000000";
  constant or1k_spr_index_icache_icbpr : or1k_spr_index_type := "00000000001";
  constant or1k_spr_index_icache_icbir : or1k_spr_index_type := "00000000010";
  constant or1k_spr_index_icache_icblr : or1k_spr_index_type := "00000000011";
  
  constant or1k_spr_field_sys_vr_rev_lsb        : natural := 0;
  constant or1k_spr_field_sys_vr_rev_msb        : natural := 5;
  constant or1k_spr_field_sys_vr_cfg_lsb        : natural := 16;
  constant or1k_spr_field_sys_vr_cfg_msb        : natural := 23;
  constant or1k_spr_field_sys_vr_ver_lsb        : natural := 24;
  constant or1k_spr_field_sys_vr_ver_msb        : natural := 31;
  
  constant or1k_spr_field_sys_upr_up            : natural := 0;
  constant or1k_spr_field_sys_upr_dcp           : natural := 1;
  constant or1k_spr_field_sys_upr_icp           : natural := 2;
  constant or1k_spr_field_sys_upr_dmp           : natural := 3;
  constant or1k_spr_field_sys_upr_imp           : natural := 4;
  constant or1k_spr_field_sys_upr_mp            : natural := 5;
  constant or1k_spr_field_sys_upr_dup           : natural := 6;
  constant or1k_spr_field_sys_upr_pcup          : natural := 7;
  constant or1k_spr_field_sys_upr_picp          : natural := 8;
  constant or1k_spr_field_sys_upr_pmp           : natural := 9;
  constant or1k_spr_field_sys_upr_ttp           : natural := 10;
  constant or1k_spr_field_sys_upr_cup_lsb       : natural := 24;
  constant or1k_spr_field_sys_upr_cup_msb       : natural := 31;
  
  constant or1k_spr_field_sys_cpucfgr_nsgr_lsb  : natural := 0;
  constant or1k_spr_field_sys_cpucfgr_nsgr_msb  : natural := 3;
  constant or1k_spr_field_sys_cpucfgr_cgf       : natural := 4;
  constant or1k_spr_field_sys_cpucfgr_ob32s     : natural := 5;
  constant or1k_spr_field_sys_cpucfgr_ob64s     : natural := 6;
  constant or1k_spr_field_sys_cpucfgr_of32s     : natural := 7;
  constant or1k_spr_field_sys_cpucfgr_of64s     : natural := 8;
  constant or1k_spr_field_sys_cpucfgr_ov64s     : natural := 9;
  constant or1k_spr_field_sys_cpucfgr_nd        : natural := 10;
  constant or1k_spr_field_sys_cpucfgr_avrp      : natural := 11;
  constant or1k_spr_field_sys_cpucfgr_evbarp    : natural := 12;
  constant or1k_spr_field_sys_cpucfgr_isrp      : natural := 13;
  constant or1k_spr_field_sys_cpucfgr_aecsrp    : natural := 14;

  constant or1k_spr_field_sys_dmmucfgr_ntw_lsb  : natural := 0;
  constant or1k_spr_field_sys_dmmucfgr_ntw_msb  : natural := 1;
  constant or1k_spr_field_sys_dmmucfgr_nts_lsb  : natural := 2;
  constant or1k_spr_field_sys_dmmucfgr_nts_msb  : natural := 4;
  constant or1k_spr_field_sys_dmmucfgr_nae_lsb  : natural := 5;
  constant or1k_spr_field_sys_dmmucfgr_nae_msb  : natural := 7;
  constant or1k_spr_field_sys_dmmucfgr_cri      : natural := 8;
  constant or1k_spr_field_sys_dmmucfgr_pri      : natural := 9;
  constant or1k_spr_field_sys_dmmucfgr_teiri    : natural := 10;
  constant or1k_spr_field_sys_dmmucfgr_htr      : natural := 11;
  
  constant or1k_spr_field_sys_immucfgr_ntw_lsb  : natural := 0;
  constant or1k_spr_field_sys_immucfgr_ntw_msb  : natural := 1;
  constant or1k_spr_field_sys_immucfgr_nts_lsb  : natural := 2;
  constant or1k_spr_field_sys_immucfgr_nts_msb  : natural := 4;
  constant or1k_spr_field_sys_immucfgr_nae_lsb  : natural := 5;
  constant or1k_spr_field_sys_immucfgr_nae_msb  : natural := 7;
  constant or1k_spr_field_sys_immucfgr_cri      : natural := 8;
  constant or1k_spr_field_sys_immucfgr_pri      : natural := 9;
  constant or1k_spr_field_sys_immucfgr_teiri    : natural := 10;
  constant or1k_spr_field_sys_immucfgr_htr      : natural := 11;

  constant or1k_spr_field_sys_dccfgr_ncw_lsb    : natural := 0;
  constant or1k_spr_field_sys_dccfgr_ncw_msb    : natural := 2;
  constant or1k_spr_field_sys_dccfgr_ncs_lsb    : natural := 3;
  constant or1k_spr_field_sys_dccfgr_ncs_msb    : natural := 6;
  constant or1k_spr_field_sys_dccfgr_cbs        : natural := 7;
  constant or1k_spr_field_sys_dccfgr_cws        : natural := 8;
  constant or1k_spr_field_sys_dccfgr_ccri       : natural := 9;
  constant or1k_spr_field_sys_dccfgr_cbiri      : natural := 10;
  constant or1k_spr_field_sys_dccfgr_cbpri      : natural := 11;
  constant or1k_spr_field_sys_dccfgr_cblri      : natural := 12;
  constant or1k_spr_field_sys_dccfgr_cbfri      : natural := 13;
  constant or1k_spr_field_sys_dccfgr_cbwbri     : natural := 14;
  
  constant or1k_spr_field_sys_iccfgr_ncw_lsb    : natural := 0;
  constant or1k_spr_field_sys_iccfgr_ncw_msb    : natural := 2;
  constant or1k_spr_field_sys_iccfgr_ncs_lsb    : natural := 3;
  constant or1k_spr_field_sys_iccfgr_ncs_msb    : natural := 6;
  constant or1k_spr_field_sys_iccfgr_cbs        : natural := 7;
  constant or1k_spr_field_sys_iccfgr_ccri       : natural := 9;
  constant or1k_spr_field_sys_iccfgr_cbiri      : natural := 10;
  constant or1k_spr_field_sys_iccfgr_cbpri      : natural := 11;
  constant or1k_spr_field_sys_iccfgr_cblri      : natural := 12;

  constant or1k_spr_field_dcfgr_ndp_lsb         : natural := 0;
  constant or1k_spr_field_dcfgr_ndp_msb         : natural := 2;
  constant or1k_spr_field_dcfgr_wpci            : natural := 3;
  
  constant or1k_spr_field_pccfgr_npc_lsb        : natural := 0;
  constant or1k_spr_field_pccfgr_npc_msb        : natural := 2;

  constant or1k_spr_field_sys_vr2_ver_lsb       : natural := 0;
  constant or1k_spr_field_sys_vr2_ver_msb       : natural := 23;
  constant or1k_spr_field_sys_vr2_cpuid_lsb       : natural := 24;
  constant or1k_spr_field_sys_vr2_cpuid_msb       : natural := 31;
  
  constant or1k_spr_field_sys_avr_rev_lsb       : natural := 8;
  constant or1k_spr_field_sys_avr_rev_msb       : natural := 15;
  constant or1k_spr_field_sys_avr_min_lsb       : natural := 16;
  constant or1k_spr_field_sys_avr_min_msb       : natural := 23;
  constant or1k_spr_field_sys_avr_maj_lsb       : natural := 24;
  constant or1k_spr_field_sys_avr_maj_msb       : natural := 31;

  constant or1k_spr_field_sys_evbar_evba_lsb     : natural := 13;
  constant or1k_spr_field_sys_evbar_evba_msb     : natural := 31;
  
  constant or1k_spr_field_sys_aecsr_cyadde        : natural := 0;
  constant or1k_spr_field_sys_aecsr_ovadde        : natural := 1;
  constant or1k_spr_field_sys_aecsr_cymule        : natural := 2;
  constant or1k_spr_field_sys_aecsr_ovmule        : natural := 3;
  constant or1k_spr_field_sys_aecsr_dbze           : natural := 4;
  constant or1k_spr_field_sys_aecsr_cymacadde     : natural := 5;
  constant or1k_spr_field_sys_aecsr_ovmacadde     : natural := 6;
  
  constant or1k_spr_field_sys_sr_sm             : natural := 0;
  constant or1k_spr_field_sys_sr_tee            : natural := 1;
  constant or1k_spr_field_sys_sr_iee            : natural := 2;
  constant or1k_spr_field_sys_sr_dce            : natural := 3;
  constant or1k_spr_field_sys_sr_ice            : natural := 4;
  constant or1k_spr_field_sys_sr_dme            : natural := 5;
  constant or1k_spr_field_sys_sr_ime            : natural := 6;
  constant or1k_spr_field_sys_sr_lee            : natural := 7;
  constant or1k_spr_field_sys_sr_ce             : natural := 8;
  constant or1k_spr_field_sys_sr_f              : natural := 9;
  constant or1k_spr_field_sys_sr_cy             : natural := 10;
  constant or1k_spr_field_sys_sr_ov             : natural := 11;
  constant or1k_spr_field_sys_sr_ove            : natural := 12;
  constant or1k_spr_field_sys_sr_dsx            : natural := 13;
  constant or1k_spr_field_sys_sr_eph            : natural := 14;
  constant or1k_spr_field_sys_sr_fo             : natural := 15;
  constant or1k_spr_field_sys_sr_sumra          : natural := 16;
  constant or1k_spr_field_sys_sr_cid_lsb        : natural := 28;
  constant or1k_spr_field_sys_sr_cid_msb        : natural := 31;

  constant or1k_spr_field_dcache_dccr_ew_lsb    : natural := 0;
  constant or1k_spr_field_dcache_dccr_ew_msb    : natural := 7;
  
  constant or1k_spr_field_dcache_iccr_ew_lsb    : natural := 0;
  constant or1k_spr_field_dcache_iccr_ew_msb    : natural := 7;
  
  constant or1k_imm_bits : natural := 16;
  subtype or1k_imm_type is std_ulogic_vector(or1k_imm_bits-1 downto 0);
  constant or1k_toc_offset_bits : natural := 26;
  subtype or1k_toc_offset_type is std_ulogic_vector(or1k_toc_offset_bits-1 downto 0);

  pure function or1k_inst_rd(inst : in or1k_inst_type) return or1k_rfaddr_type;
  pure function or1k_inst_ra(inst : in or1k_inst_type) return or1k_rfaddr_type;
  pure function or1k_inst_rb(inst : in or1k_inst_type) return or1k_rfaddr_type;
  pure function or1k_inst_imm_contig(inst : in or1k_inst_type) return or1k_imm_type;
  pure function or1k_inst_imm_split(inst : in or1k_inst_type) return or1k_imm_type;
  pure function or1k_inst_toc_offset(inst : in or1k_inst_type) return or1k_toc_offset_type;
  pure function or1k_inst_shift(inst : in or1k_inst_type) return or1k_shift_type;

end package;

package body or1k_pkg is

  pure function or1k_spr_mask(lsb, msb : natural) return or1k_spr_data_type is
    variable ret : or1k_spr_data_type;
  begin
    ret := (others => '0');
    ret(msb downto lsb) := (msb downto lsb => '1');
    return ret;
  end;

  pure function or1k_spr_index_sys_epcr (n : natural range 0 to or1k_contexts-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_sys_epcr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_sys_epcr_index_bits => '0') &
                                      to_unsigned(n, or1k_spr_index_sys_epcr_index_bits)));
  end;

  pure function or1k_spr_index_sys_eear (n : natural range 0 to or1k_contexts-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_sys_eear_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_sys_eear_index_bits => '0') &
                                      to_unsigned(n, or1k_spr_index_sys_eear_index_bits)));
  end;

  pure function or1k_spr_index_sys_esr (n : natural range 0 to or1k_contexts-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_sys_esr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_sys_esr_index_bits => '0') &
                                       to_unsigned(n, or1k_spr_index_sys_esr_index_bits)));
  end;

  pure function or1k_spr_index_sys_gpr (n : natural range 0 to 2**or1k_spr_index_sys_gpr_index_bits-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_sys_gpr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_sys_gpr_index_bits => '0') &
                                      to_unsigned(n, or1k_spr_index_sys_gpr_index_bits)));
  end;

  pure function or1k_spr_index_dmmu_datbmr (n : natural range 0 to or1k_atb_entries-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_dmmu_datbmr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_dmmu_datbmr_index_bits => '0') &
                                      to_unsigned(n, or1k_spr_index_dmmu_datbmr_index_bits)));
  end;

  pure function or1k_spr_index_dmmu_datbtr (n : natural range 0 to or1k_atb_entries-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_dmmu_datbtr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_dmmu_datbtr_index_bits => '0') &
                                      to_unsigned(n, or1k_spr_index_dmmu_datbtr_index_bits)));
  end;

  pure function or1k_spr_index_dmmu_dtlbwmr (w : natural range 0 to or1k_tlb_ways-1;
                                             n : natural range 0 to or1k_tlb_sets-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_dmmu_dtlbwmr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_dmmu_dtlbwmr_way_bits+or1k_spr_index_dmmu_dtlbwmr_index_bits => '0') &
                                      to_unsigned(w, or1k_spr_index_dmmu_dtlbwmr_way_bits) &
                                      to_unsigned(n, or1k_spr_index_dmmu_dtlbwmr_index_bits)));
  end;

  pure function or1k_spr_index_dmmu_dtlbwtr (w : natural range 0 to or1k_tlb_ways-1;
                                             n : natural range 0 to or1k_tlb_sets-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_dmmu_dtlbwtr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_dmmu_dtlbwtr_way_bits+or1k_spr_index_dmmu_dtlbwtr_index_bits => '0') &
                                      to_unsigned(w, or1k_spr_index_dmmu_dtlbwtr_way_bits) &
                                      to_unsigned(n, or1k_spr_index_dmmu_dtlbwtr_index_bits)));
  end;

  pure function or1k_spr_index_immu_iatbmr (n : natural range 0 to or1k_atb_entries-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_immu_iatbmr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_immu_iatbmr_index_bits => '0') &
                                      to_unsigned(n, or1k_spr_index_immu_iatbmr_index_bits)));
  end;

  pure function or1k_spr_index_immu_iatbtr (n : natural range 0 to or1k_atb_entries-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_immu_iatbtr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_immu_iatbtr_index_bits => '0') &
                                      to_unsigned(n, or1k_spr_index_immu_iatbtr_index_bits)));
  end;

  pure function or1k_spr_index_immu_itlbwmr (w : natural range 0 to or1k_tlb_ways-1;
                                             n : natural range 0 to or1k_tlb_sets-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_immu_itlbwmr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_immu_itlbwmr_way_bits+or1k_spr_index_immu_itlbwmr_index_bits => '0') &
                                      to_unsigned(w, or1k_spr_index_immu_itlbwmr_way_bits) &
                                      to_unsigned(n, or1k_spr_index_immu_itlbwmr_index_bits)));
  end;

  pure function or1k_spr_index_immu_itlbwtr (w : natural range 0 to or1k_tlb_ways-1;
                                             n : natural range 0 to or1k_tlb_sets-1) return or1k_spr_index_type is
  begin
    return std_ulogic_vector(unsigned(or1k_spr_index_immu_itlbwtr_base) +
                             unsigned((or1k_spr_index_bits-1 downto or1k_spr_index_immu_itlbwtr_way_bits+or1k_spr_index_immu_itlbwtr_index_bits => '0') &
                                      to_unsigned(w, or1k_spr_index_immu_itlbwtr_way_bits) &
                                      to_unsigned(n, or1k_spr_index_immu_itlbwtr_index_bits)));
  end;
  
  pure function or1k_inst_rd(inst : in or1k_inst_type) return or1k_rfaddr_type is
    variable ret : or1k_rfaddr_type := inst(25 downto 21);
  begin
    return ret;
  end function;

  pure function or1k_inst_ra(inst : in or1k_inst_type) return or1k_rfaddr_type is
    variable ret : or1k_rfaddr_type := inst(20 downto 16);
  begin
    return ret;
  end function;

  pure function or1k_inst_rb(inst : in or1k_inst_type) return or1k_rfaddr_type is
    variable ret : or1k_rfaddr_type := inst(15 downto 11);
  begin
    return ret;
  end function;

  pure function or1k_inst_imm_contig(inst : in or1k_inst_type) return or1k_imm_type is
    variable ret : or1k_imm_type := inst(15 downto 0);
  begin
    return ret;
  end function;

  pure function or1k_inst_imm_split(inst : in or1k_inst_type) return or1k_imm_type is
    variable ret : or1k_imm_type := inst(25 downto 21) & inst(10 downto 0);
  begin
    return ret;
  end function;

  pure function or1k_inst_toc_offset(inst : in or1k_inst_type) return or1k_toc_offset_type is
    variable ret : or1k_toc_offset_type := inst(25 downto 0);
  begin
    return ret;
  end function;

  pure function or1k_inst_shift(inst : in or1k_inst_type) return or1k_shift_type is
    variable ret : or1k_shift_type := inst(4 downto 0);
  begin
    return ret;
  end function;

end package body;
