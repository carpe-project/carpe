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

library util;
use util.types_pkg.all;

use work.cpu_types_pkg.all;
use work.cpu_l1mem_data_types_pkg.all;

package cpu_l1mem_data_pass_pkg is
  
  type cpu_l1mem_data_pass_ctrl_in_type is record
    request      : cpu_l1mem_data_request_code_type;
    cacheen      : std_ulogic;
    mmuen        : std_ulogic;
    alloc        : std_ulogic;
    writethrough : std_ulogic;
    priv         : std_ulogic;
    be           : std_ulogic;
  end record;
  
  type cpu_l1mem_data_pass_dp_in_type is record
    size    : cpu_data_size_type;
    vaddr  : cpu_vaddr_type;
    data  : cpu_word_type;
  end record;
  
  type cpu_l1mem_data_pass_ctrl_out_type is record
    ready : std_ulogic;
    result : cpu_l1mem_data_result_code_type;
  end record;

  type cpu_l1mem_data_pass_dp_out_type is record
    paddr  : cpu_paddr_type;
    data  : cpu_word_type;
  end record;
  
end package;
