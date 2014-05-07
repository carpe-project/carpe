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

use work.cpu_mmu_inst_pkg.all;
use work.cpu_l1mem_inst_cache_pkg.all;
use work.cpu_l1mem_inst_cache_replace_pkg.all;

library sys;
use sys.sys_pkg.all;

entity cpu_l1mem_inst_cache_dp is
  
  port (
    clk                                   : in  std_ulogic;
    rstn                                  : in  std_ulogic;

    cpu_mmu_inst_dp_in   : out cpu_mmu_inst_dp_in_type;
    cpu_mmu_inst_dp_out   : in cpu_mmu_inst_dp_out_type;
    
    cpu_l1mem_inst_cache_dp_in        : in  cpu_l1mem_inst_cache_dp_in_type;
    cpu_l1mem_inst_cache_dp_out         : out cpu_l1mem_inst_cache_dp_out_type;

    sys_master_dp_out             : out sys_master_dp_out_type;
    sys_slave_dp_out              : in sys_slave_dp_out_type;

    cpu_l1mem_inst_cache_dp_out_vram : out cpu_l1mem_inst_cache_dp_out_vram_type;

    cpu_l1mem_inst_cache_dp_in_tram  : in  cpu_l1mem_inst_cache_dp_in_tram_type;
    cpu_l1mem_inst_cache_dp_out_tram : out cpu_l1mem_inst_cache_dp_out_tram_type;

    cpu_l1mem_inst_cache_dp_in_dram  : in  cpu_l1mem_inst_cache_dp_in_dram_type;
    cpu_l1mem_inst_cache_dp_out_dram : out cpu_l1mem_inst_cache_dp_out_dram_type;

    cpu_l1mem_inst_cache_dp_in_ctrl : in cpu_l1mem_inst_cache_dp_in_ctrl_type;
    cpu_l1mem_inst_cache_dp_out_ctrl : out cpu_l1mem_inst_cache_dp_out_ctrl_type;

    cpu_l1mem_inst_cache_replace_dp_out : in cpu_l1mem_inst_cache_replace_dp_out_type;
    cpu_l1mem_inst_cache_replace_dp_in : out cpu_l1mem_inst_cache_replace_dp_in_type
    );
  
end;
