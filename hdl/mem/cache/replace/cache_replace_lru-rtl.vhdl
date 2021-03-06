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


-- LRU Cache Replacement Algorithm

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library util;
use util.numeric_pkg.all;
use util.logic_pkg.all;

library tech;

architecture rtl of cache_replace_lru is

  constant assoc : natural := 2**log2_assoc;
  constant state_bits : natural := (assoc-1)*log2_assoc;

  type way_vector_type is array (natural range <>) of std_ulogic_vector(assoc-1 downto 0);
  type statein_mru_way_tmp_type is array (assoc-1 downto 0) of std_ulogic_vector(assoc-2 downto 0);
  type stateout_dec_sel_type is array (assoc-1 downto 0) of std_ulogic_vector(1 downto 0);
  
  type comb_type is record
    statein  : std_ulogic_vector((assoc-1)*log2_assoc-1 downto 0);
    wayin    : std_ulogic_vector(assoc-1 downto 0);

    statein_dec  : way_vector_type(assoc-1 downto 0);
    statein_mru_way_tmp : statein_mru_way_tmp_type;
    statein_mru_way_unpri : std_ulogic_vector(assoc-1 downto 0);
    statein_mru_way       : std_ulogic_vector(assoc-1 downto 0);
    
    stateout : std_ulogic_vector((assoc-1)*log2_assoc-1 downto 0);
    stateout_dec_sel : std_ulogic_vector(assoc-2 downto 0);
    stateout_dec : way_vector_type(assoc-2 downto 0);

    sram_we : std_ulogic;
    sram_waddr : std_ulogic_vector(index_bits-1 downto 0);
    sram_wdata : std_ulogic_vector(state_bits-1 downto 0);
    sram_re : std_ulogic;
    sram_raddr : std_ulogic_vector(index_bits-1 downto 0);
    sram_rdata : std_ulogic_vector(state_bits-1 downto 0);

  end record;
  signal c : comb_type;

begin

  -- state is a list of queue orders
  -- least significant bits -> least recently used
  -- most significant bits -> most recently used
  -- bits indicating MRU are not stored
  -- bits are in (assoc-1) groups of size log2_assoc

  -- so statein(log2_assoc-1 downto 0) is the encoded LRU way

  -- stateout is statein after wayin has become the MRU way

  -- stateout is generated by removing the new MRU way and shifting down less recently used ways in the decoded vector

  c.statein <= wstate;
  c.wayin   <= wway;

  statein_dec_loop : for n in assoc-2 downto 0 generate
    statein_dec_decoder : entity tech.decoder(rtl)
      generic map (
        output_bits => assoc
        )
      port map (
        datain => c.statein(log2_assoc*(n+1)-1 downto log2_assoc*n),
        dataout => c.statein_dec(n)
        );
  end generate;

  -- calculate the MRU way from the stored state.
  -- this is just the way that isn't located at any position in the list of ways.
  statein_mru_way_loop : for n in assoc-1 downto 0 generate

    tmp_loop : for m in assoc-2 downto 0 generate
      c.statein_mru_way_tmp(n)(m) <= c.statein_dec(m)(n);
    end generate;

    c.statein_mru_way(n) <= not reduce_or(c.statein_mru_way_tmp(n));

  end generate;
  -- if the state is uninitialized, there might be multiple ways not present in the list.
  -- the prioritizer chooses the lowest of those ways as the MRU.
  c.statein_dec(assoc-1) <= prioritize_least(c.statein_mru_way);

  c.stateout_dec_sel(0) <= reduce_or(c.wayin and c.statein_dec(0));
  stateout_dec_sel_loop : for n in assoc-2 downto 1 generate
    c.stateout_dec_sel(n) <= reduce_or(c.wayin and c.statein_dec(n)) or c.stateout_dec_sel(n-1);
  end generate;

  with c.stateout_dec_sel(0) select
    c.stateout_dec(0) <= c.statein_dec(0) when '0',
                         c.statein_dec(1) when '1',
                         (others => 'X')  when others;
  stateout_dec_loop : for n in assoc-2 downto 1 generate
    with c.stateout_dec_sel(n) select
      c.stateout_dec(n) <= c.statein_dec(n)   when '0',
                           c.statein_dec(n+1) when '1',
                           (others => 'X')    when others;
  end generate;

  stateout_loop : for n in assoc-2 downto 0 generate
    stateout_encoder : entity tech.encoder(rtl)
      generic map (
        input_bits => assoc
        )
      port map (
        datain => c.stateout_dec(n),
        dataout => c.stateout(log2_assoc*(n+1)-1 downto log2_assoc*n)
        );
  end generate;

  c.sram_we <= we;
  c.sram_waddr <= windex;

  c.sram_wdata <= c.stateout;

  c.sram_re <= re;
  c.sram_raddr <= rindex;
  rstate <= c.sram_rdata;

  -- if the stored state hasn't yet been initialized, the encoded LRU way might me larger than the total number of ways.
  -- if that's the case, then return way 0 as the LRU way.
  rway_decoder : entity tech.decoder(rtl)
    generic map (
      output_bits => 2**log2_assoc
      )
    port map (
      datain  => c.sram_rdata(log2_assoc-1 downto 0),
      dataout => rway
      );
  
  sram : entity tech.syncram_1r1w(rtl)
    generic map (
      addr_bits => index_bits,
      data_bits => state_bits,
      write_first => true
      )
    port map (
      clk => clk,
      we => c.sram_we,
      waddr => c.sram_waddr,
      wdata => c.sram_wdata,
      re => c.sram_re,
      raddr => c.sram_raddr,
      rdata => c.sram_rdata
      );

end;
