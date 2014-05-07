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

package cpu_mmu_data_types_pkg is

  type cpu_mmu_data_result_code_index_type is (
    cpu_mmu_data_result_code_index_valid,
    cpu_mmu_data_result_code_index_error,
    cpu_mmu_data_result_code_index_tlbmiss,
    cpu_mmu_data_result_code_index_pf
    );
  type cpu_mmu_data_result_code_type is
    array (cpu_mmu_data_result_code_index_type range
           cpu_mmu_data_result_code_index_type'high downto
           cpu_mmu_data_result_code_index_type'low) of std_ulogic;
  constant cpu_mmu_data_result_code_valid    : cpu_mmu_data_result_code_type := "0001";
  constant cpu_mmu_data_result_code_error    : cpu_mmu_data_result_code_type := "0010";
  constant cpu_mmu_data_result_code_tlbmiss  : cpu_mmu_data_result_code_type := "0100";
  constant cpu_mmu_data_result_code_pf       : cpu_mmu_data_result_code_type := "1000";

end package;
