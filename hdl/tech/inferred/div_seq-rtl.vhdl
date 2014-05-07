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


architecture rtl of div_seq is
begin

  div : entity work.div_seq_inferred(rtl)
    generic map (
      latency => latency,
      src1_bits => src1_bits,
      src2_bits => src2_bits
      )
    port map (
      clk => clk,
      rstn => rstn,
      en => en,
      unsgnd => unsgnd,
      src1 => src1,
      src2 => src2,
      valid => valid,
      dbz => dbz,
      overflow => overflow,
      result => result
      );
  
end;
