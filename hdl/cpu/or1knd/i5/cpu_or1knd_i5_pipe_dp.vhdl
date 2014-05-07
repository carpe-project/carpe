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

use work.cpu_bpb_pkg.all;
use work.cpu_btb_pkg.all;
use work.cpu_or1knd_i5_pkg.all;
use work.cpu_or1knd_i5_pipe_pkg.all;
use work.cpu_l1mem_inst_pkg.all;
use work.cpu_l1mem_data_pkg.all;
use work.cpu_or1knd_i5_mmu_inst_pkg.all;
use work.cpu_or1knd_i5_mmu_data_pkg.all;

entity cpu_or1knd_i5_pipe_dp is
  
  port (
    clk                      : in  std_ulogic;
    
    cpu_or1knd_i5_pipe_dp_in_ctrl  : in cpu_or1knd_i5_pipe_dp_in_ctrl_type;
    cpu_or1knd_i5_pipe_dp_out_ctrl : out cpu_or1knd_i5_pipe_dp_out_ctrl_type;
    
    cpu_or1knd_i5_pipe_dp_in_misc  : in cpu_or1knd_i5_pipe_dp_in_misc_type;
    cpu_or1knd_i5_pipe_dp_out_misc : out cpu_or1knd_i5_pipe_dp_out_misc_type;
    
    cpu_l1mem_inst_dp_in          : out cpu_l1mem_inst_dp_in_type;
    cpu_l1mem_inst_dp_out         : in  cpu_l1mem_inst_dp_out_type;
    
    cpu_l1mem_data_dp_in          : out cpu_l1mem_data_dp_in_type;
    cpu_l1mem_data_dp_out         : in  cpu_l1mem_data_dp_out_type;
    
    cpu_bpb_dp_in            : out cpu_bpb_dp_in_type;
    cpu_bpb_dp_out           : in cpu_bpb_dp_out_type;
    
    cpu_btb_dp_in            : out cpu_btb_dp_in_type;
    cpu_btb_dp_out           : in cpu_btb_dp_out_type;
    
    cpu_or1knd_i5_mmu_inst_dp_in_pipe    : out cpu_or1knd_i5_mmu_inst_dp_in_pipe_type;
    cpu_or1knd_i5_mmu_inst_dp_out_pipe   : in  cpu_or1knd_i5_mmu_inst_dp_out_pipe_type;
    cpu_or1knd_i5_mmu_data_dp_in_pipe    : out cpu_or1knd_i5_mmu_data_dp_in_pipe_type;
    cpu_or1knd_i5_mmu_data_dp_out_pipe   : in  cpu_or1knd_i5_mmu_data_dp_out_pipe_type
    );
  
end;
