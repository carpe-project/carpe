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

library sys;
use sys.sys_pkg.all;

use work.cpu_or1knd_i5_pkg.all;

entity cpu_or1knd_i5_core is
  
  port (
    clk                           : in  std_ulogic;
    rstn                          : in  std_ulogic;
    sys_slave_ctrl_out            : in  sys_slave_ctrl_out_type;
    sys_slave_dp_out              : in  sys_slave_dp_out_type;
    sys_master_ctrl_out           : out sys_master_ctrl_out_type;
    sys_master_dp_out             : out sys_master_dp_out_type
   );
  
end;
