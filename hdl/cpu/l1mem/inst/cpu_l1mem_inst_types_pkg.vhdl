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

package cpu_l1mem_inst_types_pkg is

  type cpu_l1mem_inst_request_code_index_type is (
    cpu_l1mem_inst_request_code_index_none,
    cpu_l1mem_inst_request_code_index_fetch,
    cpu_l1mem_inst_request_code_index_invalidate,
    cpu_l1mem_inst_request_code_index_sync
    );
  type cpu_l1mem_inst_request_code_type is
    array (cpu_l1mem_inst_request_code_index_type range
           cpu_l1mem_inst_request_code_index_type'high downto
           cpu_l1mem_inst_request_code_index_type'low) of std_ulogic;
  constant cpu_l1mem_inst_request_code_none       : cpu_l1mem_inst_request_code_type := "0001";
  constant cpu_l1mem_inst_request_code_fetch      : cpu_l1mem_inst_request_code_type := "0010"; 
  constant cpu_l1mem_inst_request_code_invalidate : cpu_l1mem_inst_request_code_type := "0100";
  constant cpu_l1mem_inst_request_code_sync       : cpu_l1mem_inst_request_code_type := "1000";
  
  type cpu_l1mem_inst_fetch_direction_index_type is (
    cpu_l1mem_inst_fetch_direction_index_seq,
    cpu_l1mem_inst_fetch_direction_index_dir,
    cpu_l1mem_inst_fetch_direction_index_indir
    );
  type cpu_l1mem_inst_fetch_direction_type is
    array (cpu_l1mem_inst_fetch_direction_index_type range
           cpu_l1mem_inst_fetch_direction_index_type'high downto
           cpu_l1mem_inst_fetch_direction_index_type'low) of std_ulogic;
  constant cpu_l1mem_inst_fetch_direction_seq    : cpu_l1mem_inst_fetch_direction_type := "001";
  constant cpu_l1mem_inst_fetch_direction_dir    : cpu_l1mem_inst_fetch_direction_type := "010";
  constant cpu_l1mem_inst_fetch_direction_indir  : cpu_l1mem_inst_fetch_direction_type := "100";

  type cpu_l1mem_inst_result_code_index_type is (
    cpu_l1mem_inst_result_code_index_valid,
    cpu_l1mem_inst_result_code_index_error,
    cpu_l1mem_inst_result_code_index_tlbmiss,
    cpu_l1mem_inst_result_code_index_pf
    );
  type cpu_l1mem_inst_result_code_type is
    array (cpu_l1mem_inst_result_code_index_type range
           cpu_l1mem_inst_result_code_index_type'high downto
           cpu_l1mem_inst_result_code_index_type'low) of std_ulogic;
  constant cpu_l1mem_inst_result_code_valid    : cpu_l1mem_inst_result_code_type := "0001";
  constant cpu_l1mem_inst_result_code_error    : cpu_l1mem_inst_result_code_type := "0010";
  constant cpu_l1mem_inst_result_code_tlbmiss  : cpu_l1mem_inst_result_code_type := "0100";
  constant cpu_l1mem_inst_result_code_pf       : cpu_l1mem_inst_result_code_type := "1000";

end package;
