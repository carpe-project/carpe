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

architecture rtl of cache_core_banked_1r1w is

  constant assoc : natural := 2**log2_assoc;
  constant banks : natural := 2**log2_banks;

  type comb_type is record
    tag_we : std_ulogic;
    tag_wbanken : std_ulogic_vector(assoc-1 downto 0);
    tag_waddr : std_ulogic_vector(index_bits-1 downto 0);
    tag_wdata : std_ulogic_vector2(assoc-1 downto 0, tag_bits downto 0);
    tag_re : std_ulogic;
    tag_rbanken : std_ulogic_vector(assoc-1 downto 0);
    tag_raddr : std_ulogic_vector(index_bits-1 downto 0);
    tag_rdata : std_ulogic_vector2(assoc-1 downto 0, tag_bits downto 0);

    data_we : std_ulogic;
    data_wbanken : std_ulogic_vector(assoc*banks-1 downto 0);
    data_waddr : std_ulogic_vector(index_bits+offset_bits-1 downto 0);
    data_wdata : std_ulogic_vector2(assoc*banks-1 downto 0, word_bits-1 downto 0);
    data_re : std_ulogic;
    data_rbanken : std_ulogic_vector(assoc*banks-1 downto 0);
    data_raddr : std_ulogic_vector(index_bits+offset_bits-1 downto 0);
    data_rdata : std_ulogic_vector2(assoc*banks-1 downto 0, word_bits-1 downto 0);
  end record;
  signal c : comb_type;
    
begin

  c.tag_we        <= we and wtagen;
  c.tag_wbanken   <= wway;
  c.tag_waddr     <= windex;
  
  c.tag_re        <= re and rtagen;
  c.tag_rbanken   <= rway;
  c.tag_raddr     <= rindex;
  
  c.data_we       <= we and wdataen;
  c.data_waddr    <= windex & woffset;
  
  c.data_re       <= re and rdataen;
  c.data_raddr    <= rindex & roffset;
  
  way_loop : for n in assoc-1 downto 0 generate

    tag_bit_loop : for m in tag_bits-1 downto 0 generate
      c.tag_wdata(n, m) <= wtag(m);
      rtag(n, m) <= c.tag_rdata(n, m);
    end generate;

    bank_loop : for m in banks-1 downto 0 generate
      c.data_wbanken(n*banks+m) <= wway(n) and wbanken(m);
      c.data_rbanken(n*banks+m) <= rway(n) and rbanken(m);
      data_bit_loop : for p in word_bits-1 downto 0 generate
        c.data_wdata(n*banks+m, p) <= wdata(m, p);
        rdata(n, m, p) <= c.data_rdata(n*banks+m, p);
      end generate;
    end generate;
      
  end generate;

  seq : process (clk) is
  begin

    if rising_edge(clk) then
      case rstn is
        when '0' =>
          r <= r_init;
        when '1' =>
          r <= r_next;
        when others =>
          r <= r_x;
      end case;
    end if;

  end process;
  
  tag_sram : entity tech.syncram_banked_1r1w(rtl)
    generic map (
      addr_bits => index_bits,
      word_bits => tag_bits,
      log2_banks => log2_assoc
      )
    port map (
      clk => clk,
      we => c.tag_we,
      wbanken => c.tag_wbanken,
      waddr => c.tag_waddr,
      wdata => c.tag_wdata,
      re => c.tag_re,
      rbanken => c.tag_rbanken,
      raddr => c.tag_raddr,
      rdata => c.tag_rdata
      );

  data_sram : entity tech.syncram_banked_1r1w(rtl)
    generic map (
      addr_bits => index_bits + offset_bits,
      word_bits => word_bits,
      log2_banks => log2_assoc
      )
    port map (
      clk => clk,
      we => c.data_we,
      wbanken => c.data_wbanken,
      waddr => c.data_waddr,
      wdata => c.data_wdata,
      re => c.data_re,
      rbanken => c.data_rbanken,
      raddr => c.data_raddr,
      rdata => c.data_rdata
      );

end;
