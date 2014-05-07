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
use ieee.numeric_std.all;

architecture rtl of add_inferred is

  type comb_type is record
    src1_tmp : std_ulogic_vector(src_bits downto 0);
    src2_tmp : std_ulogic_vector(src_bits downto 0);
    result_tmp : std_ulogic_vector(src_bits downto 0);
    result_msb : std_ulogic;

    result_msb_carryin : std_ulogic;
    carryout : std_ulogic;
  end record;
  signal c : comb_type;
  
begin

  c.src1_tmp <= '0' & src1(src_bits-2 downto 0) & '1';
  c.src2_tmp <= '0' & src2(src_bits-2 downto 0) & carryin;
  
  c.result_tmp <= std_ulogic_vector(unsigned(c.src1_tmp) + unsigned(c.src2_tmp));
  c.result_msb_carryin <= c.result_tmp(src_bits);
  
  c.result_msb <= (src1(src_bits-1) xor
                   src2(src_bits-1) xor
                   c.result_msb_carryin
                   );
  c.carryout <= ((src1(src_bits-1) and (src2(src_bits-1) or c.result_msb_carryin)) or
                 (src2(src_bits-1) and c.result_msb_carryin));
  carryout <= c.carryout;
  overflow <= c.carryout xor c.result_msb_carryin;
  result <= c.result_msb & c.result_tmp(src_bits-1 downto 1);
  
end;
