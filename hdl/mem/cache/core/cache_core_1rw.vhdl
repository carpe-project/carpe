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


-- Cache Core (SRAMs), 1 read/write port

library ieee;
use ieee.std_logic_1164.all;

library util;
use util.types_pkg.all;

entity cache_core_1rw is

  generic (
    log2_assoc : natural := 0;
    word_bits : natural := 1;
    index_bits : natural := 1;
    offset_bits : natural := 0;
    tag_bits : natural := 1
    );

  port (
    clk : in std_ulogic;
    rstn : in std_ulogic;

    en : in std_ulogic;
    we : in std_ulogic;

    way : in std_ulogic_vector(2**log2_assoc-1 downto 0);
    tagen : in std_ulogic;
    dataen : in std_ulogic;
    
    index : in std_ulogic_vector(index_bits-1 downto 0);
    offset : in std_ulogic_vector(offset_bits-1 downto 0);
    
    wtag : in std_ulogic_vector(tag_bits-1 downto 0);
    wdata  : in std_ulogic_vector(word_bits-1 downto 0);
    
    rtag : out std_ulogic_vector2(2**log2_assoc-1 downto 0, tag_bits-1 downto 0);
    rdata : out std_ulogic_vector2(2**log2_assoc-1 downto 0, word_bits-1 downto 0)
    );
  
end;
