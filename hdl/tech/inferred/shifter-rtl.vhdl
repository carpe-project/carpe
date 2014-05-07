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


architecture rtl of shifter is
begin

  shifter : entity work.shifter_inferred(rtl)
    generic map (
      src_bits   => src_bits,
      shift_bits => shift_bits
      )
    port map (
      right         => right,
      rot           => rot,
      unsgnd       => unsgnd,
      src           => src,
      shift         => shift,
      shift_unsgnd => shift_unsgnd,
      result        => result
      );
  
end;
