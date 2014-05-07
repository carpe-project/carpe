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

library util;
use util.numeric_pkg.all;

entity mem_1rw is

  generic (
    addr_bits  : integer := 32;
    log2_byte_bits : integer := 3;
    log2_bus_bytes : integer := 2
    );
  port (
    clk  : in  std_ulogic;
    rstn : in  std_ulogic;
    en   : in  std_ulogic;
    we   : in  std_ulogic;
    be   : in  std_ulogic;
    size : in  std_ulogic_vector(bitsize(log2_bus_bytes)-1 downto 0);
    addr : in  std_ulogic_vector(addr_bits-1 downto 0);
    din  : in  std_ulogic_vector(2**(log2_byte_bits+log2_bus_bytes)-1 downto 0);
    dout : out std_ulogic_vector(2**(log2_byte_bits+log2_bus_bytes)-1 downto 0)
    );
  
end;