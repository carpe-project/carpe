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

package cpu_btb_miss_pkg is

  constant cpu_btb_miss_state_bits : natural := 0;
  subtype cpu_btb_miss_state_type is std_ulogic_vector(cpu_btb_miss_state_bits-1 downto 0);
  
  type cpu_btb_miss_ctrl_in_type is record
    ren : std_ulogic;
    wen : std_ulogic;
  end record;
  
  type cpu_btb_miss_dp_in_type is record
    raddr    : cpu_ivaddr_type;
    waddr    : cpu_ivaddr_type;
    wstate   : cpu_btb_miss_state_type;
    wtarget  : cpu_ivaddr_type;
  end record;
  
  type cpu_btb_miss_ctrl_out_type is record
    rvalid : std_ulogic;
  end record;
  
  type cpu_btb_miss_dp_out_type is record
    rstate  : cpu_btb_miss_state_type;
    rtarget : cpu_ivaddr_type;
  end record;
  
end package;
