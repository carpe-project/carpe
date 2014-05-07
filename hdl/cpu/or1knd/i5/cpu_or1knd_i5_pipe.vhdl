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

use work.cpu_or1knd_i5_pkg.all;
use work.cpu_or1knd_i5_pipe_pkg.all;
use work.cpu_l1mem_inst_pkg.all;
use work.cpu_l1mem_data_pkg.all;
use work.cpu_mmu_inst_pkg.all;
use work.cpu_mmu_data_pkg.all;
use work.cpu_or1knd_i5_mmu_inst_pkg.all;
use work.cpu_or1knd_i5_mmu_data_pkg.all;

entity cpu_or1knd_i5_pipe is
  
  port (
    clk                           : in  std_ulogic;
    rstn                          : in  std_ulogic;
    cpu_l1mem_inst_ctrl_in        : out cpu_l1mem_inst_ctrl_in_type;
    cpu_l1mem_inst_dp_in          : out cpu_l1mem_inst_dp_in_type;
    cpu_l1mem_inst_ctrl_out       : in  cpu_l1mem_inst_ctrl_out_type;
    cpu_l1mem_inst_dp_out         : in  cpu_l1mem_inst_dp_out_type;
    cpu_l1mem_data_ctrl_in        : out cpu_l1mem_data_ctrl_in_type;
    cpu_l1mem_data_dp_in          : out cpu_l1mem_data_dp_in_type;
    cpu_l1mem_data_ctrl_out       : in  cpu_l1mem_data_ctrl_out_type;
    cpu_l1mem_data_dp_out         : in  cpu_l1mem_data_dp_out_type;
    cpu_or1knd_i5_mmu_inst_ctrl_in_pipe    : out cpu_or1knd_i5_mmu_inst_ctrl_in_pipe_type;
    cpu_or1knd_i5_mmu_inst_ctrl_out_pipe   : in  cpu_or1knd_i5_mmu_inst_ctrl_out_pipe_type;
    cpu_or1knd_i5_mmu_data_ctrl_in_pipe    : out cpu_or1knd_i5_mmu_data_ctrl_in_pipe_type;
    cpu_or1knd_i5_mmu_data_ctrl_out_pipe   : in  cpu_or1knd_i5_mmu_data_ctrl_out_pipe_type;
    cpu_or1knd_i5_mmu_inst_dp_in_pipe    : out cpu_or1knd_i5_mmu_inst_dp_in_pipe_type;
    cpu_or1knd_i5_mmu_inst_dp_out_pipe   : in  cpu_or1knd_i5_mmu_inst_dp_out_pipe_type;
    cpu_or1knd_i5_mmu_data_dp_in_pipe    : out cpu_or1knd_i5_mmu_data_dp_in_pipe_type;
    cpu_or1knd_i5_mmu_data_dp_out_pipe   : in  cpu_or1knd_i5_mmu_data_dp_out_pipe_type
   );
  
end;
