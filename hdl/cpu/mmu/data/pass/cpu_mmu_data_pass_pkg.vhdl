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

use work.cpu_mmu_data_types_pkg.all;
use work.cpu_types_pkg.all;

package cpu_mmu_data_pass_pkg is

  type cpu_mmu_data_pass_ctrl_in_type is record
    request : std_ulogic;
    mmuen   : std_ulogic;
  end record;

  type cpu_mmu_data_pass_ctrl_out_type is record
    ready        : std_ulogic;
    result       : cpu_mmu_data_result_code_type;
  end record;
  
  type cpu_mmu_data_pass_dp_in_type is record
    vpn : cpu_vpn_type;
  end record;

  type cpu_mmu_data_pass_dp_out_type is record
    ppn : cpu_ppn_type;
  end record;

end package;
