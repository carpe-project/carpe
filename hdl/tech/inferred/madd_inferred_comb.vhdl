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

entity madd_inferred_comb is
  generic (
    src_bits : natural := 32
    );
  port (
    clk    : in std_ulogic;
    valid  : in std_ulogic;
    unsgnd : in std_ulogic;
    sub    : in std_ulogic;
    acc    : in std_ulogic_vector(2*src_bits-1 downto 0);
    src1   : in std_ulogic_vector(src_bits-1 downto 0);
    src2   : in std_ulogic_vector(src_bits-1 downto 0);
    result : out std_ulogic_vector(2*src_bits-1 downto 0);
    ov     : out std_ulogic
    );
end;
