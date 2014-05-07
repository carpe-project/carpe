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


library util;
use util.types_pkg.all;
use util.logic_pkg.all;

library tech;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of cache_core_1rw is

  constant assoc : natural := 2**log2_assoc;

  type comb_type is record
    tag_en : std_ulogic;
    tag_we : std_ulogic;
    tag_banken : std_ulogic_vector(assoc-1 downto 0);
    tag_addr : std_ulogic_vector(index_bits-1 downto 0);
    tag_wdata : std_ulogic_vector2(assoc-1 downto 0, tag_bits-1 downto 0);
    tag_rdata : std_ulogic_vector2(assoc-1 downto 0, tag_bits-1 downto 0);

    data_en : std_ulogic;
    data_we : std_ulogic;
    data_banken : std_ulogic_vector(assoc-1 downto 0);
    data_addr : std_ulogic_vector(index_bits+offset_bits-1 downto 0);
    data_wdata : std_ulogic_vector2(assoc-1 downto 0, word_bits-1 downto 0);
    data_rdata : std_ulogic_vector2(assoc-1 downto 0, word_bits-1 downto 0);
  end record;
  signal c : comb_type;
    
begin

  c.tag_en       <= en and tagen;
  c.tag_we       <= we;
  c.tag_banken   <= way;
  c.tag_addr     <= index;

  c.data_en      <= en and dataen;
  c.data_we      <= we;
  c.data_addr    <= index & offset;
  c.data_banken  <= way;
  
  way_loop : for n in assoc-1 downto 0 generate

    tag_bit_loop : for m in tag_bits-1 downto 0 generate
      c.tag_wdata(n, m) <= wtag(m);
    end generate;

    data_bit_loop : for m in word_bits-1 downto 0 generate
      c.data_wdata(n, m) <= wdata(m);
    end generate;
      
  end generate;

  rtag  <= c.tag_rdata;
  rdata <= c.data_rdata;

  tag_sram : entity tech.syncram_banked_1rw(rtl)
    generic map (
      addr_bits => index_bits,
      word_bits => tag_bits,
      log2_banks => log2_assoc
      )
    port map (
      clk => clk,
      en => c.tag_en,
      we => c.tag_we,
      banken => c.tag_banken,
      addr => c.tag_addr,
      wdata => c.tag_wdata,
      rdata => c.tag_rdata
      );

  data_sram : entity tech.syncram_banked_1rw(rtl)
    generic map (
      addr_bits => index_bits + offset_bits,
      word_bits => word_bits,
      log2_banks => log2_assoc
      )
    port map (
      clk => clk,
      en => c.data_en,
      we => c.data_we,
      banken => c.data_banken,
      addr => c.data_addr,
      wdata => c.data_wdata,
      rdata => c.data_rdata
      );

end;
