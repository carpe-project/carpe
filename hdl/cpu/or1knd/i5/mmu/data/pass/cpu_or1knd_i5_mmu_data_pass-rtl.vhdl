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


architecture rtl of cpu_or1knd_i5_mmu_data_pass is
begin

  mmu : entity work.cpu_mmu_data_pass(rtl)
    port map (
      clk => clk,
      rstn => rstn,
      cpu_mmu_data_pass_ctrl_in => cpu_or1knd_i5_mmu_data_pass_ctrl_in,
      cpu_mmu_data_pass_ctrl_out => cpu_or1knd_i5_mmu_data_pass_ctrl_out,
      cpu_mmu_data_pass_dp_in => cpu_or1knd_i5_mmu_data_pass_dp_in,
      cpu_mmu_data_pass_dp_out => cpu_or1knd_i5_mmu_data_pass_dp_out
      );

end;
