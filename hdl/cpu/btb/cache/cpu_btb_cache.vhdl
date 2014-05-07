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


use work.cpu_btb_cache_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity cpu_btb_cache is

  port (
    clk          : in std_ulogic;
    rstn         : in std_ulogic;

    cpu_btb_cache_ctrl_in  : in  cpu_btb_cache_ctrl_in_type;
    cpu_btb_cache_dp_in  : in  cpu_btb_cache_dp_in_type;
    cpu_btb_cache_ctrl_out : out cpu_btb_cache_ctrl_out_type;
    cpu_btb_cache_dp_out : out cpu_btb_cache_dp_out_type
    );

end entity;
