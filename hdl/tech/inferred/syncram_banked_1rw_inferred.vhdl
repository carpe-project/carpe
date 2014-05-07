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
use util.types_pkg.all;

entity syncram_banked_1rw_inferred is
  generic (
    addr_bits : natural := 1;
    word_bits : natural := 1;
    log2_banks : natural := 1
    );
  port (
    clk    : in std_ulogic;
    en     : in std_ulogic;
    we     : in std_ulogic;
    banken : in std_ulogic_vector(2**log2_banks-1 downto 0);
    addr   : in std_ulogic_vector(addr_bits-1 downto 0);
    wdata  : in std_ulogic_vector2(2**log2_banks-1 downto 0, word_bits-1 downto 0);
    rdata  : out std_ulogic_vector2(2**log2_banks-1 downto 0, word_bits-1 downto 0)
    );
end;
